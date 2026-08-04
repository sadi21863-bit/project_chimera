extends BTActionLeaf

## Move NPC to schedule target marker via NavigationAgent2D.

var _waiting := false


func tick(_delta: float) -> Status:
	var npc: CharacterBody2D = actor as CharacterBody2D
	if npc == null or not npc.has_method("move_to_room"):
		return Status.FAILURE

	var target_room: String = blackboard.get_value("schedule_target_room", "")
	if target_room.is_empty():
		return Status.FAILURE

	if npc.current_room == target_room:
		return Status.SUCCESS

	if not _waiting:
		npc.move_to_room(target_room)
		_waiting = true

	if npc.is_navigating():
		return Status.RUNNING

	_waiting = false
	if npc.current_room == target_room or not npc.is_navigating():
		npc.current_room = target_room
		EventLog.log_action("%s arrived at %s" % [npc.display_name, target_room], "movement", npc.npc_id)
		return Status.SUCCESS
	return Status.FAILURE
