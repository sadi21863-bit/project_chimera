extends CanvasLayer

signal travel_requested(dest_id: String)

@onready var _list: VBoxContainer = $Panel/VBox/List


func _ready() -> void:
	$Panel/VBox/CloseButton.pressed.connect(close)
	visible = false


func open() -> void:
	for child in _list.get_children():
		child.queue_free()
	for id in LocationManager.LOCATIONS:
		var btn := Button.new()
		var label: String = LocationManager.location_name(id)
		btn.text = ("! " + label) if LocationManager.is_unvisited(id) else label
		btn.disabled = id == LocationManager.current_id
		btn.pressed.connect(_on_pick.bind(id))
		_list.add_child(btn)
	visible = true


func close() -> void:
	visible = false


func _on_pick(dest_id: String) -> void:
	travel_requested.emit(dest_id)
	close()
