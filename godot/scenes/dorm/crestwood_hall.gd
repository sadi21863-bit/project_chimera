extends Node2D

## Crestwood Hall dorm layout with room markers and navigation.

signal npcs_ready(npcs: Array)
signal detective_ready(detective)

const NPC_SCENE := preload("res://scenes/npcs/npc.tscn")
const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")
const SUSPICION_WATCHER := preload("res://scenes/suspicion_watcher.gd")
const EAVESDROP_WATCHER := preload("res://scenes/eavesdrop_watcher.gd")
const ACCESS_DATA := preload("res://scripts/access/access_data.gd")
const CATCH_MODEL := preload("res://scripts/access/catch_model.gd")
const AMBIENT_STREAM_PATH := "res://assets/audio/ambient_dorm.ogg"
const ROOM_RADIUS := 90.0
const VISION_CONE_RANGE := 140.0
const VISION_CONE_HALF_ANGLE := 45.0
const VISION_PROXIMITY_RANGE := 40.0

@onready var _markers: Node2D = $RoomMarkers
@onready var _npc_container: Node2D = $NPCs
@onready var _nav_region: NavigationRegion2D = $NavigationRegion2D

var room_markers: Dictionary = {}
var npcs: Array = []
var detective: CharacterBody2D = null
var _suspicion_fired: Dictionary = {}
var _conversation_fired: Dictionary = {}
var _catch_meter := 0.0


func _process(delta: float) -> void:
	if detective == null or npcs.is_empty():
		return
	_check_suspicion()
	_check_eavesdrop()
	_check_sneaking(delta)


func _room_at(pos: Vector2) -> String:
	for room_id in room_markers:
		var marker: Marker2D = room_markers[room_id]
		if pos.distance_to(marker.global_position) <= ROOM_RADIUS:
			return room_id
	return "hallway"


func _check_sneaking(delta: float) -> void:
	var catch_model: String = str(Difficulty.get_value("catch_model", "off"))
	if catch_model == "off":
		return
	var area_id: String = _room_at(detective.global_position)
	var area: Dictionary = ACCESS_DATA.area(area_id)
	if area.is_empty():
		_catch_meter = 0.0
		return
	var owner_id: String = str(area.get("owner", ""))
	var owner_present := false
	for npc in npcs:
		if npc.npc_id == owner_id and npc.current_room == area_id:
			owner_present = true
			break
	var restricted: bool = ACCESS_DATA.is_restricted(area_id, Scheduler.get_hour(), owner_present)
	if catch_model == "meter":
		_catch_meter = CATCH_MODEL.update_meter(_catch_meter, restricted, delta)
		if _catch_meter >= 1.0:
			_on_caught(owner_id)
	elif catch_model == "vision":
		var states: Array = []
		for npc in npcs:
			var facing: Vector2 = npc.velocity.normalized() if npc.velocity.length() > 0.01 else Vector2.DOWN
			states.append({"position": npc.global_position, "facing": facing})
		if CATCH_MODEL.check_vision(restricted, detective.global_position, states,
				VISION_CONE_RANGE, VISION_CONE_HALF_ANGLE, VISION_PROXIMITY_RANGE):
			_on_caught(owner_id)


func _on_caught(owner_id: String) -> void:
	_catch_meter = 0.0
	if owner_id != "":
		Standing.adjust(owner_id, -0.2)
	if room_markers.has("hallway"):
		detective.global_position = room_markers["hallway"].global_position
	var msg := "Caught trespassing in %s's room!" % owner_id if owner_id != "" else "Caught trespassing!"
	EventLog.log_action(msg, "caught")
	Consequences.record_catch(Scheduler.get_hour())


func _check_suspicion() -> void:
	var npc_positions: Dictionary = {}
	for npc in npcs:
		npc_positions[npc.npc_id] = npc.global_position
	var caught: Array = SUSPICION_WATCHER.check(
		SuspicionData.moments(), Scheduler.get_hour(), detective.global_position,
		npc_positions, _suspicion_fired, 56.0)
	for mid in caught:
		_suspicion_fired[mid] = true
		for m in SuspicionData.moments():
			if str(m["id"]) == mid:
				var clue_id: String = str(m["reveal_clue"])
				if Investigation.discover_clue(clue_id):
					EventLog.log_action("You witnessed: %s" % str(m["description"]), "witness")


func _check_eavesdrop() -> void:
	var npc_positions: Dictionary = {}
	for npc in npcs:
		npc_positions[npc.npc_id] = npc.global_position
	var heard: Array = EAVESDROP_WATCHER.check(
		GossipData.conversations(), npc_positions, detective.global_position,
		_conversation_fired, 90.0, 120.0)
	for cid in heard:
		_conversation_fired[cid] = true
		for convo in GossipData.conversations():
			if str(convo["id"]) == cid:
				var clue: String = str(convo["reveal_clue"])
				if clue != "" and Investigation.discover_clue(clue):
					EventLog.log_action("You overheard something revealing...", "overheard")
				_play_conversation(convo)


