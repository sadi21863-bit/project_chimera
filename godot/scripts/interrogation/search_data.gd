extends RefCounted
class_name SearchData

## Detailed examination: each search point is an object you can act on in multiple ways
## (look under / dig / lift). Each action gives flavor and may reveal a clue. The "risk" field
## is consumed by the later sneaking/consequences slice; for now it is shown as a hint only.

const POINTS := {
	"common_couch": {"room": "common_room", "label": "the common-room couch",
		"actions": [
			{"id": "look_under", "label": "Look under the cushions", "reveal_clue": "clue_logbook", "risk": "safe",
				"flavor": "Wedged under a cushion: a torn page from the RA logbook."},
			{"id": "feel_sides", "label": "Feel down the sides", "reveal_clue": "", "risk": "safe",
				"flavor": "Loose change, a hair tie, three months of crumbs."},
		]},
	"kitchen_bin": {"room": "kitchen", "label": "the kitchen bin",
		"actions": [
			{"id": "dig", "label": "Dig through the trash", "reveal_clue": "clue_pills", "risk": "risky",
				"flavor": "Under the coffee grounds — an unlabeled pill bottle."},
		]},
	"hall_board": {"room": "hallway", "label": "the noticeboard",
		"actions": [
			{"id": "read", "label": "Read the notices", "reveal_clue": "", "risk": "safe",
				"flavor": "Chore charts, a lost-charger plea, and a flyer for the victim's memorial."},
			{"id": "lift", "label": "Lift the flyers", "reveal_clue": "clue_rehearsal", "risk": "safe",
				"flavor": "Pinned behind the flyers: a page of Jordan's rehearsal script."},
		]},
	"bathroom_cabinet": {"room": "bathroom", "label": "the medicine cabinet",
		"actions": [
			{"id": "open", "label": "Open the cabinet", "reveal_clue": "", "risk": "safe",
				"flavor": "Six toothbrushes, a razor, and more painkillers than one dorm should need."},
			{"id": "check_hamper", "label": "Check the laundry hamper", "reveal_clue": "", "risk": "risky",
				"flavor": "Someone's gym clothes. Not your business, but you note them anyway."},
		]},
	"alex_desk": {"room": "bedroom_1", "label": "Alex's desk",
		"actions": [
			{"id": "look_under", "label": "Look under the desk", "reveal_clue": "item_master_key", "risk": "safe",
				"flavor": "A tangle of charging cables and a master-key lanyard hung on the chair. You take the keys."},
			{"id": "open_drawer", "label": "Open the top drawer", "reveal_clue": "", "risk": "risky",
				"flavor": "RA paperwork, alphabetized. Alex runs a tight ship."},
		]},
	"jordan_dresser": {"room": "bedroom_2", "label": "Jordan's dresser",
		"actions": [
			{"id": "open_drawer", "label": "Open the dresser", "reveal_clue": "", "risk": "risky",
				"flavor": "Costume pieces from three different plays, still smelling of stage makeup."},
		]},
	"sam_nightstand": {"room": "bedroom_3", "label": "Sam's nightstand",
		"actions": [
			{"id": "open_drawer", "label": "Open the nightstand", "reveal_clue": "", "risk": "risky",
				"flavor": "A multitool, spare fuses, and a notebook of half-finished repair sketches."},
		]},
	"riley_closet": {"room": "bedroom_4", "label": "Riley's closet",
		"actions": [
			{"id": "open", "label": "Open the closet", "reveal_clue": "", "risk": "risky",
				"flavor": "Lab coats and a shelf of pharmacology textbooks, spines cracked from use."},
		]},
	"morgan_desk": {"room": "bedroom_5", "label": "Morgan's desk",
		"actions": [
			{"id": "look_under", "label": "Look under the desk", "reveal_clue": "", "risk": "safe",
				"flavor": "A shoebox of receipts, sorted by date with obsessive care."},
		]},
	"casey_shelf": {"room": "bedroom_6", "label": "Casey's shelf",
		"actions": [
			{"id": "look_under", "label": "Look behind the shelf", "reveal_clue": "", "risk": "safe",
				"flavor": "Rolled-up sketches, all of the same courtyard, none quite finished."},
		]},
	"daniel_desk": {"room": "daniel_room", "label": "Daniel's desk",
		"actions": [
			{"id": "open_drawer", "label": "Open the drawer", "reveal_clue": "clue_daniel_double_life", "risk": "safe",
				"flavor": "A second student ID, same face, a different last name. Under it, a folded letter "
					+ "addressed to 'the Crestwood family' he never sent."},
		]},
	"daniel_ledger": {"room": "daniel_room", "label": "a notebook tucked behind the headboard",
		"actions": [
			{"id": "look_under", "label": "Check behind the headboard", "reveal_clue": "clue_daniel_scheme", "risk": "safe",
				"flavor": "A running tally of names, dates, and small amounts — favors owed, favors called "
					+ "in. Careful, deliberate handwriting. Whatever this funded, he kept it quiet."},
		]},
	"daniel_nightstand": {"room": "daniel_room", "label": "Daniel's nightstand",
		"actions": [
			{"id": "open", "label": "Open the nightstand", "reveal_clue": "clue_daniel_selfmed", "risk": "safe",
				"flavor": "An unmarked bottle of stimulants, nearly empty, and a heart-clinic appointment card "
					+ "he never used — three months overdue."},
		]},
	"jordan_costume_trunk": {"room": "bedroom_2", "label": "the trunk under Jordan's bed",
		"actions": [
			{"id": "look_under", "label": "Look under the bed", "reveal_clue": "clue_ghost_costume", "risk": "risky",
				"flavor": "A cheap white sheet costume stuffed in a duffel bag. Tags still on — bought last week."},
			{"id": "dig", "label": "Dig through the trunk", "reveal_clue": "clue_ghost_note", "risk": "risky",
				"flavor": "A folded note: a payment confirmation from a tabloid stringer, and 'one sighting a week, keep it vague — Crestwood Courier.'"},
		]},
	"case_board": {"room": "police_station", "label": "the case board",
		"actions": [
			{"id": "read", "label": "Read the pinned notes", "reveal_clue": "", "risk": "safe",
				"flavor": "A chief's handwriting: 'Ruled accidental. Case closed.' Underneath, in different ink: "
					+ "'Family is pushing. Above my pay grade now.'"},
		]},
	"evidence_log": {"room": "police_station", "label": "the evidence log",
		"actions": [
			{"id": "check", "label": "Check the sign-out sheet", "reveal_clue": "", "risk": "risky",
				"flavor": "A Crestwood family lawyer signed out copies of the original report the same week "
					+ "they hired you. They've read everything you have — and more."},
		]},
	"detective_memo": {"room": "police_station", "label": "a memo on the corkboard",
		"actions": [
			{"id": "read", "label": "Read the memo", "reveal_clue": "", "risk": "safe",
				"flavor": "'Detective Reyes: don't waste your time humoring the family's hire.' Someone's already "
					+ "decided you're a nuisance. Someone else has circled it in green ink: 'be nice, she might "
					+ "actually find something.'"},
		]},
}


static func point_ids() -> Array:
	return POINTS.keys()


static func point(point_id: String) -> Dictionary:
	return POINTS.get(point_id, {})


static func resolve(point_id: String, action_id: String) -> Dictionary:
	var p: Dictionary = POINTS.get(point_id, {})
	for action in p.get("actions", []):
		if str(action["id"]) == action_id:
			return {"reveal_clue": str(action.get("reveal_clue", "")), "flavor": str(action.get("flavor", ""))}
	return {"reveal_clue": "", "flavor": ""}
