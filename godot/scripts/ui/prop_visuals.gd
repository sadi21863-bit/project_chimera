class_name PropVisuals
extends Node

const ROOT := "res://assets/2d/dorm_props/"

static func add_sprite(parent: Node2D, asset: String, at: Vector2, scale_factor: float = 0.2, z: int = 1, tint: Color = Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "Prop_%s_%s" % [asset.get_file().get_basename(), parent.get_child_count()]
	sprite.texture = load(ROOT + asset + ".png")
	sprite.position = at
	sprite.scale = Vector2.ONE * scale_factor
	sprite.modulate = tint
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)
	return sprite

static func hide_legacy_furniture(root: Node) -> void:
	for path in [
		"Furniture/Bed/Visual", "Furniture/Desk/Visual", "Furniture/Chair/Visual",
		"Furniture/Bookcase/Visual", "Furniture/Dresser/Visual"
	]:
		var n := root.get_node_or_null(path)
		if n is CanvasItem:
			n.visible = false

static func decorate_bedroom(root: Node, room_id: String) -> void:
	var furniture := root.get_node_or_null("Furniture") as Node2D
	if furniture == null:
		return
	hide_legacy_furniture(root)
	if room_id == "daniel_room":
		# Daniel's authored room is substantially larger than the six suspect rooms.
		add_sprite(furniture, "bed", Vector2(92, 95), 0.30, 1)
		add_sprite(furniture, "desk", Vector2(350, 95), 0.28, 2)
		add_sprite(furniture, "chair", Vector2(375, 150), 0.19, 3)
		add_sprite(furniture, "bookshelf", Vector2(95, 250), 0.27, 2)
		add_sprite(furniture, "locker", Vector2(350, 255), 0.25, 2)
		add_sprite(furniture, "evidence_board", Vector2(255, 74), 0.22, 2)
		add_sprite(furniture, "lamp", Vector2(435, 185), 0.17, 4)
		add_sprite(furniture, "suitcase", Vector2(250, 300), 0.17, 2)
		return
	# Keep props compact because the authored bedrooms are intentionally small.
	add_sprite(furniture, "bed", Vector2(24, 24), 0.18, 1)
	add_sprite(furniture, "desk", Vector2(120, 24), 0.17, 2)
	add_sprite(furniture, "chair", Vector2(136, 56), 0.12, 3)
	add_sprite(furniture, "bookshelf", Vector2(24, 80), 0.16, 2)
	add_sprite(furniture, "locker", Vector2(120, 100), 0.16, 2)
	add_sprite(furniture, "lamp", Vector2(154, 72), 0.11, 4)
	add_sprite(furniture, "suitcase", Vector2(74, 116), 0.12, 2)

static func add_location_sprite(parent: Node2D, asset: String, at: Vector2, scale_factor: float = 0.5, z: int = 1) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "LocationProp_%s_%s" % [asset, parent.get_child_count()]
	sprite.texture = load("res://assets/2d/location_props/" + asset + ".svg")
	sprite.position = at
	sprite.scale = Vector2.ONE * scale_factor
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(sprite)
	return sprite

