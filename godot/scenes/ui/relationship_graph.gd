extends Control

## Draws 6 NPC nodes with weighted relationship edges.

signal node_clicked(npc: DormNpc)

const NODE_RADIUS := 14.0

var _npcs: Array = []
var _relationships: Array = []
var _node_positions: Dictionary = {}
var _selected_npc_id: String = ""


func setup(npcs: Array) -> void:
	_npcs = npcs
	_layout_nodes()
	queue_redraw()


func update_relationships(rels: Array) -> void:
	_relationships = rels
	queue_redraw()


func _layout_nodes() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.35
	for i in range(_npcs.size()):
		var angle := (TAU / _npcs.size()) * i - PI / 2.0
		_node_positions[_npcs[i].npc_id] = center + Vector2(cos(angle), sin(angle)) * radius


func _draw() -> void:
	if _npcs.is_empty():
		return
	for rel in _relationships:
		var a: String = str(rel.get("from_npc", ""))
		var b: String = str(rel.get("to_npc", ""))
		if not _node_positions.has(a) or not _node_positions.has(b):
			continue
		var score: float = float(rel.get("score", 0.0))
		var color := Color.GREEN.lerp(Color.RED, 0.5 - score * 0.5)
		color.a = 0.3 + absf(score) * 0.5
		draw_line(_node_positions[a], _node_positions[b], color, 2.0 + absf(score) * 3.0)

	for npc in _npcs:
		var pos: Vector2 = _node_positions.get(npc.npc_id, Vector2.ZERO)
		if npc.npc_id == _selected_npc_id:
			draw_arc(pos, NODE_RADIUS + 4.0, 0, TAU, 32, Color.YELLOW, 2.5)
		draw_circle(pos, NODE_RADIUS, npc.profile.color if npc.profile else Color.WHITE)
		draw_arc(pos, NODE_RADIUS, 0, TAU, 32, Color.BLACK, 1.5)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-20, 28), npc.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked := _hit_test(event.position)
		if clicked != null:
			_selected_npc_id = clicked.npc_id
			queue_redraw()
			node_clicked.emit(clicked)


func _hit_test(pos: Vector2) -> DormNpc:
	for npc in _npcs:
		var node_pos: Vector2 = _node_positions.get(npc.npc_id, Vector2.ZERO)
		if pos.distance_to(node_pos) <= NODE_RADIUS:
			return npc
	return null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_nodes()
		queue_redraw()
