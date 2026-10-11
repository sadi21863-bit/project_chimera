extends SceneTree

const HERO_SCENE := preload("res://scenes/prototypes/archival_cutaway_hero.tscn")

var _hero: Node = null
var _frames := 0
var _capturing := false
var _night_requested := false
var _prompt_requested := false
var _output := "res://assets/prototypes/archival_cutaway_hero_capture.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "night=1":
			_night_requested = true
			_output = "res://assets/prototypes/archival_cutaway_hero_night_capture.png"
		elif arg == "prompt=1":
			_prompt_requested = true
			_output = "res://assets/prototypes/archival_cutaway_hero_prompt_capture.png"
	_hero = HERO_SCENE.instantiate()
	root.add_child(_hero)


func _process(_delta: float) -> bool:
	if _capturing:
		return false
	_frames += 1
	if _night_requested and _frames == 2:
		_hero.call("_toggle_night")
	if _prompt_requested and _frames == 2:
		var player := _hero.get("_player") as Node2D
		var marker := _hero.get("_evidence_marker") as Node2D
		if player != null and marker != null:
			player.position = marker.position + Vector2(-58.0, 0.0)
	if _frames < 20:
		return false
	_capturing = true
	_capture_async()
	return false


func _capture_async() -> void:
	for i in range(8):
		await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	print("ARCHIVAL_PERF fps=%s draws=%s primitives=%s process_ms=%s physics_ms=%s" % [
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.TIME_PROCESS),
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
	])
	var err := image.save_png(_output)
	if err == OK:
		print("ARCHIVAL_CAPTURE: %s" % _output)
	else:
		push_error("ARCHIVAL_CAPTURE: failed (%d)" % err)
	quit(0 if err == OK else 1)
