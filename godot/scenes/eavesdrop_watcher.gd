extends Node

## Fires a conversation when both speakers are near each other and the detective is near them.

static func check(conversations: Array, npc_positions: Dictionary, detective_pos: Vector2,
		fired: Dictionary, pair_range: float, hear_range: float) -> Array:
	var result: Array = []
	for convo in conversations:
		var cid: String = str(convo["id"])
		if fired.has(cid):
			continue
		var a: String = str(convo["npc_a"])
		var b: String = str(convo["npc_b"])
		if not npc_positions.has(a) or not npc_positions.has(b):
			continue
		var pa: Vector2 = npc_positions[a]
		var pb: Vector2 = npc_positions[b]
		if pa.distance_to(pb) > pair_range:
			continue
		if detective_pos.distance_to(pa) <= hear_range:
			result.append(cid)
	return result
