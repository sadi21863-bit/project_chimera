extends Node2D

## A minimal self-contained location: spawns the detective on a small nav region so travel +
## movement work. Mirrors the dorm's "exposes detective + npcs" contract.

const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")
const PROP_VISUALS := preload("res://scripts/ui/prop_visuals.gd")

@onready var _nav_region: NavigationRegion2D = $NavigationRegion2D

var detective: CharacterBody2D = null
var npcs: Array = []


func _ready() -> void:
	PROP_VISUALS.decorate_generic(self, "police_station")
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	detective.global_position = Vector2(400, 300)
