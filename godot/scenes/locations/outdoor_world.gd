extends Node2D

const WORLD_SIZE := Vector2(2600.0, 900.0)
const AREA_SPAWNS := {
	"campus": Vector2(700.0, 750.0),
	"courtyard": Vector2(1800.0, 360.0),
}

var detective: CharacterBody2D = null
var npcs: Array = []
var logical_area := "campus"

var _campus: Node2D = null
var _courtyard: Node2D = null


func _ready() -> void:
	_campus = $Campus
	_courtyard = $Courtyard
	_open_boundary(_campus, "Walls/East")
	_open_boundary(_courtyard, "Walls/West")
	detective = _campus.get("detective") as CharacterBody2D
	npcs = []
	_configure_camera()


func set_active(active: bool) -> void:
	visible = active
	if detective == null:
		return
	detective.set_control_enabled(active)
	if active:
		var camera := detective.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.make_current()


func set_logical_area(area_id: String) -> void:
	logical_area = area_id


func move_detective_to_area(area_id: String) -> void:
	if detective != null and AREA_SPAWNS.has(area_id):
		detective.global_position = AREA_SPAWNS[area_id]


func set_detective_position(position: Vector2) -> void:
	if detective != null:
		detective.global_position = position


func get_detective_position() -> Vector2:
	return detective.global_position if detective != null else Vector2.ZERO


func get_world_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, WORLD_SIZE)


func _open_boundary(root: Node, path: String) -> void:
	var shape := root.get_node_or_null(path) as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", true)
	var visual := root.get_node_or_null(path + "Visual")
	if visual != null:
		visual.visible = false


func _configure_camera() -> void:
	if detective == null:
		return
	var camera := detective.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.zoom = Vector2.ONE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
