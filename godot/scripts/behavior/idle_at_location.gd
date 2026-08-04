extends BTActionLeaf

## Idle at current location for a short period.

var _timer := 0.0
const IDLE_DURATION := 2.0


func tick(delta: float) -> Status:
	_timer += delta
	if _timer >= IDLE_DURATION:
		_timer = 0.0
		return Status.SUCCESS
	return Status.RUNNING
