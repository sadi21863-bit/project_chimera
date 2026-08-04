extends SceneTree

## Exercises the REAL AIClient router + NobodyWho provider (single model instance, no double-load).
## Run: Godot --headless --path godot -s res://tools/verify_nobodywho.gd

var _done := false
var _frames := 0
var _requested := false


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 10 and not _requested:
		_requested = true
		_request()
	if _frames > 1200000:
		print("TIMEOUT")
		return true
	return _done


func _request() -> void:
	var ai := root.get_node_or_null("AIClient")
	if ai == null:
		print("AIClient autoload missing")
		_done = true
		quit(4)
		return
	if not ai._local_provider.is_ready():
		print("LOCAL_NOT_READY (addon or model missing)")
		_done = true
		quit(3)
		return
	print("resolved_mode=", ai.get_mode_label())
	var ctx := {
		"npc_id": "alex", "name": "Alex", "personality": "tidy organized RA",
		"current_room": "bedroom_1", "schedule_goal": "breakfast in kitchen",
		"nearby_npcs": [], "recent_events": [], "game_hour": 8.0, "game_day": 1, "secrets": [],
	}
	ai.request_decision("alex", ctx, func(resp):
		print("DECISION source=", resp.get("source"), " action=", JSON.stringify(resp.get("action")))
		_done = true
		quit(0)
	)
