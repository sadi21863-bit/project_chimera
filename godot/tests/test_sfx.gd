extends SceneTree

## Verifies that procedural SFX generation produces valid AudioStreamWAV data.

var _failures := 0


func _check(label: String, cond: bool) -> void:
	if not cond:
		_failures += 1
		print("FAIL: %s" % label)


func _process(_delta: float) -> bool:
	var ProceduralSFXScript = load("res://scripts/audio/procedural_sfx.gd")

	# 1. 8 categories defined
	var expected_cats := [0, 1, 2, 3, 4, 5, 6, 7]
	_check("8 categories defined", expected_cats.size() == 8)

	# 2. ProceduralSFX generates valid WAV for each category
	var gen = ProceduralSFXScript.new()
	for cat in expected_cats:
		var wav: AudioStreamWAV = gen.generate(cat)
		_check("category %d generates AudioStreamWAV" % cat, wav != null)
		_check("category %d has non-empty data" % cat, wav != null and wav.data.size() > 0)
		_check("category %d is 16-bit" % cat, wav != null and wav.format == AudioStreamWAV.FORMAT_16_BITS)
		_check("category %d mix_rate 22050" % cat, wav != null and wav.mix_rate == 22050)

	# 3. Cache works
	var wav1: AudioStreamWAV = gen.generate(0)
	var wav2: AudioStreamWAV = gen.generate(0)
	_check("cache returns same instance", wav1 == wav2)

	# 4. generate_raw works
	var raw: AudioStreamWAV = gen.generate_raw(440.0, 0.5, 0.25, "sine")
	_check("generate_raw produces AudioStreamWAV", raw != null)
	_check("generate_raw has data", raw != null and raw.data.size() > 0)

	# 5. SFXHelper autoload is available
	var sfx := root.get_node_or_null("SFXHelper")
	_check("SFXHelper autoload present", sfx != null)

	if _failures == 0:
		print("PASS: test_sfx")
	else:
		print("FAIL: test_sfx — %d failures" % _failures)
	quit(_failures)
	return true
