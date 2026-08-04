extends CanvasLayer

## Shows up to two prompts at once: "[E] Examine ..." for the nearest clue and
## "[F] Talk to ..." for the nearest NPC, so they never compete for one key.

@onready var _label: Label = $Label


func bind(interactor: Interactor) -> void:
	interactor.targets_changed.connect(_on_targets_changed)
	_on_targets_changed(interactor.clue_target, interactor.npc_target)


func _on_targets_changed(clue: Interactable, npc: Interactable) -> void:
	var lines: Array = []
	if clue != null:
		lines.append("[E] %s" % clue.get_prompt())
	if npc != null:
		lines.append("[F] %s" % npc.get_prompt())
	_label.text = "\n".join(lines)
	_label.visible = not lines.is_empty()
