extends Node2D

## The outdoor campus hub: connects Crestwood Hall, the University, and the Police Station via
## a walkable street instead of only the fast-travel map. Mirrors the "exposes detective + npcs"
## contract every location scene follows (see detective_room.gd's comment).

const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")

var detective: CharacterBody2D = null
var npcs: Array = []


func _ready() -> void:
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	detective.global_position = Vector2(700, 750)
