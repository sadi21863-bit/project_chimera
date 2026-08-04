extends Node

## Fires suspicious moments when the detective is near the acting NPC at/after the moment's hour.
## Runtime wiring is added in Task 5; the pure check() is what the test exercises.

static func check(moments: Array, hour: float, detective_pos: Vector2, npc_positions: Dictionary,
		fired: Dictionary, catch_range: float) -> Array:
	var result: Array = []
	for m in moments:
		var mid: String = str(m["id"])
		if fired.has(mid):
			continue
		if hour < float(m["hour"]):
			continue
		var npc_id: String = str(m["npc_id"])
		if not npc_positions.has(npc_id):
			continue
		var npc_pos: Vector2 = npc_positions[npc_id]
		if detective_pos.distance_to(npc_pos) <= catch_range:
			result.append(mid)
	return result
