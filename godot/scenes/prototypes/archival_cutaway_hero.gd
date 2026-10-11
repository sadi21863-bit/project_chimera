extends Node2D

const DAY_TEXTURE := preload("res://assets/prototypes/archival_cutaway_room_day_inked.png")
const NIGHT_TEXTURE := preload("res://assets/prototypes/archival_cutaway_room_night_inked.png")
const INK := Color("#111820")
const SLATE := Color("#293b49")
const SLATE_LIGHT := Color("#3c5660")
const PAPER := Color("#d8d0be")
const PAPER_LIGHT := Color("#eee5cf")
const GREEN := Color("#687c6d")
const AMBER := Color("#d99a4d")
const RED := Color("#a6403d")
const TEAL := Color("#4e7778")
const PLAYER_SPEED := 220.0
const WORLD_MIN := Vector2(330.0, 300.0)
const WORLD_MAX := Vector2(980.0, 585.0)

var _background: Sprite2D
var _time_label: Label
var _case_card: PanelContainer
var _dialogue: PanelContainer
var _evidence_marker: Polygon2D
var _player: Node2D = null
var _interaction_prompt: Label = null
var _dialogue_text: Label = null
var _pulse := 0.0
var _night := false
var _searched := false


func _ready() -> void:
	_build_world()
	_build_ui()
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	if _player != null:
		var direction := Input.get_vector("camera_pan_left", "camera_pan_right", "camera_pan_up", "camera_pan_down")
		if direction != Vector2.ZERO:
			_player.position += direction * PLAYER_SPEED * delta
		_player.position.x = clampf(_player.position.x, WORLD_MIN.x, WORLD_MAX.x)
		_player.position.y = clampf(_player.position.y, WORLD_MIN.y, WORLD_MAX.y)
	if _evidence_marker != null:
		var pulse := 1.0 + sin(_pulse * 3.0) * 0.12
		_evidence_marker.scale = Vector2(pulse, pulse)
		_evidence_marker.modulate.a = 0.72 + sin(_pulse * 3.0) * 0.2
	if _interaction_prompt != null and _player != null:
		var near_evidence := _player.position.distance_to(_evidence_marker.position) < 92.0
		_interaction_prompt.visible = near_evidence and not _searched
		if near_evidence and not _searched and Input.is_action_just_pressed("interact"):
			_complete_search()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N:
			_toggle_night()
		elif event.keycode == KEY_C:
			_toggle_case_card()


func _build_world() -> void:
	_background = Sprite2D.new()
	_background.texture = DAY_TEXTURE
	_background.position = Vector2(640, 360)
	add_child(_background)
	var veil := ColorRect.new()
	veil.color = Color(0.02, 0.035, 0.05, 0.12)
	veil.position = Vector2.ZERO
	veil.size = Vector2(1280, 720)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	_player = _make_character("DETECTIVE", Vector2(455, 495), INK, AMBER, 1.08)
	_make_character("JORDAN", Vector2(700, 440), RED, PAPER_LIGHT, 1.0)
	_make_character("MORGAN", Vector2(835, 510), GREEN, TEAL, 0.98)
	_build_evidence_marker()


