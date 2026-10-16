extends SceneTree

## CHI-002 - Regression tests for the AI decision request lifecycle.
##
## These tests encode the ACCEPTANCE CONTRACT for CHI-003:
##   IDLE -> WAITING -> READY -> CONSUMED  (or -> FAILED)
## A completed callback must reach blackboard "ai_action" exactly once, regardless of
## which provider produced the response or when the callback fires.
##
## They were RED before CHI-003: `request_ai_decision.gd` used a single `_pending` boolean for
## both "not requested yet" and "response completed", so the tick that followed a completed
## callback re-entered the request branch, wiped `_result`, issued a duplicate request and
## returned RUNNING. The SUCCESS block that publishes `ai_action` was unreachable, which made
## NPC AI inert. They are now the regression guard for that contract.

var failures := 0
var checks := 0
var ac: Node = null
var _orig_provider: Node = null
var _orig_use_ai: bool = true
var _orig_server_online: bool = false
var _orig_ai_mode: int = 0
var _LeafScript: GDScript = null

# Beehave Status enum (addons/beehave/nodes/beehave_node.gd): SUCCESS=0, FAILURE=1, RUNNING=2
const ST_SUCCESS := 0
const ST_FAILURE := 1
const ST_RUNNING := 2

var _event_count_before := 0


class FakeNpc:
	extends Node
	var npc_id: String = "t_npc"
	var display_name: String = "Tester"
	var current_room: String = "hallway"
	var executed: Array = []
	var _acting := false

	func build_ai_context() -> Dictionary:
		return {
			"name": display_name,
			"personality": "methodical",
			"secrets": [],
			"schedule_goal": "",
			"current_room": current_room,
			"nearby_npcs": [],
			"recent_events": [],
		}

	func execute_action(action: Dictionary) -> void:
		executed.append(action)
		_acting = true

	func is_action_running() -> bool:
		return _acting


class FakeProvider:
	extends Node
	var decide_calls := 0
	var callbacks: Array = []
	var ready_flag := true
	var accept: bool = true

	func is_ready() -> bool:
		return ready_flag

	func decide(_npc_id: String, _persona: String, _prompt: String, cb: Callable) -> bool:
		decide_calls += 1
		if accept:
			callbacks.append(cb)
			return true
		return false


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	_run()


func _run() -> void:
	await create_timer(0.1).timeout

	ac = root.get_node_or_null("AIClient")
	_LeafScript = load("res://scripts/behavior/request_ai_decision.gd")

	if ac == null:
		print("FAIL: AIClient autoload missing - cannot run CHI-002")
		quit(1)
		return
	if _LeafScript == null:
		print("FAIL: request_ai_decision.gd failed to load")
		quit(1)
		return

	_orig_provider = ac.get("_local_provider")
	_orig_use_ai = ac.use_ai
	_orig_server_online = ac.server_online
	_orig_ai_mode = ac.ai_mode

	print("--- CHI-002 decision lifecycle regression ---")

	await _test_rule_based_sync()
	await _test_local_async_instant()
	await _test_local_async_deferred()
	await _test_server_async()
	await _test_exactly_once_no_duplicate_request()
	await _test_invalid_response_goes_failed()
	await _test_late_duplicate_callback_is_ignored()
	await _test_real_npc_branch_executes()

	_restore_state()

	print("--- CHI-002: %d checks, %d failures ---" % [checks, failures])
	quit(failures)


# ---------------------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------------------

func _make_leaf() -> Dictionary:
	var npc := FakeNpc.new()
	var leaf = _LeafScript.new()
	leaf.actor = npc
	leaf.blackboard = Blackboard.new()
	return {"leaf": leaf, "npc": npc}


func _use_rule_based_sync() -> void:
	ac.use_ai = false          # request_decision short-circuits to a synchronous callback
	ac.server_online = false
	ac.set("_local_provider", null)


func _use_local_stub() -> FakeProvider:
	var stub := FakeProvider.new()
	ac.use_ai = true
	ac.server_online = false
	ac.set("_local_provider", stub)
	return stub


