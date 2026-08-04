extends Area2D
class_name Interactor

## Tracks the nearest clue AND the nearest NPC in reach, separately, so they never compete:
## clues are examined with E, NPCs are talked to with F, and both prompts can show at once.

signal targets_changed(clue: Interactable, npc: Interactable)

var clue_target: Interactable = null
var npc_target: Interactable = null
var _in_range: Array[Interactable] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and not _in_range.has(area):
		_in_range.append(area)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_in_range.erase(area)


func _physics_process(_delta: float) -> void:
	var new_clue := _pick_nearest(_in_range, global_position, true)
	var new_npc := _pick_nearest(_in_range, global_position, false)
	if new_clue != clue_target or new_npc != npc_target:
		clue_target = new_clue
		npc_target = new_npc
		targets_changed.emit(clue_target, npc_target)


func try_examine() -> bool:
	if clue_target != null:
		clue_target.interact()
		targets_changed.emit(clue_target, npc_target)  # refresh prompt (Examine -> Examined)
		return true
	return false


func try_talk() -> bool:
	if npc_target != null:
		npc_target.interact()
		return true
	return false


static func _pick_nearest(items: Array, from: Vector2, want_clue: bool) -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for it in items:
		if not is_instance_valid(it):
			continue
		# Examine target = any non-NPC interactable (clue hotspots AND detailed search points).
		var matches := (not (it is NpcInteractable)) if want_clue else (it is NpcInteractable)
		if not matches:
			continue
		var d: float = from.distance_squared_to(it.global_position)
		if d < best_dist:
			best_dist = d
			best = it
	return best
