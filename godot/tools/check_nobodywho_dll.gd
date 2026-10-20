extends SceneTree

## Headless check that the NobodyWho GDExtension loads and registers its classes.
## Run: Godot --headless --path godot -s res://tools/check_nobodywho_dll.gd

func _initialize() -> void:
	var model := ClassDB.class_exists("NobodyWhoModel")
	var chat := ClassDB.class_exists("NobodyWhoChat")
	print("NobodyWhoModel class registered: ", model)
	print("NobodyWhoChat class registered: ", chat)
	if not model or not chat:
		print("DLL_NOT_LOADED")
		quit(1)
		return
	var prov = load("res://scripts/ai/nobodywho_provider.gd").new()
	var available: bool = prov.is_available()
	print("provider is_available: ", available)
	prov.free()
	if not available:
		print("PROVIDER_UNAVAILABLE")
		quit(2)
		return
	print("DLL_OK")
	quit(0)
