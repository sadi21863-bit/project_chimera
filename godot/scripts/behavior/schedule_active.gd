extends BTActionLeaf

## Check if schedule has an active target different from current room.

func tick(_delta: float) -> Status:
	var target: String = blackboard.get_value("schedule_target_room", "")
	var npc = actor
	if npc == null:
		return Status.FAILURE
	if target.is_empty():
		return Status.FAILURE
	if npc.current_room != target:
		return Status.SUCCESS
	return Status.FAILURE
