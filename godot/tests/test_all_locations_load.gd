extends SceneTree

## Every location registered in LocationManager must load AND instantiate
## headless. Added after 5 off-campus scenes shipped with truncated
## tile_map_data (parse error -> travel() instantiated null, silently keeping
## the player in the previous scene). No earlier test loaded these scenes.

func _initialize() -> void:
	var lm := preload("res://autoload/location_manager.gd").new()
	var failures := 0
	for id in lm.LOCATIONS:
		var scene_path: String = str(lm.LOCATIONS[id]["scene"])
		var ps: PackedScene = load(scene_path)
		if ps == null:
			failures += 1
			print("FAIL: %s — could not LOAD %s" % [id, scene_path])
			continue
		var inst: Node = ps.instantiate()
		if inst == null:
			failures += 1
			print("FAIL: %s — could not INSTANTIATE %s" % [id, scene_path])
			continue
		print("OK: %s (%s)" % [id, scene_path.get_file()])
		inst.free()
	if failures == 0:
		print("PASS: test_all_locations_load")
	quit(failures)
