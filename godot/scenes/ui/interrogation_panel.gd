extends CanvasLayer

## Interrogation UI: authored topic buttons + present-evidence + a free-text box (routed to the
## LLM by the host). Trust-gated topics reveal clues into the Investigation store.

signal free_text_submitted(suspect_id: String, text: String)
signal closed()

@onready var _name: Label = $Panel/VBox/NameLabel
@onready var _topics: VBoxContainer = $Panel/VBox/Topics
@onready var _response: Label = $Panel/VBox/Response
@onready var _input: LineEdit = $Panel/VBox/InputRow/Input

var _suspect_id := ""
var _investigation: Node = null
var _standing: Node = null


func _ready() -> void:
	$Panel/VBox/InputRow/SubmitButton.pressed.connect(_on_submit_pressed)
	$Panel/VBox/CloseButton.pressed.connect(close)
	visible = false


func open(suspect_id: String, investigation: Node, standing: Node) -> void:
	_suspect_id = suspect_id
	_investigation = investigation
	_standing = standing
	_name.text = "Interrogating %s" % str(CaseData.SUSPECTS.get(suspect_id, {}).get("name", suspect_id))
	_response.text = ""
	for child in _topics.get_children():
		child.queue_free()
	for topic in InterrogationData.topics_for(suspect_id):
		var btn := Button.new()
		btn.text = str(topic["label"])
		btn.pressed.connect(select_topic.bind(str(topic["id"])))
		_topics.add_child(btn)
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func select_topic(topic_id: String) -> void:
	var standing: float = _standing.get_standing(_suspect_id) if _standing != null else 0.0
	var result: Dictionary = InterrogationData.respond_to_topic(_suspect_id, topic_id, standing)
	_response.text = str(result["text"])
	var reveal: String = str(result["reveal_clue"])
	if reveal != "" and _investigation != null and _investigation.discover_clue(reveal):
		if _standing != null:
			_standing.adjust(_suspect_id, 0.05)
		_log("%s let something slip: %s" % [_suspect_id, reveal])


func present_evidence(clue_id: String) -> void:
	_response.text = InterrogationData.respond_to_evidence(_suspect_id, clue_id)


func show_response(text: String) -> void:
	_response.text = text


func submit_free_text(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	free_text_submitted.emit(_suspect_id, text)
	_input.text = ""


func _on_submit_pressed() -> void:
	submit_free_text(_input.text)


func _log(text: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var node := (loop as SceneTree).root.get_node_or_null("EventLog")
		if node != null:
			node.call("log_action", text, "interrogation")