func _use_server() -> void:
	ac.use_ai = true
	ac.server_online = true    # AUTO + server_online -> SERVER


func _restore_state() -> void:
	ac.use_ai = _orig_use_ai
	ac.server_online = _orig_server_online
	ac.ai_mode = _orig_ai_mode
	if _orig_provider != null:
		ac.set("_local_provider", _orig_provider)


func _wait_for_callback(leaf, timeout: float) -> bool:
	# Wait while the leaf is still WAITING (request in flight, no response delivered yet).
	var waiting: int = int(_LeafScript.State.WAITING)
	var waited := 0.0
	while int(leaf.get("_state")) == waiting and waited < timeout:
		await create_timer(0.1).timeout
		waited += 0.1
	return int(leaf.get("_state")) != waiting


# ---------------------------------------------------------------------------------------
# 1. RULE_BASED (synchronous callback)
# ---------------------------------------------------------------------------------------

func _test_rule_based_sync() -> void:
	print("[1] RULE_BASED / synchronous callback")
	_use_rule_based_sync()
	var m := _make_leaf()
	var leaf = m["leaf"]

	var s1: int = leaf.tick(0.0)
	_check(s1 == ST_RUNNING, "rule_based: first tick returns RUNNING (request in flight)")

	# callback already fired synchronously inside tick 1
	var s2: int = leaf.tick(0.0)
	_check(leaf.blackboard.get_value("ai_action", null) != null,
		"rule_based: completed callback reaches blackboard.ai_action")
	_check(s2 == ST_SUCCESS,
		"rule_based: second tick returns SUCCESS once a response is available (got %d)" % s2)

	var action: Dictionary = leaf.blackboard.get_value("ai_action", {})
	_check(not action.is_empty() and action.has("action"),
		"rule_based: published action is a non-empty action dict (got %s)" % str(action))

	m["npc"].queue_free()


# ---------------------------------------------------------------------------------------
# 2. LOCAL (callback fires inside the same call - instant)
# ---------------------------------------------------------------------------------------

func _test_local_async_instant() -> void:
	print("[2] LOCAL / callback fires immediately")
	var stub := _use_local_stub()
	var m := _make_leaf()
	var leaf = m["leaf"]

	var s1: int = leaf.tick(0.0)
	_check(s1 == ST_RUNNING, "local-instant: first tick returns RUNNING")
	_check(stub.decide_calls == 1, "local-instant: exactly one provider request issued (got %d)" % stub.decide_calls)

	if stub.callbacks.size() > 0:
		stub.callbacks[0].call('{"action":"interact","interact_object":"locker"}')

	var s2: int = leaf.tick(0.0)
	_check(leaf.blackboard.get_value("ai_action", null) != null,
		"local-instant: immediate callback reaches blackboard.ai_action")
	_check(s2 == ST_SUCCESS, "local-instant: second tick returns SUCCESS (got %d)" % s2)

	m["npc"].queue_free()
	stub.queue_free()


# ---------------------------------------------------------------------------------------
# 3. LOCAL (callback arrives several frames later)
# ---------------------------------------------------------------------------------------

func _test_local_async_deferred() -> void:
	print("[3] LOCAL / callback arrives several frames later")
	var stub := _use_local_stub()
	var m := _make_leaf()
	var leaf = m["leaf"]

	leaf.tick(0.0)
	_check(stub.decide_calls == 1, "local-deferred: exactly one request issued (got %d)" % stub.decide_calls)

	for i in range(5):
		await create_timer(0.05).timeout
		leaf.tick(0.0)          # in-flight ticks must be harmless no-ops

	_check(stub.decide_calls == 1,
		"local-deferred: in-flight ticks do not duplicate the request (got %d)" % stub.decide_calls)
	_check(leaf.blackboard.get_value("ai_action", null) == null,
		"local-deferred: nothing published before the callback arrives")

	if stub.callbacks.size() > 0:
		stub.callbacks[0].call('{"action":"interact","interact_object":"window"}')

	var s: int = leaf.tick(0.0)
	_check(s == ST_SUCCESS, "local-deferred: tick after late callback returns SUCCESS (got %d)" % s)
	_check(leaf.blackboard.get_value("ai_action", null) != null,
		"local-deferred: late callback reaches blackboard.ai_action")

	m["npc"].queue_free()
	stub.queue_free()


