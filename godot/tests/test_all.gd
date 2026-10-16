extends SceneTree

## Real test runner.
##
## The previous version looped over test scripts and counted `script.new()` as a pass. Because
## every test here `extends SceneTree`, `_initialize()` only runs when that script *is* the main
## loop - so `.new()` never executed a single assertion and "15/15" only proved 15 files parsed.
##
## This runner instead executes each test in its own Godot process and uses the process exit
## code, which is how each test already reports its failure count via `quit(failures)`.
##
## Usage:
##   godot --headless --path godot --script res://tests/test_all.gd
##   godot --headless --path godot --script res://tests/test_all.gd --filter=chi002
##   godot --headless --path godot --script res://tests/test_all.gd --shard=1/3
##
## Each test runs in its own process (OS.execute), so a run is bounded by per-test boot cost.
## Use --shard to keep one invocation short when the caller has a hard time limit. There is no
## hard per-test timeout here - a test that never calls quit() will stall the run, so tests are
## expected to enforce their own deadline.

const TEST_DIR := "res://tests"
const OUTPUT_CAP := 6000        # chars of captured output kept per test


func _initialize() -> void:
	_run()


func _run() -> void:
	var filter := ""
	var shard_k := 0
	var shard_n := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--filter="):
			filter = a.trim_prefix("--filter=")
		elif a.begins_with("--shard="):
			var parts := a.trim_prefix("--shard=").split("/")
			if parts.size() == 2:
				shard_k = int(parts[0])
				shard_n = int(parts[1])

	var tests := _discover_tests()
	if filter != "":
		var kept: Array[String] = []
		for t in tests:
			if t.contains(filter):
				kept.append(t)
		tests = kept

	if shard_n > 0 and shard_k > 0:
		var sharded: Array[String] = []
		for i in range(tests.size()):
			if (i % shard_n) == (shard_k - 1):
				sharded.append(tests[i])
		tests = sharded

	print("Running %d test file(s)%s%s..." % [
		tests.size(),
		" (filter: %s)" % filter if filter != "" else "",
		" (shard %d/%d)" % [shard_k, shard_n] if shard_n > 0 else "",
	])
	print("")

	var passed := 0
	var failed := 0
	var failed_names: Array[String] = []

	var godot_bin := OS.get_executable_path()
	var project_dir := ProjectSettings.globalize_path("res://")

	for t in tests:
		var name: String = t.get_file()
		var args := PackedStringArray(["--headless", "--path", project_dir, "--script", t])
		var out: Array = []
		var code := OS.execute(godot_bin, args, out, true, false)
		var text := "\n".join(out)

		if code == 0:
			passed += 1
			print("PASS: %s" % name)
		else:
			failed += 1
			failed_names.append(name)
			print("FAIL: %s (exit %d)" % [name, code])
			print("      --- first failures ---")
			for line in text.split("\n"):
				if line.begins_with("FAIL") or line.contains("SCRIPT ERROR") or line.contains("Parse Error"):
					print("      " + line.left(200))
			print("      ---------------------")

	print("")
	print("=== RESULTS ===")
	print("Passed: ", passed)
	print("Failed: ", failed)
	if failed > 0:
		print("Failing: ", ", ".join(failed_names))
	quit(failed)


func _discover_tests() -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		print("ERROR: cannot open ", TEST_DIR)
		return found
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		# NOTE: skip ourselves - test_all.gd matches the test_* pattern and would otherwise
		# re-exec the whole suite from inside itself (infinite recursion).
		if not dir.current_is_dir() and fname.begins_with("test_") and fname.ends_with(".gd") \
				and fname != "test_all.gd":
			found.append(TEST_DIR + "/" + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found
