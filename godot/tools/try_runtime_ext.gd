extends SceneTree

## Probe: runtime loading strategies for the NobodyWho GDExtension.
## The shipped game must NOT auto-load the extension at startup (it costs ~43s of init and does
## network work), so LOCAL has to be enabled on demand via GDExtensionManager.load_extension().
## Godot 4.7 rejected a user:// config path, so try:
##   A) absolute OS path to a config in user://
##   B) absolute OS path to a config living next to the executable (the release layout)
##   C) res:// config with an absolute [libraries] path

const DLL := "res://addons/nobodywho/libnobodywho-godot-x86_64-pc-windows-msvc-release.dll"
const USER_CFG := "user://nw_runtime.gdextension"


func _initialize() -> void:
	_run()


func _run() -> void:
	var dll_abs := ProjectSettings.globalize_path(DLL).replace("\\", "/")
	print("dll_abs=", dll_abs)
	var cfg_text := "[configuration]\nentry_symbol = \"gdext_rust_init\"\ncompatibility_minimum = 4.5\n\n[libraries]\nwindows.release.x86_64 = \"%s\"\nwindows.debug.x86_64 = \"%s\"\n" % [dll_abs, dll_abs]

	var user_abs := ProjectSettings.globalize_path(USER_CFG)
	var f := FileAccess.open(USER_CFG, FileAccess.WRITE)
	f.store_string(cfg_text)
	f.close()
	print("A_user_abs=", user_abs)

	var exe_dir := OS.get_executable_path().get_base_dir()
	var loose_cfg := exe_dir.path_join("nw_probe.gdextension")
	var f2 := FileAccess.open(loose_cfg, FileAccess.WRITE)
	f2.store_string(cfg_text)
	f2.close()
	print("B_loose_cfg=", loose_cfg)

	var res_cfg := "res://nw_probe.gdextension"
	var f3 := FileAccess.open(res_cfg, FileAccess.WRITE)
	f3.store_string(cfg_text)
	f3.close()

	for attempt in [
		["A", user_abs],
		["B", loose_cfg],
		["C", res_cfg],
	]:
		var label: String = attempt[0]
		var path: String = attempt[1]
		var sw := Time.get_ticks_msec()
		var status := GDExtensionManager.load_extension(path)
		var has_model := ClassDB.class_exists("NobodyWhoModel")
		print("%s status=%s class_NobodyWhoModel=%s elapsed_ms=%d" % [label, status, has_model, Time.get_ticks_msec() - sw])
		if has_model:
			print("WORKING_VARIANT=", label)
			break

	DirAccess.remove_absolute(ProjectSettings.globalize_path(res_cfg))
	DirAccess.remove_absolute(loose_cfg)
	quit(0)