func _make_character(name: String, position: Vector2, coat: Color, accent: Color, scale_factor: float) -> Node2D:
	var root := Node2D.new()
	root.position = position
	root.scale = Vector2(scale_factor, scale_factor)
	add_child(root)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-30, 78), Vector2(30, 78), Vector2(42, 88), Vector2(-42, 88)])
	shadow.color = Color(0.02, 0.03, 0.04, 0.28)
	root.add_child(shadow)
	var leg_outline := _outline([Vector2(-17, 32), Vector2(-3, 32), Vector2(-6, 78), Vector2(-19, 78), Vector2(-10, 45), Vector2(-25, 78), Vector2(-38, 78), Vector2(-32, 43)], INK, 1.6)
	root.add_child(leg_outline)
	var body_outline := _outline([Vector2(-24, -12), Vector2(22, -12), Vector2(30, 36), Vector2(8, 48), Vector2(-31, 35)], INK, 1.6)
	root.add_child(body_outline)
	var head_outline := _outline([Vector2(-13, -30), Vector2(12, -30), Vector2(17, -15), Vector2(10, 1), Vector2(-10, 1), Vector2(-17, -15)], INK, 1.4)
	root.add_child(head_outline)
	var legs := Polygon2D.new()
	legs.polygon = PackedVector2Array([Vector2(-17, 32), Vector2(-3, 32), Vector2(-6, 78), Vector2(-19, 78), Vector2(-10, 45), Vector2(-25, 78), Vector2(-38, 78), Vector2(-32, 43)])
	legs.color = INK
	root.add_child(legs)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-24, -12), Vector2(22, -12), Vector2(30, 36), Vector2(8, 48), Vector2(-31, 35)])
	body.color = coat
	root.add_child(body)
	var shirt := Polygon2D.new()
	shirt.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(5, 29), Vector2(-5, 29)])
	shirt.color = accent
	root.add_child(shirt)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([Vector2(-13, -30), Vector2(12, -30), Vector2(17, -15), Vector2(10, 1), Vector2(-10, 1), Vector2(-17, -15)])
	head.color = Color("#d4b08b")
	root.add_child(head)
	var hair := Polygon2D.new()
	hair.polygon = PackedVector2Array([Vector2(-17, -25), Vector2(-11, -36), Vector2(8, -37), Vector2(18, -27), Vector2(11, -24), Vector2(-8, -27)])
	hair.color = INK
	root.add_child(hair)
	var left_eye := Polygon2D.new()
	left_eye.polygon = PackedVector2Array([Vector2(-7, -18), Vector2(-3, -18), Vector2(-5, -14)])
	left_eye.color = INK
	root.add_child(left_eye)
	var right_eye := Polygon2D.new()
	right_eye.polygon = PackedVector2Array([Vector2(4, -18), Vector2(8, -18), Vector2(6, -14)])
	right_eye.color = INK
	root.add_child(right_eye)
	var mouth := Line2D.new()
	mouth.points = PackedVector2Array([Vector2(-4, -8), Vector2(5, -8)])
	mouth.width = 1.2
	mouth.default_color = INK
	root.add_child(mouth)
	if name == "DETECTIVE":
		var hat := Polygon2D.new()
		hat.polygon = PackedVector2Array([Vector2(-21, -33), Vector2(21, -33), Vector2(14, -42), Vector2(-14, -42)])
		hat.color = INK
		root.add_child(hat)
	elif name == "JORDAN":
		var scarf := Polygon2D.new()
		scarf.polygon = PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(9, 3), Vector2(-9, 3)])
		scarf.color = RED
		root.add_child(scarf)
	else:
		var bag := Polygon2D.new()
		bag.polygon = PackedVector2Array([Vector2(15, 4), Vector2(34, 4), Vector2(31, 27), Vector2(18, 27)])
		bag.color = TEAL
		root.add_child(bag)
	var tag := Label.new()
	tag.text = name
	tag.position = Vector2(-65, 92)
	tag.size = Vector2(130, 22)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", PAPER_LIGHT)
	tag.add_theme_color_override("font_shadow_color", INK)
	tag.add_theme_constant_override("shadow_offset_x", 1)
	tag.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(tag)
	return root


