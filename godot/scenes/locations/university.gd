extends Node2D

## The victim's double-life thread: a dean NPC with lore-only interrogation topics (no
## CaseData/accusation arc — see InterrogationData.SUSPECTS["dean"]). No schedule: the dean has
## no bedroom, they're always found in their office.

const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")
const NPC_SCENE := preload("res://scenes/npcs/npc.tscn")

@onready var _nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var _markers: Node2D = $RoomMarkers

var detective: CharacterBody2D = null
var npcs: Array = []
var room_markers: Dictionary = {}


func _ready() -> void:
	_collect_markers()
	_spawn_dean()
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	detective.global_position = Vector2(400, 300)


func _collect_markers() -> void:
	for child in _markers.get_children():
		if child is Marker2D:
			room_markers[child.name] = child


func _spawn_dean() -> void:
	var profile := NpcProfile.new()
	profile.npc_id = "dean"
	profile.display_name = "Dean Whitfield"
	profile.personality = "University dean. Measured, careful with words, protective of the institution's reputation."
	profile.bedroom = "office"
	profile.color = Color("#8899aa")
	profile.secrets = PackedStringArray(["Knew about Daniel's double life", "Pressured to keep it quiet"])
	if ResourceLoader.exists("res://resources/sprite_frames/dean.tres"):
		profile.sprite_frames = load("res://resources/sprite_frames/dean.tres")
	var npc: DormNpc = NPC_SCENE.instantiate()
	npc.profile = profile
	add_child(npc)
	npcs.append(npc)
	npc.setup(profile, room_markers, npcs)
	_add_talk_area(npc)


func _add_talk_area(npc: Node) -> void:
	var talk := NpcInteractable.new()
	talk.npc_name = npc.display_name
	talk.npc_id = npc.npc_id
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	talk.add_child(shape)
	npc.add_child(talk)
