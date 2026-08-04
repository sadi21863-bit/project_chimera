extends SceneTree

## One-off tool: builds the outdoor campus scene from ONE composed backdrop image (Blender
## render of a small city block assembled from Kenney's Starter Kit City Builder — properly
## textured/colored GLTF tiles: roads, 3 building variants, grass+trees — see
## godot/tools/compose_campus.py in scratch, not committed here since it's a one-off compositor
## script, not a repo tool) rather than individually-placed flat sprites. Replaced the earlier
## version of this script (scattered building sprites on a procedural grass/road TileMapLayer)
## after user feedback that the flat, mostly-untextured building renders read as unfinished
## placeholder art.
##
## Door trigger positions below are hand-measured against the backdrop image (1600x1000,
## displayed at 0.875 scale = 1400x875) — approximate centers of each visible building.
##
## Run headless: godot --headless --path godot -s res://tools/build_campus.gd

const OUT_PATH := "res://scenes/locations/campus.tscn"
const BACKDROP_TEX := "res://assets/buildings/campus_backdrop.png"
const BACKDROP_SCALE := 0.875  # 1600x1000 source -> 1400x875 displayed
const WALL_COLOR := Color(0.10, 0.09, 0.08, 1.0)

const OUTER := Rect2(0, 0, 1400, 900)
const INNER := Rect2(40, 40, 1320, 820)
const BACKDROP_CENTER := Vector2(700, 450)

const BUILDINGS := [
	{"id": "university", "label": "University", "pos": Vector2(437, 200)},
	{"id": "police_station", "label": "Police Station", "pos": Vector2(437, 590)},
	{"id": "dorm", "label": "Crestwood Hall", "pos": Vector2(962, 590)},
]


func _initialize() -> void:
	var root := Node2D.new()
	root.name = "Campus"
	root.set_script(load("res://scenes/locations/campus.gd"))

	_add_backdrop(root)
	for b in BUILDINGS:
		_add_door(root, b)
	_add_nav_region(root)
	_add_walls(root)

	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, OUT_PATH)
	if err != OK:
		printerr("failed to save %s: %d" % [OUT_PATH, err])
	else:
		print("built %s" % OUT_PATH)
	root.free()
	print("BUILD_CAMPUS_DONE")
	quit()


func _add_backdrop(root: Node) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Backdrop"
	sprite.texture = load(BACKDROP_TEX)
	sprite.scale = Vector2(BACKDROP_SCALE, BACKDROP_SCALE)
	sprite.position = BACKDROP_CENTER
	root.add_child(sprite)
	sprite.owner = root


func _add_door(root: Node, b: Dictionary) -> void:
	var label := Label.new()
	label.name = "Label_%s" % b["id"]
	label.text = b["label"]
	label.position = b["pos"] + Vector2(-60, -110)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(label)
	label.owner = root

	var door := Area2D.new()
	door.name = "DoorTo%s" % b["id"].capitalize().replace(" ", "").replace("_", "")
	door.set_script(load("res://scripts/player/door_trigger.gd"))
	door.set("dest_id", b["id"])
	door.set("dest_label", b["label"])
	door.position = b["pos"]
	root.add_child(door)
	door.owner = root
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	door.add_child(shape)
	shape.owner = root


func _add_nav_region(root: Node) -> void:
	var navpoly := NavigationPolygon.new()
	var verts := PackedVector2Array([
		INNER.position, INNER.position + Vector2(INNER.size.x, 0),
		INNER.position + INNER.size, INNER.position + Vector2(0, INNER.size.y),
	])
	navpoly.vertices = verts
	navpoly.polygons = [PackedInt32Array([0, 1, 2, 3])]
	navpoly.outlines = [verts]
	var nav_region := NavigationRegion2D.new()
	nav_region.name = "NavigationRegion2D"
	nav_region.navigation_polygon = navpoly
	root.add_child(nav_region)
	nav_region.owner = root


func _add_walls(root: Node) -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	root.add_child(walls)
	walls.owner = root
	var segments := {
		"North": Rect2(OUTER.position.x, OUTER.position.y, OUTER.size.x, INNER.position.y - OUTER.position.y),
		"South": Rect2(OUTER.position.x, INNER.position.y + INNER.size.y, OUTER.size.x, OUTER.position.y + OUTER.size.y - (INNER.position.y + INNER.size.y)),
		"West": Rect2(OUTER.position.x, INNER.position.y, INNER.position.x - OUTER.position.x, INNER.size.y),
		"East": Rect2(INNER.position.x + INNER.size.x, INNER.position.y, OUTER.position.x + OUTER.size.x - (INNER.position.x + INNER.size.x), INNER.size.y),
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
