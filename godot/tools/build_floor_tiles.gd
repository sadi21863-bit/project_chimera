extends SceneTree

## One-off tool: generates a simple tileable floor texture (no CC0 pack in the asset dump
## actually contains floor/wall tiles — kenney_roguelike-indoors turned out to be furniture-only
## on closer inspection), builds a TileSet from it, then swaps the flat ColorRect floors in the
## four location scenes for TileMapLayer nodes using that TileSet. Each location keeps its
## existing floor color via TileMapLayer.modulate, so the visual identity doesn't change, only
## the flat-color look gets replaced with a tiled texture.
##
## Run headless: godot --headless --path godot -s res://tools/build_floor_tiles.gd

const TILE_SIZE := 20
const TEX_PATH := "res://assets/tiles/floor_tile.png"
const TILESET_PATH := "res://resources/tilesets/floor.tres"

const FILL := Color(0.68, 0.65, 0.60)
const SEAM_DARK := Color(0.45, 0.43, 0.40)
const SEAM_LIGHT := Color(0.78, 0.76, 0.72)
const GRAIN := Color(0.60, 0.57, 0.52)

const LOCATIONS := [
	{"scene": "res://scenes/dorm/crestwood_hall.tscn", "floor_parent": "Floor", "floor_child": "TileBase",
		"rect": Rect2(0, 0, 1280, 720)},
	{"scene": "res://scenes/locations/detective_room.tscn", "floor_parent": ".", "floor_child": "Floor",
		"rect": Rect2(120, 120, 560, 360)},
	{"scene": "res://scenes/locations/police_station.tscn", "floor_parent": ".", "floor_child": "Floor",
		"rect": Rect2(120, 120, 560, 360)},
	{"scene": "res://scenes/locations/university.tscn", "floor_parent": ".", "floor_child": "Floor",
		"rect": Rect2(120, 120, 560, 360)},
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://assets/tiles")
	DirAccess.make_dir_recursive_absolute("res://resources/tilesets")
	if args.has("--texture-only"):
		_build_texture()
		print("BUILD_FLOOR_TEXTURE_DONE")
	else:
		_build_tileset()
		for loc in LOCATIONS:
			_migrate_scene(loc)
		print("BUILD_FLOOR_TILES_DONE")
	quit()


func _build_texture() -> void:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(FILL)
	for i in range(TILE_SIZE):
		img.set_pixel(TILE_SIZE - 1, i, SEAM_DARK)
		img.set_pixel(i, TILE_SIZE - 1, SEAM_DARK)
		img.set_pixel(0, i, SEAM_LIGHT)
		img.set_pixel(i, 0, SEAM_LIGHT)
	# a few fixed grain flecks so the tile doesn't read as perfectly flat
	for p in [Vector2i(5, 6), Vector2i(12, 9), Vector2i(8, 14), Vector2i(15, 4)]:
		img.set_pixel(p.x, p.y, GRAIN)
	var err := img.save_png(TEX_PATH)
	if err != OK:
		printerr("failed to save floor tile texture: %d" % err)
	else:
		print("saved %s" % TEX_PATH)


func _build_tileset() -> void:
	# reload as a fresh Texture2D resource so the TileSet references the just-saved file, not
	# the in-memory Image
	var tex: Texture2D = load(TEX_PATH)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i(0, 0))
	tile_set.add_source(source, 0)
	var err := ResourceSaver.save(tile_set, TILESET_PATH)
	if err != OK:
		printerr("failed to save tileset: %d" % err)
	else:
		print("saved %s" % TILESET_PATH)


func _migrate_scene(loc: Dictionary) -> void:
	var packed: PackedScene = load(loc["scene"])
	var root := packed.instantiate()

	var parent: Node = root if loc["floor_parent"] == "." else root.get_node(loc["floor_parent"])
	var old_floor: Node = parent.get_node(loc["floor_child"])
	var old_color: Color = old_floor.color if old_floor is ColorRect else Color.WHITE
	var floor_index := old_floor.get_index()
	old_floor.free()

	var tile_map := TileMapLayer.new()
	tile_map.name = loc["floor_child"]
	tile_map.tile_set = load(TILESET_PATH)
	tile_map.modulate = old_color
	parent.add_child(tile_map)
	tile_map.owner = root
	parent.move_child(tile_map, floor_index)

	var rect: Rect2 = loc["rect"]
	var x0 := int(rect.position.x / TILE_SIZE)
	var y0 := int(rect.position.y / TILE_SIZE)
	var x1 := int((rect.position.x + rect.size.x) / TILE_SIZE)
	var y1 := int((rect.position.y + rect.size.y) / TILE_SIZE)
	for x in range(x0, x1):
		for y in range(y0, y1):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	var new_packed := PackedScene.new()
	new_packed.pack(root)
	var err := ResourceSaver.save(new_packed, loc["scene"])
	if err != OK:
		printerr("failed to save %s: %d" % [loc["scene"], err])
	else:
		print("migrated %s (%d x %d tiles)" % [loc["scene"], x1 - x0, y1 - y0])
	root.free()
