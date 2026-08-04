extends RefCounted
class_name NpcProfileFactory

const NPC_DATA := [
	{
		"id": "alex",
		"name": "Alex",
		"personality": "Ambitious RA who keeps the dorm running. Organized, slightly controlling.",
		"bedroom": "bedroom_1",
		"color": Color("#4ecdc4"),
		"secrets": ["Failed last semester quietly", "Has a crush on Jordan"],
		"seeds": {"jordan": 0.6, "morgan": -0.2},
	},
	{
		"id": "jordan",
		"name": "Jordan",
		"personality": "Theater kid, dramatic, always rehearsing monologues in hallways.",
		"bedroom": "bedroom_2",
		"color": Color("#ff6b6b"),
		"secrets": ["Audition anxiety", "Writes poetry about Riley"],
		"seeds": {"alex": 0.6, "riley": 0.7},
	},
	{
		"id": "sam",
		"name": "Sam",
		"personality": "Night owl programmer. Lives on instant noodles and lo-fi beats.",
		"bedroom": "bedroom_3",
		"color": Color("#45aaf2"),
		"secrets": ["Building a secret app", "Owes Alex a favor"],
		"seeds": {"alex": 0.3, "morgan": 0.5},
	},
	{
		"id": "riley",
		"name": "Riley",
		"personality": "Pre-med student, stressed but kind. Always studying in the common room.",
		"bedroom": "bedroom_4",
		"color": Color("#a55eea"),
		"secrets": ["Considering dropping pre-med", "Hides care packages from Casey"],
		"seeds": {"jordan": 0.7, "casey": 0.4},
	},
	{
		"id": "morgan",
		"name": "Morgan",
		"personality": "Athlete, early riser, competitive but loyal to friends.",
		"bedroom": "bedroom_5",
		"color": Color("#26de81"),
		"secrets": ["Injury they're hiding from coach", "Rivalry with Alex over leadership"],
		"seeds": {"sam": 0.5, "casey": 0.8, "alex": -0.2},
	},
	{
		"id": "casey",
		"name": "Casey",
		"personality": "Artist, quiet observer, paints at odd hours. Notices everything.",
		"bedroom": "bedroom_6",
		"color": Color("#fd9644"),
		"secrets": ["Painting portraits of dorm mates secretly", "Knows everyone's secrets"],
		"seeds": {"riley": 0.4, "morgan": 0.8},
	},
]


