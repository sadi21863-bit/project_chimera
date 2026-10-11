extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/prototypes/archival_cutaway_hero.tscn")
	if scene == null:
		print("FAIL: archival hero scene could not load")
		quit(1)
		return
	var hero: Node2D = scene.instantiate()
	root.add_child(hero)
	await process_frame
	var failures := 0
	if hero.get("_background") == null:
		print("FAIL: background missing")
		failures += 1
	if hero.get("_case_card") == null:
		print("FAIL: case card missing")
		failures += 1
	if hero.get("_dialogue") == null:
		print("FAIL: dialogue missing")
		failures += 1
	if hero.get("_evidence_marker") == null:
		print("FAIL: evidence marker missing")
		failures += 1
	if hero.get("_player") == null:
		print("FAIL: player missing")
		failures += 1
	if hero.get("_interaction_prompt") == null:
		print("FAIL: interaction prompt missing")
		failures += 1
	var card := hero.get("_case_card") as PanelContainer
	var card_visible := card.visible
	hero.call("_toggle_case_card")
	if card.visible == card_visible:
		print("FAIL: case card toggle failed")
		failures += 1
	hero.call("_toggle_night")
	if not bool(hero.get("_night")):
		print("FAIL: night toggle failed")
		failures += 1
	hero.call("_toggle_night")
	hero.call("_complete_search")
	if not bool(hero.get("_searched")) or not card.visible:
		print("FAIL: evidence search did not complete")
		failures += 1
	if failures == 0:
		print("PASS: test_archival_cutaway_hero")
	hero.queue_free()
	quit(failures)
