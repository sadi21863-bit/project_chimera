extends RefCounted
class_name EndingContent

## The endings. Every "wrong" ending convicts an innocent; the flashback (built from CaseData
## clue truths) reveals the death was an accident all along. The accident ending is the only
## non-tragic outcome — and the player only feels its weight in hindsight.

const ACCIDENT := {
	"title": "Case Closed — Accidental Death",
	"body": "You sign off: a tragic accident. The dorm grieves a little longer, then life closes "
		+ "over the gap like water. No one is ruined. You will never know how close you came to "
		+ "being right — because you were.",
}

const TRUTH := {
	"title": "The Truth, Untarnished",
	"body": "You piece it together: the pills, the camera, the ghost, the sketch — all of it "
		+ "points to the same thing. Daniel died alone, by accident, in a building full of people "
		+ "who almost helped. The truth doesn't save him, but it saves them. Each resident leaves "
		+ "Crestwood carrying a little less guilt than they arrived with.",
}

const PARTIAL_TRUTH := {
	"title": "Close Enough",
	"body": "You get the broad strokes right — it was an accident, not murder. But some details "
		+ "slip through your fingers. The pills, the camera, the ghost — you never connect them all. "
		+ "The residents leave with questions they'll never answer. So do you.",
}

const COVERUP := {
	"title": "The Quiet Settlement",
	"body": "The family accepts your conclusion: accidental death. But the standing you've "
		+ "maintained comes at a cost. You've smoothed over cracks instead of filling them. The "
		+ "residents suspect you chose convenience over truth. They're right.",
}

const TABLOID := {
	"title": "Headlines Over Honesty",
	"body": "The Crestwood Courier runs the story before you close the case. 'Dorm Death: "
		+ "Detective Blames Wrong Suspect.' Your reputation is ash. The residents refuse to speak "
		+ "to reporters. You've turned a tragedy into content.",
}

const WALK_AWAY := {
	"title": "The Case That Stayed Open",
	"body": "You hand in your badge before the deadline. The case goes cold, then frozen, then "
		+ "forgotten. Daniel's family gets a letter: 'Investigation suspended due to insufficient "
		+ "evidence.' It's the kindest lie you've ever told.",
}

const SACRIFICE := {
	"title": "The Wrong Confession",
	"body": "You confess to tampering with evidence. It's not true — but it protects someone who "
		+ "needs protecting. The case closes with your name in the file, not Daniel's. You'll carry "
		+ "that weight longer than anyone will carry his memory.",
}

const GAME_OVER := {
	"ending_fired_strikes": {"title": "Taken Off the Case",
		"body": "The chief calls you in. Too many complaints, too many nights caught somewhere you "
			+ "shouldn't have been. The Crestwood family is told, quietly, that their detective made "
			+ "too many mistakes to trust. Someone else will close the file — or won't."},
	"ending_fired_deadline": {"title": "The Clock Ran Out",
		"body": "The family's patience — and their money — has limits. Without an arrest, your "
			+ "mandate quietly expires. The case reverts to the police file it started as: closed, "
			+ "accidental, unremarkable."},
	"ending_death": {"title": "Caught in the Dark",
		"body": "You were where you shouldn't have been, alone, long after anyone would have heard "
			+ "you call out. The same stairs that killed the person you were investigating claim a "
			+ "second accident. Nobody thinks to connect the two. Why would they?"},
}

const WRONG := {
	"alex": {"title": "The RA Falls",
		"body": "Alex is led out in front of the residents he kept safe. The keys that opened "
			+ "every door couldn't open the one cell that mattered."},
	"jordan": {"title": "The Understudy's Last Role",
		"body": "Jordan is arrested mid-rehearsal. The stage goes dark on a career that never "
			+ "got its opening night."},
	"sam": {"title": "The Quiet One, Convicted",
		"body": "They call Sam a mastermind. The boy who only ever talked to machines has no "
			+ "words left for the people taking him away."},
	"riley": {"title": "First, Do No Harm",
		"body": "Riley's hands — steady enough to heal — are cuffed. The kindness of a single "
			+ "pill becomes the proof that hangs her."},
	"morgan": {"title": "The Loyal One, Broken",
		"body": "Morgan goes without a fight. Loyalty looks like guilt when you're the one who "
			+ "found the body and touched the scene."},
	"casey": {"title": "Punished for Watching",
		"body": "Casey is believed precisely because they saw too much. The portraits — made out "
			+ "of love — are read aloud as the work of a stalker. The kindest one falls hardest."},
}


static func ending_for(ending_id: String) -> Dictionary:
	if ending_id == "ending_accident":
		return ACCIDENT
	if ending_id == "ending_truth":
		return TRUTH
	if ending_id == "ending_partial_truth":
		return PARTIAL_TRUTH
	if ending_id == "ending_coverup":
		return COVERUP
	if ending_id == "ending_tabloid":
		return TABLOID
	if ending_id == "ending_walk_away":
		return WALK_AWAY
	if ending_id == "ending_sacrifice":
		return SACRIFICE
	if GAME_OVER.has(ending_id):
		return GAME_OVER[ending_id]
	var suspect_id := ending_id.trim_prefix("ending_")
	if WRONG.has(suspect_id):
		return WRONG[suspect_id]
	return {}


static func build_flashback(discovered_clue_ids: Array) -> Array:
	var result: Array = []
	for clue_id in CaseData.CLUES:  # CaseData order for stable presentation
		if clue_id in discovered_clue_ids:
			var data: Dictionary = CaseData.CLUES[clue_id]
			result.append({"title": str(data["title"]), "truth": str(data["truth"])})
	return result


static func get_ending_count() -> int:
	return 6 + GAME_OVER.size() + WRONG.size()  # 6 special + game_over + wrong suspect endings


static func get_all_ending_ids() -> Array:
	var ids: Array = []
	ids.append("ending_accident")
	ids.append("ending_truth")
	ids.append("ending_partial_truth")
	ids.append("ending_coverup")
	ids.append("ending_tabloid")
	ids.append("ending_walk_away")
	ids.append("ending_sacrifice")
	ids.append_array(GAME_OVER.keys())
	for suspect_id in WRONG.keys():
		ids.append("ending_" + suspect_id)
	return ids
