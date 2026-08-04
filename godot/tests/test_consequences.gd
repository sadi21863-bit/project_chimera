extends SceneTree

## _process (not _initialize): Consequences' signal wiring to GameFlow/Scheduler happens in its
## own _ready(), which hasn't run yet during _initialize() — waiting for the first _process gives
## every autoload's _ready() a chance to fire first.

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true

	var consequences = root.get_node("Consequences")
	var difficulty = root.get_node("Difficulty")
	var game_flow = root.get_node("GameFlow")
	var scheduler = root.get_node("Scheduler")
	var failures := 0

	# --- strikes -> fired (Medium: strikes_to_fired = 5) ---
	difficulty.set_preset("medium")
	game_flow.phase = game_flow.Phase.CHOICE
	game_flow.current_ending_id = ""
	consequences.reset()
	scheduler.set_time(8.0, 1)
	game_flow.choose_murder()

	for i in range(4):
		consequences.record_catch(14.0)  # daytime, not the death window
	if game_flow.phase == game_flow.Phase.ENDING:
		failures += 1; print("FAIL: should not be fired before reaching the strike threshold")
	consequences.record_catch(14.0)  # 5th strike
	if game_flow.phase != game_flow.Phase.ENDING or game_flow.current_ending_id != "ending_fired_strikes":
		failures += 1; print("FAIL: reaching the strike threshold should fire the detective")

	# --- deadline (Medium: deadline_days = 14) ---
	difficulty.set_preset("medium")
	game_flow.phase = game_flow.Phase.CHOICE
	game_flow.current_ending_id = ""
	consequences.reset()
	scheduler.set_time(8.0, 1)
	game_flow.choose_murder()
	scheduler.set_time(8.0, 20)  # well past day 1 + 14
	if game_flow.phase != game_flow.Phase.ENDING or game_flow.current_ending_id != "ending_fired_deadline":
		failures += 1; print("FAIL: the deadline passing should fire the detective")

	# --- death (Extreme, deep night) ---
	difficulty.set_preset("extreme")
	game_flow.phase = game_flow.Phase.CHOICE
	game_flow.current_ending_id = ""
	consequences.reset()
	scheduler.set_time(8.0, 1)
	game_flow.choose_murder()
	consequences.record_catch(2.0)  # deep night
	if game_flow.phase != game_flow.Phase.ENDING or game_flow.current_ending_id != "ending_death":
		failures += 1; print("FAIL: a deep-night catch on Extreme should be fatal")

	# --- Easy: no forced game-over from strikes or the deadline ---
	difficulty.set_preset("easy")
	game_flow.phase = game_flow.Phase.CHOICE
	game_flow.current_ending_id = ""
	consequences.reset()
	scheduler.set_time(8.0, 1)
	game_flow.choose_murder()
	for i in range(10):
		consequences.record_catch(14.0)
	scheduler.set_time(8.0, 500)
	if game_flow.phase == game_flow.Phase.ENDING:
		failures += 1; print("FAIL: Easy should never force a game-over from strikes or the deadline")

	if failures == 0:
		print("PASS: test_consequences")
	quit(failures)
	return true