func _play_conversation(convo: Dictionary) -> void:
	for line in convo["lines"]:
		var speaker_id: String = str(line["speaker"])
		var speaker_name: String = _npc_display_name(speaker_id)
		DialogSystem.show_dialogue(speaker_name, str(line["text"]))
		EventLog.log_action("[Overheard] %s: %s" % [speaker_name, str(line["text"])], "overheard")
		await get_tree().create_timer(2.5).timeout


func _npc_display_name(npc_id: String) -> String:
	for npc in npcs:
		if npc.npc_id == npc_id:
			return npc.display_name
	return npc_id


func _ready() -> void:
	_collect_markers()
	_spawn_npcs()
	_setup_ambient_audio()
	_spawn_detective()
	_spawn_clue_hotspots()
	_spawn_search_points()


func _collect_markers() -> void:
	for child in _markers.get_children():
		if child is Marker2D:
			room_markers[child.name] = child


func _spawn_npcs() -> void:
	var profiles := NpcProfileFactory.create_all_profiles()
	for p in profiles:
		var npc: DormNpc = NPC_SCENE.instantiate()
		npc.profile = p
		_npc_container.add_child(npc)
		npcs.append(npc)
	for npc in npcs:
		npc.setup(npc.profile, room_markers, npcs)
		_add_talk_area(npc)
	npcs_ready.emit(npcs)


func _add_talk_area(npc: Node) -> void:
	# An Interactable that follows the NPC so the detective can "talk" (placeholder until Plan C).
	var talk := NpcInteractable.new()
	talk.npc_name = npc.display_name
	talk.npc_id = npc.npc_id
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	talk.add_child(shape)
	npc.add_child(talk)


func _spawn_detective() -> void:
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	var spawn := Vector2(450, 120)
	if room_markers.has("hallway"):
		var marker: Marker2D = room_markers["hallway"]
		spawn = marker.global_position
	detective.global_position = spawn
	detective_ready.emit(detective)


func _spawn_clue_hotspots() -> void:
	# Every authored clue becomes an examinable hotspot, placed in its room (CaseData, Plan B).
	for clue_id in CaseData.CLUES:
		var data: Dictionary = CaseData.CLUES[clue_id]
		var hotspot := ClueHotspot.new()
		hotspot.clue_id = clue_id
		hotspot.clue_title = str(data["title"])
		hotspot.clue_description = str(data.get("truth", ""))
		hotspot.prompt_text = "Examine"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		hotspot.add_child(shape)
		add_child(hotspot)
		var room_id: String = str(data["room"])
		if room_markers.has(room_id):
			var marker: Marker2D = room_markers[room_id]
			hotspot.global_position = marker.global_position


func _spawn_search_points() -> void:
	# Detailed-examination objects (look under / dig / lift), placed near their room marker.
	for pid in SearchData.point_ids():
		var data: Dictionary = SearchData.point(pid)
		var point_room: String = str(data.get("room", ""))
		if point_room.begins_with("bedroom_"):
			continue  # these now live inside each suspect's own bedroom scene
		var sp := SearchPoint.new()
		sp.point_id = pid
		sp.label = str(data.get("label", pid))
		sp.prompt_text = "Search"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		sp.add_child(shape)
		add_child(sp)
		var room_id: String = str(data.get("room", ""))
		if room_markers.has(room_id):
			var marker: Marker2D = room_markers[room_id]
			sp.global_position = marker.global_position + Vector2(0, -28)


func _setup_ambient_audio() -> void:
	var ambient := AudioStreamPlayer.new()
	ambient.name = "AmbientLoop"
	ambient.volume_db = -20.0
	ambient.bus = "Master"
	add_child(ambient)
	if ResourceLoader.exists(AMBIENT_STREAM_PATH):
		var stream: AudioStream = load(AMBIENT_STREAM_PATH)
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		ambient.stream = stream
		EventLog.log_action("Ambient dorm loop playing", "system")
	else:
		ambient.stream = _make_procedural_ambient()
		EventLog.log_action("Ambient dorm file missing — using procedural hum fallback", "system")
	ambient.play()


func _make_procedural_ambient() -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := mix_rate * 4
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var smoothed := 0.0
	for i in range(sample_count):
		smoothed = lerpf(smoothed, randf_range(-1.0, 1.0), 0.05)
		data.encode_s16(i * 2, int(clampf(smoothed, -1.0, 1.0) * 4000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = sample_count
	stream.data = data
	return stream


func get_save_data() -> Dictionary:
	var npc_data: Array = []
	for npc in npcs:
		npc_data.append(npc.get_save_data())
	return {"npcs": npc_data}


func load_save_data(data: Dictionary) -> void:
	for i in range(mini(npcs.size(), data.get("npcs", []).size())):
		npcs[i].load_save_data(data["npcs"][i])
