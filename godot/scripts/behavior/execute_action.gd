extends BTActionLeaf

## Execute action from AI decision or fallback.

var _executing := false


func tick(_delta: float) -> Status:
	var npc = actor
	if npc == null:
		return Status.FAILURE

	var action: Dictionary = blackboard.get_value("ai_action", {})
	if action.is_empty():
		return Status.FAILURE

	if not _executing:
		_executing = true
		npc.execute_action(action)
		return Status.RUNNING

	if npc.is_action_running():
		return Status.RUNNING

	_executing = false
	return Status.SUCCESS