static func decorate_generic(root: Node, location_id: String) -> void:
	var props := root.get_node_or_null("BlenderProps") as Node2D
	if props == null:
		props = Node2D.new()
		props.name = "BlenderProps"
		props.z_index = 1
		root.add_child(props)
	# NOTE (workspace port): coordinates below are fitted to OUR generated room
	# sizes (common_room 320x224, kitchen/bathroom 224x160, hallway 384x96,
	# university 570x360 interior) — the source pass assumed larger rooms.
	match location_id:
		"common_room":
			add_sprite(props, "bookshelf", Vector2(60, 50), 0.25, 1)
			add_location_sprite(props, "couch", Vector2(170, 110), 0.50, 2)
			add_sprite(props, "desk", Vector2(250, 60), 0.23, 2)
			add_sprite(props, "chair", Vector2(268, 105), 0.17, 3)
			add_sprite(props, "lamp", Vector2(295, 35), 0.16, 4)
			add_sprite(props, "suitcase", Vector2(160, 180), 0.15, 2)
		"kitchen":
			add_location_sprite(props, "counter", Vector2(70, 50), 0.60, 1)
			add_sprite(props, "locker", Vector2(160, 45), 0.23, 2)
			add_sprite(props, "trash_bin", Vector2(190, 118), 0.17, 4)
			add_sprite(props, "chair", Vector2(110, 100), 0.16, 3)
			add_sprite(props, "lamp", Vector2(185, 30), 0.14, 4)
		"hallway":
			add_location_sprite(props, "noticeboard", Vector2(150, 32), 0.55, 3)
			add_location_sprite(props, "vending", Vector2(310, 48), 0.48, 3)
			add_sprite(props, "locker", Vector2(60, 45), 0.22, 2)
			add_sprite(props, "locker", Vector2(250, 45), 0.22, 2)
			add_sprite(props, "lamp", Vector2(200, 25), 0.12, 4)
			add_sprite(props, "security_camera", Vector2(200, 12), 0.13, 5)
		"bathroom":
			add_sprite(props, "locker", Vector2(80, 65), 0.18, 1)
			add_sprite(props, "trash_bin", Vector2(180, 110), 0.15, 3)
			add_sprite(props, "lamp", Vector2(150, 30), 0.13, 4)
			add_sprite(props, "chair", Vector2(105, 115), 0.14, 2)
		"server_room":
			add_location_sprite(props, "server_rack", Vector2(190, 155), 0.56, 2)
			add_location_sprite(props, "server_rack", Vector2(360, 155), 0.56, 2)
			add_location_sprite(props, "terminal", Vector2(550, 190), 0.50, 3)
			add_sprite(props, "security_camera", Vector2(690, 75), 0.13, 5)
		"library":
			add_sprite(props, "bookshelf", Vector2(150, 140), 0.36, 1)
			add_sprite(props, "bookshelf", Vector2(690, 140), 0.36, 1)
			add_location_sprite(props, "terminal", Vector2(420, 200), 0.50, 3)
			add_sprite(props, "desk", Vector2(560, 430), 0.25, 2)
			add_sprite(props, "chair", Vector2(595, 480), 0.17, 3)
		"hospital":
			add_location_sprite(props, "hospital_cart", Vector2(220, 160), 0.56, 2)
			add_sprite(props, "locker", Vector2(455, 145), 0.28, 2)
			add_location_sprite(props, "hospital_cart", Vector2(650, 365), 0.48, 2)
			add_sprite(props, "lamp", Vector2(530, 105), 0.14, 4)
		"bar":
			add_location_sprite(props, "bar_booth", Vector2(275, 230), 0.62, 2)
			add_location_sprite(props, "counter", Vector2(560, 125), 0.58, 2)
			add_sprite(props, "chair", Vector2(585, 220), 0.18, 3)
			add_sprite(props, "lamp", Vector2(690, 150), 0.15, 4)
		"courtyard", "campus":
			add_location_sprite(props, "courtyard_tree", Vector2(650, 150), 0.58, 1)
			add_location_sprite(props, "courtyard_tree", Vector2(740, 430), 0.46, 1)
			add_sprite(props, "suitcase", Vector2(350, 500), 0.13, 2)
		"university":
			# Same dressing as courtyard, refitted: university interior is
			# x 115-685 / y 115-485 (trees at 740 / suitcase at y 500 land outside).
			add_location_sprite(props, "courtyard_tree", Vector2(250, 180), 0.58, 1)
			add_location_sprite(props, "courtyard_tree", Vector2(560, 350), 0.46, 1)
			add_sprite(props, "suitcase", Vector2(350, 400), 0.13, 2)
		"detective_room":
			add_sprite(props, "desk", Vector2(250, 160), 0.29, 2)
			add_sprite(props, "bookshelf", Vector2(620, 145), 0.32, 1)
			add_sprite(props, "lamp", Vector2(430, 110), 0.16, 4)
		_:
			add_sprite(props, "lamp", Vector2(390, 140), 0.14, 3)
			add_sprite(props, "suitcase", Vector2(585, 445), 0.15, 2)
