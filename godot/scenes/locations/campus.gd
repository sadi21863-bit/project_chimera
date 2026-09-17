extends Node2D

## The outdoor campus hub: connects Crestwood Hall, the University, and the Police Station via
## a walkable street instead of only the fast-travel map. Mirrors the "exposes detective + npcs"
## contract every location scene follows (see detective_room.gd's comment).

const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")
const PROP_VISUALS := preload("res://scripts/ui/prop_visuals.gd")

var detective: CharacterBody2D = null
var npcs: Array = []

const SPOT_OFFSETS := [
	Vector2(400, 200),
	Vector2(800, 200),
	Vector2(400, 600),
	Vector2(800, 600),
]


func _ready() -> void:
	_spawn_search_points()
	PROP_VISUALS.decorate_generic(self, "campus")
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	detective.global_position = Vector2(700, 750)


func _spawn_search_points() -> void:
	var index := 0
	for pid in SearchData.point_ids():
		var data: Dictionary = SearchData.point(pid)
		if str(data.get("room", "")) != "campus":
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
