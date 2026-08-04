extends SceneTree

## Verifies WASD movement: hold the "right" action and confirm the detective walks right.
## Input.action_press polls the raw input state (no event propagation), matching how the
## detective reads movement — so this can't be swallowed by UI, just like the real game.

var _main
var _det
var _start := Vector2.ZERO
var _phase := 0
var _wait := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_det = _main.get_node("LocationHost/CrestwoodHall").detective
		if _det == null:
			print("FAIL: detective missing"); quit(1); return true
		_start = _det.global_position
		Input.action_press("camera_pan_right")  # hold D
		_phase = 1
		return false
	_wait += 1
	if _wait < 30:  # ~0.5s of held input
		return false
	Input.action_release("camera_pan_right")
	var dx: float = _det.global_position.x - _start.x
	if dx > 30.0:
		print("PASS: test_detective_move — WASD moved detective right %.1f px" % dx)
		quit(0)
	else:
		print("FAIL: WASD did not move detective (dx=%.1f)" % dx)
		quit(1)
	return true
