extends RefCounted
class_name CaseData

## Authored suspects and clues. Each suspect has 2 implicating clues; threshold is 2.
## Every "false_motive" is built from a real but innocent act (see each clue's "truth").

const SUSPECTS := {
	"alex": {"name": "Alex", "threshold": 2, "friends": ["jordan"],
		"secret": "Failed last semester quietly",
		"innocent_act": "Used the master key for a noise complaint",
		"false_motive": "Had access and a secret the victim could expose"},
	"jordan": {"name": "Jordan", "threshold": 2, "friends": ["alex", "riley"],
		"secret": "Audition anxiety",
		"innocent_act": "Rehearsing alone in the hallway; walked past the victim",
		"false_motive": "Last seen near the victim, and lied about being there"},
	"sam": {"name": "Sam", "threshold": 2, "friends": ["morgan", "alex"],
		"secret": "Owes Alex a favor; building a secret app",
		"innocent_act": "Touched the wiring/camera for his app",
		"false_motive": "Tampered with the scene; entangled in the scheme"},
	"riley": {"name": "Riley", "threshold": 2, "friends": ["jordan", "casey"],
		"secret": "Considering dropping pre-med",
		"innocent_act": "Gave the victim a harmless sleep aid",
		"false_motive": "Knew exactly how an overdose works"},
	"morgan": {"name": "Morgan", "threshold": 2, "friends": ["casey", "sam"],
		"secret": "Hiding an injury; rivalry with Alex",
		"innocent_act": "Found the body first and moved one object in panic",
		"false_motive": "Strength, bad blood, and a 'staged' scene"},
	"casey": {"name": "Casey", "threshold": 2, "friends": ["morgan", "riley"],
		"secret": "Secret portraits; knows everyone's secrets",
		"innocent_act": "Glimpsed the night through a window and sketched it",
		"false_motive": "Knew too much; the portraits look like stalking"},
}

const CLUES := {
	"clue_keys": {"title": "Scuffed master-key fob", "room": "hallway", "implicates": ["alex"],
		"truth": "Alex used it for a late noise complaint."},
	"clue_logbook": {"title": "RA logbook gap", "room": "common_room", "implicates": ["alex"],
		"truth": "The gap is Alex hiding his failed grade, not the victim."},
	"clue_pills": {"title": "Unlabeled pill bottle", "room": "common_room", "implicates": ["riley"],
		"truth": "Riley gave the victim a harmless sleep aid."},
	"clue_medbook": {"title": "Pharmacology notes", "room": "bedroom_4", "implicates": ["riley"],
		"truth": "Just exam study, not a poisoning plan."},
	"clue_wiring": {"title": "Tampered wiring", "room": "hallway", "implicates": ["sam"],
		"truth": "Sam was fixing wiring for his app."},
	"clue_camera": {"title": "Disabled camera", "room": "common_room", "implicates": ["sam"],
		"truth": "The camera was off because Sam borrowed its feed."},
	"clue_rehearsal": {"title": "Rehearsal script", "room": "hallway", "implicates": ["jordan"],
		"truth": "Proves Jordan was rehearsing, not lurking."},
	"clue_witness_jordan": {"title": "A witness places Jordan", "room": "kitchen", "implicates": ["jordan"],
		"truth": "Jordan walked past, assuming the victim was drunk."},
	"clue_moved_object": {"title": "Rearranged scene", "room": "bedroom_5", "implicates": ["morgan"],
		"truth": "Morgan moved a bottle in panic on finding the body."},
	"clue_morgan_early": {"title": "Up before dawn", "room": "kitchen", "implicates": ["morgan"],
		"truth": "Morgan was simply up early for a run."},
	"clue_sketch": {"title": "Torn courtyard sketch", "room": "kitchen", "implicates": ["casey"],
		"truth": "Casey sketched the window the night before."},
	"clue_portraits": {"title": "Secret portrait series", "room": "bedroom_6", "implicates": ["casey"],
		"truth": "The portraits are art, not surveillance."},
}


static func get_suspect_ids() -> Array:
	return SUSPECTS.keys()


static func clues_for_suspect(suspect_id: String) -> Array:
	var result: Array = []
	for clue_id in CLUES:
		if suspect_id in CLUES[clue_id]["implicates"]:
			result.append(clue_id)
	return result
