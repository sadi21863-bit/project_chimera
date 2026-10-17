extends SceneTree

func _init():
	var passed := 0
	var failed := 0

	# Test 1: Load EvidenceQuality script
	var script = load("res://autoload/evidence_quality.gd")
	if script:
		passed += 1
		print("PASS: test_evidence_quality - Load script")
	else:
		print("FAIL: Could not load EvidenceQuality script")
		failed += 1

	# Test 2: Initialize
	var eq = script.new()
	if eq._evidence.is_empty():
		passed += 1
		print("PASS: test_evidence_quality - Initialize")
	else:
		print("FAIL: Should start empty")
		failed += 1

	# Test 3: Record evidence
	eq.record("clue_keys", eq.EvidenceQuality.MODERATE, eq.EvidenceSource.FOUND)
	if eq.has_evidence("clue_keys"):
		passed += 1
		print("PASS: test_evidence_quality - Record evidence")
	else:
		print("FAIL: Should have clue_keys")
		failed += 1

	# Test 4: Get quality
	if eq.get_quality("clue_keys") == eq.EvidenceQuality.MODERATE:
		passed += 1
		print("PASS: test_evidence_quality - Get quality")
	else:
		print("FAIL: Quality should be MODERATE")
		failed += 1

	# Test 5: Get source
	if eq.get_source("clue_keys") == eq.EvidenceSource.FOUND:
		passed += 1
		print("PASS: test_evidence_quality - Get source")
	else:
		print("FAIL: Source should be FOUND")
		failed += 1

	# Test 6: Get quality name
	if eq.get_quality_name("clue_keys") == "Moderate":
		passed += 1
		print("PASS: test_evidence_quality - Get quality name")
	else:
		print("FAIL: Quality name should be 'Moderate'")
		failed += 1

	# Test 7: Get source name
	if eq.get_source_name("clue_keys") == "Found":
		passed += 1
		print("PASS: test_evidence_quality - Get source name")
	else:
		print("FAIL: Source name should be 'Found'")
		failed += 1

	# Test 8: Unknown clue defaults to MODERATE (unrecorded discovery weighs 1.0;
	# only explicitly recorded WEAK evidence counts half)
	if eq.get_quality("nonexistent") == eq.EvidenceQuality.MODERATE:
		passed += 1
		print("PASS: test_evidence_quality - Unknown clue returns moderate")
	else:
		print("FAIL: Unknown clue should return MODERATE")
		failed += 1

	# Test 9: Quality weight calculation
	var weight = eq._quality_weight(eq.EvidenceQuality.WEAK)
	if weight == 0.5:
		passed += 1
		print("PASS: test_evidence_quality - Weak weight")
	else:
		print("FAIL: Weak weight should be 0.5")
		failed += 1

	weight = eq._quality_weight(eq.EvidenceQuality.DEFINITIVE)
	if weight == 2.0:
		passed += 1
		print("PASS: test_evidence_quality - Definitive weight")
	else:
		print("FAIL: Definitive weight should be 2.0")
		failed += 1

	# Test 10: Save/load
	eq.record("clue_camera", eq.EvidenceQuality.STRONG, eq.EvidenceSource.TESTIMONIAL)
	var save = eq.get_save_data()
	var eq2 = script.new()
	eq2.load_save_data(save)
	if eq2.has_evidence("clue_keys") and eq2.get_quality("clue_camera") == eq.EvidenceQuality.STRONG:
		passed += 1
		print("PASS: test_evidence_quality - Save/load")
	else:
		print("FAIL: Save/load roundtrip failed")
		failed += 1

	# Test 11: Reset
	eq2.reset()
	if eq2._evidence.is_empty():
		passed += 1
		print("PASS: test_evidence_quality - Reset")
	else:
		print("FAIL: Reset should clear evidence")
		failed += 1

	print("=== ", passed, " passed, ", failed, " failed ===")
	quit()
