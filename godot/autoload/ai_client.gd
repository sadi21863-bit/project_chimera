extends Node

## Provider router for NPC AI. Routes decisions/memory through the best available backend:
##   SERVER     — HTTP -> FastAPI -> Ollama + ChromaDB (richest; needs ai-server/ running)
##   LOCAL      — NobodyWho in-engine GGUF + LocalMemory (fully offline single binary)
##   RULE_BASED — deterministic fallback (always available)
## AUTO picks SERVER -> LOCAL -> RULE_BASED by availability. See docs/echo-hybrid-architecture.md.
##
## Public API (request_decision/record_memory/recall_memory/inject_event/fetch_relationships) and
## signals are unchanged, so behavior-tree leaves and the observer panel need no edits.

signal server_status_changed(online: bool)
signal local_ready_changed(ready: bool)
signal decision_received(npc_id: String, action: Dictionary)
signal mode_changed(mode: int)

enum AiMode { AUTO, SERVER, LOCAL, RULE_BASED }

const BASE_URL := "http://localhost:8000"
const MAX_CONCURRENT := 2
const MAX_RETRIES := 3
## Hard bound on a single /npc/decide HTTP call. Without it a connection that is accepted but
## never answered keeps the request pending forever: `_active` is never decremented, the queue
## freezes and the NPC decision callback is never delivered (CHI-003 defect #2).
const DECIDE_TIMEOUT_SECONDS := 3.0
## Health probe: hard bound so a hung backend cannot leave server_online unresolved, plus the
## re-probe interval (previously the probe ran once and never again).
const HEALTH_TIMEOUT_SECONDS := 3.0
const HEALTH_INTERVAL_SECONDS := 15.0

const NobodyWhoProvider := preload("res://scripts/ai/nobodywho_provider.gd")

var ai_mode: AiMode = AiMode.AUTO
var server_online: bool = false
var use_ai: bool = true

var _local_provider: Node = null
var _queue: Array[Dictionary] = []
var _active: int = 0
var _requests: Array[HTTPRequest] = []
var _retry_counts: Dictionary = {}
var _health_busy := false


func _ready() -> void:
	_local_provider = NobodyWhoProvider.new()
	_local_provider.name = "NobodyWhoProvider"
	add_child(_local_provider)
	EventBus.subscribe("relationship_changed", _on_relationship_changed)
	_check_health()
	# The server can come up or go down after launch, and the old code probed exactly once in
	# _ready(): a server started later was never discovered, and one that died left
	# server_online latched true forever. Re-probe periodically; _on_health_completed only
	# emits/logs when the answer actually changes.
	var health_timer := Timer.new()
	health_timer.wait_time = HEALTH_INTERVAL_SECONDS
	health_timer.autostart = true
	health_timer.timeout.connect(_check_health)
	add_child(health_timer)


## Effective mode for this moment (resolves AUTO).
func resolve_mode() -> AiMode:
	if ai_mode != AiMode.AUTO:
		return ai_mode
	if server_online:
		return AiMode.SERVER
	if _local_provider != null and _local_provider.is_ready():
		return AiMode.LOCAL
	return AiMode.RULE_BASED


## True when the LOCAL runtime (NobodyWho GDExtension) is present — independent of whether
## a model file has been downloaded/is loaded.
func local_available() -> bool:
	return _local_provider != null and _local_provider.is_available()


## Re-evaluate LOCAL readiness (after a model download finished or a model was removed) and
## broadcast the new state; the next request_decision resolves LOCAL/RULE_BASED accordingly.
func refresh_local_provider() -> void:
	if _local_provider == null:
		return
	_local_provider.reload_model()
	var ready: bool = _local_provider.is_ready()
	local_ready_changed.emit(ready)
	EventLog.log_action("LOCAL AI model %s" % ("ready" if ready else "missing"), "system")


func set_mode(mode: AiMode) -> void:
	ai_mode = mode
	mode_changed.emit(mode)


func get_mode_label() -> String:
	match resolve_mode():
		AiMode.SERVER: return "SERVER"
		AiMode.LOCAL: return "LOCAL"
		_: return "RULE_BASED"


## Compact tokens for width-constrained UI bars. The observer top bar is an HBoxContainer at
## 1280x720: the full "RULE_BASED" token inflates the status line by ~35% and crowds the
## slider/play controls, so compact views get the abbreviated form.
func get_mode_short_label() -> String:
	match resolve_mode():
		AiMode.SERVER: return "SERVER"
		AiMode.LOCAL: return "LOCAL"
		_: return "RULE"