# ---------------------------------------------------------------------------------------
# 4. SERVER (asynchronous, real queue + HTTP path)
#
# Defect #2 surfaced here: AIClient never sets HTTPRequest.timeout and discards the return
# code of request(). When the server is unreachable the request stays pending forever,
# `_active` is never decremented and no callback is ever delivered - the decision pipeline
# wedges permanently. A bounded callback is therefore part of the acceptance contract.
# ---------------------------------------------------------------------------------------

func _test_server_async() -> void:
	print("[4] SERVER / asynchronous callback via AIClient queue (bounded time)")
	_use_server()
	var m := _make_leaf()
	var leaf = m["leaf"]

	var s1: int = leaf.tick(0.0)
	_check(s1 == ST_RUNNING, "server: first tick returns RUNNING")

	var landed := await _wait_for_callback(leaf, 5.0)
	_check(landed,
		"server: callback must arrive within 5s even when the backend is unreachable (AIClient sets no HTTPRequest.timeout)")

	if landed:
		var s2: int = leaf.tick(0.0)
		_check(s2 == ST_SUCCESS, "server: tick after callback returns SUCCESS (got %d)" % s2)
		_check(leaf.blackboard.get_value("ai_action", null) != null,
			"server: callback reaches blackboard.ai_action")

	m["npc"].queue_free()
	ac.set("_local_provider", _orig_provider)


# ---------------------------------------------------------------------------------------
# 5. exactly-once: no duplicate request, one applied action
# ---------------------------------------------------------------------------------------

func _test_exactly_once_no_duplicate_request() -> void:
	print("[5] exactly-once consumption")
	var stub := _use_local_stub()
	var m := _make_leaf()
	var leaf = m["leaf"]

	leaf.tick(0.0)
	_check(stub.decide_calls == 1, "once: one request after first tick (got %d)" % stub.decide_calls)

	# ticks that occur before any response must not spawn extra requests
	for i in range(4):
		await create_timer(0.05).timeout
		leaf.tick(0.0)
	_check(stub.decide_calls == 1,
		"once: no duplicate request while waiting (got %d)" % stub.decide_calls)

	# response arrives
	stub.callbacks[0].call('{"action":"idle"}')
	leaf.tick(0.0)
	_check(stub.decide_calls == 1,
		"once: consumption does not fire a second request (got %d)" % stub.decide_calls)

	var applied: Array = m["npc"].executed
	_check(applied.size() <= 1, "once: at most one action applied (got %d)" % applied.size())

	# subsequent ticks must not re-request or re-apply
	for i in range(3):
		await create_timer(0.05).timeout
		leaf.tick(0.0)
	_check(stub.decide_calls == 1,
		"once: still one request after the decision was consumed (got %d)" % stub.decide_calls)
	_check(m["npc"].executed.size() <= 1,
		"once: no duplicate execution after consumption (got %d)" % m["npc"].executed.size())

	m["npc"].queue_free()
	stub.queue_free()


# ---------------------------------------------------------------------------------------
# 6. failure path: empty/invalid response must resolve, not hang or re-request
# ---------------------------------------------------------------------------------------

func _test_invalid_response_goes_failed() -> void:
	print("[6] invalid / empty response")
	var stub := _use_local_stub()
	var m := _make_leaf()
	var leaf = m["leaf"]

	leaf.tick(0.0)
	if stub.callbacks.size() > 0:
		stub.callbacks[0].call("not json at all")   # _extract_json -> {} -> rule_based fallback

	await create_timer(0.1).timeout
	var s: int = leaf.tick(0.0)
	_check(s == ST_SUCCESS or s == ST_FAILURE,
		"invalid: leaf resolves to SUCCESS or FAILURE instead of hanging RUNNING (got %d)" % s)
	_check(stub.decide_calls <= 2,
		"invalid: no runaway re-request storm (provider calls: %d)" % stub.decide_calls)

	m["npc"].queue_free()
	stub.queue_free()


