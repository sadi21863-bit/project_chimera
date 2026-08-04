extends SceneTree

func _initialize() -> void:
	var ad := preload("res://scripts/access/access_data.gd")
	var failures := 0

	# public areas are never restricted, any hour, owner absent or present
	for area_id in ["kitchen", "common_room", "hallway", "bathroom"]:
		if ad.is_restricted(area_id, 3.0, false):
			failures += 1; print("FAIL: %s should never be restricted (owner absent, 3am)" % area_id)
		if ad.is_restricted(area_id, 14.0, false):
			failures += 1; print("FAIL: %s should never be restricted (owner absent, 2pm)" % area_id)

	# an unknown area is never restricted
	if ad.is_restricted("nowhere", 3.0, false):
		failures += 1; print("FAIL: unknown area should not be restricted")

	# a bedroom during its open window, owner absent, is not restricted
	if ad.is_restricted("bedroom_1", 14.0, false):
		failures += 1; print("FAIL: bedroom_1 at 2pm (owner absent) should not be restricted")

	# a bedroom after hours, owner absent, is restricted
	if not ad.is_restricted("bedroom_1", 23.0, false):
		failures += 1; print("FAIL: bedroom_1 at 11pm (owner absent) should be restricted")
	if not ad.is_restricted("bedroom_1", 3.0, false):
		failures += 1; print("FAIL: bedroom_1 at 3am (owner absent) should be restricted")

	# the owner being present overrides the time window entirely
	if ad.is_restricted("bedroom_1", 3.0, true):
		failures += 1; print("FAIL: bedroom_1 at 3am with the owner present should not be restricted")

	# area() exposes the owner
	if str(ad.area("bedroom_4").get("owner", "")) != "riley":
		failures += 1; print("FAIL: bedroom_4 should be owned by riley")

	if failures == 0:
		print("PASS: test_access_data")
	quit(failures)