# --- Health (SERVER availability) ---

func _check_health() -> void:
	if _health_busy:
		return  # never stack probes: one in flight is enough to know the current state
	_health_busy = true
	var req := HTTPRequest.new()
	req.timeout = HEALTH_TIMEOUT_SECONDS
	add_child(req)
	req.request_completed.connect(_on_health_completed.bind(req))
	var err := req.request(BASE_URL + "/health")
	if err != OK:
		# request() failed synchronously, so request_completed will never fire; resolve the
		# probe here or _health_busy would stay set and block every later re-probe.
		_on_health_completed(HTTPRequest.RESULT_CONNECTION_ERROR, 0, PackedStringArray(),
			PackedByteArray(), req)


func _on_health_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, req: HTTPRequest) -> void:
	_health_busy = false
	var was_online := server_online
	server_online = result == HTTPRequest.RESULT_SUCCESS and response_code == 200
	if was_online != server_online:
		server_status_changed.emit(server_online)
		EventLog.log_action(
			"AI server %s" % ("online" if server_online else "offline — using %s" % get_mode_label()),
			"system"
		)
	req.queue_free()


# --- Decisions ---

func request_decision(npc_id: String, context: Dictionary, callback: Callable) -> void:
	if not use_ai:
		callback.call({"action": _fallback_action(context), "source": "rule_based"})
		return
	match resolve_mode():
		AiMode.SERVER:
			_queue.append({"npc_id": npc_id, "context": context, "callback": callback})
			_process_queue()
		AiMode.LOCAL:
			_local_decide(npc_id, context, callback)
		_:
			callback.call({"action": _fallback_action(context), "source": "rule_based"})


func request_decision_batch(contexts: Array[Dictionary], callback: Callable) -> void:
	if resolve_mode() == AiMode.SERVER and not contexts.is_empty():
		var req := HTTPRequest.new()
		add_child(req)
		req.request_completed.connect(func(result, code, _h, body):
			req.queue_free()
			if result == HTTPRequest.RESULT_SUCCESS and code == 200:
				var parsed = JSON.parse_string(body.get_string_from_utf8())
				if parsed is Dictionary and parsed.has("decisions"):
					callback.call(parsed["decisions"])
					return
			var fallback: Array = []
			for ctx in contexts:
				fallback.append({"action": _fallback_action(ctx), "source": "rule_based"})
			callback.call(fallback)
		)
		var payload := JSON.stringify({"contexts": contexts})
		req.request(BASE_URL + "/npc/decide/batch", _headers(), HTTPClient.METHOD_POST, payload)
		return
	# LOCAL/RULE_BASED: decisions flow through the per-NPC behavior tree (request_decision);
	# batch returns rule-based results synchronously.
	var results: Array = []
	for ctx in contexts:
		results.append({"action": _fallback_action(ctx), "source": "rule_based"})
	callback.call(results)


func _local_decide(npc_id: String, context: Dictionary, callback: Callable) -> void:
	var query := "%s %s" % [str(context.get("schedule_goal", "")), str(context.get("current_room", ""))]
	var memories: Array = LocalMemory.recall(npc_id, query, 5)
	var built := _build_local_prompt(context, memories)
	var ok: bool = _local_provider.decide(npc_id, built["persona"], built["prompt"], func(text):
		var action := _extract_json(text)
		if action.is_empty() or not action.has("action"):
			callback.call({"action": _fallback_action(context), "source": "rule_based"})
			return
		decision_received.emit(npc_id, action)
		callback.call({"action": action, "source": "local"})
	)
	if not ok:
		callback.call({"action": _fallback_action(context), "source": "rule_based"})