# ---------------------------------------------------------------------------------------
# 7. late / duplicate callback must not overwrite a settled decision
# ---------------------------------------------------------------------------------------

func _test_late_duplicate_callback_is_ignored() -> void:
	print("[7] late duplicate callback is ignored")
	var stub := _use_local_stub()
	var m := _make_leaf()
	var leaf = m["leaf"]

	leaf.tick(0.0)
	if stub.callbacks.is_empty():
		_check(false, "late: provider callback was captured")
		m["npc"].queue_free()
		stub.queue_free()
		return

	stub.callbacks[0].call('{"action":"interact","interact_object":"locker"}')
	leaf.tick(0.0)
	var first = leaf.blackboard.get_value("ai_action", null)
	_check(first != null, "late: first callback applied")

	# a stale duplicate delivery must not mutate the settled decision
	stub.callbacks[0].call('{"action":"move","target_room":"bathroom"}')
	leaf.tick(0.0)
	var second = leaf.blackboard.get_value("ai_action", null)
	_check(str(second) == str(first),
		"late: stale duplicate callback does not overwrite ai_action (was %s, now %s)" % [str(first), str(second)])

	m["npc"].queue_free()
	stub.queue_free()


# ---------------------------------------------------------------------------------------
# 8. real NPC scene: AwaitingAI -> RequestAIDecision -> ExecuteAction -> world state
# ---------------------------------------------------------------------------------------

func _test_real_npc_branch_executes() -> void:
	print("[8] real npc.tscn branch integration")
	_use_rule_based_sync()

	var scene: PackedScene = load("res://scenes/npcs/npc.tscn")
	if scene == null:
		_check(false, "integration: npc.tscn loaded")
		return
	var npc := scene.instantiate()
	root.add_child(npc)
	# Stop wall-clock ticking BEFORE the next frame, otherwise the 5s gate cooldown is
	# consumed behind our back and leaves the branch mid-cycle.
	npc.get_node("BehaviorTree").set_process(false)
	await create_timer(0.05).timeout

	var bt := npc.get_node_or_null("BehaviorTree")
	if bt == null:
		_check(false, "integration: BehaviorTree node present")
		npc.queue_free()
		return

	var root_selector := bt.get_node("RootSelector")
	var aibranch := bt.get_node("RootSelector/AIBranch")
	var gate := aibranch.get_node("AwaitingAI")
	var request_leaf := aibranch.get_node("RequestAIDecision")
	var bb: Blackboard = bt.get_blackboard()
	bb.set_value("schedule_target_room", "")   # let the selector fall through to AIBranch

	# reset the branch to a clean pre-decision state
	gate.set("_cooldown", 0.0)
	request_leaf.set("_state", _LeafScript.State.IDLE)
	request_leaf.set("_result", {})

	var ev_before: int = root.get_node("EventLog").entries.size()

	# cycle 1: gate opens, request issued (callback fires synchronously under rule_based)
	var r1: int = root_selector.tick(0.0)
	_check(r1 == ST_RUNNING, "integration: first cycle returns RUNNING (got %d)" % r1)

	# the gate cooldown is 5s; zero it to simulate the next permitted decision window
	gate.set("_cooldown", 0.0)

	# cycle 2: the response is ready - this is where the current code re-requests instead
	# of publishing, so ExecuteAction never runs.
	var r2: int = root_selector.tick(0.0)

	_check(bb.get_value("ai_action", null) != null,
		"integration: ai_action published to the NPC blackboard")
	var ev_after: int = root.get_node("EventLog").entries.size()
	var acted: bool = npc.is_action_running() or ev_after != ev_before
	_check(acted,
		"integration: ExecuteAction ran and produced an observable world-state change (status=%d)" % r2)

	if ev_after != ev_before:
		print("        (EventLog entries %d -> %d)" % [ev_before, ev_after])

	npc.queue_free()

