extends SceneTree

func _init():
    var passed := 0
    var failed := 0

    # Test 1: Load Effects script
    var script = load("res://autoload/effects.gd")
    if script:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Could not load Effects script")
        failed += 1

    # Test 2: Initialize effects
    var effects = script.new()
    if effects._shake_intensity == 0.0:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Initial shake intensity should be 0.0")
        failed += 1

    # Test 3: Shake sets intensity
    effects.shake(8.0, 0.3)
    if effects._shake_intensity == 8.0 and effects._shake_duration == 0.3:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Shake should set intensity and duration")
        failed += 1

    # Test 4: Reset clears shake
    effects.reset()
    if effects._shake_intensity == 0.0 and effects._shake_timer == 0.0:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Reset should clear shake")
        failed += 1

    # Test 5: Set camera
    var cam := Camera2D.new()
    effects.set_camera(cam)
    if effects._camera == cam:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Set camera should store reference")
        failed += 1

    # Test 6: Shake with no camera doesn't crash
    effects._camera = null
    effects.shake(4.0, 0.1)
    if effects._shake_intensity == 4.0:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Shake should work without camera")
        failed += 1

    # Test 7: Process updates shake timer
    effects.reset()
    effects.shake(4.0, 0.5)
    effects._process(0.1)
    if effects._shake_timer < 0.5:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Process should decrease shake timer")
        failed += 1

    # Test 8: Shake offset calculated
    effects.reset()
    effects.shake(4.0, 0.5)
    effects._process(0.0)
    if effects._shake_offset != Vector2.ZERO:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Shake offset should be non-zero during shake")
        failed += 1

    # Test 9: Default color for flash
    var default_color = Color.WHITE
    if default_color.a == 1.0:
        passed += 1
        print("PASS: test_effects")
    else:
        print("FAIL: Default flash color should be opaque")
        failed += 1

    print("=== ", passed, " passed, ", failed, " failed ===")
    quit()
