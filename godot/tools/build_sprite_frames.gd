extends SceneTree

## One-off tool: builds a SpriteFrames .tres per character from the rendered PNG frames
## in res://assets/characters/<id>/. Run headless:
##   godot --headless --path godot -s res://tools/build_sprite_frames.gd

const CHAR_IDS := ["detective", "alex", "jordan", "sam", "riley", "morgan", "casey", "dean"]
const ANIM_DEFS := [
	{"name": "idle_down", "dir": "idle_down", "fps": 5.0, "loop": true},
	{"name": "walk_down", "dir": "walk_down", "fps": 8.0, "loop": true},
	{"name": "walk_up", "dir": "walk_up", "fps": 8.0, "loop": true},
	{"name": "walk_left", "dir": "walk_left", "fps": 8.0, "loop": true},
	{"name": "walk_right", "dir": "walk_right", "fps": 8.0, "loop": true},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/sprite_frames")
	for char_id in CHAR_IDS:
		_build_for(char_id)
	print("BUILD_SPRITE_FRAMES_DONE")
	quit()


func _build_for(char_id: String) -> void:
	var base := "res://assets/characters/%s" % char_id
	if not DirAccess.dir_exists_absolute(base):
		printerr("missing character folder: %s" % base)
		return

	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for anim in ANIM_DEFS:
		var dir_path := "%s/%s" % [base, anim["dir"]]
		if not DirAccess.dir_exists_absolute(dir_path):
			printerr("missing animation folder: %s" % dir_path)
			continue
		var frame_files := _sorted_frame_files(dir_path)
		if frame_files.is_empty():
			printerr("no frames found in: %s" % dir_path)
			continue
		frames.add_animation(anim["name"])
		frames.set_animation_speed(anim["name"], anim["fps"])
		frames.set_animation_loop(anim["name"], anim["loop"])
		for f in frame_files:
			var tex := load("%s/%s" % [dir_path, f])
			frames.add_frame(anim["name"], tex)

	var out_path := "res://resources/sprite_frames/%s.tres" % char_id
	var err := ResourceSaver.save(frames, out_path)
	if err != OK:
		printerr("failed to save %s: %d" % [out_path, err])
	else:
		print("saved %s (%d animations)" % [out_path, frames.get_animation_names().size()])


func _sorted_frame_files(dir_path: String) -> Array:
	var result: Array = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return result
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.ends_with(".png"):
			result.append(f)
		f = d.get_next()
	d.list_dir_end()
	result.sort_custom(func(a, b): return _frame_index(a) < _frame_index(b))
	return result


func _frame_index(filename: String) -> int:
	var digits := filename.replace("frame_", "").replace(".png", "")
	return digits.to_int()
