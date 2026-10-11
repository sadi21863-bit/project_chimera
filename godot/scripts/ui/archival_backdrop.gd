extends Node2D
class_name ArchivalBackdrop

## Paints a pre-rendered Archival Cutaway floor plan behind a room and hides the
## legacy tilemap and wall ColorRects. Collision, navigation, doors, markers and
## NPCs are untouched, so the room keeps behaving exactly as before.

const DAY_TEXTURE := "res://assets/prototypes/archival_dorm_backdrop_day_inked.png"
const NIGHT_TEXTURE := "res://assets/prototypes/archival_dorm_backdrop_night_inked.png"

const DAY_START := 6.0
const DAY_END := 19.0

const LEGACY_VISUALS := [
	"Floor/TileBase",
	"Walls/NorthVisual",
	"Walls/SouthVisual",
	"Walls/WestVisual",
	"Walls/EastVisual",
	"CorridorWalls/WestVisual",
	"CorridorWalls/EastVisual",
	"InteriorWalls/UpperCommon_WestVisual",
	"InteriorWalls/UpperCommon_EastVisual",
]

var _day_sprite: Sprite2D
var _night_sprite: Sprite2D
var _night := false


func _ready() -> void:
	z_index = -100
	_day_sprite = _make_sprite(DAY_TEXTURE)
	_night_sprite = _make_sprite(NIGHT_TEXTURE)
	_hide_legacy_visuals()
	_night = is_night(_current_hour())
	set_night(_night)
	var scheduler := _scheduler()
	if scheduler != null and not scheduler.time_changed.is_connected(_on_time_changed):
		scheduler.time_changed.connect(_on_time_changed)


func _make_sprite(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = path.get_file().get_basename().to_pascal_case()
	sprite.centered = false
	sprite.flip_v = true
	sprite.position = Vector2.ZERO
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		push_warning("ArchivalBackdrop missing texture: %s" % path)
	add_child(sprite)
	return sprite


func _hide_legacy_visuals() -> void:
	for path in LEGACY_VISUALS:
		var node := get_node_or_null(NodePath(".." + "/" + path))
		if node is CanvasItem:
			(node as CanvasItem).visible = false


func _scheduler() -> Node:
	return get_node_or_null("/root/Scheduler")


func _current_hour() -> float:
	var scheduler := _scheduler()
	if scheduler == null:
		return 12.0
	return float(scheduler.get_hour())


func _on_time_changed(hour: float, _minute: int, _day: int) -> void:
	set_night(is_night(hour))


static func is_night(hour: float) -> bool:
	var wrapped := fmod(hour, 24.0)
	return wrapped < DAY_START or wrapped >= DAY_END


func set_night(night: bool) -> void:
	_night = night
	if _day_sprite:
		_day_sprite.visible = not night
	if _night_sprite:
		_night_sprite.visible = night


func is_night_visible() -> bool:
	return _night


func has_texture() -> bool:
	return _day_sprite != null and _day_sprite.texture != null


func covers_room() -> bool:
	if _day_sprite == null or _day_sprite.texture == null:
		return false
	var size := _day_sprite.texture.get_size()
	return size.x >= 1280.0 and size.y >= 720.0
