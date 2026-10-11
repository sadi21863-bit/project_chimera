extends SceneTree

const SPIKE_SCENE := preload("res://scenes/prototypes/civic_model_spike.tscn")
const OUTPUT := "res://assets/prototypes/civic_model_spike_capture.png"

var _spike: Node = null
var _frames := 0
var _capturing := false


func _initialize() -> void:
	_spike = SPIKE_SCENE.instantiate()
	root.add_child(_spike)


func _process(_delta: float) -> bool:
	if _capturing:
		return false
	_frames += 1
	if _frames < 30:
		return false
	_capturing = true
	_capture_async()
	return false


func _capture_async() -> void:
	for i in range(8):
		await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	print("CIVIC_PERF fps=%s draws=%s primitives=%s process_ms=%s physics_ms=%s" % [
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.TIME_PROCESS),
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
	])
	var err := image.save_png(OUTPUT)
	if err == OK:
		print("CIVIC_CAPTURE: %s" % OUTPUT)
	else:
		push_error("CIVIC_CAPTURE: failed (%d)" % err)
	quit(0 if err == OK else 1)
