extends BTActionLeaf

## Check if AI decision branch should run (every N minutes at location).

var _cooldown := 0.0
const DECISION_INTERVAL := 5.0


func tick(delta: float) -> Status:
	_cooldown -= delta
	if _cooldown > 0.0:
		return Status.FAILURE
	_cooldown = DECISION_INTERVAL
	return Status.SUCCESS
