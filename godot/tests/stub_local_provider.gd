extends Node

## Test stub standing in for NobodyWhoProvider: lets AIClient-focused tests drive
## LOCAL/RULE_BASED resolution without the real GDExtension or a model file.

signal ready_changed(ready: bool)

var ready_flag := false
var reload_count := 0
var decide_result := '{"action":"nudge","reason":"stub","source":"local"}'

func is_available() -> bool:
	return true

func is_ready() -> bool:
	return ready_flag

func reload_model() -> void:
	reload_count += 1

func decide(_npc_id: String, _persona: String, _prompt: String, cb: Callable) -> bool:
	cb.call(decide_result)
	return true
