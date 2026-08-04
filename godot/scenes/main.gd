extends Node2D

enum Mode { PLAY, OBSERVER }

var mode: Mode = Mode.PLAY

@onready var _host: Node2D = $LocationHost
@onready var _camera: Camera2D = $Camera2D
@onready var _observer: Control = $UI/ObserverPanel
@onready var _day_night: CanvasModulate = $DayNightModulate
@onready var _prompt: CanvasLayer = $UI/InteractionPrompt
@onready var _story: CanvasLayer = $UI/StoryScreen
@onready var _case_panel: CanvasLayer = $UI/CasePanel
@onready var _interrogation: CanvasLayer = $UI/InterrogationPanel
@onready var _settings: CanvasLayer = $UI/SettingsScreen
@onready var _search_panel: CanvasLayer = $UI/SearchPanel
@onready var _travel_map: CanvasLayer = $UI/TravelMap

const CAMERA_SPEED := 300.0
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.0

var _dragging := false
var _drag_start := Vector2.ZERO
var _location: Node2D = null


func _ready() -> void:
	Scheduler.time_changed.connect(_update_day_night)
	_update_day_night(Scheduler.get_hour(), 0, Scheduler.game_day)
	_load_location(LocationManager.current_id)
	LocationManager.location_changing.connect(_load_location)
	EventLog.log_action("Crestwood Hall simulation started", "system")
	_story.choice_made.connect(_on_choice_made)
	_story.settings_requested.connect(_settings.open)
	_case_panel.accuse_requested.connect(_on_accuse_requested)
	GameFlow.phase_changed.connect(_on_phase_changed)
	_case_panel.set_open(false)
	_on_phase_changed(GameFlow.phase)  # show the First Choice on start
	_interrogation.free_text_submitted.connect(_on_free_text)
	_travel_map.travel_requested.connect(func(d): LocationManager.travel(d))
	_search_panel.action_selected.connect(_on_search_action_selected)


func _load_location(id: String) -> void:
	if _location != null:
		_location.queue_free()
	var scene: PackedScene = load(LocationManager.location_scene(id))
	_location = scene.instantiate()
	_host.add_child(_location)
	_bind_location(_location)


func _bind_location(loc: Node2D) -> void:
	if loc.detective != null:
		_prompt.bind(loc.detective.get_node("Interactor"))
	set_mode(Mode.PLAY)
	_observer.bind_npcs(loc.npcs)
	for npc in loc.npcs:
		var area: Area2D = npc.get_node("ClickArea")
		area.input_pickable = true
		area.input_event.connect(_on_npc_input.bind(npc))
		for ch in npc.get_children():
			if ch is NpcInteractable:
				ch.talk_requested.connect(_on_talk_requested)
	for ch in loc.get_children():
		if ch is SearchPoint:
			ch.search_requested.connect(_on_search_requested)
		elif ch is RestPoint:
			ch.rest_requested.connect(_on_rest_requested)
		elif ch is DoorTrigger:
			ch.door_triggered.connect(func(d): LocationManager.travel(d))


func _process(delta: float) -> void:
	if mode == Mode.OBSERVER:
		_pan_camera(delta)


