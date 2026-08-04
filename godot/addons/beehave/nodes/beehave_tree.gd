extends BeehaveNode
class_name BehaviorTree

@export var enabled: bool = true

var _blackboard := Blackboard.new()


func _ready() -> void:
	actor = get_parent()
	blackboard = _blackboard
	_setup_children(self)


func _setup_children(node: Node) -> void:
	for child in node.get_children():
		if child is BeehaveNode:
			child.actor = actor
			child.blackboard = _blackboard
			_setup_children(child)


func _process(delta: float) -> void:
	if not enabled or Scheduler.is_paused:
		return
	if get_child_count() == 0:
		return
	var root := get_child(0)
	if root is BeehaveNode:
		root.tick(delta)


func get_blackboard() -> Blackboard:
	return _blackboard