func _build_evidence_marker() -> void:
	_evidence_marker = Polygon2D.new()
	_evidence_marker.position = Vector2(650, 520)
	_evidence_marker.polygon = PackedVector2Array([Vector2(0, -18), Vector2(18, 0), Vector2(0, 18), Vector2(-18, 0)])
	_evidence_marker.color = AMBER
	_evidence_marker.z_index = 5
	add_child(_evidence_marker)
	var label := Label.new()
	label.text = "PRESCRIPTION BOTTLE"
	label.position = Vector2(575, 548)
	label.size = Vector2(160, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", AMBER)
	label.add_theme_color_override("font_shadow_color", INK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_build_top_bar(root)
	_build_case_file(root)
	_build_objective(root)
	_build_interaction_prompt(root)
	_build_case_card(root)
	_build_dialogue(root)
	_build_controls(root)


func _build_top_bar(root: Control) -> void:
	var panel := _panel(Color(0.04, 0.07, 0.09, 0.92), AMBER)
	panel.position = Vector2(24, 18)
	panel.size = Vector2(1232, 58)
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.position = Vector2(22, 10)
	row.size = Vector2(1188, 38)
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var title := Label.new()
	title.text = "ARCHIVE  /  CRESTWOOD HALL"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", PAPER_LIGHT)
	row.add_child(title)
	var objective := Label.new()
	objective.text = "KITCHEN / HALLWAY  ·  FOLLOW THE PAPER TRAIL"
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective.add_theme_font_size_override("font_size", 12)
	objective.add_theme_color_override("font_color", PAPER)
	row.add_child(objective)
	_time_label = Label.new()
	_time_label.text = "DAY 01  ·  07:04"
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 13)
	_time_label.add_theme_color_override("font_color", AMBER)
	row.add_child(_time_label)


func _build_case_file(root: Control) -> void:
	var panel := _panel(Color(0.04, 0.07, 0.09, 0.88), SLATE_LIGHT)
	panel.position = Vector2(28, 104)
	panel.size = Vector2(286, 462)
	root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	column.add_child(_label("CASE FILE  /  01", 18, AMBER))
	column.add_child(_label("THE ACCIDENT THAT WASN'T", 11, PAPER))
	column.add_child(_rule())
	column.add_child(_label("EVIDENCE", 11, TEAL))
	column.add_child(_evidence_row("01", "PRESCRIPTION BOTTLE", "MEDICAL", AMBER))
	column.add_child(_evidence_row("02", "KEYS", "UNEXPLAINED", PAPER))
	column.add_child(_evidence_row("03", "WITNESS ACCOUNT", "CONTRADICTS", RED))
	column.add_child(_rule())
	column.add_child(_label("CURRENT THREAD", 11, TEAL))
	var thread := _label("Someone moved the bottle after the lights went out.", 14, PAPER_LIGHT)
	thread.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	thread.custom_minimum_size = Vector2(0, 56)
	column.add_child(thread)
	var confidence := _label("CONFIDENCE  ·  MODERATE", 11, AMBER)
	column.add_child(confidence)


func _build_objective(root: Control) -> void:
	var panel := _panel(Color(0.04, 0.07, 0.09, 0.84), TEAL)
	panel.position = Vector2(982, 108)
	panel.size = Vector2(270, 144)
	root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	column.add_child(_label("OBSERVATION", 11, TEAL))
	column.add_child(_label("The kitchen is empty.\nThe hallway is not.", 16, PAPER_LIGHT))
	column.add_child(_label("NEXT  ·  EXAMINE THE BOTTLE", 10, AMBER))


func _build_interaction_prompt(root: Control) -> void:
	_interaction_prompt = _label("[E]  EXAMINE THE PRESCRIPTION BOTTLE", 13, AMBER)
	_interaction_prompt.position = Vector2(470, 566)
	_interaction_prompt.size = Vector2(340, 26)
	_interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt.add_theme_color_override("font_shadow_color", INK)
	_interaction_prompt.add_theme_constant_override("shadow_offset_x", 1)
	_interaction_prompt.add_theme_constant_override("shadow_offset_y", 1)
	_interaction_prompt.visible = false
	root.add_child(_interaction_prompt)


func _build_case_card(root: Control) -> void:
	_case_card = _panel(Color(0.82, 0.78, 0.67, 0.96), RED)
	_case_card.position = Vector2(950, 300)
	_case_card.size = Vector2(300, 180)
	root.add_child(_case_card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	_case_card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)
	column.add_child(_label("EVIDENCE 03", 11, RED))
	column.add_child(_label("PRESCRIPTION BOTTLE", 17, INK))
	column.add_child(_rule(Color(0.35, 0.12, 0.10, 0.55)))
	column.add_child(_label("Found near the service door.\nLabel partially removed.", 13, INK))
	var status := _label("STATUS  ·  UNVERIFIED", 10, RED)
	column.add_child(status)


func _build_dialogue(root: Control) -> void:
	_dialogue = _panel(Color(0.04, 0.07, 0.09, 0.94), AMBER)
	_dialogue.position = Vector2(330, 620)
	_dialogue.size = Vector2(620, 70)
	root.add_child(_dialogue)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	_dialogue.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)
	column.add_child(_label("JORDAN  ·  THEATER KID", 10, AMBER))
	_dialogue_text = _label("“I heard something. I kept walking. That is the part I cannot say out loud.”", 15, PAPER_LIGHT)
	column.add_child(_dialogue_text)


func _build_controls(root: Control) -> void:
	var night := Button.new()
	night.text = "NIGHT  [N]"
	night.position = Vector2(1032, 650)
	night.size = Vector2(112, 32)
	night.add_theme_font_size_override("font_size", 10)
	night.pressed.connect(_toggle_night)
	root.add_child(night)
	var card := Button.new()
	card.text = "CARD  [C]"
	card.position = Vector2(1152, 650)
	card.size = Vector2(100, 32)
	card.add_theme_font_size_override("font_size", 10)
	card.pressed.connect(_toggle_case_card)
	root.add_child(card)


func _complete_search() -> void:
	_searched = true
	_evidence_marker.color = GREEN
	_interaction_prompt.visible = false
	_case_card.visible = true
	if _dialogue_text != null:
		_dialogue_text.text = "Jordan: \"You found it. I thought I was the only one who saw him leave.\""


func _toggle_night() -> void:
	_night = not _night
	_background.texture = NIGHT_TEXTURE if _night else DAY_TEXTURE
	_time_label.text = "DAY 01  ·  23:18" if _night else "DAY 01  ·  07:04"


func _toggle_case_card() -> void:
	_case_card.visible = not _case_card.visible


func _panel(background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _outline(points: Array, color: Color, width: float) -> Line2D:
	var outline := Line2D.new()
	var closed_points := PackedVector2Array(points)
	closed_points.append(closed_points[0])
	outline.points = closed_points
	outline.width = width
	outline.default_color = color
	return outline


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _rule(color: Color = Color(0.55, 0.52, 0.44, 0.45)) -> Control:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return rule


func _evidence_row(number: String, title: String, status: String, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	row.add_theme_constant_override("separation", 8)
	var id := _label(number, 11, color)
	id.custom_minimum_size = Vector2(22, 0)
	row.add_child(id)
	var text := _label(title, 12, PAPER_LIGHT)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var state := _label(status, 9, color)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(state)
	return row
