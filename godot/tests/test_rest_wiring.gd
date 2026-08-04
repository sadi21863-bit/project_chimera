extends SceneTree

## Functional check: travel to the detective's room, stand on the Bed, examine (E) it,
## and confirm the day counter advances.

var _main
var _det
var _bed
var _sched
var _start_day := 0
var _phase := 0
var _wait := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_sched = root.get_node("Scheduler")
		_start_day = _sched.game_day
		root.get_node("LocationManager").travel("detective_room")
		var host = _main.get_node("LocationHost")
		var loc = host.get_child(host.get_child_count() - 1)
		_det = loc.detective
		_bed = loc.get_node("Bed")
		if _det == null or _bed == null:
			print("FAIL: detective or Bed missing in detective_room"); quit(1); return true
		_det.global_position = _bed.global_position
		_phase = 1
		return false

	_wait += 1
	if _wait < 15:
		return false

	var interactor = _det.get_node("Interactor")
	var failures := 0
	if interactor.clue_target == null:
		failures += 1; print("FAIL: interactor did not detect the RestPoint in reach")
	else:
		interactor.try_examine()

	if _sched.game_day != _start_day + 1:
		failures += 1; print("FAIL: resting should advance the day (start=%d now=%d)" % [_start_day, _sched.game_day])

	if failures == 0:
		print("PASS: test_rest_wiring")
	quit(failures)
	return true
