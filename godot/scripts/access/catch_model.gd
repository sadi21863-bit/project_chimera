extends Node
class_name CatchModel

## Pure detection math for the two "seen" catch models (Difficulty.catch_model). Runtime wiring
## (calling these every frame, acting on the result) lives in the dorm, mirroring the
## SuspicionWatcher/EavesdropWatcher pure-check() pattern.

const METER_FILL_PER_SEC := 0.35
const METER_DRAIN_PER_SEC := 0.5


## Medium: a suspicion meter fills while in a restricted area, drains otherwise. Caller checks
## the returned value against 1.0 to know if the detective was caught.
static func update_meter(meter: float, restricted: bool, delta: float) -> float:
	if restricted:
		meter += METER_FILL_PER_SEC * delta
	else:
		meter -= METER_DRAIN_PER_SEC * delta
	return clampf(meter, 0.0, 1.0)


## Hard/Extreme: caught if restricted and inside any NPC's close proximity or facing vision cone.
## npc_states: Array of {"position": Vector2, "facing": Vector2}.
static func check_vision(restricted: bool, detective_pos: Vector2, npc_states: Array,
		cone_range: float, cone_half_angle_deg: float, proximity_range: float) -> bool:
	if not restricted:
		return false
	for s in npc_states:
		var npc_pos: Vector2 = s["position"]
		var to_detective: Vector2 = detective_pos - npc_pos
		var dist: float = to_detective.length()
		if dist <= proximity_range:
			return true
		if dist <= cone_range:
			var facing: Vector2 = s.get("facing", Vector2.DOWN)
			if facing.length() > 0.001:
				var angle: float = rad_to_deg(facing.normalized().angle_to(to_detective.normalized()))
				if absf(angle) <= cone_half_angle_deg:
					return true
	return false
