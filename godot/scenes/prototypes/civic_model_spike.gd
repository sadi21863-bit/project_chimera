extends Node3D

const ROOM_SCENE := preload("res://assets/prototypes/archival_cutaway_room.glb")

@onready var _camera: Camera3D = $Camera3D
@onready var _room: Node3D = $Room


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#101820"))
	_room.rotation_degrees = Vector3.ZERO
	var bounds := _room_bounds()
	var center := bounds.get_center()
	_camera.position = center + Vector3(0.0, 18.0, 0.0)
	_camera.look_at(center, Vector3(0, 0, 1))
	_camera.size = maxf(bounds.size.x, bounds.size.z) * 1.15
	_build_actor("DETECTIVE", Vector3(-1.8, 0.0, -0.6), Color("#16212b"), Color("#d99a4d"), 0.95)
	_build_actor("JORDAN", Vector3(0.2, 0.0, -1.4), Color("#a6403d"), Color("#d8d0be"), 0.9)
	_build_actor("MORGAN", Vector3(2.0, 0.0, -0.2), Color("#687c6d"), Color("#4e7778"), 0.88)
	_build_evidence()
	_build_overlay()


func _build_actor(label_text: String, position: Vector3, coat: Color, accent: Color, height: float) -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.22
	capsule.height = height
	body.mesh = capsule
	body.position = position + Vector3(0, height * 0.5, 0)
	body.material_override = _material(coat, 0.86)
	add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	head.mesh = sphere
	head.position = position + Vector3(0, height + 0.12, 0)
	head.material_override = _material(Color("#c9a27f"), 0.9)
	add_child(head)
	var tag := Label3D.new()
	tag.text = label_text
	tag.font_size = 24
	tag.modulate = accent
	tag.outline_size = 6
	tag.position = position + Vector3(0, height + 0.48, 0)
	add_child(tag)


func _build_evidence() -> void:
	var marker := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18
	torus.outer_radius = 0.24
	marker.mesh = torus
	marker.position = Vector3(0.9, 1.15, 0.3)
	marker.rotation_degrees = Vector3(90, 0, 0)
	marker.material_override = _material(Color("#d99a4d"), 0.4, 0.7)
	add_child(marker)
	var tag := Label3D.new()
	tag.text = "EVIDENCE"
	tag.font_size = 22
	tag.modulate = Color("#d99a4d")
	tag.outline_size = 6
	tag.position = Vector3(0.9, 1.6, 0.3)
	add_child(tag)


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 22)
	panel.size = Vector2(560, 72)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.09, 0.9)
	style.border_color = Color("#d99a4d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	var title := Label.new()
	title.text = "CIVIC MODEL  /  LIVE 3D SPIKE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#eee5cf"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "COMPATIBILITY RENDERER  ·  MEASURE BEFORE MIGRATING"
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color("#d99a4d"))
	column.add_child(subtitle)


func _room_bounds() -> AABB:
	var bounds := AABB()
	var first := true
	for node in _all_nodes(_room):
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			var world_bounds: AABB = mesh.global_transform * mesh.get_aabb()
			if first:
				bounds = world_bounds
				first = false
			else:
				bounds = bounds.merge(world_bounds)
	return bounds


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in root.get_children():
		nodes.append(child)
		nodes.append_array(_all_nodes(child))
	return nodes


func _material(color: Color, roughness: float, emission: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
