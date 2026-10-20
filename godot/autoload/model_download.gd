extends Node

## Game-owned GGUF download manager: probe -> chunked Range download -> SHA-256 verify ->
## atomic promote into user://models. When the engine moves past 4.7, HTTPRequest's
## keep_partial_download/append_to_download_file can replace the chunk loop (PR #118226).

signal state_changed(state: int, detail: String)
signal progress_changed(recv: int, total: int)
signal finished(ok: bool, detail: String)
signal local_model_downloaded(key: String)

enum State { IDLE, CHECKING, PROBING, DOWNLOADING, PAUSED, VERIFYING, PROMOTING, DONE, FAILED }

const ModelCatalog := preload("res://scripts/ai/model_catalog.gd")

const TARGET_DIR := "user://models"
const PART_SUFFIX := ".part"
const META_SUFFIX := ".json"
const CHUNK_BYTES := 8388608
const CHUNK_TIMEOUT_S := 30.0
const MAX_STREAM_RETRIES := 10
const RETRY_BACKOFF_BASE := 0.25
const RETRY_BACKOFF_CAP := 4.0
const SPACE_RECHECK_BYTES := 268435456
const FREE_BYTES_MULTIPLIER := 2
const BUSY_STATES: Array[int] = [
	State.CHECKING, State.PROBING, State.DOWNLOADING, State.PAUSED, State.VERIFYING, State.PROMOTING,
]

var state: int = State.IDLE
var state_detail: String = ""
var active_key: String = ""

var test_root: String = ""
var test_catalog: Dictionary = {}
var probe_hook: Callable = Callable()
var chunk_hook: Callable = Callable()
var disk_hook: Callable = Callable()
var chunk_bytes: int = CHUNK_BYTES
var max_stream_retries: int = MAX_STREAM_RETRIES
var chunk_timeout_s: float = CHUNK_TIMEOUT_S

var _pause_requested := false
var _stream_retries := 0
var _bytes_since_space_check := 0
var _probe_req: HTTPRequest = null
var _chunk_req: HTTPRequest = null
var _key_states: Dictionary = {}
var _key_details: Dictionary = {}
var _key_progress: Dictionary = {}


func _ready() -> void:
	for key in _catalog():
		if is_model_present(key):
			_key_states[key] = State.DONE
			_key_details[key] = ""
			continue
		if _meta_load(key).is_empty():
			continue
		if FileAccess.file_exists(_part_path(key)):
			start(key)
			return


func start(key: String) -> void:
	if not _catalog().has(key):
		return
	if state in [State.CHECKING, State.PROBING, State.DOWNLOADING, State.VERIFYING, State.PROMOTING]:
		return
	active_key = key
	_pause_requested = false
	_stream_retries = 0
	_bytes_since_space_check = 0
	_begin_checking()


func pause() -> void:
	if state in [State.CHECKING, State.PROBING, State.DOWNLOADING]:
		_pause_requested = true


func resume() -> void:
	if state != State.PAUSED or active_key == "":
		return
	start(active_key)


func cancel() -> void:
	if state == State.IDLE:
		return
	if _chunk_req != null and is_instance_valid(_chunk_req):
		_chunk_req.cancel_request()
	if _probe_req != null and is_instance_valid(_probe_req):
		_probe_req.cancel_request()
	var key := active_key
	if state in BUSY_STATES and key != "":
		_delete_part_files(key)
	active_key = ""
	state = State.IDLE
	state_detail = ""
	if key != "":
		_key_states[key] = State.IDLE
		_key_details[key] = ""
	state_changed.emit(State.IDLE, "")


func delete_model(key: String) -> bool:
	if active_key == key and state in BUSY_STATES:
		return false
	var removed := false
	var dir := _dir()
	if dir != null and dir.file_exists(key + ".gguf"):
		dir.remove(key + ".gguf")
		removed = true
	_delete_part_files(key)
	_key_states[key] = State.IDLE
	_key_details[key] = ""
	if key == active_key and state in [State.DONE, State.FAILED]:
		active_key = ""
		state = State.IDLE
		state_detail = ""
	state_changed.emit(State.IDLE, "")
	return removed


