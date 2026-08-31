extends Node

## Reads the Investigation store to compute per-suspect case strength and gate accusations.
## accuse() (Task 4) returns an ending id and applies standing fallout.
## Evidence quality system tracks quality levels and sources for discovered clues.

var resolved := false
var accused_id := ""

var _investigation: Node = null
var _standing: Node = null
var _evidence_quality: Node = null


func _ready() -> void:
	# Defer dependency lookup: sibling autoloads (esp. EvidenceQuality, near the
	# end of project.godot's order) may not exist yet when this _ready fires.
	_resolve_dependencies.call_deferred()


func _resolve_dependencies() -> void:
	# Sibling-relative lookup (via /root): absolute "/root/X" paths hit the
	# is_inside_tree guard during some boot orders / headless script runs.
	var r := get_parent()
	if r == null:
		return
	_investigation = r.get_node_or_null("Investigation")
	_standing = r.get_node_or_null("Standing")
	_evidence_quality = r.get_node_or_null("EvidenceQuality")


func _ensure_deps() -> void:
	# Lazy re-resolution: sibling autoloads may register after this node's
	# _ready depending on boot order; tests may also run before any frame
	# flushes deferred setup.
	if _investigation == null or _standing == null or _evidence_quality == null:
		_resolve_dependencies()


func case_strength(suspect_id: String) -> int:
	_ensure_deps()
	if _investigation == null:
		return 0
	var count := 0
	for clue_id in CaseData.clues_for_suspect(suspect_id):
		if _investigation.is_discovered(clue_id):
			count += 1
	return count


## Quality-weighted strength for a suspect's evidence.
func quality_strength(suspect_id: String) -> float:
	_ensure_deps()
	if _evidence_quality == null or _investigation == null:
		return float(case_strength(suspect_id))
	return _evidence_quality.quality_strength(suspect_id, _investigation)


func can_accuse(suspect_id: String) -> bool:
	if not CaseData.SUSPECTS.has(suspect_id):
		return false
	var threshold: int = CaseData.SUSPECTS[suspect_id]["threshold"]
	## Use quality-weighted strength when available.
	var strength := quality_strength(suspect_id)
	return strength >= float(threshold)


## You can't accuse anyone until you've gathered evidence on EVERY resident — no rushing to
## convict the first person you build a case against.
func accusations_unlocked() -> bool:
	for sid in CaseData.SUSPECTS:
		if case_strength(sid) < 1:
			return false
	return true


func accuse(suspect_id: String) -> Dictionary:
	_ensure_deps()
	var threshold: int = CaseData.SUSPECTS[suspect_id]["threshold"] if CaseData.SUSPECTS.has(suspect_id) else 0
	var strength := quality_strength(suspect_id)
	if strength < float(threshold) or threshold == 0:
		if _standing != null and CaseData.SUSPECTS.has(suspect_id):
			_standing.adjust(suspect_id, -0.15)
		return {"accepted": false, "ending_id": "", "strength": strength, "threshold": threshold}

	resolved = true
	accused_id = suspect_id

	if _standing != null:
		_standing.adjust(suspect_id, -0.5)
		for friend_id in CaseData.SUSPECTS[suspect_id]["friends"]:
			_standing.adjust(friend_id, -0.3)

	return {"accepted": true, "ending_id": "ending_%s" % suspect_id, "strength": strength, "threshold": threshold}


func _determine_ending(suspect_id: String) -> String:
	_ensure_deps()
	var total := CaseData.CLUES.size()
	var discovered: int = _investigation.discovered_count() if _investigation != null else 0
	var ratio := float(discovered) / float(total) if total > 0 else 0.0

	## Only use ending logic when standing is properly initialized (not null).
	## When standing is null, fall through to default suspect-specific ending.
	if _standing != null:
		var avg_standing := _average_standing()

		if ratio >= 1.0 and suspect_id == "sam":
			return "ending_truth"
		if ratio >= 0.7 and suspect_id == "sam":
			if avg_standing >= 0.7:
				return "ending_coverup"
			return "ending_partial_truth"
		if suspect_id != "sam" and avg_standing < 0.3:
			return "ending_tabloid"

	return "ending_%s" % suspect_id


func _average_standing() -> float:
	if _standing == null:
		return 0.0
	var total := 0.0
	var count := 0
	for suspect_id in CaseData.SUSPECTS:
		total += _standing.get_standing(suspect_id)
		count += 1
	return total / float(count) if count > 0 else 0.0


func get_save_data() -> Dictionary:
	return {"resolved": resolved, "accused_id": accused_id}


func load_save_data(data: Dictionary) -> void:
	resolved = bool(data.get("resolved", false))
	accused_id = str(data.get("accused_id", ""))


func reset() -> void:
	resolved = false
	accused_id = ""
