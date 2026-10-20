extends SceneTree

## T1: model path resolution order on NobodyWhoProvider
## (downloaded user:// model wins; project setting next; res:// fallbacks last).

const Catalog := preload("res://scripts/ai/model_catalog.gd")
const ProviderScript := preload("res://scripts/ai/nobodywho_provider.gd")

var _failures := 0

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		print("FAIL: %s" % msg)

func _process(_delta: float) -> bool:
	var provider: Node = ProviderScript.new()
	var test_dir := "user://t1_models"
	DirAccess.make_dir_recursive_absolute(test_dir)
	var key: String = Catalog.DEFAULT_KEY
	var upath := test_dir.path_join(key + ".gguf")
	var f := FileAccess.open(upath, FileAccess.WRITE)
	f.store_8(0x47)
	f.close()

	var setting: String = str(ProjectSettings.get_setting("echo/nobodywho_model_path", ""))

	# (a) downloaded-model file wins over the project setting, and comes back globalized
	Catalog.catalog_dir_override = test_dir
	var got: String = provider._resolve_model_path()
	_check(got == ProjectSettings.globalize_path(upath),
		"catalog file should win and be globalized (got %s)" % got)
	_check(provider._path_usable(got), "globalized catalog path should be usable")

	# (b) with no downloaded file, the project setting wins (returned as authored)
	Catalog.catalog_dir_override = "user://t1_empty_models"
	DirAccess.make_dir_recursive_absolute("user://t1_empty_models")
	var got_setting: String = provider._resolve_model_path()
	if setting.is_empty():
		_check(not got_setting.is_empty(), "empty setting must still resolve a default")
	else:
		_check(got_setting == setting,
			"setting should win when catalog dir is empty (got %s, want %s)" % [got_setting, setting])

	# (c) missing everything: provider stays not-ready and does not crash
	var p2: Node = ProviderScript.new()
	root.add_child(p2)
	_check(p2.is_ready() == false, "provider without any model must not report ready")
	p2.queue_free()

	# cleanup
	Catalog.catalog_dir_override = ""
	provider.free()
	var d := DirAccess.open(test_dir)
	if d != null and d.file_exists(key + ".gguf"):
		d.remove(key + ".gguf")
	var de := DirAccess.open("user://")
	if de != null:
		if de.dir_exists("t1_models"):
			de.remove("t1_models")
		if de.dir_exists("t1_empty_models"):
			de.remove("t1_empty_models")

	if _failures == 0:
		print("PASS: test_model_path_resolution")
	quit(_failures)
	return true
