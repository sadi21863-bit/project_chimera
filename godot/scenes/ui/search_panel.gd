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
var _investigation: Node = null


func _ready() -> void:
	$Panel/VBox/CloseButton.pressed.connect(close)
	visible = false


func open(point_id: String, investigation: Node) -> void:
	_point_id = point_id
	_investigation = investigation
	var p: Dictionary = SearchData.point(point_id)
	_title.text = "Searching %s" % str(p.get("label", point_id))
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
	var res: Dictionary = SearchData.resolve(_point_id, action_id)
	_response.text = str(res["flavor"])
	var reveal: String = str(res["reveal_clue"])
	if reveal != "" and _investigation != null and _investigation.discover_clue(reveal):
		_log("Your search turned up a clue.")
	action_selected.emit(_point_id, action_id, _risk_for(action_id))


func _risk_for(action_id: String) -> String:
	var p: Dictionary = SearchData.point(_point_id)
	for action in p.get("actions", []):
		if str(action["id"]) == action_id:
			return str(action.get("risk", "safe"))
	return "safe"


func close() -> void:
	visible = false
	closed.emit()


func _log(text: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var node := (loop as SceneTree).root.get_node_or_null("EventLog")
		if node != null:
			node.call("log_action", text, "search")
