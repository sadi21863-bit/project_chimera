extends SceneTree

## Observer top-bar AI label regression (CHI-003 follow-up).
##
## The old label keyed off AIClient.server_online ("AI ON"/"AI OFF"), so a healthy LOCAL
## model and the degraded rule-based fallback rendered identically as "AI OFF". It now shows
## the effective mode via AIClient.get_mode_short_label() with width-safe tokens, because the
## TopBar is an HBoxContainer at 1280x720 and long labels crowd the slider/play controls.
## Layout is asserted with the LONGEST token ("SERVER") active.

var failures := 0
var checks := 0

const PANEL_SCENE := "res://scenes/ui/observer_panel.tscn"
const PANEL_SIZE := Vector2(1280, 720)


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	_run()


func _run() -> void:
	await create_timer(0.1).timeout

	var ac = root.get_node_or_null("AIClient")
	if ac == null:
		print("FAIL: AIClient autoload missing")
		quit(1)
		return
	var scene: PackedScene = load(PANEL_SCENE)
	if scene == null:
		print("FAIL: observer_panel.tscn failed to load")
		quit(1)
		return

	var orig_mode: int = ac.ai_mode

	# --- unit: short labels resolve to compact tokens for every fixed mode ---
	var ac_script: GDScript = load("res://autoload/ai_client.gd")
	var tokens := {
		ac_script.AiMode.SERVER: "SERVER",
		ac_script.AiMode.LOCAL: "LOCAL",
		ac_script.AiMode.RULE_BASED: "RULE",
	}
	for mode in tokens:
		ac.ai_mode = mode
		_check(ac.get_mode_short_label() == tokens[mode],
			"short label for fixed mode %s is %s (got %s)" % [str(mode), tokens[mode], str(ac.get_mode_short_label())])

	# --- integration: the panel renders the effective mode, never the old "AI OFF" ---
	var panel = scene.instantiate()
	root.add_child(panel)
	panel.size = PANEL_SIZE
	await create_timer(0.05).timeout
	await create_timer(0.05).timeout

	if not panel.has_method("_update_status"):
		print("FAIL: observer panel has no _update_status()")
		quit(1)
		return

	var status_label: Label = panel.get_node("Margin/VBox/TopBar/StatusLabel")
	for mode in tokens:
		ac.ai_mode = mode
		panel.call("_update_status")
		var text: String = status_label.text
		_check(text.contains("AI: %s" % tokens[mode]),
			"panel label contains 'AI: %s' in mode %s (got '%s')" % [tokens[mode], str(mode), text])
		_check(not text.contains("AI OFF"),
			"panel label never says 'AI OFF' (got '%s')" % text)
		_check(text.contains("RUNNING") or text.contains("PAUSED"),
			"panel label still shows pause state (got '%s')" % text)

	ac.ai_mode = orig_mode

	# --- layout: worst case is the longest token ("SERVER"); every TopBar child must fit,
	# nothing may overlap, and the speed slider must not be crushed.
	ac.ai_mode = ac_script.AiMode.SERVER
	panel.call("_update_status")
	await create_timer(0.05).timeout
	await create_timer(0.05).timeout

	var topbar: Control = panel.get_node("Margin/VBox/TopBar")
	var children := topbar.get_children()
	var sorted := children.duplicate()
	sorted.sort_custom(func(a, b): return a.position.x < b.position.x)
	var prev_right := -1.0
	for child in sorted:
		var right: float = child.position.x + child.size.x
		_check(right <= topbar.size.x + 1.0,
			"TopBar child %s fits inside the bar (right edge %.1f > %.1f)" % [child.name, right, topbar.size.x])
		_check(prev_right < 0.0 or child.position.x >= prev_right - 1.0,
			"TopBar child %s does not overlap its left neighbour (x=%.1f, prev right=%.1f)" % [child.name, child.position.x, prev_right])
		prev_right = right

	var slider: HSlider = panel.get_node("Margin/VBox/TopBar/SpeedSlider")
	_check(slider.size.x >= 40.0,
		"speed slider is not crushed by the longer label (width %.1f)" % slider.size.x)

	ac.ai_mode = orig_mode
	panel.queue_free()

	print("--- observer top-bar label: %d checks, %d failures ---" % [checks, failures])
	quit(failures)
