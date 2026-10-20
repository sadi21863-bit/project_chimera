extends SceneTree

## T5: network edge cases â€” unreachable URL, part-already-complete skip, empty-part restart.

const MD := preload("res://autoload/model_download.gd")

const KEY := "Test-Model"
const SIZE := 768

var _failures := 0
var _expected := PackedByteArray()
var _sha := ""
var _phase := 0
var _md: Node = null
var _probe_calls := 0
var _range_log: Array = []

func _prep_sha() -> void:
	var f := FileAccess.open("user://t5_expected.bin", FileAccess.WRITE)
	f.store_buffer(_expected)
	f.close()
	_sha = FileAccess.get_sha256("user://t5_expected.bin")
	DirAccess.remove_absolute("user://t5_expected.bin")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		print("FAIL: %s" % msg)

func _make_manager(test_root: String) -> Node:
	var md: Node = MD.new()
	md.test_root = "user://" + test_root
	md.test_catalog = {
		KEY: {
			"url": "http://127.0.0.1:1/x.gguf",
			"size_bytes": SIZE,
			"sha256": _sha,
		},
	}
	md.chunk_bytes = 300
	md.max_stream_retries = 2
	root.add_child(md)
	return md

func _fake_probe(_url: String, cb: Callable) -> void:
	_probe_calls += 1
	cb.call(HTTPRequest.RESULT_SUCCESS, 200,
		PackedStringArray(["Content-Length: %d" % SIZE, 'ETag: "abc"']), PackedByteArray())

func _fake_chunk(_url: String, headers: PackedStringArray, cb: Callable) -> void:
	var start := -1
	for h in headers:
		if h.begins_with("Range: bytes="):
			start = int(h.substr(13).split("-")[0])
	_range_log.append(start)
	var take: int = mini(_md.chunk_bytes, SIZE - start)
	cb.call(HTTPRequest.RESULT_SUCCESS, 206, PackedStringArray(), _expected.slice(start, start + take))

func _wipe(dir: String) -> void:
	var base := DirAccess.open("user://")
	if base == null or not base.dir_exists(dir):
		return
	var d := DirAccess.open("user://" + dir)
	if d != null:
		d.list_dir_begin()
		var fname := d.get_next()
		while fname != "":
			if not d.current_is_dir():
				d.remove(fname)
			fname = d.get_next()
		d.list_dir_end()
	base.remove(dir)

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		for dir in ["t5a", "t5b", "t5c"]:
			_wipe(dir)
		for i in range(SIZE):
			_expected.append((i * 7 + 13) % 256)
		_prep_sha()
		create_timer(20.0).timeout.connect(func() -> void:
			print("FAIL: deadline exceeded in test_model_disk_gate")
			quit(99))
		# (a) unreachable URL: real probe to reserved port -> FAILED(url_unreachable), no part
		_md = _make_manager("t5a")
		_md.chunk_timeout_s = 3.0
		_md.start(KEY)
		return false
	if _phase == 1:
		if _md.state != MD.State.FAILED:
			return false
		_check(_md.state_detail == "url_unreachable",
			"unreachable URL must fail url_unreachable (got %s)" % _md.state_detail)
		var d := DirAccess.open("user://t5a")
		_check(d == null or not d.file_exists("%s.gguf.part" % KEY),
			"failed probe must not leave a part behind")
		_check(not d.file_exists("%s.gguf" % KEY) if d != null else true,
			"failed probe must not leave a final file behind")
		_md.free()
		# (b) full-size part with matching sha: straight VERIFYING->DONE, zero network
		_md = _make_manager("t5b")
		_md.probe_hook = Callable(self, "_fake_probe")
		_md.chunk_hook = Callable(self, "_fake_chunk")
		DirAccess.make_dir_recursive_absolute("user://t5b")
		var pf := FileAccess.open("user://t5b/%s.gguf.part" % KEY, FileAccess.WRITE)
		pf.store_buffer(_expected)
		pf.close()
		var mf := FileAccess.open("user://t5b/%s.gguf.json" % KEY, FileAccess.WRITE)
		mf.store_var({"url": "http://127.0.0.1:1/x.gguf", "etag": "\"abc\"", "size": SIZE})
		mf.close()
		_md.start(KEY)
		_check(_md.state == MD.State.DONE,
			"complete part should promote straight to DONE (got %d)" % int(_md.state))
		_check(_probe_calls == 0, "complete part must not touch the network (probe calls %d)" % _probe_calls)
		_check(_range_log.is_empty(), "complete part must not fetch chunks (ranges %s)" % str(_range_log))
		var final_b := FileAccess.get_file_as_bytes("user://t5b/%s.gguf" % KEY)
		_check(final_b == _expected, "promoted file bytes must match expected")
		_md.free()
		# (c) 0-byte part + valid meta: fresh download from 0
		_md = _make_manager("t5c")
		_md.probe_hook = Callable(self, "_fake_probe")
		_md.chunk_hook = Callable(self, "_fake_chunk")
		DirAccess.make_dir_recursive_absolute("user://t5c")
		var zf := FileAccess.open("user://t5c/%s.gguf.part" % KEY, FileAccess.WRITE)
		zf.close()
		var zmf := FileAccess.open("user://t5c/%s.gguf.json" % KEY, FileAccess.WRITE)
		zmf.store_var({"url": "http://127.0.0.1:1/x.gguf", "etag": "\"abc\"", "size": SIZE})
		zmf.close()
		_md.start(KEY)
		_check(_md.state == MD.State.DONE, "0-byte part should download fresh (got %d)" % int(_md.state))
		_check(_range_log[0] == 0, "0-byte part must Range from 0 (got %s)" % str(_range_log))
		var final_c := FileAccess.get_file_as_bytes("user://t5c/%s.gguf" % KEY)
		_check(final_c == _expected, "0-byte-part final bytes must match expected")
		_md.free()
		for dir in ["t5a", "t5b", "t5c"]:
			_wipe(dir)
		if _failures == 0:
			print("PASS: test_model_disk_gate")
		quit(_failures)
		return true
	return false
