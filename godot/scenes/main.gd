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
@onready var _interrogation = $UI/InterrogationPanel
@onready var _settings: CanvasLayer = $UI/SettingsScreen
@onready var _search_panel: CanvasLayer = $UI/SearchPanel
@onready var _travel_map: CanvasLayer = $UI/TravelMap
@onready var _cinematic: CanvasLayer = $UI/OpeningCinematic
@onready var _notebook: CanvasLayer = $UI/NotebookPanel
@onready var _evidence_board: CanvasLayer = $UI/EvidenceBoard
@onready var _npc_relationships: CanvasLayer = $UI/NPCRelationshipPanel
@onready var _quit_case_btn: CanvasLayer = $UI/QuitCaseButton
@onready var _investigation_hud: CanvasLayer = $UI/InvestigationHUD
@onready var _dialogue: CanvasLayer = $UI/DialoguePanel
@onready var _accuse_reveal: CanvasLayer = $UI/AccusationReveal

const CAMERA_SPEED := 300.0
const ZOOM_MIN := 0.5
# Cap high enough that a ~190x160 bedroom can auto-fit the viewport (old 2.0 cap
# left small rooms filling only ~1/3 of the screen).
const ZOOM_MAX := 6.0
const ZOOM_FIT_PADDING := 0.85

var _dragging := false
var _drag_start := Vector2.ZERO
var _location = null


func _ready() -> void:
	Scheduler.time_changed.connect(_update_day_night)
	_update_day_night(Scheduler.get_hour(), 0, Scheduler.game_day)
	_load_location(LocationManager.current_id)
	LocationManager.location_changing.connect(_load_location)
	EventLog.log_action("Crestwood Hall simulation started", "system")
	_story.choice_made.connect(_on_choice_made)
	_story.settings_requested.connect(_settings.open)
	_story.new_game_requested.connect(_on_new_game)
	_story.quit_case_requested.connect(_on_quit_case_requested)
	_case_panel.accuse_requested.connect(_on_accuse_requested)
	GameFlow.phase_changed.connect(_on_phase_changed)
	_case_panel.set_open(false)
	_interrogation.free_text_submitted.connect(_on_free_text)
	_interrogation.confess_triggered.connect(_on_confess_triggered)
	_travel_map.travel_requested.connect(func(d):
		Effects.fade_transition(func(): LocationManager.travel(d))
	)
	_search_panel.action_selected.connect(_on_search_action_selected)
	_dialogue.finished.connect(_on_dialogue_finished)
	_accuse_reveal.confirmed.connect(_on_accuse_confirmed)
	_accuse_reveal.cancelled.connect(_on_accuse_cancelled)
	_cinematic.cinematic_finished.connect(_on_cinematic_finished)
	Investigation.clue_discovered.connect(func(_c): Tutorial.on_clue_found())
	Investigation.clue_discovered.connect(_on_clue_discovered)
	Scheduler.time_changed.connect(func(_h, _m, _d): Tutorial.on_day_passed())
	Effects.set_camera(_camera)
	_quit_case_btn.get_node("Panel/Button").pressed.connect(_on_quit_case_pressed)
	if GameFlow.phase == GameFlow.Phase.CHOICE:
		_cinematic.start_cinematic()
	else:
		_on_phase_changed(GameFlow.phase)


func _load_location(id: String) -> void:
	if _location != null:
		SFXHelper.travel()
		_location.queue_free()
	var scene: PackedScene = load(LocationManager.location_scene(id))
	_location = scene.instantiate()
	_host.add_child(_location)
	_bind_location(_location)
	_fit_camera_to_location(_location)


## Zoom both cameras so the room's floor fills most of the viewport. Small dorm
## bedrooms (~190x160) otherwise read as tiny islands of floor on a 1152x648 screen.
func _fit_camera_to_location(loc: Node2D) -> void:
	var rect := _location_floor_rect(loc)
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	var vp := get_viewport().get_visible_rect().size
	var fit := minf(vp.x / rect.size.x, vp.y / rect.size.y) * ZOOM_FIT_PADDING
	fit = clampf(fit, ZOOM_MIN, ZOOM_MAX)
	var z := Vector2(fit, fit)
	if loc.detective != null:
		var cam := loc.detective.get_node_or_null("Camera2D") as Camera2D
		if cam != null:
			cam.zoom = z
	_camera.zoom = z
	_camera.position = rect.get_center()