func is_busy() -> bool:
	return state in BUSY_STATES


func keys() -> Array:
	return _catalog().keys()


func entry(key: String) -> Dictionary:
	return _catalog().get(key, {})


func entry_state(key: String) -> int:
	if key == active_key:
		return state
	if is_model_present(key):
		return State.DONE
	return int(_key_states.get(key, State.IDLE))


func detail(key: String) -> String:
	if key == active_key:
		return state_detail
	return str(_key_details.get(key, ""))


func last_progress(key: String) -> Vector2i:
	return _key_progress.get(key, Vector2i(0, 0))


func is_model_present(key: String) -> bool:
	return FileAccess.file_exists(_final_path(key))


# --- flow steps ---

func _begin_checking() -> void:
	_set_state(State.CHECKING, "")
	var key := active_key
	var size := int(entry(key).get("size_bytes", 0))
	if size <= 0:
		_fail("invalid_entry")
		return
	_ensure_target_dir()
	if is_model_present(key):
		_key_states[key] = State.DONE
		_key_details[key] = ""
		state = State.DONE
		state_detail = ""
		finished.emit(true, "")
		if test_catalog.is_empty():
			local_model_downloaded.emit(key)
		return
	var n := _part_size(key)
	if n >= size:
		_begin_verify()
		return
	if n > 0 and _meta_load(key).is_empty() and n <= chunk_bytes:
		_delete_part_files(key)
		n = 0
	if n < size:
		var free := _query_space()
		if free > 0 and free < size * FREE_BYTES_MULTIPLIER:
			_set_state(State.PAUSED, "disk_low")
			return
	_probe()


func _probe() -> void:
	_set_state(State.PROBING, "")
	var url := str(entry(active_key).get("url", ""))
	_fire_probe(url, _on_probe_done)


func _fire_probe(url: String, cb: Callable) -> void:
	if probe_hook.is_valid():
		probe_hook.call(url, cb)
		return
	_probe_req = _spawn_request()
	_probe_req.request_completed.connect(cb, CONNECT_ONE_SHOT)
	var err := _probe_req.request(url, PackedStringArray(), HTTPClient.METHOD_HEAD)
	if err != OK:
		_probe_req.queue_free()
		_probe_req = null
		cb.call(HTTPRequest.RESULT_REQUEST_FAILED, 0, PackedStringArray(), PackedByteArray())


func _on_probe_done(result: int, code: int, headers: PackedStringArray, _body: PackedByteArray) -> void:
	var req := _probe_req
	_probe_req = null
	if req != null and is_instance_valid(req):
		req.queue_free()
	if state != State.PROBING or active_key == "":
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("url_unreachable")
		return
	var key := active_key
	var ent: Dictionary = entry(key)
	var size := int(ent.get("size_bytes", 0))
	var content_len := _int_header(_header_value(headers, "Content-Length"))
	if content_len > 0 and content_len != size:
		_fail("size_mismatch")
		return
	var etag := _header_value(headers, "ETag")
	var last_modified := _header_value(headers, "Last-Modified")
	var meta := _meta_load(key)
	if meta.is_empty() or str(meta.get("url", "")) != str(ent.get("url", "")):
		_meta_save(key, {
			"url": ent.get("url", ""), "etag": etag,
			"last_modified": last_modified, "size": size,
		})
	elif not etag.is_empty() and str(meta.get("etag", "")) != etag:
		_restart_part(key)
		meta["etag"] = etag
		meta["last_modified"] = last_modified
		_meta_save(key, meta)
	_set_state(State.DOWNLOADING, "")
	_pump()


