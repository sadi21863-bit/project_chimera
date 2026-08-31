extends RefCounted
class_name SearchData

## Detailed examination: each search point is an object you can act on in multiple ways
## (look under / dig / lift). Each action gives flavor and may reveal a clue. The "risk" field
## is consumed by the later sneaking/consequences slice; for now it is shown as a hint only.

const POINTS := {
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
					+ "decided you're a nuisance. Someone else has has circled it in green ink: 'be nice, she might "
					+ "actually find something.'"},
		]},
	"hallway_vending": {"room": "hallway", "label": "the vending machine",
		"actions": [
			{"id": "check", "label": "Check the coin slot", "reveal_clue": "", "risk": "safe",
				"flavor": "A crumpled receipt stuck in the coin return. Someone bought three energy drinks at 2 AM — the timestamp matches Sam's usual coding hours."},
			{"id": "look_under", "label": "Look under the machine", "reveal_clue": "clue_wiring", "risk": "safe",
				"flavor": "A tangle of spare ethernet cable and a handwritten note: 'Meet at the server room. 2 AM. —S'"},
		]},
	"courtyard_bench": {"room": "courtyard", "label": "the courtyard bench",
		"actions": [
			{"id": "sit", "label": "Sit and observe", "reveal_clue": "", "risk": "safe",
				"flavor": "From here you can see every dorm window. Casey's sketch makes sense — this is the perfect vantage point. A charcoal smudge marks the armrest."},
			{"id": "check_cushion", "label": "Check under the cushion", "reveal_clue": "clue_sketch", "risk": "safe",
				"flavor": "A torn piece of sketch paper with a partial drawing of the dorm facade. The date is written in the corner: the night before Daniel's death."},
		]},
	"dorm_entrance": {"room": "hallway", "label": "the entrance noticeboard",
		"actions": [
			{"id": "read", "label": "Read the fire safety notice", "reveal_clue": "", "risk": "safe",
				"flavor": "Standard fire safety poster. But someone has written in the margin: 'Check the alarms — S says they're disconnected on weekends.'"},
			{"id": "lift", "label": "Lift the notices", "reveal_clue": "clue_camera", "risk": "safe",
				"flavor": "Behind the fire safety poster: a maintenance log. Camera #3 was 'serviced' (disabled) on the night of the party. Signed by Sam."},
		]},
	"server_workstation": {"room": "server_room", "label": "Sam's workstation",
		"actions": [
			{"id": "check_screen", "label": "Check the monitors", "reveal_clue": "clue_camera", "risk": "risky",
				"flavor": "The monitors show camera feeds from the dorm. Camera #3 is black — disabled. A sticky note reads: 'Feed routed to app. Delete this. —S'"},
			{"id": "check_desk", "label": "Check the desk drawers", "reveal_clue": "clue_wiring", "risk": "risky",
				"flavor": "Spare ethernet cables, a soldering iron, and a notebook with wiring diagrams. One page is torn out — the one showing the camera room layout."},
		]},
	"library_research": {"room": "library", "label": "the research terminal",
		"actions": [
			{"id": "search_daniel", "label": "Search for Daniel's records", "reveal_clue": "clue_daniel_double_life", "risk": "safe",
				"flavor": "The terminal shows two student profiles for the same face — different last names. The name change was approved by Dean Whitfield."},
			{"id": "search_newspapers", "label": "Search old newspapers", "reveal_clue": "", "risk": "safe",
				"flavor": "A article from two years ago: 'Crestwood Family Donates $2M to University.' The family name appears in every campus building."},
		]},
	"hospital_lockers": {"room": "hospital", "label": "Riley's locker",
		"actions": [
			{"id": "open", "label": "Open the locker", "reveal_clue": "clue_medbook", "risk": "risky",
				"flavor": "Lab coats, a pharmacology textbook with highlighted pages on drug interactions, and a rotation schedule. Riley was working the night shift the week Daniel died."},
			{"id": "check_pockets", "label": "Check the coat pockets", "reveal_clue": "clue_pills", "risk": "risky",
				"flavor": "A small bottle of over-the-counter sleep aids in the pocket. The label is partially torn — looks like it was removed hastily."},
		]},
	"bar_booth": {"room": "bar", "label": "the corner booth",
		"actions": [
			{"id": "check_table", "label": "Check the table", "reveal_clue": "clue_ghost_note", "risk": "safe",
				"flavor": "A cocktail napkin with a handwritten note: 'Crestwood Courier — one sighting a week, keep it vague. Payment via Venmo.' The same tabloid Jordan was working for."},
			{"id": "talk_bartender", "label": "Talk to the bartender", "reveal_clue": "", "risk": "safe",
				"flavor": "The bartender remembers a 'nervous kid with a backpack' coming in after midnight several times. Always sat in the same booth. Tipped badly."},
		]},
	"common_room_couch": {"room": "common_room", "label": "the common room couch",
		"actions": [
			{"id": "check_under", "label": "Check under the cushions", "reveal_clue": "clue_logbook", "risk": "safe",
				"flavor": "Wedged under a cushion: a torn page from the RA logbook. The entry for the night of Daniel's death has been ripped out — only the date remains."},
			{"id": "feel_sides", "label": "Feel down the sides", "reveal_clue": "", "risk": "safe",
				"flavor": "Loose change, a hair tie, three months of crumbs. And something else — a small, folded note with a phone number."},
		]},
	"kitchen_counter": {"room": "kitchen", "label": "the kitchen counter",
		"actions": [
			{"id": "check_sink", "label": "Check the sink", "reveal_clue": "", "risk": "safe",
				"flavor": "A coffee mug with dried residue. The mug says 'World's Best RA' — Alex's. Next to it, a pill bottle half-hidden behind the dish soap."},
			{"id": "check_fridge", "label": "Check the fridge", "reveal_clue": "clue_pills", "risk": "safe",
				"flavor": "Inside the fridge: leftover pizza, energy drinks, and a small bottle with no label. Riley's handwriting on a sticky note: 'Take 1 before bed.'"},
		]},
	"hallway_stairs": {"room": "hallway", "label": "the staircase",
		"actions": [
			{"id": "check_railing", "label": "Check the railing", "reveal_clue": "", "risk": "safe",
				"flavor": "Scuff marks on the railing. Something — or someone — hit this hard on the way down. The marks are fresh, gouged into the wood."},
			{"id": "check_landing", "label": "Check the landing", "reveal_clue": "clue_witness_jordan", "risk": "safe",
				"flavor": "A single thread caught on the corner of the landing. Blue, synthetic — the same color as Jordan's rehearsal costume. They were here that night."},
		]},
	"bedroom_1_desk": {"room": "bedroom_1", "label": "Alex's desk",
		"actions": [
			{"id": "check_drawer", "label": "Check the top drawer", "reveal_clue": "clue_keys", "risk": "risky",
				"flavor": "RA paperwork, alphabetized. And a master-key lanyard tucked under the files. Alex runs a tight ship — but this key opens every door in the building."},
			{"id": "check_computer", "label": "Check the computer", "reveal_clue": "", "risk": "risky",
				"flavor": "The browser history shows searches for 'how to change student records' and 'academic probation appeal.' Alex was hiding something — but not murder."},
		]},
	"bedroom_2_mirror": {"room": "bedroom_2", "label": "Jordan's mirror",
		"actions": [
			{"id": "check_frame", "label": "Check the frame", "reveal_clue": "clue_rehearsal", "risk": "safe",
				"flavor": "Taped to the mirror: a rehearsal schedule. 'Memorize lines by Thursday. Meet director at 2 PM.' The date is from the week Daniel died."},
			{"id": "check_drawers", "label": "Check the dresser", "reveal_clue": "clue_ghost_costume", "risk": "risky",
				"flavor": "Costume pieces from three different plays. And underneath — a cheap white sheet, folded neatly. Tags still on: bought last week."},
		]},
	"bedroom_3_desk": {"room": "bedroom_3", "label": "Sam's desk",
		"actions": [
			{"id": "check_monitors", "label": "Check the monitors", "reveal_clue": "clue_camera", "risk": "risky",
				"flavor": "Three monitors, all running code. One shows a live camera feed from the dorm hallway. Camera #3 is black — disabled. A sticky note: 'Feed routed to app.'"},
			{"id": "check_notes", "label": "Check the notebook", "reveal_clue": "clue_wiring", "risk": "risky",
				"flavor": "Wiring diagrams, server layouts, and a page torn from the maintenance manual. Sam was rewiring the camera system for his app — but it looks like a cover-up."},
		]},
	"bedroom_4_bed": {"room": "bedroom_4", "label": "Riley's bed",
		"actions": [
			{"id": "check_pillow", "label": "Check under the pillow", "reveal_clue": "clue_medbook", "risk": "risky",
				"flavor": "A pharmacology textbook, open to a chapter on drug interactions. A page is bookmarked: 'Sleep aids and stimulant interactions.' Riley was studying — or planning."},
			{"id": "check_nightstand", "label": "Check the nightstand", "reveal_clue": "clue_pills", "risk": "risky",
				"flavor": "A bottle of over-the-counter sleep aids. The label is partially torn. And a note: 'Give to Daniel — he hasn't been sleeping.' Riley was trying to help."},
		]},
	"bedroom_5_window": {"room": "bedroom_5", "label": "Morgan's window",
		"actions": [
			{"id": "check_view", "label": "Check the view", "reveal_clue": "clue_morgan_early", "risk": "safe",
				"flavor": "The window overlooks the courtyard. Morgan was up early — the running shoes by the door are worn. They saw everything from here, but said nothing."},
			{"id": "check_shoes", "label": "Check the running shoes", "reveal_clue": "clue_moved_object", "risk": "risky",
				"flavor": "The soles are muddy — fresh mud, not old. Morgan was out that night, not just on a morning run. And there's something stuck in the laces: a small glass shard."},
		]},
	"bedroom_6_easel": {"room": "bedroom_6", "label": "Casey's easel",
		"actions": [
			{"id": "check_canvas", "label": "Check the canvas", "reveal_clue": "clue_portraits", "risk": "safe",
				"flavor": "A portrait of the dorm residents, all together. Casey sees people clearly — maybe too clearly. The faces are detailed, intimate. This isn't surveillance. It's love."},
			{"id": "check_sketches", "label": "Check the sketchbook", "reveal_clue": "clue_sketch", "risk": "safe",
				"flavor": "Page after page of the courtyard, drawn from different angles. The last sketch is dated the night before Daniel's death. Casey was watching — but only drawing."},
		]},
	"university_noticeboard": {"room": "university", "label": "the department noticeboard",
		"actions": [
			{"id": "read_notices", "label": "Read the notices", "reveal_clue": "clue_ghost_note", "risk": "safe",
				"flavor": "Among the faculty postings, a student achievement list. Daniel's name appears twice — once under his real name, once under an alias. Two identities, one department."},
			{"id": "check_mailboxes", "label": "Check faculty mailboxes", "reveal_clue": "clue_logbook", "risk": "medium",
				"flavor": "A interdepartmental memo from Dean Whitfield to the registrar: 'Please ensure all reference letters for Daniel Crestwood go through my office first.' Controlling the narrative."},
		]},
	"university_filing_cabinet": {"room": "university", "label": "the filing cabinet",
		"actions": [
			{"id": "pull_records", "label": "Pull Daniel's student records", "reveal_clue": "clue_ghost_note", "risk": "medium",
				"flavor": "Two enrollment forms, same student ID, different names. The second form was submitted by the Dean's office. Someone helped Daniel disappear."},
			{"id": "check_financial_aid", "label": "Check financial aid files", "reveal_clue": "clue_logbook", "risk": "safe",
				"flavor": "A scholarship letter addressed to 'Daniel Whitfield' — the Dean's nephew? Or another identity? The amount covers full tuition. Someone was paying for silence."},
		]},
	"campus_fountain": {"room": "campus", "label": "the campus fountain",
		"actions": [
			{"id": "check_inscriptions", "label": "Read the dedication plaque", "reveal_clue": "clue_moved_object", "risk": "safe",
				"flavor": "'Erected through the generosity of the Crestwood Family, 2019.' The same year Daniel enrolled. The family built this campus — and they can bury what happens on it."},
			{"id": "look_around", "label": "Observe the area", "reveal_clue": "", "risk": "safe",
				"flavor": "Students pass through without a second glance. The fountain gurgles. Somewhere, a lecture hall echoes. This campus runs on routine — and routines hide secrets."},
		]},
	"campus_bench": {"room": "campus", "label": "a bench near the library",
		"actions": [
			{"id": "check_under", "label": "Look under the bench", "reveal_clue": "clue_sketch", "risk": "safe",
				"flavor": "A crumpled sketchpad page, weighted down with a stone. Casey's style — quick, observant lines. The drawing shows the dorm entrance at night. Dated three days before Daniel's death."},
			{"id": "read_graffiti", "label": "Read the carved initials", "reveal_clue": "", "risk": "safe",
				"flavor": "D+C intertwined in the wood. Daniel and Casey? Or Daniel and someone else? The carving is old, weathered. This bench has stories."},
		]},
	"desk_case_notes": {"room": "detective_room", "label": "your case notes on the desk",
		"actions": [
			{"id": "review_notes", "label": "Review your notes", "reveal_clue": "", "risk": "safe",
				"flavor": "Your own handwriting stares back at you. The timeline is solid, but there's a gap — Tuesday night, 11pm to 2am. You were asleep. Everyone else was supposedly asleep too. But someone was moving."},
			{"id": "check_phone", "label": "Check your phone", "reveal_clue": "clue_morgan_early", "risk": "safe",
				"flavor": "A text from Morgan at 10:47pm: 'Can we talk tomorrow? It's about Daniel.' You never saw it. It came after you'd already gone to bed. Morgan knew something that night."},
		]},
	"closet_case_file": {"room": "detective_room", "label": "the case file in your closet",
		"actions": [
			{"id": "read_file", "label": "Read the file again", "reveal_clue": "clue_logbook", "risk": "safe",
				"flavor": "The official police report. Clean, clinical, wrong. The cause of death reads 'accidental overdose' but the toxicology shows traces of something else — a sedative not in Riley's pill bottle. Someone else was involved."},
			{"id": "check_evidence_bag", "label": "Examine the evidence bag", "reveal_clue": "clue_witness_jordan", "risk": "medium",
				"flavor": "Jordan's testimony, recorded but never followed up. 'I saw someone leaving Daniel's room at 1am. Dark clothes, hood up. Could have been anyone.' The officer wrote 'unreliable' in the margin. Jordan saw the killer."},
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
