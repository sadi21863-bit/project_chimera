extends Node

## Reads the Investigation store to compute per-suspect case strength and gate accusations.
## accuse() (Task 4) returns an ending id and applies standing fallout.

var resolved := false
var accused_id := ""

var _investigation: Node = null
var _standing: Node = null


func _ready() -> void:
	_investigation = get_node_or_null("/root/Investigation")
	_standing = get_node_or_null("/root/Standing")


func case_strength(suspect_id: String) -> int:
	if _investigation == null:
		return 0
	var count := 0
	for clue_id in CaseData.clues_for_suspect(suspect_id):
		if _investigation.is_discovered(clue_id):
			count += 1
	return count


func can_accuse(suspect_id: String) -> bool:
	if not CaseData.SUSPECTS.has(suspect_id):
		return false
	var threshold: int = CaseData.SUSPECTS[suspect_id]["threshold"]
	return case_strength(suspect_id) >= threshold


## You can't accuse anyone until you've gathered evidence on EVERY resident — no rushing to
## convict the first person you build a case against.
func accusations_unlocked() -> bool:
	for sid in CaseData.SUSPECTS:
		if case_strength(sid) < 1:
			return false
	return true


func accuse(suspect_id: String) -> Dictionary:
	var threshold: int = CaseData.SUSPECTS[suspect_id]["threshold"] if CaseData.SUSPECTS.has(suspect_id) else 0
	var strength: int = case_strength(suspect_id)
	if strength < threshold or threshold == 0:
		if _standing != null and CaseData.SUSPECTS.has(suspect_id):
			_standing.adjust(suspect_id, -0.15)  # resentment at a baseless accusation
		return {"accepted": false, "ending_id": "", "strength": strength, "threshold": threshold}

	resolved = true
	accused_id = suspect_id
	if _standing != null:
		_standing.adjust(suspect_id, -0.5)
		for friend_id in CaseData.SUSPECTS[suspect_id]["friends"]:
			_standing.adjust(friend_id, -0.3)
	return {"accepted": true, "ending_id": "ending_%s" % suspect_id, "strength": strength, "threshold": threshold}


func get_save_data() -> Dictionary:
	return {"resolved": resolved, "accused_id": accused_id}


func load_save_data(data: Dictionary) -> void:
	resolved = bool(data.get("resolved", false))
	accused_id = str(data.get("accused_id", ""))
