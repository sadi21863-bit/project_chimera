extends Node

## Local-AI runtime loader.
##
## The NobodyWho GDExtension is NOT bundled inside the PCK and NOT auto-loaded at startup:
## measured on this machine, an engine-startup load of the extension costs ~43 s of init
## (a runtime load of the same library costs ~2.4 s), so shipping it auto-loaded would give every
## player a 45-second boot before the first frame. Instead the extension is loaded on demand:
##
##   1. the player downloads a GGUF into user://models (ModelDownload),
##   2. LocalAI.enable() writes a runtime .gdextension config into user:// whose [libraries] entry
##      points at the ABSOLUTE path of the loose DLL, and calls GDExtensionManager.load_extension(),
##   3. the provider (nobodywho_provider.gd) re-resolves the model path and LOCAL becomes live.
##
## Godot 4.7 accepts the config only when it is addressed by absolute OS path; a "user://"
## argument is rejected with "GDExtension dynamic library not found" (verified).
##
## The DLL lives loose next to the executable in a release build
## (<exe dir>/addons/nobodywho/libnobodywho-godot-x86_64-pc-windows-msvc-release.dll) and in
## res://addons/nobodywho/ in a dev checkout. When it is absent (fresh clone, or a build made
## without it) is_available() stays false and the settings screen says so.

signal availability_changed(available: bool)
signal load_finished(ok: bool, detail: String)

const DLL_NAME := "libnobodywho-godot-x86_64-pc-windows-msvc-release.dll"
const CONFIG_PATH := "user://nobodywho_runtime.gdextension"
const CONFIG_TEMPLATE := "[configuration]\nentry_symbol = \"gdext_rust_init\"\ncompatibility_minimum = 4.5\n\n[libraries]\nwindows.release.x86_64 = \"%s\"\nwindows.debug.x86_64 = \"%s\"\n"
const ModelCatalog := preload("res://scripts/ai/model_catalog.gd")

var _loading: bool = false
var _last_error: String = ""


func _ready() -> void:
	if is_available():
		return
	# A model already on disk means the player opted into LOCAL before: bring the runtime up.
	for key in ModelCatalog.REQUIREMENTS:
		if FileAccess.file_exists(ModelCatalog.model_file_path(str(key))):
			enable()
			return


## True when the NobodyWho classes are registered (runtime loaded).
func is_available() -> bool:
	return ClassDB.class_exists("NobodyWhoModel") and ClassDB.class_exists("NobodyWhoChat")


func last_error() -> String:
	return _last_error


## Absolute path of the loose extension library, or "" when it is not shipped.
func dll_path() -> String:
	var candidates: PackedStringArray = []
	candidates.append(OS.get_executable_path().get_base_dir().path_join("addons/nobodywho").path_join(DLL_NAME))
	candidates.append(ProjectSettings.globalize_path("res://addons/nobodywho").path_join(DLL_NAME))
	for candidate in candidates:
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


## Load the extension (idempotent). Returns true when the runtime is available afterwards.
func enable() -> bool:
	if is_available():
		_refresh_provider()
		return true
	if _loading:
		return false
	_loading = true
	var dll := dll_path()
	if dll.is_empty():
		_loading = false
		_last_error = "runtime_missing"
		load_finished.emit(false, _last_error)
		return false
	if not _write_config(dll):
		_loading = false
		_last_error = "config_failed"
		load_finished.emit(false, _last_error)
		return false
	var status := GDExtensionManager.load_extension(ProjectSettings.globalize_path(CONFIG_PATH))
	_loading = false
	var ok: bool = status == OK and is_available()
	if not ok:
		_last_error = "load_failed"
		load_finished.emit(false, _last_error)
		return false
	_last_error = ""
	load_finished.emit(true, "")
	availability_changed.emit(true)
	_refresh_provider()
	return true


## Text of the runtime config that enable() writes — exposed for tests.
func config_text(dll_path_abs: String) -> String:
	var p := dll_path_abs.replace("\\", "/")
	return CONFIG_TEMPLATE % [p, p]


func _write_config(dll_path_abs: String) -> bool:
	var f := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(config_text(dll_path_abs))
	f.close()
	return true


func _refresh_provider() -> void:
	var ac := get_node_or_null("/root/AIClient")
	if ac != null and ac.has_method("refresh_local_provider"):
		ac.refresh_local_provider()