func _location_floor_rect(loc: Node2D) -> Rect2:
	# Prefer the walled enclosure when present: Floor/Grass tilemaps often spill
	# past the walls (stray tiles), which under-zooms small rooms.
	var walls := loc.get_node_or_null("Walls")
	if walls != null:
		var rect := Rect2()
		var first := true
		for child in walls.get_children():
			if child is Control:
				var r := (child as Control).get_global_rect()
				rect = r if first else rect.merge(r)
				first = false
		if not first:
			return rect
	for node_name in ["Floor", "GrassLayer", "TileBase"]:
		var floor_node := loc.get_node_or_null(node_name)
		if floor_node is TileMapLayer:
			var layer := floor_node as TileMapLayer
			var used := layer.get_used_rect()
			if used.size.x > 0 and used.size.y > 0:
				var tile := Vector2i(16, 16)
				if layer.tile_set != null:
					tile = layer.tile_set.tile_size
				var local_rect := Rect2(
					Vector2(used.position * tile),
					Vector2(used.size * tile)
				)
				return layer.get_global_transform() * local_rect
		elif floor_node != null:
			# crestwood_hall: Floor is a Node2D wrapping TileBase.
			var nested := floor_node.get_node_or_null("TileBase")
			if nested is TileMapLayer:
				var layer2 := nested as TileMapLayer
				var used2 := layer2.get_used_rect()
				if used2.size.x > 0 and used2.size.y > 0:
					var tile2 := Vector2i(16, 16)
					if layer2.tile_set != null:
						tile2 = layer2.tile_set.tile_size
					return layer2.get_global_transform() * Rect2(
						Vector2(used2.position * tile2),
						Vector2(used2.size * tile2)
					)
	return Rect2()


func _bind_location(loc: Node2D) -> void:
	if loc.detective != null:
		_prompt.bind(loc.detective.get_node("Interactor"))
	set_mode(Mode.PLAY)
	_observer.bind_npcs(loc.npcs)
	for npc in loc.npcs:
		var area: Area2D = npc.get_node("ClickArea")
		area.input_pickable = true
		if not area.input_event.is_connected(_on_npc_input):
			area.input_event.connect(_on_npc_input.bind(npc))
		for ch in npc.get_children():
			if ch is NpcInteractable:
				if not ch.talk_requested.is_connected(_on_talk_requested):
					ch.talk_requested.connect(_on_talk_requested)
				if not ch.talk_requested.is_connected(func(_s): Tutorial.on_npc_approached()):
					ch.talk_requested.connect(func(_s): Tutorial.on_npc_approached())
	# Location-level interactables must wire even when loc.npcs is empty
	for ch in loc.get_children():
		if ch is SearchPoint:
			if not ch.search_requested.is_connected(_on_search_requested):
				ch.search_requested.connect(_on_search_requested)
		elif ch is RestPoint:
			if not ch.rest_requested.is_connected(_on_rest_requested):
				ch.rest_requested.connect(_on_rest_requested)
		elif ch is DoorTrigger:
			if not ch.door_triggered.is_connected(func(d): Effects.fade_transition(func(): LocationManager.travel(d))):
				ch.door_triggered.connect(func(d): Effects.fade_transition(func(): LocationManager.travel(d)))


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
	if event.is_action_pressed("toggle_notebook") and GameFlow.phase == GameFlow.Phase.INVESTIGATION:
		_notebook.set_open(not _notebook.visible)
		return
	if event.is_action_pressed("toggle_board") and GameFlow.phase == GameFlow.Phase.INVESTIGATION:
		_evidence_board.set_open(not _evidence_board.visible)
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

	# Reduce day/night effect for indoor locations (they have artificial lighting)
	if _is_indoor(LocationManager.current_id):
		color = Color(1.0, 1.0, 1.0).lerp(color, 0.3)

	_day_night.color = color


