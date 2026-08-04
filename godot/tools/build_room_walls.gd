extends SceneTree

## One-off tool: adds perimeter wall collision (+ a simple visual frame) to the four location
## scenes, so the player-controlled Detective (a plain WASD CharacterBody2D that never reads
## NavigationPolygon) can no longer walk off the edge of a room's floor. NPCs already stay on
## the nav mesh for pathfinding, but the player had zero physical boundary until now.
##
## Run headless: godot --headless --path godot -s res://tools/build_room_walls.gd

const WALL_COLOR := Color(0.10, 0.09, 0.08, 1.0)

# Each location: the wall ring's outer and inner rectangles. The player-walkable interior is the
# inner rect; the wall band fills the gap between inner and outer.
const LOCATIONS := [
	{
		"scene": "res://scenes/dorm/crestwood_hall.tscn",
		"outer": Rect2(0, 0, 1280, 720),
		"inner": Rect2(40, 40, 1200, 640),  # matches the existing NavigationPolygon inset
	},
	{
		"scene": "res://scenes/locations/detective_room.tscn",
		"outer": Rect2(110, 110, 580, 380),
		"inner": Rect2(120, 120, 560, 360),
	},
	{
		"scene": "res://scenes/locations/police_station.tscn",
		"outer": Rect2(110, 110, 580, 380),
		"inner": Rect2(120, 120, 560, 360),
	},
	{
		"scene": "res://scenes/locations/university.tscn",
		"outer": Rect2(110, 110, 580, 380),
		"inner": Rect2(120, 120, 560, 360),
	},
]


func _initialize() -> void:
	for loc in LOCATIONS:
		_migrate_scene(loc)
	print("BUILD_ROOM_WALLS_DONE")
	quit()


func _migrate_scene(loc: Dictionary) -> void:
	var packed: PackedScene = load(loc["scene"])
	var root := packed.instantiate()

	if root.has_node("Walls"):
		root.get_node("Walls").free()

	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	root.add_child(walls)
	walls.owner = root

	var outer: Rect2 = loc["outer"]
	var inner: Rect2 = loc["inner"]
	var segments := {
		"North": Rect2(outer.position.x, outer.position.y, outer.size.x, inner.position.y - outer.position.y),
		"South": Rect2(outer.position.x, inner.position.y + inner.size.y, outer.size.x, outer.position.y + outer.size.y - (inner.position.y + inner.size.y)),
		"West": Rect2(outer.position.x, inner.position.y, inner.position.x - outer.position.x, inner.size.y),
		"East": Rect2(inner.position.x + inner.size.x, inner.position.y, outer.position.x + outer.size.x - (inner.position.x + inner.size.x), inner.size.y),
	}

	for seg_name in segments:
		var rect: Rect2 = segments[seg_name]
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
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

	var new_packed := PackedScene.new()
	new_packed.pack(root)
	var err := ResourceSaver.save(new_packed, loc["scene"])
	if err != OK:
		printerr("failed to save %s: %d" % [loc["scene"], err])
	else:
		print("added walls to %s" % loc["scene"])
	root.free()