func _pump() -> void:
	if state != State.DOWNLOADING or active_key == "":
		return
	if _pause_requested:
		_set_state(State.PAUSED, "paused")
		return
	var key := active_key
	var ent: Dictionary = entry(key)
	var size := int(ent.get("size_bytes", 0))
	var n := _part_size(key)
	if n >= size:
		_begin_verify()
		return
	var end_byte := n + chunk_bytes - 1
	if end_byte > size - 1:
		end_byte = size - 1
	var headers := PackedStringArray([
		"Range: bytes=%d-%d" % [n, end_byte],
		"Accept-Encoding: identity",
	])
	var etag := str(_meta_load(key).get("etag", ""))
	if not etag.is_empty():
		headers.append("If-Range: " + etag)
	_fire_chunk(str(ent.get("url", "")), headers, _on_chunk_done.bind(n))


func _fire_chunk(url: String, headers: PackedStringArray, cb: Callable) -> void:
	if chunk_hook.is_valid():
		chunk_hook.call(url, headers, cb)
		return
	_chunk_req = _spawn_request()
	_chunk_req.request_completed.connect(cb, CONNECT_ONE_SHOT)
	var err := _chunk_req.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_chunk_req.queue_free()
		_chunk_req = null
		cb.call(HTTPRequest.RESULT_REQUEST_FAILED, 0, PackedStringArray(), PackedByteArray())


func _on_chunk_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, n_requested: int) -> void:
	var req := _chunk_req
	_chunk_req = null
	if req != null and is_instance_valid(req):
		req.queue_free()
	if state != State.DOWNLOADING or active_key == "":
		return
	var key := active_key
	var size := int(entry(key).get("size_bytes", 0))
	var n := _part_size(key)
	if n != n_requested:
		return
	if result != HTTPRequest.RESULT_SUCCESS or (code != 206 and code != 200):
		_stream_retry()
		return
	if code == 200 and n > 0:
		_restart_part(key)
		_bytes_since_space_check = 0
		_pump()
		return
	if body.is_empty():
		_stream_retry()
		return
	_stream_retries = 0
	var remaining := size - n
	var take := body.size()
	if take > remaining:
		take = remaining
	if not _append_chunk(_part_path(key), body, take, n == 0):
		_fail("write_error")
		return
	var n2 := _part_size(key)
	progress_changed.emit(n2, size)
	_key_progress[key] = Vector2i(n2, size)
	_bytes_since_space_check += take
	if _bytes_since_space_check >= SPACE_RECHECK_BYTES:
		_bytes_since_space_check = 0
		var free := _query_space()
		if free > 0 and free < int(entry(key).get("size_bytes", 0)) * FREE_BYTES_MULTIPLIER:
			_set_state(State.PAUSED, "disk_low")
			return
	if n2 >= size:
		_begin_verify()
		return
	_pump()


func _stream_retry() -> void:
	_stream_retries += 1
	if _stream_retries >= max_stream_retries:
		_set_state(State.PAUSED, "network_dropout")
		return
	var delay: float = minf(RETRY_BACKOFF_BASE * pow(2.0, float(_stream_retries)), RETRY_BACKOFF_CAP)
	get_tree().create_timer(delay).timeout.connect(_pump)


func _begin_verify() -> void:
	_set_state(State.VERIFYING, "")
	var key := active_key
	var ent: Dictionary = entry(key)
	var size := int(ent.get("size_bytes", 0))
	var sha := str(ent.get("sha256", ""))
	var part_path := _part_path(key)
	if not FileAccess.file_exists(part_path) or _part_size(key) != size:
		_delete_part_files(key)
		_fail("size_mismatch")
		return
	if not sha.is_empty() and FileAccess.get_sha256(part_path) != sha:
		_delete_part_files(key)
		_fail("checksum_mismatch")
		return
	_begin_promote()


