extends SceneTree

## One-off tool: adds a DoorTrigger at each bedroom_N marker in Crestwood Hall so walking up to
## where the marker already is now actually enters that suspect's bedroom. Uses a script (rather
## than hand-editing the .tscn) because the scene's tile_map_data blob is too large to reliably
## round-trip through a text editor.
##
## Run headless: godot --headless --path godot -s res://tools/add_bedroom_doors.gd

const SCENE_PATH := "res://scenes/dorm/crestwood_hall.tscn"
const BEDROOM_IDS := ["bedroom_1", "bedroom_2", "bedroom_3", "bedroom_4", "bedroom_5", "bedroom_6"]
const LABELS := ["Alex's room", "Jordan's room", "Sam's room", "Riley's room", "Morgan's room", "Casey's room"]


func _initialize() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	var root := packed.instantiate()
	var markers: Node2D = root.get_node("RoomMarkers")

	for i in range(BEDROOM_IDS.size()):
		var room_id: String = BEDROOM_IDS[i]
		if not markers.has_node(room_id):
			printerr("missing marker: %s" % room_id)
			continue
		var marker: Marker2D = markers.get_node(room_id)
		var door_name := "DoorTo%s" % room_id.capitalize().replace(" ", "")
		if root.has_node(door_name):
			root.get_node(door_name).free()

		var door := Area2D.new()
		door.name = door_name
		door.set_script(load("res://scripts/player/door_trigger.gd"))
		door.set("dest_id", room_id)
		door.set("dest_label", LABELS[i])
		door.position = marker.position
		root.add_child(door)
		door.owner = root

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		door.add_child(shape)
		shape.owner = root

	var new_packed := PackedScene.new()
	new_packed.pack(root)
	var err := ResourceSaver.save(new_packed, SCENE_PATH)
	if err != OK:
		printerr("failed to save %s: %d" % [SCENE_PATH, err])
	else:
		print("added %d bedroom doors to %s" % [BEDROOM_IDS.size(), SCENE_PATH])
	root.free()
	print("ADD_BEDROOM_DOORS_DONE")
	quit()
