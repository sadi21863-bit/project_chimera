extends BTActionLeaf

## Gate for the AI decision branch: lets one decision attempt through every DECISION_INTERVAL.
##
## CHI-003 - two changes:
##
## 1. The cooldown is restarted when a decision is actually CONSUMED (published to the
##    blackboard as ai_decision_seq), not when the gate opened. Arming it at gate-open meant
##    the interval was spent before the provider had even answered, so a slow response ate the
##    whole window and the next one could open while the previous response was still in flight.
## 2. Each opening bumps ai_decision_epoch. That is the signal RequestAIDecision uses to leave
##    CONSUMED and start a new request - without it, either the leaf never re-armed or it
##    re-armed on the very next tick and issued duplicates.

const DECISION_INTERVAL := 5.0
const KEY_SEQ := "ai_decision_seq"
const KEY_EPOCH := "ai_decision_epoch"

var _cooldown := 0.0
var _synced := false
var _last_seq := -1


func tick(delta: float) -> Status:
	var seq := int(blackboard.get_value(KEY_SEQ, -1))
	if not _synced:
		# Adopt whatever history is already on the blackboard instead of treating it as a
		# fresh consumption (which would hold the gate shut for one interval at startup).
		_synced = true
		_last_seq = seq
	elif seq != _last_seq:
		_last_seq = seq
		_cooldown = DECISION_INTERVAL

	_cooldown -= delta
	if _cooldown > 0.0:
		return Status.FAILURE

	_cooldown = DECISION_INTERVAL
	blackboard.set_value(KEY_EPOCH, int(blackboard.get_value(KEY_EPOCH, 0)) + 1)
	return Status.SUCCESS
