extends BeehaveNode
class_name BTActionLeaf

## Override tick() in extending scripts for custom behavior tree actions.

func tick(_delta: float) -> Status:
	return Status.SUCCESS
