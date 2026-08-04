extends BTActionLeaf

## Request AI decision from Python server (Phase 3).

var _pending := false
var _result: Dictionary = {}


func tick(_delta: float) -> Status:
	var npc = actor
	if npc == null or not npc.has_method("build_ai_context"):
		return Status.FAILURE

	if not _pending:
		_pending = true
		_result = {}
		var context: Dictionary = npc.build_ai_context()
		AIClient.request_decision(npc.npc_id, context, func(response):
			_result = response
			_pending = false
		)
		return Status.RUNNING

	if _pending:
		return Status.RUNNING

	if _result.is_empty():
		return Status.FAILURE

	blackboard.set_value("ai_action", _result.get("action", {}))
	blackboard.set_value("ai_source", _result.get("source", "unknown"))
	return Status.SUCCESS
