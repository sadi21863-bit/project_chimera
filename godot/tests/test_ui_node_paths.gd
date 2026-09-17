extends SceneTree

## Every $Node/Path referenced in the staged UI scripts must exist in its
## matching .tscn. Added after accusation_reveal shipped with 8 paths missing
## an intermediate VBox level (its _ready crashed on open, silently breaking
## the accusation flow the panel was built for).

const PAIRS := [
	["res://scripts/ui/accusation_reveal.gd", "res://scenes/ui/accusation_reveal.tscn"],
	["res://scripts/ui/investigation_hud.gd", "res://scenes/ui/investigation_hud.tscn"],
	["res://scenes/ui/dialogue_panel.gd", "res://scenes/ui/dialogue_panel.tscn"],
]

var _phase := 0


func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		return false
	var failures := 0
	for pair in PAIRS:
		var gd_text: String = FileAccess.get_file_as_string(pair[0])
		var tscn_text: String = FileAccess.get_file_as_string(pair[1])
		var nodes := {}
		for m in _node_re().search_all(tscn_text):
			var strings := m.get_strings()
			var nm: String = strings[1]
			var parent: String = strings[2]
			nodes[parent + "/" + nm if parent != "." else nm] = true
		for m in _path_re().search_all(gd_text):
			var path: String = m.get_strings()[1]
			if not nodes.has(path):
				failures += 1
				print("FAIL: %s references missing node $%s (see %s)" % [pair[0].get_file(), path, pair[1].get_file()])
	if failures == 0:
		print("PASS: test_ui_node_paths")
	quit(failures)
	return true


func _node_re() -> RegEx:
	var re := RegEx.new()
	re.compile('\\[node name="([^"]+)"(?: type="[^"]+")? parent="([^"]+)"\\]')
	return re


func _path_re() -> RegEx:
	var re := RegEx.new()
	re.compile('\\$([A-Za-z0-9_/]+)')
	return re
