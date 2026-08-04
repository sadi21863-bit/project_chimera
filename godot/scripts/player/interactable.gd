extends Area2D
class_name Interactable

## Passive component: something the detective can interact with.

@export var prompt_text: String = "Examine"


func get_prompt() -> String:
	return prompt_text


func interact() -> void:
	pass