func _build_local_prompt(context: Dictionary, memories: Array) -> Dictionary:
	var secrets: Array = context.get("secrets", [])
	var persona := "You are %s. Personality: %s\nSecrets (never reveal directly): %s" % [
		str(context.get("name", "an NPC")),
		str(context.get("personality", "")),
		", ".join(secrets) if not secrets.is_empty() else "none",
	]
	var nearby_names: Array = []
	for n in context.get("nearby_npcs", []):
		nearby_names.append(str(n.get("name", "")))
	var recent: Array = context.get("recent_events", [])
	var memory_block := "- No relevant memories."
	if not memories.is_empty():
		memory_block = "- " + "\n- ".join(memories)
	# Concise, example-driven prompt: small (<=2B) instruct models reliably copy a filled-in
	# JSON example but mangle abstract templates like {"action":"move|speak|idle"}.
	var prompt := "Situation: in %s at hour %.0f (day %d). Goal: %s. Nearby: %s. Recent: %s. Memory: %s\n\nDecide your single next action. Reply with ONLY one JSON object, exactly these keys, like the example:\n{\"action\":\"move\",\"target_room\":\"kitchen\",\"target_npc\":\"\",\"text\":\"\",\"reason\":\"go eat breakfast\"}\n- action: one of move, speak, idle, interact\n- target_room (when moving): one of bedroom_1, bedroom_2, bedroom_3, bedroom_4, bedroom_5, bedroom_6, common_room, kitchen, bathroom, hallway\n- target_npc and text: fill only when action is speak\n- reason: a few words" % [
		str(context.get("current_room", "hallway")),
		float(context.get("game_hour", 8.0)),
		int(context.get("game_day", 1)),
		str(context.get("schedule_goal", "idle")),
		", ".join(nearby_names) if not nearby_names.is_empty() else "nobody",
		"; ".join(recent) if not recent.is_empty() else "nothing",
		memory_block.replace("\n", " "),
	]
	return {"persona": persona, "prompt": prompt}


func _process_queue() -> void:
	while _active < MAX_CONCURRENT and not _queue.is_empty():
		var item: Dictionary = _queue.pop_front()
		_send_decide_request(item)


func _send_decide_request(item: Dictionary) -> void:
	_active += 1
	var req := HTTPRequest.new()
	req.timeout = DECIDE_TIMEOUT_SECONDS
	add_child(req)
	_requests.append(req)
	var npc_id: String = item["npc_id"]
	req.request_completed.connect(func(result, code, _h, body):
		_release_request(req)
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			_retry_counts.erase(npc_id)
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and parsed.has("action"):
				decision_received.emit(npc_id, parsed["action"])
				item["callback"].call(parsed)
				return
		if _is_unreachable(result):
			# The backend is not there (or is not answering). A retry ladder only delays the
			# fallback and leaves the NPC frozen, so deliver the rule-based decision now.
			_deliver_fallback(item)
			return
		_retry_or_fallback(item)
	)
	var payload := JSON.stringify({"context": item["context"]})
	# request() reports "this never even started" synchronously. If that return code is
	# discarded, request_completed above can never fire and the decision pipeline wedges
	# with _active pinned and no fallback ever delivered (CHI-003 defect #2).
	var err := req.request(BASE_URL + "/npc/decide", _headers(), HTTPClient.METHOD_POST, payload)
	if err != OK:
		_release_request(req)
		_deliver_fallback(item)


func _is_unreachable(result: int) -> bool:
	return result in [
		HTTPRequest.RESULT_CANT_RESOLVE,
		HTTPRequest.RESULT_CANT_CONNECT,
		HTTPRequest.RESULT_CONNECTION_ERROR,
		HTTPRequest.RESULT_TIMEOUT,
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR,
	]


## Terminal delivery for one decide call. Always clears the per-NPC retry counter, otherwise
## a single exhausted chain poisons every later decision for that NPC (the first failure would
## immediately exceed MAX_RETRIES and never attempt a real request again).
func _deliver_fallback(item: Dictionary) -> void:
	_retry_counts.erase(item["npc_id"])
	item["callback"].call({"action": _fallback_action(item["context"]), "source": "rule_based"})


func _release_request(req: HTTPRequest) -> void:
	_active -= 1
	_requests.erase(req)
	if is_instance_valid(req):
		req.queue_free()
	_process_queue()


func _retry_or_fallback(item: Dictionary) -> void:
	var npc_id: String = item["npc_id"]
	var retries: int = _retry_counts.get(npc_id, 0) + 1
	_retry_counts[npc_id] = retries
	if retries >= MAX_RETRIES:
		_deliver_fallback(item)
		return
	var delay: float = pow(2, retries) * 0.5
	get_tree().create_timer(delay).timeout.connect(func():
		_queue.push_front(item)
		_process_queue()
	)


# --- Memory ---

func record_memory(npc_id: String, text: String, event_type: String = "observation") -> void:
	if resolve_mode() == AiMode.SERVER:
		var req := HTTPRequest.new()
		add_child(req)
		req.request_completed.connect(func(_r, _c, _h, _b): req.queue_free())
		var payload := JSON.stringify({"npc_id": npc_id, "text": text, "event_type": event_type})
		req.request(BASE_URL + "/memory/record", _headers(), HTTPClient.METHOD_POST, payload)
		return
	LocalMemory.record(npc_id, text, {"event_type": event_type})


