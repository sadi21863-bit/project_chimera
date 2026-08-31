extends Node2D

## A minimal self-contained location: spawns the detective on a small nav region so travel +
## movement work. Mirrors the dorm's "exposes detective + npcs" contract.

const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")

@onready var _nav_region: NavigationRegion2D = $NavigationRegion2D

var detective: CharacterBody2D = null
var npcs: Array = []

const SPOT_OFFSETS := [
	Vector2(200, 200),
	Vector2(400, 200),
	Vector2(200, 350),
	Vector2(400, 350),
]


func _ready() -> void:
	_spawn_search_points()
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	detective.global_position = Vector2(400, 300)


func _spawn_search_points() -> void:
	var index := 0
	for pid in SearchData.point_ids():
		var data: Dictionary = SearchData.point(pid)
		if str(data.get("room", "")) != "detective_room":
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
		sp.position = SPOT_OFFSETS[index % SPOT_OFFSETS.size()]
		index += 1
		add_child(sp)
