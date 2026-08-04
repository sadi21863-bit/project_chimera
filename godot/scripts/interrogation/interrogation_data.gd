extends RefCounted
class_name InterrogationData

## Authored interrogation content. Topics with trust_min reveal a clue only once the detective
## has earned enough standing — interrogation is a real evidence source (the same clues can also
## be examined or witnessed). evidence[clue_id] is how the suspect reacts when shown that clue.

const SUSPECTS := {
	"alex": {
		"persona": "Alex the RA: controlling, protective of authority, hiding a quietly failed semester — not a crime.",
		"topics": [
			{"id": "that_night", "label": "Where were you that night?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Doing my rounds. I have keys to every door — that's the job, not a motive."},
			{"id": "the_grade", "label": "What are you hiding about your record?", "trust_min": 0.3, "reveal_clue": "clue_logbook",
				"response": "...Fine. There's a gap in the logbook. I failed a class and quietly fixed the record. It has nothing to do with the death."},
		],
		"evidence": {
			"clue_keys": "Those are mine, yes. Everyone's fob is scuffed — we use them daily.",
			"clue_logbook": "That gap is me covering my own grade. Not the victim. Please leave it.",
		},
	},
	"jordan": {
		"persona": "Jordan the actor: dramatic, anxious, lied about being in the hallway because he froze, not because he's guilty.",
		"topics": [
			{"id": "that_night", "label": "Were you near the victim's room?", "trust_min": 0.0, "reveal_clue": "",
				"response": "No. I mean — I was rehearsing. In the hallway. That's all."},
			{"id": "the_lie", "label": "You lied about being there. Why?", "trust_min": 0.4, "reveal_clue": "clue_witness_jordan",
				"response": "Because I saw him stumble and I just... walked past. I thought he was drunk. I didn't help. I couldn't say that out loud."},
			{"id": "the_tip", "label": "You knew Daniel from more than the dorm. Anything you haven't said?", "trust_min": 0.5, "reveal_clue": "",
				"response": "He talked big about the university side of his life — like it was a completely different person wearing his name. If you want the truth about that half of him, the dean knows more than she's letting on. I'd start there."},
		],
		"evidence": {
			"clue_rehearsal": "My script, yes — proof I was rehearsing, not lurking.",
			"clue_witness_jordan": "Okay. I was there. I walked past him. That's my whole crime — walking past.",
			"clue_ghost_costume": "...okay, yes, that's mine. A tabloid stringer offered good money to fake a haunting for clicks. It has nothing to do with Daniel. I know exactly how it looks.",
			"clue_ghost_note": "That's the payment note. I shouldn't have taken it. After he died I panicked and figured stopping would look worse than finishing, so I kept doing it. Stupid, I know.",
		},
	},
	"sam": {
		"persona": "Sam the hacker: terse, evasive about the wiring and a borrowed camera feed for a secret app, owes Alex a favor.",
		"topics": [
			{"id": "that_night", "label": "What were you doing late?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Up. Coding. I'm always up. Ask anyone — actually, don't ask anyone."},
			{"id": "the_camera", "label": "Why was the camera disabled?", "trust_min": 0.4, "reveal_clue": "clue_camera",
				"response": "I borrowed the feed for my app. That's why it was off. I wasn't hiding a body, I was hiding a side project."},
		],
		"evidence": {
			"clue_wiring": "I was fixing the wiring for my app. That's all that was.",
			"clue_camera": "Yeah, I turned it off. For the feed. Bad timing, not bad intent.",
		},
	},
	"riley": {
		"persona": "Riley the pre-med: kind, anxious, wracked with guilt for giving the victim a harmless sleep aid.",
		"topics": [
			{"id": "that_night", "label": "How did the victim seem?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Stressed. Worn down. I wanted to help. I always want to help."},
			{"id": "the_pills", "label": "Did you give them anything?", "trust_min": 0.2, "reveal_clue": "clue_medbook",
				"response": "I gave them something to sleep. Over-the-counter. My notes are just exam prep — but I know how it looks."},
		],
		"evidence": {
			"clue_pills": "Those are mine — a mild sleep aid. I was trying to help, I swear.",
			"clue_medbook": "My pharmacology notes are for an exam, not a plan. Please don't twist this.",
		},
	},
	"morgan": {
		"persona": "Morgan the athlete: loyal, blunt, panicked when finding the body and moved one object, hiding an injury.",
		"topics": [
			{"id": "that_night", "label": "You were up early?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Always am. Morning run. Found... I found things quiet."},
			{"id": "the_scene", "label": "Did you touch the scene?", "trust_min": 0.5, "reveal_clue": "clue_moved_object",
				"response": "I found him first. I panicked. I moved a bottle — I don't even know why. Then I called it in. That's it."},
		],
		"evidence": {
			"clue_moved_object": "I moved it. In the moment. I wasn't thinking. That's not murder, that's panic.",
			"clue_morgan_early": "I was up for a run, like every day. Being early isn't a crime.",
		},
	},
	"casey": {
		"persona": "Casey the artist: quiet, watchful, sketched the courtyard window the night before; knows everyone's secrets.",
		"topics": [
			{"id": "that_night", "label": "What did you see?", "trust_min": 0.0, "reveal_clue": "",
				"response": "I see a lot. People forget I'm there. That's not the same as doing anything."},
			{"id": "the_window", "label": "Tell me about the window sketch.", "trust_min": 0.3, "reveal_clue": "clue_portraits",
				"response": "I draw at night. I sketched the courtyard the evening before. The portraits... they're love, not surveillance. People never believe that."},
			{"id": "the_hint", "label": "You said you see everything. Give me something.", "trust_min": 0.5, "reveal_clue": "",
				"response": "Fine. Two things. Somebody's been playing ghost near the courtyard after midnight — ask around about a trunk in bedroom two. And the department's not as united as they want the family to think. Ask at the station."},
		],
		"evidence": {
			"clue_sketch": "I sketched the window the night before it happened. Coincidence is not guilt.",
			"clue_portraits": "Those portraits are how I pay attention to people. Not how I stalk them.",
		},
	},
	"dean": {
		"persona": "Dean Whitfield: measured, careful with words, protective of the university's name.",
		"topics": [
			{"id": "that_night", "label": "What can you tell me about Daniel?", "trust_min": 0.0, "reveal_clue": "",
				"response": "A promising student. Bright future. Beyond that, I'd rather not speculate — grief doesn't need my commentary."},
			{"id": "the_double_life", "label": "What was he hiding here?", "trust_min": 0.4, "reveal_clue": "",
				"response": "Daniel was living two lives — one at the dorm, one on this campus, and they didn't overlap the way he wanted people to think. I was asked, by people with more say than me, to keep that quiet. I'm not proud of agreeing."},
		],
		"evidence": {},
	},
}


static func topics_for(suspect_id: String) -> Array:
	if SUSPECTS.has(suspect_id):
		return SUSPECTS[suspect_id]["topics"]
	return []


static func respond_to_topic(suspect_id: String, topic_id: String, standing: float) -> Dictionary:
	for topic in topics_for(suspect_id):
		if topic["id"] == topic_id:
			var reveal: String = str(topic.get("reveal_clue", ""))
			var trust_min: float = float(topic.get("trust_min", 0.0))
			if reveal != "" and standing < trust_min:
				return {"text": "I've told you what I'm going to tell you.", "reveal_clue": ""}
			return {"text": str(topic["response"]), "reveal_clue": reveal}
	return {"text": "I don't know what you mean.", "reveal_clue": ""}


static func respond_to_evidence(suspect_id: String, clue_id: String) -> String:
	if SUSPECTS.has(suspect_id):
		var ev: Dictionary = SUSPECTS[suspect_id]["evidence"]
		if ev.has(clue_id):
			return str(ev[clue_id])
	return "I don't see what that has to do with me."