func recall_memory(npc_id: String, query: String, callback: Callable) -> void:
	if resolve_mode() == AiMode.SERVER:
		var req := HTTPRequest.new()
		add_child(req)
		req.request_completed.connect(func(result, code, _h, body):
			req.queue_free()
			if result == HTTPRequest.RESULT_SUCCESS and code == 200:
				var parsed = JSON.parse_string(body.get_string_from_utf8())
				if parsed is Dictionary:
					callback.call(parsed.get("memories", []))
					return
			callback.call([])
		)
		var payload := JSON.stringify({"npc_id": npc_id, "query": query, "top_k": 5})
		req.request(BASE_URL + "/memory/recall", _headers(), HTTPClient.METHOD_POST, payload)
		return
	callback.call(LocalMemory.recall(npc_id, query, 5))


# --- Events ---

func inject_event(text: String, severity: String = "normal", target_room: String = "") -> void:
	if resolve_mode() == AiMode.SERVER:
		var req := HTTPRequest.new()
		add_child(req)
		req.request_completed.connect(func(_r, c, _h, body):
			req.queue_free()
			if c == 200:
				var parsed = JSON.parse_string(body.get_string_from_utf8())
				EventLog.log_action("Injected: %s" % parsed.get("event", text), "injection")
		)
		var payload := JSON.stringify({"text": text, "severity": severity, "target_room": target_room})
		req.request(BASE_URL + "/events/inject", _headers(), HTTPClient.METHOD_POST, payload)
		return
	# LOCAL/RULE_BASED: record the event into every NPC's local memory.
	var msg := "[%s] %s" % [severity, text]
	if target_room != "":
		msg += " (room: %s)" % target_room
	for npc_id in _all_npc_ids():
		LocalMemory.record(npc_id, msg, {"event_type": "injected"})
	EventLog.log_action("Injected: %s" % msg, "injection")


# --- Relationships ---

func fetch_relationships(callback: Callable) -> void:
	if resolve_mode() == AiMode.SERVER:
		var req := HTTPRequest.new()
		add_child(req)
		req.request_completed.connect(func(result, code, _h, body):
			req.queue_free()
			if result == HTTPRequest.RESULT_SUCCESS and code == 200:
				var parsed = JSON.parse_string(body.get_string_from_utf8())
				if parsed is Dictionary:
					callback.call(parsed.get("relationships", []))
					return
			callback.call([])
		)
		req.request(BASE_URL + "/relationships", _headers())
		return
	callback.call(LocalMemory.get_relationships())


func _on_relationship_changed(data: Variant) -> void:
	# In SERVER mode the Python Game Master owns relationship updates; only apply locally otherwise.
	if resolve_mode() == AiMode.SERVER:
		return
	if data is Dictionary and data.has("from") and data.has("to"):
		LocalMemory.update_relationship(str(data["from"]), str(data["to"]), float(data.get("delta", 0.05)))


# --- Helpers ---

func _all_npc_ids() -> Array:
	var ids: Array = []
	for npc in get_tree().get_nodes_in_group("npcs"):
		if "npc_id" in npc:
			ids.append(npc.npc_id)
	return ids


func _extract_json(text: String) -> Dictionary:
	# Slice the first {...} block (tolerates code fences and surrounding prose from small models),
	# and avoid JSON.parse_string's noisy error logging by using a JSON instance.
	var start := text.find("{")
	var end := text.rfind("}")
	if start == -1 or end == -1 or end <= start:
		return {}
	var json := JSON.new()
	if json.parse(text.substr(start, end - start + 1)) == OK and json.data is Dictionary:
		return json.data
	return {}


func _headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json"])


func _fallback_action(context: Dictionary) -> Dictionary:
	var goal: String = str(context.get("schedule_goal", "")).to_lower()
	var current: String = str(context.get("current_room", "hallway"))
	var room_targets := {
		"kitchen": "kitchen",
		"common": "common_room",
		"bathroom": "bathroom",
		"bedroom": "bedroom_1",
		"hallway": "hallway",
	}
	for key in room_targets:
		if key in goal and room_targets[key] != current:
			return {"action": "move", "target_room": room_targets[key], "reason": "schedule fallback"}
	return {"action": "idle", "reason": "schedule fallback"}
