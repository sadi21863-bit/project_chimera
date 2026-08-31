extends CanvasLayer

## Detailed-examination panel: shows an object's actions (look under / dig / lift). Each action
## prints its flavor and may reveal a clue. Risky actions are flagged (the consequence comes with
## the later sneaking slice).

signal closed()
signal action_selected(point_id: String, action_id: String, risk: String)

@onready var _title: Label = $Panel/VBox/Title
@onready var _actions: VBoxContainer = $Panel/VBox/Actions
@onready var _response: Label = $Panel/VBox/Response

var _point_id := ""
var _action_id := ""
var _investigation: Node = null
var _evidence_quality: Node = null


func _ready() -> void:
	$Panel/VBox/CloseButton.pressed.connect(close)
	visible = false


func open(point_id: String, investigation: Node) -> void:
	_point_id = point_id
	_investigation = investigation
	_evidence_quality = get_node_or_null("/root/EvidenceQuality")
	var p: Dictionary = SearchData.point(point_id)
	_title.text = "Searching %s" % str(p.get("label", point_id))
	var clue_count := 0
	for action in p.get("actions", []):
		if str(action.get("reveal_clue", "")) != "":
			clue_count += 1
	if clue_count > 0:
		_title.text += " (%d clue%s available)" % [clue_count, "s" if clue_count > 1 else ""]
	_response.text = ""
	for child in _actions.get_children():
		child.queue_free()
	for action in p.get("actions", []):
		var btn := Button.new()
		var risk: String = str(action.get("risk", "safe"))
		var risk_hints: String = str(Difficulty.get_value("risk_hints", "shown"))
		btn.text = str(action["label"]) + RiskAssessor.hint_for(risk, risk_hints)
		btn.pressed.connect(select_action.bind(str(action["id"])))
		_actions.add_child(btn)
	visible = true


func select_action(action_id: String) -> void:
	SFXHelper.search()
	_action_id = action_id
	var res: Dictionary = SearchData.resolve(_point_id, action_id)
	_response.text = str(res["flavor"])
	var reveal: String = str(res["reveal_clue"])
	if reveal != "" and _investigation != null and _investigation.discover_clue(reveal):
		_log("Your search turned up a clue: %s" % reveal)
		_record_evidence_quality(reveal)
		Effects.shake_subtle()
	else:
		_response.text += "\n\nNothing useful here."
		_log("Searched but found nothing of interest.")
	action_selected.emit(_point_id, action_id, _risk_for(action_id))
	var screen_center := Vector2(640, 360)
	Effects.dust(screen_center)


func _record_evidence_quality(clue_id: String) -> void:
	if _evidence_quality == null:
		return
	var risk := _risk_for_current_action()
	var quality: int
	match risk:
		"dangerous", "risky":
			quality = _evidence_quality.EvidenceQuality.DEFINITIVE
		"medium":
			quality = _evidence_quality.EvidenceQuality.STRONG
		_:
			quality = _evidence_quality.EvidenceQuality.MODERATE
	_evidence_quality.record(clue_id, quality, _evidence_quality.EvidenceSource.FOUND)


func _risk_for(action_id: String) -> String:
	var p: Dictionary = SearchData.point(_point_id)
	for action in p.get("actions", []):
		if str(action["id"]) == action_id:
			return str(action.get("risk", "safe"))
	return "safe"


func _risk_for_current_action() -> String:
	return _risk_for(_action_id)


func close() -> void:
	visible = false
	closed.emit()


func _log(text: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var node := (loop as SceneTree).root.get_node_or_null("EventLog")
		if node != null:
			node.call("log_action", text, "search")
