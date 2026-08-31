extends CanvasLayer

## Brief on-screen feedback when a clue is found: its title and who it implicates.
## (The innocent truth is withheld — it's only revealed in the ending flashback.)

@onready var _label: Label = $Label

var _timer := 0.0


func _ready() -> void:
	var inv := get_node_or_null("/root/Investigation")
	if inv != null:
		inv.clue_discovered.connect(_on_clue_discovered)
	_label.visible = false


func _on_clue_discovered(clue_id: String) -> void:
	if not CaseData.CLUES.has(clue_id):
		return
	var data: Dictionary = CaseData.CLUES[clue_id]
	var names: Array = []
	for sid in data.get("implicates", []):
		names.append(str(CaseData.SUSPECTS[sid]["name"]) if CaseData.SUSPECTS.has(sid) else str(sid))
	_label.text = "🔎 Found: %s — points to %s    (C: case file | N: notebook)" % [
		str(data["title"]), ", ".join(names)]
	_label.visible = true
	_timer = 4.0
	SFXHelper.clue_found()
	var screen_center := Vector2(640, 360)
	Effects.sparkle(screen_center, Color(1.0, 0.95, 0.4))


func _process(delta: float) -> void:
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_label.visible = false