func _pan_camera(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("camera_pan_up"):
		dir.y -= 1
	if Input.is_action_pressed("camera_pan_down"):
		dir.y += 1
	if Input.is_action_pressed("camera_pan_left"):
		dir.x -= 1
	if Input.is_action_pressed("camera_pan_right"):
		dir.x += 1
	if dir != Vector2.ZERO:
		_camera.position += dir.normalized() * CAMERA_SPEED * delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mode"):
		set_mode(_next_mode(mode) as Mode)
		return
	if event.is_action_pressed("toggle_case") and GameFlow.phase == GameFlow.Phase.INVESTIGATION:
		_case_panel.refresh(CaseFile)
		_case_panel.set_open(not _case_panel.visible)
		return
	if event.is_action_pressed("toggle_map") and GameFlow.phase == GameFlow.Phase.INVESTIGATION:
		_travel_map.open()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_active_camera(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_active_camera(1.0 / 1.1)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
			_drag_start = event.position


func _zoom_active_camera(factor: float) -> void:
	# Zooms whichever Camera2D the viewport is actually showing — the detective's own camera in
	# PLAY mode, or this scene's free-fly Camera2D in OBSERVER mode — not always the latter, so
	# zoom works during normal play, not just the separate spectator mode.
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	cam.zoom = (cam.zoom * factor).clamp(Vector2(ZOOM_MIN, ZOOM_MIN), Vector2(ZOOM_MAX, ZOOM_MAX))


func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseMotion:
		_camera.position -= event.relative / _camera.zoom


func _update_day_night(hour: float, _m: int, _d: int) -> void:
	var phase := hour / 24.0
	var day_color := Color(1.0, 1.0, 1.0)
	var night_color := Color(0.35, 0.4, 0.65)
	var dawn_dusk := Color(1.0, 0.75, 0.55)
	var t := phase
	var color: Color
	if t < 0.25:
		color = night_color.lerp(dawn_dusk, t / 0.25)
	elif t < 0.5:
		color = dawn_dusk.lerp(day_color, (t - 0.25) / 0.25)
	elif t < 0.75:
		color = day_color.lerp(dawn_dusk, (t - 0.5) / 0.25)
	else:
		color = dawn_dusk.lerp(night_color, (t - 0.75) / 0.25)
	_day_night.color = color


static func _next_mode(m: int) -> int:
	return Mode.OBSERVER if m == Mode.PLAY else Mode.PLAY


func set_mode(m: Mode) -> void:
	mode = m
	var playing := m == Mode.PLAY
	if _location != null and _location.detective != null:
		_location.detective.set_control_enabled(playing)  # makes the detective camera current in PLAY
	_camera.enabled = not playing  # the free observer camera is only active in OBSERVER mode
	if not playing:
		_camera.make_current()
	_observer.visible = not playing
	EventLog.log_action("Mode: %s" % ("PLAY (detective)" if playing else "OBSERVER"), "system")


func _on_npc_input(_viewport: Node, event: InputEvent, _shape_idx: int, npc: DormNpc) -> void:
	if mode != Mode.OBSERVER:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_observer.select_npc(npc)


func _on_choice_made(is_murder: bool) -> void:
	if is_murder:
		GameFlow.choose_murder()
	else:
		GameFlow.choose_accident()


func _on_accuse_requested(suspect_id: String) -> void:
	var result: Dictionary = CaseFile.accuse(suspect_id)
	if result["accepted"]:
		_case_panel.set_open(false)
		GameFlow.trigger_ending(result["ending_id"])
	else:
		EventLog.log_action("Not enough evidence to accuse %s (%d/%d)" % [
			suspect_id, result["strength"], result["threshold"]], "case")


func _on_phase_changed(phase: int) -> void:
	match phase:
		GameFlow.Phase.CHOICE:
			_story.show_choice()
		GameFlow.Phase.INVESTIGATION:
			_story.hide_screen()
		GameFlow.Phase.ENDING:
			_story.show_ending(GameFlow.current_ending_id, _collect_discovered_clue_ids())


func _collect_discovered_clue_ids() -> Array:
	var ids: Array = []
	for clue_id in CaseData.CLUES:
		if Investigation.is_discovered(clue_id):
			ids.append(clue_id)
	return ids


func _on_talk_requested(suspect_id: String) -> void:
	_interrogation.open(suspect_id, Investigation, Standing)


func _on_search_requested(point_id: String) -> void:
	_search_panel.open(point_id, Investigation)


func _on_rest_requested() -> void:
	Scheduler.advance_days(1)
	EventLog.log_action("Rested — a day passed", "system")


func _on_search_action_selected(point_id: String, _action_id: String, risk: String) -> void:
	if risk != "risky" or _location == null or _location.detective == null:
		return
	var room_id: String = str(SearchData.point(point_id).get("room", ""))
	var area: Dictionary = AccessData.area(room_id)
	var owner_id: String = str(area.get("owner", ""))
	var owner_present := false
	var witnessed := false
	var det_pos: Vector2 = _location.detective.global_position
	for npc in _location.npcs:
		if npc.npc_id == owner_id and npc.current_room == room_id:
			owner_present = true
		if det_pos.distance_to(npc.global_position) <= 100.0:
			witnessed = true
	var restricted: bool = AccessData.is_restricted(room_id, Scheduler.get_hour(), owner_present)
	Consequences.record_risky_search(restricted, witnessed)


func _on_free_text(suspect_id: String, text: String) -> void:
	# Hybrid: use the LLM when the AI layer is live, else an authored deflection.
	if AIClient.use_ai and AIClient.resolve_mode() != AIClient.AiMode.RULE_BASED:
		var persona: String = str(InterrogationData.SUSPECTS.get(suspect_id, {}).get("persona", ""))
		AIClient._local_decide(suspect_id, {"name": suspect_id, "personality": persona,
			"schedule_goal": "answer the detective", "current_room": "", "nearby_npcs": [],
			"recent_events": [text], "secrets": []}, func(resp):
			var action: Dictionary = resp.get("action", {})
			var line: String = str(action.get("text", action.get("reason", "")))
			_interrogation.show_response(line if line != "" else "I won't dignify that.")
		)
	else:
		_interrogation.show_response("Ask me something specific, detective.")
