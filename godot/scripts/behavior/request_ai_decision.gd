extends BTActionLeaf

## Request one AI decision per decision window from AIClient (Phase 3).
##
## CHI-003 - explicit lifecycle instead of the old single `_pending` boolean:
##
##     IDLE -> WAITING -> READY -> CONSUMED      (or WAITING -> FAILED)
##
## Why: `_pending` used to serve double duty as "no request issued yet" and "the response has
## already been handled". The callback cleared it the instant a response arrived, so the next
## tick matched the "not requested yet" branch again: it wiped `_result`, issued a duplicate
## request and returned RUNNING. The SUCCESS block below - the only place `ai_action` is ever
## published - was unreachable, so NPC AI never executed anything (not even the rule-based
## fallback, which flows through the same leaf).
##
## Contract (test_chi002_decision_lifecycle.gd):
##   - exactly one request per decision window, regardless of how many ticks occur while it
##     is in flight;
##   - a completed callback reaches blackboard "ai_action" exactly once, on a later tick;
##   - a late/duplicate delivery can never overwrite a settled decision;
##   - an unusable response resolves to FAILED instead of hanging RUNNING forever.

enum State { IDLE, WAITING, READY, CONSUMED, FAILED }

const KEY_ACTION := "ai_action"
const KEY_SOURCE := "ai_source"
## Bumped every time a decision is published. AwaitingAI restarts its cooldown from this.
const KEY_SEQ := "ai_decision_seq"
## Bumped by AwaitingAI when a new decision window opens - the only thing that re-arms us
## from CONSUMED, so ticks that follow a consumed decision can never fire a second request.
const KEY_EPOCH := "ai_decision_epoch"

var _state: int = State.IDLE
var _result: Dictionary = {}
var _epoch_seen := -1  # sentinel: synced from the blackboard on the first tick


func tick(_delta: float) -> Status:
	var npc = actor
	if npc == null or not npc.has_method("build_ai_context"):
		return Status.FAILURE

	if _epoch_seen < 0:
		_epoch_seen = int(blackboard.get_value(KEY_EPOCH, 0))

	match _state:
		State.IDLE:
			_result = {}
			_state = State.WAITING
			var context: Dictionary = npc.build_ai_context()
			AIClient.request_decision(npc.npc_id, context, _on_response)
			# The response may already have landed: RULE_BASED and the local provider both call
			# back synchronously, before request_decision returns. Publication is deliberately
			# deferred to the next tick so "request issued" always reports RUNNING exactly once
			# and the caller can never observe a half-published decision.
			return Status.RUNNING

		State.WAITING:
			# In flight. Never issue a second request for the same decision window.
			return Status.RUNNING

		State.READY:
			_publish()
			return Status.SUCCESS

		State.CONSUMED:
			# A new window opened: re-arm and fall through so the request is issued now
			# rather than a wasted cycle later.
			var epoch := int(blackboard.get_value(KEY_EPOCH, 0))
			if epoch != _epoch_seen:
				_epoch_seen = epoch
				_state = State.IDLE
				return tick(_delta)
			return Status.FAILURE

		State.FAILED:
			_state = State.IDLE
			return Status.FAILURE

	return Status.FAILURE


## Called for every provider/scheduler delivery. Ignores anything that arrives once the
## decision has already settled (duplicate or stale callbacks).
func _on_response(response) -> void:
	if _state != State.WAITING:
		return

	var action = response.get("action") if response is Dictionary else null
	var usable: bool = response is Dictionary \
		and response.has("action") \
		and action != null \
		and not (action is Dictionary and action.is_empty())

	if usable:
		_result = response
		_state = State.READY
	else:
		_result = {}
		_state = State.FAILED


func _publish() -> void:
	blackboard.set_value(KEY_ACTION, _result.get("action", {}))
	blackboard.set_value(KEY_SOURCE, str(_result.get("source", "unknown")))
	blackboard.set_value(KEY_SEQ, int(blackboard.get_value(KEY_SEQ, -1)) + 1)
	_result = {}
	_state = State.CONSUMED
