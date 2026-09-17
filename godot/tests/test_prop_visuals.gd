extends SceneTree

## Asset-pass wiring: bedrooms dress themselves with isometric prop sprites via
## PropVisuals, hiding the flat legacy ColorRect furniture (collision stays).
## Location scenes dress via decorate_generic. New UI scenes must load.
##
## NOTE: checks run from _process, not _initialize — in --script runs, child
## _ready() notifications flush on later frames, so inspecting immediately
## after add_child sees pre-ready state.

const DECORATED_SCENES := [
	"res://scenes/dorm/bedroom_1.tscn",
	"res://scenes/dorm/bedroom_2.tscn",
	"res://scenes/dorm/bedroom_3.tscn",
	"res://scenes/dorm/bedroom_4.tscn",
	"res://scenes/dorm/bedroom_5.tscn",
	"res://scenes/dorm/bedroom_6.tscn",
	"res://scenes/dorm/daniel_room.tscn",
	"res://scenes/dorm/hallway.tscn",
	"res://scenes/dorm/kitchen.tscn",
	"res://scenes/dorm/common_room.tscn",
	"res://scenes/dorm/bathroom.tscn",
	"res://scenes/locations/server_room.tscn",
	"res://scenes/locations/library.tscn",
	"res://scenes/locations/hospital.tscn",
	"res://scenes/locations/courtyard.tscn",
	"res://scenes/locations/bar.tscn",
	"res://scenes/locations/campus.tscn",
	"res://scenes/locations/university.tscn",
	"res://scenes/locations/detective_room.tscn",
	"res://scenes/locations/police_station.tscn",
]

const UI_SCENES := [
	"res://scenes/ui/dialogue_panel.tscn",
	"res://scenes/ui/accusation_reveal.tscn",
	"res://scenes/ui/investigation_hud.tscn",
	"res://scenes/debug/asset_gallery.tscn",
]

var _phase := 0
var _scene_idx := 0
var _loc: Node2D = null


func _process(_delta: float) -> bool:
	if _phase == 0:
		_next_scene()
		_phase = 1
		return false
	if _phase == 1:
		# One idle frame so the location's _ready (props, detective, search)
		# has flushed before we inspect.
		_phase = 2
		return false
	var failures := _check_current()
	if _loc != null:
		_loc.queue_free()
		_loc = null
	_scene_idx += 1
	if _scene_idx < DECORATED_SCENES.size():
		_next_scene()
		_phase = 1
		return false
	for path in UI_SCENES:
		failures += _check_ui_scene(path)
	if failures == 0:
		print("PASS: test_prop_visuals")
	quit(failures)
	return true


func _next_scene() -> void:
	_loc = load(DECORATED_SCENES[_scene_idx]).instantiate()
	root.add_child(_loc)


func _props_of(node: Node, out: Array) -> void:
	for ch in node.get_children():
		if ch is Sprite2D and (String(ch.name).begins_with("Prop_") or String(ch.name).begins_with("LocationProp_")):
			out.append(ch)
		_props_of(ch, out)


func _check_current() -> int:
	var failures := 0
	var path: String = DECORATED_SCENES[_scene_idx]
	var props: Array = []
	_props_of(_loc, props)
	if props.is_empty():
		failures += 1
		print("FAIL: %s spawned no prop sprites" % path.get_file())
		return failures
	var floor := _loc.get_node_or_null("Floor") as TileMapLayer
	if floor != null:
		var ts: Vector2i = floor.tile_set.tile_size
		var used: Rect2i = floor.get_used_rect()
		var bounds := Rect2(Vector2(used.position * ts) - Vector2(24, 24),
			Vector2(used.size * ts) + Vector2(48, 48))
		for sp in props:
			var pos: Vector2 = (sp as Node2D).position
			if not bounds.has_point(pos):
				failures += 1
				print("FAIL: %s prop %s at %s outside floor bounds %s" % [path.get_file(), sp.name, pos, bounds])
	if path.get_file().begins_with("bedroom_"):
		for legacy in ["Furniture/Bed/Visual", "Furniture/Desk/Visual", "Furniture/Chair/Visual",
				"Furniture/Bookcase/Visual", "Furniture/Dresser/Visual"]:
			var v := _loc.get_node_or_null(legacy) as CanvasItem
			if v != null and v.visible:
				failures += 1
				print("FAIL: %s legacy visual still visible: %s" % [path.get_file(), legacy])
	if failures == 0:
		print("OK: %s (%d props in bounds)" % [path.get_file(), props.size()])
	return failures


func _check_ui_scene(path: String) -> int:
	var ps: PackedScene = load(path)
	if ps == null:
		print("FAIL: could not LOAD %s" % path)
		return 1
	var inst: Node = ps.instantiate()
	if inst == null:
		print("FAIL: could not INSTANTIATE %s" % path)
		return 1
	print("OK: %s" % path.get_file())
	inst.free()
	return 0
