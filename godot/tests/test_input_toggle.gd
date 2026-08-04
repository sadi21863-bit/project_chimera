extends SceneTree

## Drives the REAL input pipeline: synthesize the "toggle_mode" (Tab) action via
## Input.parse_input_event and verify main.gd._unhandled_input flips PLAY <-> OBSERVER.
## This is Godot's native equivalent of automated input testing (no pygame needed).

var _main
var _phase := 0
var _wait := 0

func _send_toggle() -> void:
	var ev := InputEventAction.new()
	ev.action = "toggle_mode"
	ev.pressed = true
	Input.parse_input_event(ev)

func _process(_delta: float) -> bool:
	match _phase:
		0:
			_main = load("res://scenes/main.tscn").instantiate()
			root.add_child(_main)
			_phase = 1
		1:
			if _main.mode != 0:
				print("FAIL: should start in PLAY"); quit(1); return true
			_send_toggle()
			_phase = 2; _wait = 0
		2:
			_wait += 1
			if _wait < 4:
				return false
			if _main.mode != 1:
				print("FAIL: Tab did not switch to OBSERVER (mode=%d)" % _main.mode); quit(1); return true
			_send_toggle()
			_phase = 3; _wait = 0
		3:
			_wait += 1
			if _wait < 4:
				return false
			if _main.mode != 0:
				print("FAIL: second Tab did not return to PLAY (mode=%d)" % _main.mode); quit(1); return true
			print("PASS: test_input_toggle — Tab drives PLAY<->OBSERVER through real input")
			quit(0)
			return true
	return false
