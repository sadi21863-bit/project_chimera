extends BeehaveNode
class_name BTSequence

func tick(delta: float) -> Status:
	for child in get_child_nodes():
		var status: Status = child.tick(delta)
		if status != Status.SUCCESS:
			return status
	return Status.SUCCESS
