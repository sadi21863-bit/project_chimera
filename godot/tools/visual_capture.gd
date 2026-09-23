extends SceneTree

## Deterministic single-shot visual capture (NON-headless — needs a real window).
##
## Hardened per the Claude-of-Duty harness lessons:
##   1. ISOLATION — exactly ONE screenshot per process. Each invocation starts a
##      fresh engine instance, instantiates a fresh main.tscn, reseeds the global
##      RNG, and resets every self-persisting autoload (Investigation/Standing/
##      Difficulty/LocalMemory/Tutorial) so user:// state can never leak between
##      a baseline run and a capture run.
##   2. FIXED FRAME BUDGET — pair with --fixed-fps <fps> so delta is constant;
##      all staging waits are exact frame counts, and the capture fires once,
##      after a settle period, on RenderingServer.frame_post_draw. Identical
##      hardware-independent output across runs.
##
## Usage (windowed build required):
##   Godot_v4.7-stable_win64.exe --path godot --fixed-fps 30 \
##       -s res://tools/visual_capture.gd -- shot=dorm settle=45 seed=1337
##
## Shots: cinematic | story_choice | dorm | bedroom | case_panel | interrogation | dialogue | accusation | travel_map | settings

const CAPTURE_DIR := "res://qa/captures/"
const MAIN_SCENE := "res://scenes/main.tscn"

enum Step {
	BOOT,
	LOAD_MAIN,
	WAIT_MAIN,
	CINEMATIC,
	STORY_CHOICE,
	INVESTIGATE,
	DORM,
	BEDROOM,
	CASE_PANEL,
	INTERROGATION,
	DIALOGUE,
	ACCUSATION,
	TRAVEL_MAP,
	SETTINGS,
	DONE,
}

var _shot := ""
var _settle := 45
var _phase: int = Step.BOOT
var _wait := 0
var _capture_pending := false
var _captured := false

var _story: CanvasLayer = null
var _case_panel: CanvasLayer = null
var _interrogation: CanvasLayer = null
var _travel_map: CanvasLayer = null
var _settings: CanvasLayer = null
var _cinematic: CanvasLayer = null
var _main: Node = null


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=", true, 1)
		if kv.size() != 2:
			continue
		match kv[0]:
			"shot":
				_shot = kv[1]
			"settle":
				_settle = int(kv[1])
			"seed":
				seed(int(kv[1]))


