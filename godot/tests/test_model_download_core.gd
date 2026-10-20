extends SceneTree

## T2: ModelDownload core flow with fully scripted (no-network) hooks.
## Fixture: 768 bytes, chunk window 300 -> windows at 0 / 300 / 600.

const MD := preload("res://autoload/model_download.gd")

const KEY := "Test-Model"
const SIZE := 768

var _failures := 0
var _expected := PackedByteArray()
var _sha := ""
var _seq: Array = []
var _fin: Array = []
var _range_log: Array = []
var _probe_log: Array = []
var _chunk_script: Array = []
var _md: Node = null
var _cur_dir := ""
var _phase := 0

func _prep_sha() -> void:
	var f := FileAccess.open("user://t2_expected.bin", FileAccess.WRITE)
	f.store_buffer(_expected)
	f.close()
	_sha = FileAccess.get_sha256("user://t2_expected.bin")
	DirAccess.remove_absolute("user://t2_expected.bin")

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		print("FAIL: %s" % msg)

func _make_manager() -> void:
	_md = MD.new()
	_md.test_root = "user://" + _cur_dir
	_md.test_catalog = {
		KEY: {
			"url": "http://127.0.0.1:1/never-requested.gguf",
			"size_bytes": SIZE,
			"sha256": _sha,
		},
	}
	_md.chunk_bytes = 300
	_md.max_stream_retries = 2
	_md.probe_hook = Callable(self, "_fake_probe")
	_md.chunk_hook = Callable(self, "_fake_chunk")
	root.add_child(_md)
	_seq = []
	_fin = []
	_range_log = []
	_probe_log = []
	_chunk_script = []
	_md.state_changed.connect(func(s: int, _d: String) -> void: _seq.append(s))
	_md.finished.connect(func(ok: bool, _d: String) -> void: _fin.append(ok))

func _fake_probe(_url: String, cb: Callable) -> void:
	_probe_log.append(_url)
	cb.call(HTTPRequest.RESULT_SUCCESS, 200,
		PackedStringArray(["Content-Length: %d" % SIZE, 'ETag: "abc"']), PackedByteArray())

func _fake_chunk(_url: String, headers: PackedStringArray, cb: Callable) -> void:
	var start := -1
	for h in headers:
		if h.begins_with("Range: bytes="):
			start = int(h.substr(13).split("-")[0])
	_range_log.append(start)
	if not _chunk_script.is_empty():
		var scripted: Variant = _chunk_script.pop_front()
		if scripted is int:
			cb.call(int(scripted), 0, PackedStringArray(), PackedByteArray())
			return
	var take: int = mini(_md.chunk_bytes, SIZE - start)
	cb.call(HTTPRequest.RESULT_SUCCESS, 206, PackedStringArray(), _expected.slice(start, start + take))

func _disk_100() -> int:
	return 100

