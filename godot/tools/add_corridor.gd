extends SceneTree

## One-off tool: adds a walled corridor strip along the bedroom row in Crestwood Hall, so the 7
## bedroom doors read as doors off a real hallway instead of floating triggers in open floor
## space. One gap in the corridor's north wall connects it back to the rest of the dorm. The
## corridor's south side reuses the building's existing outer perimeter wall (from
## build_room_walls.gd) rather than adding a redundant second wall.
##
## Run headless: godot --headless --path godot -s res://tools/add_corridor.gd

const SCENE_PATH := "res://scenes/dorm/crestwood_hall.tscn"
const WALL_COLOR := Color(0.10, 0.09, 0.08, 1.0)
const WALL_Y := 490.0
const WALL_THICKNESS := 10.0
const GAP_START := 500.0
const GAP_END := 660.0
const CORRIDOR_LEFT := 60.0
const CORRIDOR_RIGHT := 1160.0


func _initialize() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	var root := packed.instantiate()

	if root.has_node("CorridorWalls"):
		root.get_node("CorridorWalls").free()

	_rebuild_nav_mesh(root)

	var walls := StaticBody2D.new()
	walls.name = "CorridorWalls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	root.add_child(walls)
	walls.owner = root

	var segments := {
		"West": Rect2(CORRIDOR_LEFT, WALL_Y, GAP_START - CORRIDOR_LEFT, WALL_THICKNESS),
		"East": Rect2(GAP_END, WALL_Y, CORRIDOR_RIGHT - GAP_END, WALL_THICKNESS),
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

	var new_packed := PackedScene.new()
	new_packed.pack(root)
	var err := ResourceSaver.save(new_packed, SCENE_PATH)
	if err != OK:
		printerr("failed to save %s: %d" % [SCENE_PATH, err])
	else:
		print("added corridor walls to %s" % SCENE_PATH)
	root.free()
	print("ADD_CORRIDOR_DONE")
	quit()


## NPCs path via NavigationAgent2D over this mesh, not the new wall's physics collision — without
## this, a scheduled NPC walking to a bedroom marker would path straight into the new wall band
## and get physically stuck by move_and_slide(). Splits the walkable area into three rectangles
## (above the wall band / the door gap / the corridor below) so pathfinding routes through the gap.
func _rebuild_nav_mesh(root: Node) -> void:
	var nav_region: NavigationRegion2D = root.get_node("NavigationRegion2D")
	var navpoly := NavigationPolygon.new()
	var verts := PackedVector2Array([
		Vector2(40, 40), Vector2(1240, 40), Vector2(1240, WALL_Y), Vector2(40, WALL_Y),  # 0-3 upper
		Vector2(GAP_START, WALL_Y), Vector2(GAP_END, WALL_Y),
		Vector2(GAP_END, WALL_Y + WALL_THICKNESS), Vector2(GAP_START, WALL_Y + WALL_THICKNESS),  # 4-7 gap
		Vector2(40, WALL_Y + WALL_THICKNESS), Vector2(1240, WALL_Y + WALL_THICKNESS),
		Vector2(1240, 680), Vector2(40, 680),  # 8-11 corridor
	])
	navpoly.vertices = verts
	navpoly.polygons = [
		PackedInt32Array([0, 1, 2, 3]),
		PackedInt32Array([4, 5, 6, 7]),
		PackedInt32Array([8, 9, 10, 11]),
	]
	navpoly.outlines = [
		PackedVector2Array([verts[0], verts[1], verts[2], verts[3]]),
		PackedVector2Array([verts[4], verts[5], verts[6], verts[7]]),
		PackedVector2Array([verts[8], verts[9], verts[10], verts[11]]),
	]
	nav_region.navigation_polygon = navpoly
