extends SceneTree

## One-off tool: divides Crestwood Hall's open floor with a wall separating the upper area
## (kitchen/hallway/bathroom — still one connected space, not subdivided further) from the
## common room below, with one doorway gap. Simplified down from an original 4-room design
## (separate kitchen/hallway/bathroom rooms) after that ran into a real Godot NavigationPolygon
## limitation: wall holes that touch each other at a shared corner (a T-junction where a vertical
## divider meets a horizontal one) make make_polygons_from_outlines() fail outright ("outlines
## can not overlap vertices or edges... with other outlines"). A single wall with one gap has no
## such junction, sidestepping the issue entirely rather than hand-solving polygon-merging for
## touching holes.
##
## Nav mesh technique: NavigationPolygon.add_outline() + make_polygons_from_outlines() — hand-
## appending separate .polygons/.vertices per convex piece was tried first and never produced a
## connected mesh regardless of exact coordinate matching or deliberate overlap (verified via
## NavigationServer2D.map_get_path returning 0 points across the board). The wall segments here
## touch the outer boundary at both ends (spanning corner-to-corner with a gap in the middle), so
## they're carved as notches directly into the outer boundary's own outline rather than as
## separate hole outlines — a hole that touches the boundary also breaks triangulation
## (degenerate zero-width sliver). Holes need the SAME winding as the outer boundary, not
## opposite, despite that being the more common convention elsewhere — confirmed by Godot's own
## error message when this was gotten backwards.
##
## Run headless: godot --headless --path godot -s res://tools/add_interior_walls.gd

const SCENE_PATH := "res://scenes/dorm/crestwood_hall.tscn"
const WALL_COLOR := Color(0.10, 0.09, 0.08, 1.0)
const T := 10.0  # wall thickness

const DIVIDER_Y := 250.0
const GAP_X0 := 450.0
const GAP_X1 := 650.0
const FLOOR_LEFT := 40.0
const FLOOR_RIGHT := 1240.0
const UPPER_TOP := 40.0
const CORRIDOR_BOTTOM := 680.0

# existing corridor walls from add_corridor.gd — replicated here so the rebuilt nav mesh's outer
# boundary (which now spans the full kitchen-through-corridor area) still accounts for them
const CORRIDOR_LEFT := 60.0
const CORRIDOR_RIGHT := 1160.0
const CORRIDOR_GAP_X0 := 500.0
const CORRIDOR_GAP_X1 := 660.0
const CORRIDOR_WALL_Y := 490.0


func _wall_segments() -> Dictionary:
	return {
		"UpperCommon_West": Rect2(FLOOR_LEFT, DIVIDER_Y - T / 2, GAP_X0 - FLOOR_LEFT, T),
		"UpperCommon_East": Rect2(GAP_X1, DIVIDER_Y - T / 2, FLOOR_RIGHT - GAP_X1, T),
	}


func _corridor_wall_segments() -> Dictionary:
	return {
		"CorridorWest": Rect2(CORRIDOR_LEFT, CORRIDOR_WALL_Y, CORRIDOR_GAP_X0 - CORRIDOR_LEFT, T),
		"CorridorEast": Rect2(CORRIDOR_GAP_X1, CORRIDOR_WALL_Y, CORRIDOR_RIGHT - CORRIDOR_GAP_X1, T),
	}


func _initialize() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	var root := packed.instantiate()

	if root.has_node("InteriorWalls"):
		root.get_node("InteriorWalls").free()

	_add_walls(root)
	_rebuild_nav_mesh(root)

	var new_packed := PackedScene.new()
	new_packed.pack(root)
	var err := ResourceSaver.save(new_packed, SCENE_PATH)
	if err != OK:
		printerr("failed to save %s: %d" % [SCENE_PATH, err])
	else:
		print("added interior walls to %s" % SCENE_PATH)
	root.free()
	print("ADD_INTERIOR_WALLS_DONE")
	quit()


func _add_walls(root: Node) -> void:
	var walls := StaticBody2D.new()
	walls.name = "InteriorWalls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	root.add_child(walls)
	walls.owner = root

	for seg_name in _wall_segments():
		var rect: Rect2 = _wall_segments()[seg_name]
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


func _rect_outline_cw(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position, rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size, rect.position + Vector2(0, rect.size.y),
	])


func _outer_boundary_with_notches() -> PackedVector2Array:
	var s := _wall_segments()
	var west: Rect2 = s["UpperCommon_West"]
	var east: Rect2 = s["UpperCommon_East"]
	return PackedVector2Array([
		Vector2(FLOOR_LEFT, UPPER_TOP),
		Vector2(FLOOR_RIGHT, UPPER_TOP),
		Vector2(FLOOR_RIGHT, east.position.y),
		Vector2(east.position.x, east.position.y), Vector2(east.position.x, east.end.y), Vector2(FLOOR_RIGHT, east.end.y),
		Vector2(FLOOR_RIGHT, CORRIDOR_BOTTOM),
		Vector2(FLOOR_LEFT, CORRIDOR_BOTTOM),
		Vector2(FLOOR_LEFT, west.end.y),
		Vector2(west.end.x, west.end.y), Vector2(west.end.x, west.position.y), Vector2(FLOOR_LEFT, west.position.y),
	])


func _rebuild_nav_mesh(root: Node) -> void:
	var nav_region: NavigationRegion2D = root.get_node("NavigationRegion2D")
	var navpoly := NavigationPolygon.new()

	navpoly.add_outline(_outer_boundary_with_notches())
	# the corridor walls don't touch the outer boundary (they start/end short of it), so they
	# work fine as plain holes, same winding as the outer outline
	for seg_name in _corridor_wall_segments():
		navpoly.add_outline(_rect_outline_cw(_corridor_wall_segments()[seg_name]))

	navpoly.make_polygons_from_outlines()
	print("nav mesh polygons after triangulation: ", navpoly.polygons.size())
	nav_region.navigation_polygon = navpoly
