extends SceneTree

## T4: LOCAL readiness re-evaluation contract on AIClient.

var _failures := 0

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		print("FAIL: %s" % msg)

func _process(_delta: float) -> bool:
	var client: Node = root.get_node("AIClient")
	var stub: Node = load("res://tests/stub_local_provider.gd").new()
	var orig_provider: Node = client.get("_local_provider")
	var orig_mode: int = client.get("ai_mode")
	client.set("_local_provider", stub)
	client.set("ai_mode", client.AiMode.AUTO)
	client.set("server_online", false)

	var seen: Array = []
	client.local_ready_changed.connect(func(r: bool) -> void: seen.append(r))

	# (a) AUTO resolves RULE_BASED while stub not ready
	_check(client.resolve_mode() == client.AiMode.RULE_BASED,
		"not-ready stub under AUTO should resolve RULE_BASED (got %d)" % int(client.resolve_mode()))

	# (b) ready stub: refresh flips AUTO->LOCAL, emits signal, reload_model was called
	stub.ready_flag = true
	client.refresh_local_provider()
	_check(client.resolve_mode() == client.AiMode.LOCAL,
		"ready stub under AUTO should resolve LOCAL (got %d)" % int(client.resolve_mode()))
	_check(seen == [true], "local_ready_changed should fire once with true (got %s)" % str(seen))
	_check(int(stub.reload_count) == 1, "refresh should call reload_model once (got %d)" % int(stub.reload_count))
	var decision_box: Array = []
	client.set("use_ai", true)
	client.request_decision("npc_stub", {"name": "Stub", "schedule_goal": "idle", "current_room": "hall"}, func(j: Variant) -> void: decision_box.append(j))
	var decision: Variant = decision_box[0] if decision_box.size() > 0 else null
	_check(decision is Dictionary,
		"request_decision must deliver a Dictionary (got %s)" % str(decision))
	_check(decision is Dictionary and str(decision.get("source", "")) == "local",
		"LOCAL decision should carry source=local (got %s)" % str(decision))

	# (c) readiness lost: refresh emits false, AUTO falls back to rule-based
	stub.ready_flag = false
	client.refresh_local_provider()
	_check(client.resolve_mode() == client.AiMode.RULE_BASED,
		"lost readiness should fall back to RULE_BASED (got %d)" % int(client.resolve_mode()))
	_check(seen == [true, false], "local_ready_changed should fire false after loss (got %s)" % str(seen))

	# (d) real provider reload_model is safe without any model present
	var real: Node = load("res://scripts/ai/nobodywho_provider.gd").new()
	var real_ready_seen: Array = []
	real.ready_changed.connect(func(r: bool) -> void: real_ready_seen.append(r))
	real.reload_model()
	_check(real.is_ready() == false, "real provider without model must not report ready")
	_check(real_ready_seen == [false] or real_ready_seen.is_empty(),
		"real provider reload should emit false (or stay silent without DLL) (got %s)" % str(real_ready_seen))
	real.free()

	client.set("_local_provider", orig_provider)
	client.set("ai_mode", orig_mode)
	stub.free()

	if _failures == 0:
		print("PASS: test_provider_ready_reeval")
	quit(_failures)
	return true