func _part_bytes(n: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(n)
	b.fill(0xAA)
	return b

func _dir_file(dir: String, name: String) -> bool:
	var d := DirAccess.open("user://" + dir)
	return d != null and d.file_exists(name)

func _wipe(dir: String) -> void:
	var base := DirAccess.open("user://")
	if base == null:
		return
	if not base.dir_exists(dir):
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
		_run_all_cases()
	return _poll_resume_b()

func _run_all_cases() -> void:
	for d in ["t2a", "t2b", "t2c", "t2d", "t2e", "t2f"]:
		_wipe(d)
	for i in range(SIZE):
		_expected.append((i * 7 + 13) % 256)
	_prep_sha()
	create_timer(25.0).timeout.connect(func() -> void:
		print("FAIL: deadline exceeded in test_model_download_core")
		quit(99))

	# --- (a) happy path: exact state sequence + exact bytes ---
	_cur_dir = "t2a"
	_make_manager()
	_md.start(KEY)
	_check(_seq == [MD.State.CHECKING, MD.State.PROBING, MD.State.DOWNLOADING, MD.State.VERIFYING, MD.State.PROMOTING],
		"happy path state sequence wrong (got %s)" % str(_seq))
	_check(_md.state == MD.State.DONE, "happy path should end DONE (got %d)" % int(_md.state))
	_check(_fin == [true], "happy path should emit finished(true) once (got %s)" % str(_fin))
	_check(_range_log == [0, 300, 600], "range log should hit all three windows (got %s)" % str(_range_log))
	var final := FileAccess.get_file_as_bytes("user://t2a/%s.gguf" % KEY)
	_check(final == _expected, "final file bytes must match expected")
	_check(not _dir_file("t2a", "%s.gguf.part" % KEY), "part must be gone after promote")
	_check(not _dir_file("t2a", "%s.gguf.json" % KEY), "meta must be gone after promote")
	_md.free()

	# --- (c) checksum mismatch deletes part+meta and fails ---
	_cur_dir = "t2c"
	_make_manager()
	_md.test_catalog[KEY]["sha256"] = "00".repeat(32)
	_md.start(KEY)
	_check(_md.state == MD.State.FAILED and _md.state_detail == "checksum_mismatch",
		"checksum mismatch should FAILED(checksum_mismatch) (got %d/%s)" % [int(_md.state), _md.state_detail])
	_check(not _dir_file("t2c", "%s.gguf.part" % KEY), "checksum mismatch must delete part")
	_check(not _dir_file("t2c", "%s.gguf.json" % KEY), "checksum mismatch must delete meta")
	_md.free()

	# --- (d) etag mismatch restarts from 0 ---
	_cur_dir = "t2d"
	_make_manager()
	DirAccess.make_dir_recursive_absolute("user://t2d")
	var mf := FileAccess.open("user://t2d/%s.gguf.json" % KEY, FileAccess.WRITE)
	mf.store_var({"url": "http://127.0.0.1:1/never-requested.gguf", "etag": "old-etag", "size": SIZE})
	mf.close()
	var pf := FileAccess.open("user://t2d/%s.gguf.part" % KEY, FileAccess.WRITE)
	pf.store_buffer(_part_bytes(600))
	pf.close()
	_md.start(KEY)
	_check(_md.state == MD.State.DONE, "etag-mismatch run should still complete (got %d)" % int(_md.state))
	_check(_range_log[0] == 0, "etag mismatch must restart download at 0 (got first range %s)" % str(_range_log))
	var final_d := FileAccess.get_file_as_bytes("user://t2d/%s.gguf" % KEY)
	_check(final_d == _expected, "etag-mismatch final bytes must be fully re-downloaded")
	_md.free()

	# --- (e) short part resumes at its own size ---
	_cur_dir = "t2e"
	_make_manager()
	DirAccess.make_dir_recursive_absolute("user://t2e")
	var ef := FileAccess.open("user://t2e/%s.gguf.part" % KEY, FileAccess.WRITE)
	ef.store_buffer(_expected.slice(0, 500))
	ef.close()
	var emf := FileAccess.open("user://t2e/%s.gguf.json" % KEY, FileAccess.WRITE)
	emf.store_var({"url": "http://127.0.0.1:1/never-requested.gguf", "etag": "\"abc\"", "size": SIZE})
	emf.close()
	_md.start(KEY)
	_check(_md.state == MD.State.DONE, "short-part run should complete (got %d)" % int(_md.state))
	_check(_range_log[0] == 500, "short part must resume at 500 (got first range %s)" % str(_range_log))
	var final_e := FileAccess.get_file_as_bytes("user://t2e/%s.gguf" % KEY)
	_check(final_e == _expected, "short-part final bytes must match expected")
	_md.free()

	# --- (f) disk gate fires before any request ---
	_cur_dir = "t2f"
	_make_manager()
	_md.disk_hook = Callable(self, "_disk_100")
	_md.start(KEY)
	_check(_md.state == MD.State.PAUSED and _md.state_detail == "disk_low",
		"tiny disk should PAUSED(disk_low) (got %d/%s)" % [int(_md.state), _md.state_detail])
	_check(_probe_log.is_empty(), "disk gate must fire before any request (probe log %s)" % str(_probe_log))
	_md.free()

	# --- (b) interrupted resume: 2 chunks, then connection errors -> PAUSED; resume finishes ---
	_cur_dir = "t2b"
	_make_manager()
	_chunk_script = [null, null, HTTPRequest.RESULT_CONNECTION_ERROR, HTTPRequest.RESULT_CONNECTION_ERROR]
	_md.start(KEY)

func _poll_resume_b() -> bool:
	if _md == null:
		return false
	if _md.state == MD.State.PAUSED and _md.state_detail == "network_dropout":
		_check(_part_file_size() == 600, "part must be preserved at 600 bytes before resume (got %d)" % _part_file_size())
		_check(_range_log == [0, 300, 600, 600],
			"windows should be 0/300 successes then two failed 600s (got %s)" % str(_range_log))
		_md.resume()
		_check(_md.state == MD.State.DONE, "resume should complete synchronously (got %d)" % int(_md.state))
		_check(_range_log == [0, 300, 600, 600, 600], "resumed download must Range from 600 (got %s)" % str(_range_log))
		var final_b := FileAccess.get_file_as_bytes("user://t2b/%s.gguf" % KEY)
		_check(final_b == _expected, "resumed final bytes must match expected")
		_md.free()
		for d in ["t2a", "t2b", "t2c", "t2d", "t2e", "t2f"]:
			_wipe(d)
		if _failures == 0:
			print("PASS: test_model_download_core")
		quit(_failures)
		return true
	return false

func _part_file_size() -> int:
	return FileAccess.get_size("user://t2b/%s.gguf.part" % KEY)
