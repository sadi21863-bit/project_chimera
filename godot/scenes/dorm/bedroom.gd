extends Node2D

## Shared script for every suspect bedroom (Alex/Jordan/Sam/Riley/Morgan/Casey) plus Daniel's
## room. Each bedroom is its own top-level LocationManager location, reached via a DoorTrigger
## from Crestwood Hall. room_id matches the existing AccessData/SearchData room key
## ("bedroom_1" etc.) so no new suspect->room translation table is needed.
##
## Spawns its own Detective — every location scene owns this contract (see detective_room.gd's
## comment: "mirrors the dorm's 'exposes detective + npcs' contract") since main.gd rebuilds the
## whole scene tree on every location swap rather than reparenting a persistent player node.
##
## Sneaking/trespassing: Crestwood Hall's own _check_sneaking() only runs while its scene is
## loaded, so it stops applying the moment the detective steps into a separate bedroom scene.
## Bedrooms have no live NPCs of their own to check proximity/vision against, so "is the owner
## home" is derived from their authored schedule for the current hour instead of a live NPC
## position — the same schedule data that drives their actual movement, just consulted directly.

const ACCESS_DATA := preload("res://scripts/access/access_data.gd")
const CATCH_MODEL := preload("res://scripts/access/catch_model.gd")
const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")
const PROP_VISUALS := preload("res://scripts/ui/prop_visuals.gd")
const SPOT_OFFSETS := [Vector2(300, 220), Vector2(220, 300), Vector2(380, 300), Vector2(300, 350)]

@export var room_id := ""
@export var display_name := ""

var detective: CharacterBody2D = null
var npcs: Array = []
var _catch_meter := 0.0


func _ready() -> void:
	_spawn_search_points()
	_spawn_detective()
	# Asset-pass prop dressing: sub-rooms share the generic dresser (fitted to
	# their small footprints); bedrooms use the bedroom dresser. Legacy flat
	# ColorRect furniture stays as collision, hidden under the sprites.
	if room_id in ["hallway", "kitchen", "common_room", "bathroom"]:
		PROP_VISUALS.decorate_generic(self, room_id)
	else:
		PROP_VISUALS.decorate_bedroom(self, room_id)


func _spawn_detective() -> void:
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	# Prefer the scene's own PlayerSpawn marker (generated rooms place it inside
	# their walls); fall back to daniel_room's legacy center position.
	var spawn := Vector2(300, 380)
	var marker := get_node_or_null("PlayerSpawn") as Marker2D
	if marker != null:
		spawn = marker.position
	detective.global_position = spawn


func _spawn_search_points() -> void:
	# Collect existing point_ids to avoid duplicates from static SearchPoints nodes
	var existing: Dictionary = {}
	for child in get_children():
		if child is SearchPoint:
			existing[child.point_id] = true
		elif child.name == "SearchPoints":
			for sp_child in child.get_children():
				if sp_child is SearchPoint:
					existing[sp_child.point_id] = true
				elif sp_child.has_method("get") and "point_id" in sp_child:
					existing[str(sp_child.get("point_id"))] = true
	var index := 0
	for pid in SearchData.point_ids():
		if existing.has(pid):
			continue
		var data: Dictionary = SearchData.point(pid)
		if str(data.get("room", "")) != room_id:
			continue
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
		sp.global_position = SPOT_OFFSETS[index % SPOT_OFFSETS.size()]
		index += 1


func _process(delta: float) -> void:
	_check_sneaking(delta)


func _check_sneaking(delta: float) -> void:
	if detective == null:
		return
	var catch_model: String = str(Difficulty.get_value("catch_model", "off"))
	if catch_model == "off":
		return
	var area: Dictionary = ACCESS_DATA.area(room_id)
	if area.is_empty():
		return
	var owner_id: String = str(area.get("owner", ""))
	var owner_present := _is_owner_present(owner_id)
	var restricted: bool = ACCESS_DATA.is_restricted(room_id, Scheduler.get_hour(), owner_present)
	if not restricted:
		_catch_meter = 0.0
		return
	if catch_model == "meter":
		_catch_meter = CATCH_MODEL.update_meter(_catch_meter, restricted, delta)
		if _catch_meter >= 1.0:
			_on_caught(owner_id)
	else:  # vision (hard/extreme): a small room means being caught is immediate, not cone-based
		if owner_present:
			_on_caught(owner_id)


func _is_owner_present(owner_id: String) -> bool:
	if owner_id.is_empty():
		return false
	var schedule: NpcSchedule = NpcProfileFactory.create_schedule(owner_id, room_id)
	var entry := schedule.get_entry_for_hour(Scheduler.get_hour())
	return entry != null and entry.target_room == room_id


func _on_caught(owner_id: String) -> void:
	_catch_meter = 0.0
	if owner_id != "":
		Standing.adjust(owner_id, -0.2)
	var msg := "Caught trespassing in %s's room!" % owner_id if owner_id != "" else "Caught trespassing!"
	EventLog.log_action(msg, "caught")
	Consequences.record_catch(Scheduler.get_hour())
	Effects.fade_transition(func(): LocationManager.travel("dorm"))
