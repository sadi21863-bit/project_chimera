extends CanvasLayer

## Shows up to two prompts at once: "[E] Examine ..." for the nearest clue and
## "[F] Talk to ..." for the nearest NPC, so they never compete for one key.

@onready var _label: Label = $Label
var _interactor: Interactor = null


func bind(interactor: Interactor) -> void:
	if _interactor == interactor:
		return
	if is_instance_valid(_interactor) and _interactor.targets_changed.is_connected(_on_targets_changed):
		_interactor.targets_changed.disconnect(_on_targets_changed)
	_interactor = interactor
	_interactor.targets_changed.connect(_on_targets_changed)
	_on_targets_changed(_interactor.clue_target, _interactor.npc_target)


func _on_targets_changed(clue: Interactable, npc: Interactable) -> void:
	var lines: Array = []
	if clue != null:
		lines.append("[E] %s" % clue.get_prompt())
	if npc != null:
		lines.append("[F] %s" % npc.get_prompt())
	_label.text = "\n".join(lines)
	_label.visible = not lines.is_empty()
