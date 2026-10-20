extends SceneTree

## Local-AI runtime loader regression.
##
## The NobodyWho GDExtension is loaded on demand (never at engine startup: measured ~43 s of init
## vs ~2.4 s for a runtime load), so the loader must (a) find the loose DLL, (b) write a runtime
## .gdextension config addressed by ABSOLUTE path into user://, and (c) actually register the
## NobodyWho classes. On a checkout without the DLL the loader must degrade gracefully.

var failures := 0
var checks := 0


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	_run()


func _run() -> void:
	await create_timer(0.1).timeout
	var local_ai = root.get_node_or_null("LocalAI")
	if local_ai == null:
		print("FAIL: LocalAI autoload missing")
		quit(1)
		return

	var dll: String = local_ai.dll_path()
	if dll.is_empty():
		_check(not local_ai.is_available(), "runtime unavailable when the DLL is absent")
		_check(not local_ai.enable(), "enable() fails cleanly when the DLL is absent")
		_check(local_ai.last_error() == "runtime_missing", "error code is runtime_missing (got %s)" % local_ai.last_error())
		print("--- local AI runtime: %d checks, %d failures (no DLL present) ---" % [checks, failures])
		quit(failures)
		return

	_check(dll.ends_with("libnobodywho-godot-x86_64-pc-windows-msvc-release.dll"), "dll_path points at the extension library (got %s)" % dll)
	_check(FileAccess.file_exists(dll), "dll_path exists on disk")

	var cfg: String = local_ai.config_text(dll)
	_check(cfg.contains("entry_symbol = \"gdext_rust_init\""), "config declares the Rust entry symbol")
	_check(cfg.contains("windows.release.x86_64 = \"%s\"" % dll.replace("\\", "/")), "config binds the absolute DLL path")
	_check(not cfg.contains("user://"), "config does not use a user:// library path (Godot rejects those)")

	var ok: bool = local_ai.enable()
	_check(ok, "enable() loads the extension (last_error=%s)" % local_ai.last_error())
	_check(local_ai.is_available(), "NobodyWho classes are registered after enable()")
	_check(ClassDB.class_exists("NobodyWhoModel"), "ClassDB has NobodyWhoModel")
	_check(ClassDB.class_exists("NobodyWhoChat"), "ClassDB has NobodyWhoChat")
	_check(local_ai.enable(), "enable() is idempotent")

	print("--- local AI runtime: %d checks, %d failures ---" % [checks, failures])
	quit(failures)
