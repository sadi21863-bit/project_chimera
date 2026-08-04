extends SceneTree

## One-off tool: generates the 6 suspect bedroom scenes (each its own LocationManager location,
## reached via a DoorTrigger from Crestwood Hall). tile_map_data is a packed binary blob
## (impractical to hand-author as .tscn text), so — same approach as build_floor_tiles.gd and
## build_room_walls.gd — these are built programmatically rather than hand-written.
##
## Run headless: godot --headless --path godot -s res://tools/build_bedrooms.gd

const TILESET_PATH := "res://resources/tilesets/floor.tres"
const WALL_COLOR := Color(0.10, 0.09, 0.08, 1.0)
const TILE_SIZE := 20

# local floor rect for every bedroom: (100,100)-(500,400), 400x300, tile-grid aligned
const FLOOR_RECT := Rect2(100, 100, 400, 300)
const WALL_OUTER := Rect2(90, 90, 420, 320)

const BEDROOMS := [
	{"room_id": "bedroom_1", "display": "Alex's Room", "tint": Color(0.95, 0.85, 1.0, 1)},
	{"room_id": "bedroom_2", "display": "Jordan's Room", "tint": Color(1.0, 0.85, 0.85, 1)},
	{"room_id": "bedroom_3", "display": "Sam's Room", "tint": Color(0.82, 0.90, 1.0, 1)},
	{"room_id": "bedroom_4", "display": "Riley's Room", "tint": Color(0.88, 0.82, 1.0, 1)},
	{"room_id": "bedroom_5", "display": "Morgan's Room", "tint": Color(0.85, 1.0, 0.88, 1)},
	{"room_id": "bedroom_6", "display": "Casey's Room", "tint": Color(1.0, 0.92, 0.78, 1)},
	{"room_id": "daniel_room", "display": "Daniel's Room", "tint": Color(0.72, 0.75, 0.80, 1)},
]


func _initialize() -> void:
	for b in BEDROOMS:
		_build_bedroom(b["room_id"], b["display"], b["tint"], "res://scenes/dorm/%s.tscn" % b["room_id"])
	print("BUILD_BEDROOMS_DONE")
	quit()


func _build_bedroom(room_id: String, display_name: String, tint: Color, out_path: String) -> void:
	var root := Node2D.new()
	root.name = "Bedroom"
	root.set_script(load("res://scenes/dorm/bedroom.gd"))
	root.set("room_id", room_id)
	root.set("display_name", display_name)

	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	floor_layer.tile_set = load(TILESET_PATH)
	floor_layer.modulate = tint
	root.add_child(floor_layer)
	floor_layer.owner = root
	var x0 := int(FLOOR_RECT.position.x / TILE_SIZE)
	var y0 := int(FLOOR_RECT.position.y / TILE_SIZE)
	var x1 := int((FLOOR_RECT.position.x + FLOOR_RECT.size.x) / TILE_SIZE)
	var y1 := int((FLOOR_RECT.position.y + FLOOR_RECT.size.y) / TILE_SIZE)
	for x in range(x0, x1):
		for y in range(y0, y1):
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(FLOOR_RECT.position.x + 10, FLOOR_RECT.position.y + 8)
	name_label.text = display_name
	root.add_child(name_label)
	name_label.owner = root

	var navpoly := NavigationPolygon.new()
	var verts := PackedVector2Array([
		FLOOR_RECT.position,
		FLOOR_RECT.position + Vector2(FLOOR_RECT.size.x, 0),
		FLOOR_RECT.position + FLOOR_RECT.size,
		FLOOR_RECT.position + Vector2(0, FLOOR_RECT.size.y),
	])
	navpoly.vertices = verts
	navpoly.polygons = [PackedInt32Array([0, 1, 2, 3])]
	var nav_region := NavigationRegion2D.new()
	nav_region.name = "NavigationRegion2D"
	nav_region.navigation_polygon = navpoly
	root.add_child(nav_region)
	nav_region.owner = root

	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	root.add_child(walls)
	walls.owner = root
	var segments := {
		"North": Rect2(WALL_OUTER.position.x, WALL_OUTER.position.y, WALL_OUTER.size.x, FLOOR_RECT.position.y - WALL_OUTER.position.y),
		"South": Rect2(WALL_OUTER.position.x, FLOOR_RECT.position.y + FLOOR_RECT.size.y, WALL_OUTER.size.x, WALL_OUTER.position.y + WALL_OUTER.size.y - (FLOOR_RECT.position.y + FLOOR_RECT.size.y)),
		"West": Rect2(WALL_OUTER.position.x, FLOOR_RECT.position.y, FLOOR_RECT.position.x - WALL_OUTER.position.x, FLOOR_RECT.size.y),
		"East": Rect2(FLOOR_RECT.position.x + FLOOR_RECT.size.x, FLOOR_RECT.position.y, WALL_OUTER.position.x + WALL_OUTER.size.x - (FLOOR_RECT.position.x + FLOOR_RECT.size.x), FLOOR_RECT.size.y),
	}
	for seg_name in segments:
		var rect: Rect2 = segments[seg_name]
		var center := rect.position + rect.size / 2.0
		var col := CollisionShape2D.new()
		col.name = seg_name
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		col.shape = shape
		col.position = center
		walls.add_child(col)
		col.owner = root
		var visual := ColorRect.new()
		visual.name = seg_name + "Visual"
		visual.color = WALL_COLOR
		visual.position = rect.position
		visual.size = rect.size
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		walls.add_child(visual)
		visual.owner = root

	var exit_door := Area2D.new()
	exit_door.name = "ExitDoor"
	exit_door.set_script(load("res://scripts/player/door_trigger.gd"))
	exit_door.set("dest_id", "dorm")
	exit_door.set("dest_label", "the hallway")
	exit_door.position = Vector2(FLOOR_RECT.position.x + FLOOR_RECT.size.x / 2.0, FLOOR_RECT.position.y + FLOOR_RECT.size.y - 15)
	root.add_child(exit_door)
	exit_door.owner = root
	var exit_shape := CollisionShape2D.new()
	var exit_circle := CircleShape2D.new()
	exit_circle.radius = 20.0
	exit_shape.shape = exit_circle
	exit_door.add_child(exit_shape)
	exit_shape.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, out_path)
	if err != OK:
		printerr("failed to save %s: %d" % [out_path, err])
	else:
		print("built %s (%s)" % [out_path, display_name])
	root.free()
