extends BeehaveNode
class_name BTSelector

func tick(delta: float) -> Status:
	for child in get_child_nodes():
		var status: Status = child.tick(delta)
		if status != Status.FAILURE:
			return status
	return Status.FAILURE
