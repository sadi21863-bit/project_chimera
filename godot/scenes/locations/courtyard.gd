extends Node2D

## Courtyard — outdoor area where Casey sketches and the ghost is sighted.

var npcs: Array = []
var detective: CharacterBody2D = null

const PROP_VISUALS := preload("res://scripts/ui/prop_visuals.gd")

const SPOT_OFFSETS := [
	Vector2(400, 300),
	Vector2(300, 400),
	Vector2(500, 400),
	Vector2(400, 450),
]


func _ready() -> void:
	_spawn_search_points()
	PROP_VISUALS.decorate_generic(self, "courtyard")


func _spawn_search_points() -> void:
	var index := 0
	for pid in SearchData.point_ids():
		var data: Dictionary = SearchData.point(pid)
		if str(data.get("room", "")) != "courtyard":
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