func _process(_delta: float) -> bool:
	if _capture_pending:
		return false
	if _shot.is_empty():
		push_error("VISUAL_CAPTURE: pass shot=<name> after '--'")
		quit(2)
		return true
	_wait += 1
	match _phase:
		Step.BOOT:
			# First frame: neutralize cross-run state before anything reads it.
			for node_name in ["Investigation", "Standing", "Difficulty", "LocalMemory", "Tutorial"]:
				var n: Node = root.get_node_or_null(node_name)
				if n == null:
					continue
				if "persist_enabled" in n:
					n.set("persist_enabled", false)
				if n.has_method("reset"):
					n.call("reset")
			_phase = Step.LOAD_MAIN
		Step.LOAD_MAIN:
			DirAccess.make_dir_recursive_absolute(CAPTURE_DIR)
			_main = load(MAIN_SCENE).instantiate()
			root.add_child(_main)
			_wait = 0
			_phase = Step.WAIT_MAIN
		Step.WAIT_MAIN:
			if _wait < 15:
				return false
			_story = root.get_node("Main/UI/StoryScreen")
			_case_panel = root.get_node("Main/UI/CasePanel")
			_interrogation = root.get_node("Main/UI/InterrogationPanel")
			_travel_map = root.get_node("Main/UI/TravelMap")
			_settings = root.get_node("Main/UI/SettingsScreen")
			_cinematic = root.get_node("Main/UI/OpeningCinematic")
			# Deterministic first-run look: tutorial hints suppressed everywhere.
			var tutorial_panel := root.get_node_or_null("Main/UI/TutorialPanel")
			if tutorial_panel != null:
				tutorial_panel.hide()
			_wait = 0
			_phase = Step.CINEMATIC
		Step.CINEMATIC:
			if _wait < 5:
				return false
			# Freeze the auto-playing cinematic on a known beat (its step timer
			# would otherwise advance mid-capture).
			if _cinematic._timer.timeout.is_connected(_cinematic._on_step_done):
				_cinematic._timer.timeout.disconnect(_cinematic._on_step_done)
			_cinematic._timer.stop()
			_cinematic.visible = true
			_cinematic._speaker.text = "Daniel"
			_cinematic._body.text = "Great party, Jordan. You really outdid yourself."
			if _shot == "cinematic":
				_start_capture()
			else:
				_phase = Step.STORY_CHOICE
				_wait = 0
		Step.STORY_CHOICE:
			if _wait < 5:
				return false
			_cinematic.cinematic_finished.emit()
			# Replicate real post-cinematic state: in-game _finish() hides the
			# panel before emitting; our frozen panel would otherwise cover
			# every later shot.
			_cinematic.visible = false
			if _shot == "story_choice":
				_start_capture()
			else:
				_phase = Step.INVESTIGATE
				_wait = 0
		Step.INVESTIGATE:
			if _wait < 30:
				return false
			root.get_node("GameFlow").choose_murder()
			_wait = 0
			_phase = Step.DORM
		Step.DORM:
			if _wait < 20:
				return false
			if _shot == "dorm":
				_start_capture()
			elif _shot == "bedroom":
				root.get_node("LocationManager").travel("bedroom_1")
				_wait = 0
				_phase = Step.BEDROOM
			else:
				_phase = Step.CASE_PANEL
				_wait = 0
		Step.BEDROOM:
			if _wait < 20:
				return false
			if _shot == "bedroom":
				_start_capture()
			else:
				push_error("VISUAL_CAPTURE: unexpected shot '%s' in BEDROOM phase" % _shot)
				quit(2)
		Step.CASE_PANEL:
			if _wait < 5:
				return false
			root.get_node("Investigation").discover_clue("clue_keys")
			root.get_node("Investigation").discover_clue("clue_rehearsal")
			_case_panel.refresh(root.get_node("CaseFile"))
			_case_panel.set_open(true)
			if _shot == "case_panel":
				_start_capture()
			else:
				_phase = Step.INTERROGATION
				_wait = 0
		Step.INTERROGATION:
			if _wait < 5:
				return false
			_case_panel.set_open(false)
			_interrogation.open("alex", root.get_node("Investigation"), root.get_node("Standing"))
			if _shot == "interrogation":
				_start_capture()
			elif _shot == "dialogue":
				_interrogation.close()
				_main.get_node("UI/DialoguePanel").open("alex")
				_wait = 0
				_phase = Step.DIALOGUE
			elif _shot == "accusation":
				_interrogation.close()
				root.get_node("Investigation").discover_clue("clue_wiring")
				root.get_node("Investigation").discover_clue("clue_camera")
				_main._on_accuse_requested("sam")
				_wait = 0
				_phase = Step.ACCUSATION
			else:
				_phase = Step.TRAVEL_MAP
				_wait = 0
		Step.DIALOGUE:
			if _wait < 10:
				return false
			if _shot == "dialogue":
				_start_capture()
			else:
				push_error("VISUAL_CAPTURE: unexpected shot '%s' in DIALOGUE phase" % _shot)
				quit(2)
		Step.ACCUSATION:
			if _wait < 10:
				return false
			if _shot == "accusation":
				_start_capture()
			else:
				push_error("VISUAL_CAPTURE: unexpected shot '%s' in ACCUSATION phase" % _shot)
				quit(2)
		Step.TRAVEL_MAP:
			if _wait < 5:
				return false
			_interrogation.close()
			_travel_map.open()
			if _shot == "travel_map":
				_start_capture()
			else:
				_phase = Step.SETTINGS
				_wait = 0
		Step.SETTINGS:
			if _wait < 5:
				return false
			_travel_map.hide()
			_settings.open()
			if _shot == "settings":
				_start_capture()
			else:
				push_error("VISUAL_CAPTURE: unknown shot '%s'" % _shot)
				quit(2)
		Step.DONE:
			pass
	if _captured:
		quit(0)
		return true
	return false


## One capture per process. Fires from an independent coroutine (never await
## inside _process itself — that orphans the main loop), after `_settle` further
## rendered frames so tweens/particles reach their known steady state.
func _start_capture() -> void:
	_phase = Step.DONE
	_capture_pending = true
	_capture_async()


func _capture_async() -> void:
	for i in range(_settle):
		await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	var path := CAPTURE_DIR + _shot + ".png"
	var err := image.save_png(path)
	if err == OK:
		print("VISUAL_CAPTURE: captured %s" % path)
	else:
		push_error("VISUAL_CAPTURE: failed to save %s (err %d)" % [path, err])
	_captured = err == OK
	_capture_pending = false