# Per-NPC daily routines so characters live independent lives (not in lockstep) even with the
# LLM off. "BED" is substituted with each NPC's bedroom. Each routine covers a full 0-24h day.
const ROUTINES := {
	"alex": [  # RA: early riser, patrols the dorm
		[0.0, 6.5, "BED", "sleep"], [6.5, 7.0, "bathroom", "morning routine"],
		[7.0, 7.5, "kitchen", "early breakfast"], [7.5, 10.0, "hallway", "RA rounds"],
		[10.0, 12.0, "common_room", "check-ins"], [12.0, 12.5, "kitchen", "lunch"],
		[12.5, 14.0, "BED", "admin work"], [14.0, 17.0, "hallway", "RA rounds"],
		[17.0, 18.5, "common_room", "hang out"], [18.5, 19.0, "kitchen", "dinner"],
		[19.0, 22.0, "common_room", "evening"], [22.0, 24.0, "BED", "sleep prep"],
	],
	"jordan": [  # theater kid: rehearses in the hallways, late riser
		[0.0, 8.0, "BED", "sleep"], [8.0, 8.5, "bathroom", "morning routine"],
		[8.5, 9.0, "kitchen", "breakfast"], [9.0, 12.0, "hallway", "rehearsing"],
		[12.0, 12.5, "kitchen", "lunch"], [12.5, 16.0, "hallway", "rehearsing"],
		[16.0, 18.5, "common_room", "socialize"], [18.5, 19.0, "kitchen", "dinner"],
		[19.0, 23.0, "common_room", "socialize"], [23.0, 24.0, "BED", "sleep prep"],
	],
	"sam": [  # night owl programmer: sleeps late, codes through the night
		[0.0, 3.0, "common_room", "late coding"], [3.0, 11.0, "BED", "sleep"],
		[11.0, 11.5, "kitchen", "brunch"], [11.5, 17.0, "BED", "coding"],
		[17.0, 18.0, "common_room", "break"], [18.0, 18.5, "kitchen", "dinner"],
		[18.5, 23.0, "BED", "coding"], [23.0, 24.0, "kitchen", "midnight snack"],
	],
	"riley": [  # pre-med: studies in the common room nearly all day
		[0.0, 7.0, "BED", "sleep"], [7.0, 7.5, "bathroom", "morning routine"],
		[7.5, 8.0, "kitchen", "breakfast"], [8.0, 12.0, "common_room", "studying"],
		[12.0, 12.5, "kitchen", "lunch"], [12.5, 18.0, "common_room", "studying"],
		[18.0, 18.5, "kitchen", "dinner"], [18.5, 22.0, "common_room", "studying"],
		[22.0, 24.0, "BED", "sleep prep"],
	],
	"morgan": [  # athlete: very early riser, sleeps early
		[0.0, 5.5, "BED", "sleep"], [5.5, 6.0, "bathroom", "morning routine"],
		[6.0, 6.5, "kitchen", "early breakfast"], [6.5, 9.0, "common_room", "workout"],
		[9.0, 11.0, "BED", "rest"], [11.0, 11.5, "kitchen", "early lunch"],
		[11.5, 15.0, "common_room", "hang out"], [15.0, 17.0, "hallway", "walk"],
		[17.0, 17.5, "kitchen", "early dinner"], [17.5, 20.0, "common_room", "evening"],
		[20.0, 24.0, "BED", "sleep prep"],
	],
	"casey": [  # artist: paints in their room, roams at odd hours
		[0.0, 2.0, "hallway", "night roaming"], [2.0, 9.0, "BED", "sleep"],
		[9.0, 9.5, "kitchen", "breakfast"], [9.5, 13.0, "BED", "painting"],
		[13.0, 15.0, "common_room", "observing"], [15.0, 17.0, "hallway", "sketching"],
		[17.0, 18.0, "kitchen", "dinner"], [18.0, 22.0, "BED", "painting"],
		[22.0, 24.0, "hallway", "night roaming"],
	],
}


static func create_schedule(npc_id: String, bedroom: String) -> NpcSchedule:
	var schedule := NpcSchedule.new()
	schedule.npc_id = npc_id
	var routine: Array = ROUTINES.get(npc_id, _default_routine())
	var entries: Array[ScheduleEntry] = []
	for block in routine:
		var room: String = block[2]
		if room == "BED":
			room = bedroom
		entries.append(_make_entry(block[0], block[1], room, block[3]))
	schedule.entries = entries
	return schedule


static func _load_sprite_frames(npc_id: String) -> SpriteFrames:
	var path := "res://resources/sprite_frames/%s.tres" % npc_id
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func _default_routine() -> Array:
	return [
		[0.0, 7.0, "BED", "sleep"], [7.0, 9.0, "kitchen", "breakfast"],
		[9.0, 17.0, "common_room", "day"], [17.0, 19.0, "kitchen", "dinner"],
		[19.0, 24.0, "BED", "evening"],
	]


static func _make_entry(start: float, end: float, room: String, activity: String) -> ScheduleEntry:
	var entry := ScheduleEntry.new()
	entry.start_hour = start
	entry.end_hour = end
	entry.target_room = room
	entry.activity = activity
	return entry


static func create_all_profiles() -> Array[NpcProfile]:
	var profiles: Array[NpcProfile] = []
	for data in NPC_DATA:
		var profile := NpcProfile.new()
		profile.npc_id = data["id"]
		profile.display_name = data["name"]
		profile.personality = data["personality"]
		profile.bedroom = data["bedroom"]
		profile.color = data["color"]
		profile.secrets = PackedStringArray(data["secrets"])
		profile.relationship_seeds = data["seeds"]
		profile.schedule = create_schedule(data["id"], data["bedroom"])
		profile.sprite_frames = _load_sprite_frames(data["id"])
		profiles.append(profile)
	return profiles
