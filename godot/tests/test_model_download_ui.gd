extends SceneTree

## T3: settings-screen Local AI section driven by a scripted manager (no network, no DLL need —
## AIClient._local_provider is swapped for a stub so the LOCAL runtime appears available).

const MD := preload("res://autoload/model_download.gd")

var _failures := 0

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		print("FAIL: %s" % msg)


class FakeManager extends RefCounted:
	signal state_changed(state: int, detail: String)
	signal progress_changed(recv: int, total: int)
	signal finished(ok: bool, detail: String)
	enum State { IDLE, CHECKING, PROBING, DOWNLOADING, PAUSED, VERIFYING, PROMOTING, DONE, FAILED }

	var state: int = State.IDLE
	var detail_text := ""
	var active_key := ""
	var busy := false
	var present := false
	var recv := 0
	var total := 0

	func is_busy() -> bool:
		return busy

	func entry_state(_k: String) -> int:
		return state

	func detail(_k: String) -> String:
		return detail_text

	func last_progress(_k: String) -> Vector2i:
		return Vector2i(recv, total)

	func is_model_present(_k: String) -> bool:
		return present

	func start(k: String) -> void:
		active_key = k
		busy = true
		state = State.DOWNLOADING
		detail_text = ""
		state_changed.emit(state, "")

	func pause() -> void:
		state = State.PAUSED
		detail_text = "paused"
		state_changed.emit(state, detail_text)

	func resume() -> void:
		state = State.DOWNLOADING
		detail_text = ""
		state_changed.emit(state, "")

	func cancel() -> void:
		active_key = ""
		busy = false
		state = State.IDLE
		state_changed.emit(State.IDLE, "")

	func delete_model(_k: String) -> bool:
		present = false
		busy = false
		state = State.IDLE
		state_changed.emit(State.IDLE, "")
		return true


func _process(_delta: float) -> bool:
	var client: Node = root.get_node("AIClient")
	var orig_provider: Node = client.get("_local_provider")
	var stub: Node = load("res://tests/stub_local_provider.gd").new()
	client.set("_local_provider", stub)

	var screen: Node = load("res://scenes/ui/settings_screen.tscn").instantiate()
	root.add_child(screen)
	var fake := FakeManager.new()
	screen.bind_manager(fake)

	_check(screen.get_node_or_null("Panel/VBox/LocalStatus") != null, "LocalStatus node must exist")
	_check(screen.get_node_or_null("Panel/VBox/LocalDownload") != null, "LocalDownload node must exist")
	_check(screen.get_node_or_null("Panel/VBox/LocalChoice") != null,
		"LocalChoice must exist (catalog has 2 entries)")
	_check(screen.get_node_or_null("Panel/VBox/LocalAttribution") != null, "LocalAttribution node must exist")

	# idle: download offered, progress hidden
	_check(String(screen._local_status.text).contains("Not installed"),
		"idle status should say not installed (got %s)" % screen._local_status.text)
	_check(screen._local_download.visible, "download button should be visible when idle")

	# download press -> scripted DOWNLOADING
	screen._local_download.pressed.emit()
	_check(String(screen._local_status.text).begins_with("Downloading"),
		"status should show downloading after start (got %s)" % screen._local_status.text)
	_check(not screen._local_download.visible, "download button must hide while downloading")
	_check(screen._local_pause.visible and screen._local_cancel.visible,
		"pause+cancel must show while downloading")

	# progress signal drives the bar
	fake.progress_changed.emit(384, 768)
	_check(absf(float(screen._local_progress.value) - 384.0) < 0.001,
		"progress bar value should track signal (got %s)" % str(screen._local_progress.value))
	_check(absf(float(screen._local_progress.max_value) - 768.0) < 0.001,
		"progress bar max should be total bytes (got %s)" % str(screen._local_progress.max_value))

	# pause / resume labels
	fake.pause()
	_check(String(screen._local_status.text).contains("Paused"),
		"status should show paused (got %s)" % screen._local_status.text)
	_check(screen._local_resume.visible, "resume must show when paused")
	fake.resume()
	_check(String(screen._local_status.text).begins_with("Downloading"),
		"status should return to downloading on resume (got %s)" % screen._local_status.text)

	# cancel needs a second confirming press
	screen._local_cancel.pressed.emit()
	_check(String(screen._local_cancel.text).contains("press again"),
		"first cancel press should arm confirmation (got %s)" % screen._local_cancel.text)
	screen._local_cancel.pressed.emit()
	_check(String(screen._local_status.text).contains("Not installed"),
		"confirmed cancel should return to idle (got %s)" % screen._local_status.text)

	# failure surfaces the reason
	fake.state = FakeManager.State.FAILED
	fake.detail_text = "checksum_mismatch"
	fake.state_changed.emit(FakeManager.State.FAILED, "checksum_mismatch")
	fake.finished.emit(false, "checksum_mismatch")
	_check(String(screen._local_status.text) == "Download failed (checksum_mismatch).",
		"failure label should name the reason (got %s)" % screen._local_status.text)

	# success: Installed state, delete offered, download hidden
	fake.present = true
	fake.state = FakeManager.State.DONE
	fake.detail_text = ""
	fake.state_changed.emit(FakeManager.State.DONE, "")
	fake.finished.emit(true, "")
	_check(String(screen._local_status.text) == "Installed. LOCAL mode active next decision.",
		"success label should say installed (got %s)" % screen._local_status.text)
	_check(not screen._local_download.visible, "download must hide when installed")
	_check(screen._local_delete.visible, "delete must show when installed")

	# delete needs a second confirming press
	screen._local_delete.pressed.emit()
	_check(String(screen._local_delete.text).contains("press again"),
		"first delete press should arm confirmation (got %s)" % screen._local_delete.text)
	screen._local_delete.pressed.emit()
	_check(String(screen._local_status.text).contains("Not installed"),
		"confirmed delete should return to idle (got %s)" % screen._local_status.text)

	# attribution line carries source + license
	_check(String(screen._local_attr.text).contains("License"),
		"attribution line should mention the license (got %s)" % screen._local_attr.text)

	client.set("_local_provider", orig_provider)
	stub.free()
	screen.free()

	if _failures == 0:
		print("PASS: test_model_download_ui")
	quit(_failures)
	return true
