extends RefCounted
class_name SuspicionData

## Scheduled "suspicious moments." Catch one (be near the NPC at/after the hour) and it reveals a
## clue you can then press them on in interrogation — another evidence source via the living sim.

const MOMENTS := [
	{"id": "sam_night", "npc_id": "sam", "hour": 2.0, "reveal_clue": "clue_camera",
		"description": "Sam slips out of the victim's room, pocketing something"},
	{"id": "morgan_dawn", "npc_id": "morgan", "hour": 6.0, "reveal_clue": "clue_moved_object",
		"description": "Morgan wipes down a surface and pockets a small bottle"},
	{"id": "casey_late", "npc_id": "casey", "hour": 23.0, "reveal_clue": "clue_portraits",
		"description": "Casey sketches the dorm from a darkened corner, watching everyone"},
	{"id": "jordan_ghost", "npc_id": "jordan", "hour": 1.0, "reveal_clue": "clue_ghost_sighting",
		"description": "Jordan slips a white sheet over their shoulders near the courtyard, practicing a moan under their breath"},
]


static func moments() -> Array:
	return MOMENTS