func _begin_promote() -> void:
	_set_state(State.PROMOTING, "")
	var key := active_key
	var dir := _dir()
	if dir == null:
		_fail("promote_error")
		return
	var err := dir.rename(key + ".gguf" + PART_SUFFIX, key + ".gguf")
	if err != OK:
		_fail("promote_error")
		return
	dir.remove(key + ".gguf" + META_SUFFIX)
	state = State.DONE
	state_detail = ""
	_key_states[key] = State.DONE
	_key_details[key] = ""
	finished.emit(true, "")
	if test_catalog.is_empty():
		var local_ai := get_node_or_null("/root/LocalAI")
		if local_ai != null and local_ai.has_method("enable"):
			local_ai.enable()
		else:
			var ac := get_node_or_null("/root/AIClient")
			if ac != null and ac.has_method("refresh_local_provider"):
				ac.refresh_local_provider()
		local_model_downloaded.emit(key)


# --- helpers ---

func _fail(detail: String) -> void:
	_set_state(State.FAILED, detail)
	finished.emit(false, detail)


func _set_state(s: int, d: String) -> void:
	state = s
	state_detail = d
	if active_key != "":
		_key_states[active_key] = s
		_key_details[active_key] = d
	state_changed.emit(s, d)


func _catalog() -> Dictionary:
	return test_catalog if not test_catalog.is_empty() else ModelCatalog.REQUIREMENTS


func _target_dir() -> String:
	return test_root if not test_root.is_empty() else TARGET_DIR


func _final_path(key: String) -> String:
	return _target_dir().path_join(key + ".gguf")


func _part_path(key: String) -> String:
	return _final_path(key) + PART_SUFFIX


func _meta_path(key: String) -> String:
	return _final_path(key) + META_SUFFIX


func _part_size(key: String) -> int:
	var p := _part_path(key)
	return FileAccess.get_size(p) if FileAccess.file_exists(p) else 0


func _dir() -> DirAccess:
	return DirAccess.open(_target_dir())


func _ensure_target_dir() -> void:
	var d := _target_dir()
	if DirAccess.dir_exists_absolute(d):
		return
	DirAccess.make_dir_recursive_absolute(d)


func _query_space() -> int:
	if disk_hook.is_valid():
		return int(disk_hook.call())
	_ensure_target_dir()
	var dir := _dir()
	if dir == null:
		return 0
	return dir.get_space_left()


func _delete_part_files(key: String) -> void:
	var dir := _dir()
	if dir == null:
		return
	var part_name := key + ".gguf" + PART_SUFFIX
	var meta_name := key + ".gguf" + META_SUFFIX
	if dir.file_exists(part_name):
		dir.remove(part_name)
	if dir.file_exists(meta_name):
		dir.remove(meta_name)


func _restart_part(key: String) -> void:
	var dir := _dir()
	if dir != null:
		var part_name := key + ".gguf" + PART_SUFFIX
		if dir.file_exists(part_name):
			dir.remove(part_name)


func _append_chunk(part_path: String, body: PackedByteArray, take: int, fresh: bool) -> bool:
	var f: FileAccess = FileAccess.open(part_path, FileAccess.WRITE if fresh else FileAccess.READ_WRITE)
	if f == null:
		return false
	if not fresh:
		f.seek(f.get_length())
	f.store_buffer(body.slice(0, take))
	var err := f.get_error()
	f.close()
	return err == OK


func _meta_load(key: String) -> Dictionary:
	var path := _meta_path(key)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = f.get_var()
	f.close()
	if v is Dictionary:
		return v
	return {}


func _meta_save(key: String, meta: Dictionary) -> void:
	var f := FileAccess.open(_meta_path(key), FileAccess.WRITE)
	if f == null:
		return
	f.store_var(meta)
	f.close()


func _spawn_request() -> HTTPRequest:
	var req := HTTPRequest.new()
	req.timeout = chunk_timeout_s
	req.accept_gzip = false
	req.max_redirects = 8
	add_child(req)
	return req


func _header_value(headers: PackedStringArray, name: String) -> String:
	var lname := name.to_lower()
	for h in headers:
		var ci := h.find(":")
		if ci <= 0:
			continue
		if h.substr(0, ci).strip_edges().to_lower() == lname:
			return h.substr(ci + 1).strip_edges()
	return ""


func _int_header(value: String) -> int:
	if value.is_empty():
		return -1
	return int(value)
