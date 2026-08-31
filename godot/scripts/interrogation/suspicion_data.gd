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
	{"id": "alex_patrol", "npc_id": "alex", "hour": 22.0, "reveal_clue": "clue_keys",
		"description": "Alex checks door locks with a master key, lingering at the victim's door"},
	{"id": "riley_common", "npc_id": "riley", "hour": 20.0, "reveal_clue": "clue_pills",
		"description": "Riley sets a small bottle on the common room table, then hesitates and pockets it again"},
	{"id": "casey_courtyard", "npc_id": "casey", "hour": 3.0, "reveal_clue": "clue_sketch",
		"description": "Casey sits alone in the courtyard, drawing by moonlight, glancing up at the dorm windows"},
	{"id": "sam_server", "npc_id": "sam", "hour": 4.0, "reveal_clue": "clue_wiring",
		"description": "Sam crouches near the server room, splicing cables with shaking hands"},
	{"id": "alex_logbook", "npc_id": "alex", "hour": 21.0, "reveal_clue": "clue_logbook",
		"description": "Alex flips through the RA logbook, tearing out a page and crumpling it in their pocket"},
	{"id": "riley_pharma", "npc_id": "riley", "hour": 23.5, "reveal_clue": "clue_medbook",
		"description": "Riley reads a pharmacology textbook under the hallway light, marking a page on drug interactions"},
	{"id": "jordan_script", "npc_id": "jordan", "hour": 0.5, "reveal_clue": "clue_rehearsal",
		"description": "Jordan practices lines in the empty hallway, pausing to stare at Daniel's closed door"},
]


static func moments() -> Array:
	return MOMENTS
