extends RefCounted
class_name Blackboard

var data: Dictionary = {}


func set_value(key: String, value: Variant) -> void:
	data[key] = value


func get_value(key: String, default: Variant = null) -> Variant:
	return data.get(key, default)


func erase_value(key: String) -> void:
	data.erase(key)
