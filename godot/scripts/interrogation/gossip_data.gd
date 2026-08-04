extends RefCounted
class_name GossipData

## Authored two-person conversations. Overheard when the detective is near both speakers; a
## revealing line surfaces a clue (another evidence source). speaker values are npc_ids.

const CONVERSATIONS := [
	{"id": "morgan_casey_panic", "npc_a": "morgan", "npc_b": "casey", "reveal_clue": "clue_moved_object",
		"lines": [
			{"speaker": "morgan", "text": "I shouldn't have touched anything that morning."},
			{"speaker": "casey", "text": "You panicked. Anyone would have."},
			{"speaker": "morgan", "text": "If the detective finds out I moved that bottle..."},
		]},
	{"id": "jordan_riley_worry", "npc_a": "jordan", "npc_b": "riley", "reveal_clue": "clue_witness_jordan",
		"lines": [
			{"speaker": "jordan", "text": "I keep seeing him stumble in that hallway."},
			{"speaker": "riley", "text": "You were there? Jordan, you have to say something."},
			{"speaker": "jordan", "text": "And admit I walked past him? They'll think I did it."},
		]},
	{"id": "sam_alex_favor", "npc_a": "sam", "npc_b": "alex", "reveal_clue": "clue_camera",
		"lines": [
			{"speaker": "sam", "text": "I only killed the camera feed for the app."},
			{"speaker": "alex", "text": "Do not tell the detective that. It looks like a cover-up."},
			{"speaker": "sam", "text": "It wasn't. It just... is."},
		]},
]


static func conversations() -> Array:
	return CONVERSATIONS
