extends SceneTree

func _init():
    var passed := 0
    var failed := 0

    # Test 1: Load Effects script
    var script = load("res://autoload/effects.gd")
    if script:
        passed += 1
        print("PASS: test_particles - Load effects script")
    else:
        print("FAIL: Could not load Effects script")
        failed += 1

    # Test 2: Initialize effects
    var effects = script.new()
    if effects._shake_intensity == 0.0:
        passed += 1
        print("PASS: test_particles - Initialize effects")
    else:
        print("FAIL: Initial shake intensity should be 0.0")
        failed += 1

    # Test 3: set_canvas works
    var canvas := CanvasLayer.new()
    var container := Control.new()
    container.name = "Control"
    container.set_anchors_preset(Control.PRESET_FULL_RECT)
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(container)
    effects.set_canvas(canvas)
    passed += 1
    print("PASS: test_particles - set_canvas works")

    # Test 4: sparkle doesn't crash
    effects.sparkle(Vector2(100, 100), Color.YELLOW)
    passed += 1
    print("PASS: test_particles - sparkle runs")

    # Test 5: dust doesn't crash
    effects.dust(Vector2(200, 200))
    passed += 1
    print("PASS: test_particles - dust runs")

    # Test 6: glow doesn't crash
    effects.glow(Vector2(300, 300), Color.CYAN)
    passed += 1
    print("PASS: test_particles - glow runs")

    # Test 7: trail doesn't crash
    effects.trail(Vector2(100, 100), Vector2(200, 200), Color.GREEN)
    passed += 1
    print("PASS: test_particles - trail runs")

    # Test 8: burst doesn't crash
    effects.burst(Vector2(400, 400), Color.ORANGE, 8)
    passed += 1
    print("PASS: test_particles - burst runs")

    # Test 9: reset doesn't crash
    effects.reset()
    passed += 1
    print("PASS: test_particles - reset runs")

    print("=== ", passed, " passed, ", failed, " failed ===")
    quit()