func _is_indoor(loc_id: String) -> bool:
	match loc_id:
		"dorm", "bedroom_1", "bedroom_2", "bedroom_3", "bedroom_4", "bedroom_5", "bedroom_6":
			return true
		"daniel_room", "detective_room", "police_station", "university":
			return true
		"server_room", "library", "hospital", "bar":
			return true
		_:
			return false


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
	# Asset-pass flow: preview the case on the reveal screen first; nothing is
	# committed until the player confirms there (confirmed signal).
	var preview := _preview_accusation(suspect_id)
	_accuse_reveal.open(suspect_id, preview)


## Read-only preview of what accuse() would decide — no standing fallout,
## no resolution, safe to show before the player commits.
func _preview_accusation(suspect_id: String) -> Dictionary:
	if not CaseData.SUSPECTS.has(suspect_id):
		return {"accepted": false, "ending_id": "", "strength": 0.0, "threshold": 0}
	var threshold: int = int(CaseData.SUSPECTS[suspect_id]["threshold"])
	var strength: float = CaseFile.quality_strength(suspect_id)
	var accepted: bool = CaseFile.can_accuse(suspect_id)
	var ending_id := ""
	if accepted:
		ending_id = CaseFile._determine_ending(suspect_id)
	return {"accepted": accepted, "ending_id": ending_id,
		"strength": strength, "threshold": threshold}


func _on_accuse_confirmed(suspect_id: String, _ending_id: String) -> void:
	SFXHelper.accuse()
	Effects.shake_dramatic()
	var result: Dictionary = CaseFile.accuse(suspect_id)
	if result["accepted"]:
		_case_panel.set_open(false)
		SFXHelper.ending()
		GameFlow.trigger_ending(result["ending_id"])
	else:
		EventLog.log_action("Not enough evidence to accuse %s (%d/%d)" % [
			suspect_id, result["strength"], result["threshold"]], "case")


func _on_accuse_cancelled() -> void:
	_accuse_reveal.hide()


func _on_phase_changed(phase: int) -> void:
	match phase:
		GameFlow.Phase.CHOICE:
			_story.show_choice()
			_quit_case_btn.visible = false
		GameFlow.Phase.INVESTIGATION:
			_story.hide_screen()
			_quit_case_btn.visible = true
			Tutorial.start()
		GameFlow.Phase.ENDING:
			_quit_case_btn.visible = false
			_story.show_ending(GameFlow.current_ending_id, _collect_discovered_clue_ids())


func _collect_discovered_clue_ids() -> Array:
	var ids: Array = []
	for clue_id in CaseData.CLUES:
		if Investigation.is_discovered(clue_id):
			ids.append(clue_id)
	return ids


func _on_clue_discovered(_clue_id: String) -> void:
	Effects.shake_subtle()
	Effects.flash(Color(0.2, 0.4, 0.8, 0.3), 0.2)


func _on_talk_requested(suspect_id: String) -> void:
	# Asset-pass flow: authored dialogue card first; the interrogation opens
	# when the player continues past it (finished signal).
	_dialogue.open(suspect_id)


func _on_dialogue_finished(suspect_id: String) -> void:
	_interrogation.open(suspect_id, Investigation, Standing)
	Tutorial.on_interrogation_started()
	EventLog.log_action("Interrogating %s" % str(CaseData.SUSPECTS.get(suspect_id, {}).get("name", suspect_id)), "interrogation")


func _on_search_requested(point_id: String) -> void:
	_search_panel.open(point_id, Investigation)
	if _location != null and _location.detective != null:
		Effects.glow(_location.detective.global_position, Color(0.4, 0.8, 1.0))


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


func _on_new_game() -> void:
	Scheduler.reset()
	GameFlow.reset()
	Investigation.reset()
	Standing.reset()
	CaseFile.reset()
	Consequences.reset()
	LocalMemory.clear()
	EventLog.clear_log()
	Notebook.reset()
	LocationManager.reset()
	Tutorial.reset()
	get_tree().reload_current_scene()


func _on_quit_case_requested() -> void:
	Consequences.trigger_walk_away()


func _on_quit_case_pressed() -> void:
	_story.show_quit_case()


func _on_confess_triggered() -> void:
	Consequences.trigger_sacrifice()


func _on_cinematic_finished() -> void:
	_story.show_choice()
