extends CanvasLayer

## Enhanced interrogation UI with branching paths and questioning styles.
## Style choice affects NPC reactions, trust, and resistance.

signal free_text_submitted(suspect_id: String, text: String)
signal closed()
signal confess_triggered()

@onready var _name: Label = $Panel/VBox/NameLabel
@onready var _topics: VBoxContainer = $Panel/VBox/Topics
@onready var _response: Label = $Panel/VBox/Response
@onready var _input: LineEdit = $Panel/VBox/InputRow/Input
@onready var _style_label: Label = $Panel/VBox/StyleLabel

var _suspect_id := ""
var _investigation: Node = null
var _standing: Node = null
var _evidence_quality: Node = null
var _npc_relationships: Node = null
var _current_style: int = EnhancedInterrogationData.Style.DIRECT
var _asked_topics: Array = []
var _unlocked_topics: Array = []


func _ready() -> void:
	$Panel/VBox/InputRow/SubmitButton.pressed.connect(_on_submit_pressed)
	$Panel/VBox/CloseButton.pressed.connect(close)
	$Panel/VBox/ConfessButton.pressed.connect(_on_confess_pressed)
	$Panel/VBox/StyleRow/DirectButton.pressed.connect(_on_style_direct)
	$Panel/VBox/StyleRow/EmpatheticButton.pressed.connect(_on_style_empathetic)
	$Panel/VBox/StyleRow/ConfrontationalButton.pressed.connect(_on_style_confrontational)
	visible = false


func open(suspect_id: String, investigation: Node, standing: Node) -> void:
	_suspect_id = suspect_id
	_investigation = investigation
	_standing = standing
	_evidence_quality = get_node_or_null("/root/EvidenceQuality")
	_npc_relationships = get_node_or_null("/root/NPCRelationships")
	SFXHelper.interrogation_start()
	Effects.show_vignette()
	_name.text = "Interrogating %s" % str(CaseData.SUSPECTS.get(suspect_id, {}).get("name", suspect_id))
	_response.text = ""
	_asked_topics.clear()
	_unlocked_topics.clear()
	_current_style = EnhancedInterrogationData.Style.DIRECT
	_update_style_ui()
	_rebuild_topic_buttons()
	var current_standing: float = standing.get_standing(suspect_id) if standing != null else 0.0
	$Panel/VBox/ConfessButton.visible = current_standing >= 0.5
	visible = true


func close() -> void:
	visible = false
	Effects.hide_vignette()
	closed.emit()


func _rebuild_topic_buttons() -> void:
	for child in _topics.get_children():
		child.queue_free()
	var available := EnhancedInterrogationData.get_available_topics(_suspect_id, _asked_topics, _unlocked_topics)
	for topic_id in available:
		var btn := Button.new()
		btn.text = _get_topic_label(topic_id)
		btn.pressed.connect(select_topic.bind(topic_id))
		_topics.add_child(btn)


func _get_topic_label(topic_id: String) -> String:
	var labels := {
		"that_night": "Where were you that night?",
		"the_keys": "About those master keys...",
		"the_grade": "Tell me about your academic record.",
		"the_lie": "You lied about being there. Why?",
		"the_tip": "Give me something to work with.",
		"the_camera": "Why was the camera disabled?",
		"the_pills": "Did you give them anything?",
		"the_scene": "Did you touch the scene?",
		"the_window": "Tell me about the window sketch.",
		"the_hint": "You said you see everything.",
		"the_double_life": "What was he hiding here?",
		"the_family": "What's the Crestwood family's involvement?",
		"the_coverup": "Who told you to stay quiet?",
		"the_student_id": "Daniel had two student IDs. How?",
	}
	return labels.get(topic_id, topic_id)


func select_topic(topic_id: String) -> void:
	var standing_val: float = _standing.get_standing(_suspect_id) if _standing != null else 0.0
	var result: Dictionary = EnhancedInterrogationData.get_branching_response(_suspect_id, topic_id, _current_style, standing_val)
	_response.text = str(result["text"])
	var reveal: String = str(result["reveal_clue"])
	var follow_up: String = str(result["follow_up"])
	var resistance_inc: float = float(result.get("resistance_increase", 0.0))
	_asked_topics.append(topic_id)
	if follow_up != "" and follow_up not in _asked_topics:
		_unlocked_topics.append(follow_up)
	if reveal != "" and _investigation != null and _investigation.discover_clue(reveal):
		if _standing != null:
			_standing.adjust(_suspect_id, 0.05)
		if _evidence_quality != null:
			_evidence_quality.record(reveal, _evidence_quality.EvidenceQuality.STRONG, _evidence_quality.EvidenceSource.TESTIMONIAL)
		_log("%s revealed %s via %s approach" % [_suspect_id, reveal, EnhancedInterrogationData.STYLE_NAMES[_current_style]])
	if resistance_inc > 0.0 and _npc_relationships != null:
		_npc_relationships.adjust_resistance(_suspect_id, resistance_inc)
	var modifier := EnhancedInterrogationData.get_style_modifier(_current_style)
	if _standing != null and modifier.trust_delta != 0.0:
		_standing.adjust(_suspect_id, modifier.trust_delta)
	_rebuild_topic_buttons()


func present_evidence(clue_id: String) -> void:
	_response.text = InterrogationData.respond_to_evidence(_suspect_id, clue_id)
	if _standing != null:
		var response: String = InterrogationData.respond_to_evidence(_suspect_id, clue_id)
		if response != "I don't see what that has to do with me.":
			_standing.adjust(_suspect_id, 0.08)


func show_response(text: String) -> void:
	_response.text = text


func submit_free_text(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	free_text_submitted.emit(_suspect_id, text)
	_input.text = ""


func _on_style_direct() -> void:
	_current_style = EnhancedInterrogationData.Style.DIRECT
	_update_style_ui()


func _on_style_empathetic() -> void:
	_current_style = EnhancedInterrogationData.Style.EMPATHETIC
	_update_style_ui()


func _on_style_confrontational() -> void:
	_current_style = EnhancedInterrogationData.Style.CONFRONTATIONAL
	_update_style_ui()


func _update_style_ui() -> void:
	_style_label.text = "Style: %s" % EnhancedInterrogationData.STYLE_NAMES[_current_style]
	$Panel/VBox/StyleRow/DirectButton.disabled = _current_style == EnhancedInterrogationData.Style.DIRECT
	$Panel/VBox/StyleRow/EmpatheticButton.disabled = _current_style == EnhancedInterrogationData.Style.EMPATHETIC
	$Panel/VBox/StyleRow/ConfrontationalButton.disabled = _current_style == EnhancedInterrogationData.Style.CONFRONTATIONAL


func _on_submit_pressed() -> void:
	submit_free_text(_input.text)


func _on_confess_pressed() -> void:
	confess_triggered.emit()
	close()


func _log(text: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var node := (loop as SceneTree).root.get_node_or_null("EventLog")
		if node != null:
			node.call("log_action", text, "interrogation")
