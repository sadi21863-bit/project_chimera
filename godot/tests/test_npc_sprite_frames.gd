extends SceneTree

## Verifies every dorm NPC profile gets a SpriteFrames resource with the animations the
## movement/idle wiring in npc.gd and detective.gd expects.

const REQUIRED_ANIMS := ["idle_down", "walk_down", "walk_up", "walk_left", "walk_right"]

func _initialize() -> void:
	var factory := preload("res://resources/npc_profiles/npc_profile_factory.gd")
	var profiles = factory.create_all_profiles()
	var failures := 0

	if profiles.is_empty():
		print("FAIL: no profiles created")
		failures += 1

	for p in profiles:
		if p.sprite_frames == null:
			print("FAIL: %s has no sprite_frames" % p.npc_id)
			failures += 1
			continue
		for anim in REQUIRED_ANIMS:
			if not p.sprite_frames.has_animation(anim):
				print("FAIL: %s sprite_frames missing animation '%s'" % [p.npc_id, anim])
				failures += 1

	var detective_frames = load("res://resources/sprite_frames/detective.tres")
	if detective_frames == null:
		print("FAIL: detective sprite_frames resource missing")
		failures += 1
	else:
		for anim in REQUIRED_ANIMS:
			if not detective_frames.has_animation(anim):
				print("FAIL: detective sprite_frames missing animation '%s'" % anim)
				failures += 1

	if failures == 0:
		print("PASS: test_npc_sprite_frames — all profiles + detective have full sprite_frames")
	quit(failures)
