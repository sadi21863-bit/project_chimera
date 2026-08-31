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
	{"id": "alex_riley_keys", "npc_a": "alex", "npc_b": "riley", "reveal_clue": "clue_keys",
		"lines": [
			{"speaker": "alex", "text": "I used the master key for a noise complaint. That's all."},
			{"speaker": "riley", "text": "But you were near his door, Alex. That looks bad."},
			{"speaker": "alex", "text": "I know. I should have knocked instead."},
		]},
	{"id": "casey_sam_observations", "npc_a": "casey", "npc_b": "sam", "reveal_clue": "clue_portraits",
		"lines": [
			{"speaker": "casey", "text": "I saw you near the camera room that night."},
			{"speaker": "sam", "text": "I was fixing the wiring. That's it."},
			{"speaker": "casey", "text": "I know. But the detective doesn't. Be careful."},
		]},
	{"id": "riley_morgan_pharma", "npc_a": "riley", "npc_b": "morgan", "reveal_clue": "clue_medbook",
		"lines": [
			{"speaker": "riley", "text": "My pharmacology notes are just for the exam."},
			{"speaker": "morgan", "text": "Then why did you hide them when the detective came around?"},
			{"speaker": "riley", "text": "Because I know how it looks. I gave him a sleep aid, not poison."},
		]},
	{"id": "alex_jordan_keys", "npc_a": "alex", "npc_b": "jordan", "reveal_clue": "clue_keys",
		"lines": [
			{"speaker": "alex", "text": "I heard the detective asking about the master key."},
			{"speaker": "jordan", "text": "Everyone has a fob, Alex. It's not exactly secret."},
			{"speaker": "alex", "text": "Mine opens every door. That's different, and you know it."},
		]},
	{"id": "casey_riley_observations", "npc_a": "casey", "npc_b": "riley", "reveal_clue": "clue_portraits",
		"lines": [
			{"speaker": "casey", "text": "I saw you giving Daniel something that night."},
			{"speaker": "riley", "text": "It was just a sleep aid. He looked exhausted."},
			{"speaker": "casey", "text": "I know. But the way you whispered... it looked like a secret."},
		]},
	{"id": "sam_jordan_wiring", "npc_a": "sam", "npc_b": "jordan", "reveal_clue": "clue_wiring",
		"lines": [
			{"speaker": "sam", "text": "The detective found the wiring in the hallway."},
			{"speaker": "jordan", "text": "That was for your app, right? Not... anything else?"},
			{"speaker": "sam", "text": "Just the app. But it looks bad. Really bad."},
		]},
	{"id": "morgan_casey_morning", "npc_a": "morgan", "npc_b": "casey", "reveal_clue": "clue_moved_object",
		"lines": [
			{"speaker": "morgan", "text": "I keep thinking about that bottle. I shouldn't have moved it."},
			{"speaker": "casey", "text": "You panicked. Anyone would have."},
			{"speaker": "morgan", "text": "But now it looks like I was tampering with evidence."},
		]}
]


static func conversations() -> Array:
	return CONVERSATIONS
