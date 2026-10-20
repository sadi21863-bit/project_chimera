extends Node

## LOCAL inference provider: wraps the NobodyWho GDExtension (embedded llama.cpp + GGUF).
##
## Guarded by ClassDB so this script parses and the project runs even when the NobodyWho addon is
## NOT installed; is_available() returns false and AIClient routes around it.
##
## Design notes for low-VRAM hardware (e.g. 1.7 GB GPUs):
##  - ONE shared NobodyWhoChat (one compute buffer) instead of one chat per NPC, so 6 NPCs don't
##    multiply VRAM. Requests serialize through a busy flag; callers fall back when busy.
##  - Small context_length keeps the compute buffer tiny.
##  - JSON-schema sampler forces valid action JSON, so even small models emit parseable output.
##  - Persona is folded into the prompt (not per-call system_prompt) and reset_context() runs between
##    decisions, so each decision is independent and no NPC's persona leaks into another.

const DEFAULT_MODEL_PATH := "res://models/model.gguf"
const MODEL_PATH_SETTING := "echo/nobodywho_model_path"
const CONTEXT_LENGTH := 512
const ModelCatalog := preload("res://scripts/ai/model_catalog.gd")

const SYSTEM_PROMPT := "You are an NPC decision engine in a dorm simulation. Read the character and situation, then output exactly one JSON action object and nothing else."

const ACTION_SCHEMA := '{"type":"object","properties":{"action":{"type":"string","enum":["move","speak","idle","interact"]},"target_room":{"type":"string"},"target_npc":{"type":"string"},"text":{"type":"string"},"reason":{"type":"string"}},"required":["action","reason"]}'

var _model: Object = null
var _chat: Object = null
var _busy: bool = false
var _pending: Callable = Callable()
var _model_path: String = ""
# Test seam: when set, the downloaded-models branch of _resolve_model_path() consults this
# directory instead of the real user://models, so tests stay deterministic on machines that
# already hold a downloaded model.
var catalog_dir_override: String = ""

signal ready_changed(ready: bool)


func _ready() -> void:
	if not is_available():
		return
	_model_path = _resolve_model_path()
	if not _path_usable(_model_path):
		push_warning("NobodyWho: model file not found at %s — LOCAL mode inert until provided." % _model_path)
		ready_changed.emit(false)
		return
	_build_model_and_chat()
	ready_changed.emit(true)


func reload_model() -> void:
	if not is_available():
		return
	if _busy and _chat != null and is_instance_valid(_chat):
		_chat.call("stop_generation")
	_teardown()
	_model_path = _resolve_model_path()
	if not _path_usable(_model_path):
		_model_path = ""
		ready_changed.emit(false)
		return
	_build_model_and_chat()
	ready_changed.emit(is_ready())


func _build_model_and_chat() -> void:
	_model = ClassDB.instantiate("NobodyWhoModel")
	_model.set("model_path", _model_path)
	# Force CPU-only. GPU offload drives low-VRAM/mobile GPUs (the norm for this project's target
	# hardware) via Vulkan, which is what caused the freezes that led to LOCAL mode being disabled —
	# verified empirically: the same model loads and completes inference cleanly with GPU offload off.
	_model.set("use_gpu_if_available", false)
	add_child(_model)

	_chat = ClassDB.instantiate("NobodyWhoChat")
	_chat.set("model_node", _model)
	_chat.set("context_length", CONTEXT_LENGTH)
	_chat.set("system_prompt", SYSTEM_PROMPT)
	add_child(_chat)
	_chat.connect("response_finished", _on_response_finished)
	if _chat.has_signal("worker_failed"):
		_chat.connect("worker_failed", _on_worker_failed)
	# Unconstrained generation with the engine's default sampler — verified to yield clean,
	# parseable local decisions (source=local) with Llama-3.2-1B. The JSON-grammar samplers proved
	# unreliable with sub-2B models in this NobodyWho build (Qwen runs away → context-shift crash;
	# Llama stalls after "{"), and the DRY preset broke JSON formation. Robustness instead comes
	# from a concise example-driven prompt (AIClient._build_local_prompt) + tolerant parsing
	# (AIClient._extract_json), with a graceful rule-based fallback when parsing fails.
	# (Minor 1B artifact: occasional word doubling like "HeyHey" — cosmetic, action stays valid.)
	_chat.call("start_worker")


func _teardown() -> void:
	for node in [_chat, _model]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_chat = null
	_model = null
	_busy = false
	_pending = Callable()


func _path_usable(path: String) -> bool:
	if path.begins_with("hf://") or path.begins_with("https://"):
		return true
	return FileAccess.file_exists(path)


## Stop any in-flight generation before the engine tears down nodes — quitting mid-generation
## otherwise crashes (observed as a segfault on shutdown while a request was still running).
func _exit_tree() -> void:
	if _chat != null and _busy:
		_chat.call("stop_generation")


## True when the addon is installed and a model has been wired up.
func is_available() -> bool:
	return ClassDB.class_exists("NobodyWhoModel") and ClassDB.class_exists("NobodyWhoChat")


func is_ready() -> bool:
	return is_available() and _chat != null


## Send a decision prompt. Returns false if LOCAL can't serve it now (caller falls back).
## On completion, callback.call(text_response) with the raw (JSON) model text.
func decide(_npc_id: String, persona: String, prompt: String, callback: Callable) -> bool:
	if not is_ready() or _busy:
		return false
	_busy = true
	_pending = callback
	_chat.call("reset_context")
	_chat.call("ask", "%s\n\n%s" % [persona, prompt])
	return true


func _on_response_finished(text: String) -> void:
	_busy = false
	var cb := _pending
	_pending = Callable()
	if cb.is_valid():
		cb.call(text)


func _on_worker_failed(error: String) -> void:
	push_warning("NobodyWho worker failed: %s" % error)
	_busy = false
	var cb := _pending
	_pending = Callable()
	if cb.is_valid():
		cb.call("")  # empty -> AIClient parses to rule-based fallback


func _resolve_model_path() -> String:
	for key in ModelCatalog.REQUIREMENTS:
		var user_path := ModelCatalog.model_file_path(str(key))
		if FileAccess.file_exists(user_path):
			return ProjectSettings.globalize_path(user_path)
	if ProjectSettings.has_setting(MODEL_PATH_SETTING):
		var configured := str(ProjectSettings.get_setting(MODEL_PATH_SETTING))
		if not configured.is_empty():
			return configured
	if FileAccess.file_exists(DEFAULT_MODEL_PATH):
		return DEFAULT_MODEL_PATH
	# Auto-discover the first .gguf in res://models/ so any dropped-in model just works.
	var dir := DirAccess.open("res://models")
	if dir != null:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.to_lower().ends_with(".gguf"):
				return "res://models/" + fname
			fname = dir.get_next()
	return DEFAULT_MODEL_PATH
