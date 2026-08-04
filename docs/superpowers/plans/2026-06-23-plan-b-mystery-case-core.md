# Plan B — Mystery Case Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn discovered clues into a real case: per-suspect case strength, evidence-gated accusations that return an ending, and standing (the detective's trust with each NPC) that drops when you accuse.

**Architecture:** A static `CaseData` module holds the authored suspects + clues (each clue implicates one or more suspects and carries its innocent truth). A `CaseFile` autoload reads Plan A's `Investigation` store to compute case strength and gate accusations. A `Standing` autoload tracks the detective's trust per NPC; `CaseFile.accuse` applies the relationship fallout. Pure GDScript logic, headless-tested. The in-game accusation UI and the flashback/endings are Plan D.

**Tech Stack:** Godot 4.7 (GDScript). Builds on autoloads `Investigation` (Plan A), `LocalMemory`, `EventLog`.

## Global Constraints

- **Engine:** Godot 4.7 stable; project root is `godot/`.
- **Warnings are errors:** never `:=` infer from a `Variant`-returning call (`Dictionary.get`, untyped `var.x`, `JSON.parse_string`). Use explicit types (`var x: int = ...`).
- **GDScript style:** snake_case funcs/vars, PascalCase classes, typed where practical.
- **Reuse:** `Investigation.is_discovered(clue_id)`, `EventLog.log_action(text, category)`, `LocalMemory`.
- **Test runner:** `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd` — each prints `PASS: <name>` and `quit(0)` on success, else `FAIL:` lines and `quit(<n>)`.
- **Testability:** `CaseFile`/`Standing` resolve their autoload dependencies into injectable vars (`_investigation`, `_standing`) in `_ready`, so tests instantiate them fresh and inject stubs (avoids the headless autoload-global-resolution problem seen in Plan A).
- **Git:** Task 1 creates branch `plan-b-mystery-case-core` from `main`. Commit after every task. End commit messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **Authored truth (from the Story Bible):** each suspect has exactly 2 clues; the accusation threshold is 2 (both required). All accusations are "wrong" — they still return an ending id; the flashback is Plan D.

---

### Task 1: `CaseData` — authored suspects & clues

**Files:**
- Create: `godot/scripts/case/case_data.gd`
- Create: `godot/tests/test_case_data.gd`

**Interfaces:**
- Produces: `CaseData` (`class_name`, extends `RefCounted`):
  - `const SUSPECTS: Dictionary` — `id -> {name, secret, innocent_act, false_motive, threshold:int, friends:Array}`
  - `const CLUES: Dictionary` — `id -> {title, room, implicates:Array, truth}`
  - `static get_suspect_ids() -> Array`
  - `static clues_for_suspect(suspect_id: String) -> Array` (clue ids whose `implicates` contains the suspect)

- [ ] **Step 1: Create branch**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git checkout main && git checkout -b plan-b-mystery-case-core
```

- [ ] **Step 2: Write the failing test**

Create `godot/tests/test_case_data.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var cd := preload("res://scripts/case/case_data.gd")
	var failures := 0
	var ids: Array = cd.get_suspect_ids()
	if ids.size() != 6:
		failures += 1; print("FAIL: expected 6 suspects, got %d" % ids.size())
	# Every suspect has exactly 2 implicating clues, matching its threshold.
	for sid in ids:
		var clues: Array = cd.clues_for_suspect(sid)
		if clues.size() != 2:
			failures += 1; print("FAIL: suspect %s has %d clues (expected 2)" % [sid, clues.size()])
		var threshold: int = cd.SUSPECTS[sid]["threshold"]
		if threshold != 2:
			failures += 1; print("FAIL: suspect %s threshold %d (expected 2)" % [sid, threshold])
	# Every clue implicates only real suspects.
	for clue_id in cd.CLUES:
		for sid in cd.CLUES[clue_id]["implicates"]:
			if not cd.SUSPECTS.has(sid):
				failures += 1; print("FAIL: clue %s implicates unknown suspect %s" % [clue_id, sid])
	if failures == 0:
		print("PASS: test_case_data")
	quit(failures)
```

- [ ] **Step 3: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_case_data.gd`
Expected: preload error — file does not exist.

- [ ] **Step 4: Implement `CaseData`**

Create `godot/scripts/case/case_data.gd`:
```gdscript
extends RefCounted
class_name CaseData

## Authored suspects and clues. Each suspect has 2 implicating clues; threshold is 2.
## Every "false_motive" is built from a real but innocent act (see each clue's "truth").

const SUSPECTS := {
	"alex": {"name": "Alex", "threshold": 2, "friends": ["jordan"],
		"secret": "Failed last semester quietly",
		"innocent_act": "Used the master key for a noise complaint",
		"false_motive": "Had access and a secret the victim could expose"},
	"jordan": {"name": "Jordan", "threshold": 2, "friends": ["alex", "riley"],
		"secret": "Audition anxiety",
		"innocent_act": "Rehearsing alone in the hallway; walked past the victim",
		"false_motive": "Last seen near the victim, and lied about being there"},
	"sam": {"name": "Sam", "threshold": 2, "friends": ["morgan", "alex"],
		"secret": "Owes Alex a favor; building a secret app",
		"innocent_act": "Touched the wiring/camera for his app",
		"false_motive": "Tampered with the scene; entangled in the scheme"},
	"riley": {"name": "Riley", "threshold": 2, "friends": ["jordan", "casey"],
		"secret": "Considering dropping pre-med",
		"innocent_act": "Gave the victim a harmless sleep aid",
		"false_motive": "Knew exactly how an overdose works"},
	"morgan": {"name": "Morgan", "threshold": 2, "friends": ["casey", "sam"],
		"secret": "Hiding an injury; rivalry with Alex",
		"innocent_act": "Found the body first and moved one object in panic",
		"false_motive": "Strength, bad blood, and a 'staged' scene"},
	"casey": {"name": "Casey", "threshold": 2, "friends": ["morgan", "riley"],
		"secret": "Secret portraits; knows everyone's secrets",
		"innocent_act": "Glimpsed the night through a window and sketched it",
		"false_motive": "Knew too much; the portraits look like stalking"},
}

const CLUES := {
	"clue_keys": {"title": "Scuffed master-key fob", "room": "hallway", "implicates": ["alex"],
		"truth": "Alex used it for a late noise complaint."},
	"clue_logbook": {"title": "RA logbook gap", "room": "common_room", "implicates": ["alex"],
		"truth": "The gap is Alex hiding his failed grade, not the victim."},
	"clue_pills": {"title": "Unlabeled pill bottle", "room": "common_room", "implicates": ["riley"],
		"truth": "Riley gave the victim a harmless sleep aid."},
	"clue_medbook": {"title": "Pharmacology notes", "room": "bedroom_4", "implicates": ["riley"],
		"truth": "Just exam study, not a poisoning plan."},
	"clue_wiring": {"title": "Tampered wiring", "room": "hallway", "implicates": ["sam"],
		"truth": "Sam was fixing wiring for his app."},
	"clue_camera": {"title": "Disabled camera", "room": "common_room", "implicates": ["sam"],
		"truth": "The camera was off because Sam borrowed its feed."},
	"clue_rehearsal": {"title": "Rehearsal script", "room": "hallway", "implicates": ["jordan"],
		"truth": "Proves Jordan was rehearsing, not lurking."},
	"clue_witness_jordan": {"title": "A witness places Jordan", "room": "kitchen", "implicates": ["jordan"],
		"truth": "Jordan walked past, assuming the victim was drunk."},
	"clue_moved_object": {"title": "Rearranged scene", "room": "bedroom_5", "implicates": ["morgan"],
		"truth": "Morgan moved a bottle in panic on finding the body."},
	"clue_morgan_early": {"title": "Up before dawn", "room": "kitchen", "implicates": ["morgan"],
		"truth": "Morgan was simply up early for a run."},
	"clue_sketch": {"title": "Torn courtyard sketch", "room": "kitchen", "implicates": ["casey"],
		"truth": "Casey sketched the window the night before."},
	"clue_portraits": {"title": "Secret portrait series", "room": "bedroom_6", "implicates": ["casey"],
		"truth": "The portraits are art, not surveillance."},
}


static func get_suspect_ids() -> Array:
	return SUSPECTS.keys()


static func clues_for_suspect(suspect_id: String) -> Array:
	var result: Array = []
	for clue_id in CLUES:
		if suspect_id in CLUES[clue_id]["implicates"]:
			result.append(clue_id)
	return result
```

- [ ] **Step 5: Run to verify it passes**

Run import then the test:
`"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
`"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_case_data.gd`
Expected: `PASS: test_case_data`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: CaseData — authored suspects + clues"
```

---

### Task 2: `Standing` autoload — detective's trust per NPC

**Files:**
- Create: `godot/autoload/standing.gd`
- Create: `godot/tests/test_standing.gd`
- Modify: `godot/project.godot` (register `Standing` autoload after `Investigation`)

**Interfaces:**
- Produces: autoload `Standing`: `get_standing(npc_id: String) -> float` (default 0.0, range clamped [-1,1]), `adjust(npc_id: String, delta: float) -> float`, `reset() -> void`, `signal standing_changed(npc_id: String, value: float)`, `var persist_enabled: bool`.

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_standing.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var s = preload("res://autoload/standing.gd").new()
	s.set("persist_enabled", false)
	var failures := 0
	if s.get_standing("alex") != 0.0:
		failures += 1; print("FAIL: default standing should be 0.0")
	var v: float = s.adjust("alex", -0.5)
	if absf(v - (-0.5)) > 0.001:
		failures += 1; print("FAIL: adjust should return -0.5, got %f" % v)
	if absf(s.get_standing("alex") - (-0.5)) > 0.001:
		failures += 1; print("FAIL: get_standing should be -0.5")
	# clamps to [-1, 1]
	s.adjust("alex", -5.0)
	if s.get_standing("alex") != -1.0:
		failures += 1; print("FAIL: standing should clamp at -1.0")
	if failures == 0:
		print("PASS: test_standing")
	s.free()
	quit(failures)
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_standing.gd`
Expected: preload error — file does not exist.

- [ ] **Step 3: Implement `Standing`**

Create `godot/autoload/standing.gd`:
```gdscript
extends Node

## The detective's standing (trust) with each NPC, in [-1, 1]. Starts neutral/skeptical (0).
## Accusations drop it (CaseFile applies the fallout); investigation progress can raise it later.

signal standing_changed(npc_id: String, value: float)

const SAVE_PATH := "user://standing.json"

var persist_enabled := true
var _standing: Dictionary = {}  # npc_id -> float


func _ready() -> void:
	if persist_enabled:
		_load()


func get_standing(npc_id: String) -> float:
	return float(_standing.get(npc_id, 0.0))


func adjust(npc_id: String, delta: float) -> float:
	var v: float = clampf(get_standing(npc_id) + delta, -1.0, 1.0)
	_standing[npc_id] = v
	standing_changed.emit(npc_id, v)
	if persist_enabled:
		_save()
	return v


func reset() -> void:
	_standing.clear()
	if persist_enabled:
		_save()


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_standing))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_standing = parsed
```

Register the autoload — in `godot/project.godot`, under `[autoload]`, add after the `Investigation` line:
```
Standing="*res://autoload/standing.gd"
```

- [ ] **Step 4: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_standing.gd`
Expected: `PASS: test_standing`

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: Standing autoload — detective trust per NPC"
```

---

### Task 3: `CaseFile` — case strength & accusation gating

**Files:**
- Create: `godot/autoload/case_file.gd`
- Create: `godot/tests/test_case_strength.gd`
- Modify: `godot/project.godot` (register `CaseFile` autoload after `Standing`)

**Interfaces:**
- Consumes: `CaseData` (Task 1), `Investigation` (Plan A: `is_discovered`).
- Produces: autoload `CaseFile`: `case_strength(suspect_id: String) -> int`, `can_accuse(suspect_id: String) -> bool`, injectable `var _investigation: Node`, `var _standing: Node`.

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_case_strength.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var inv = preload("res://autoload/investigation.gd").new()
	inv.set("persist_enabled", false)
	var cf = preload("res://autoload/case_file.gd").new()
	cf.set("_investigation", inv)
	var failures := 0

	if cf.case_strength("riley") != 0:
		failures += 1; print("FAIL: strength should start at 0")
	if cf.can_accuse("riley") != false:
		failures += 1; print("FAIL: cannot accuse with no evidence")

	inv.discover_clue("clue_pills")   # 1 of riley's 2 clues
	if cf.case_strength("riley") != 1:
		failures += 1; print("FAIL: strength should be 1 after one clue")
	if cf.can_accuse("riley") != false:
		failures += 1; print("FAIL: still below threshold at 1")

	inv.discover_clue("clue_medbook")  # 2nd riley clue
	if cf.case_strength("riley") != 2:
		failures += 1; print("FAIL: strength should be 2")
	if cf.can_accuse("riley") != true:
		failures += 1; print("FAIL: should be accusable at threshold")

	inv.free(); cf.free()
	if failures == 0:
		print("PASS: test_case_strength")
	quit(failures)
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_case_strength.gd`
Expected: preload error — file does not exist.

- [ ] **Step 3: Implement `CaseFile` (strength + gating)**

Create `godot/autoload/case_file.gd`:
```gdscript
extends Node

## Reads the Investigation store to compute per-suspect case strength and gate accusations.
## accuse() (Task 4) returns an ending id and applies standing fallout.

var resolved := false
var accused_id := ""

var _investigation: Node = null
var _standing: Node = null


func _ready() -> void:
	_investigation = get_node_or_null("/root/Investigation")
	_standing = get_node_or_null("/root/Standing")


func case_strength(suspect_id: String) -> int:
	if _investigation == null:
		return 0
	var count := 0
	for clue_id in CaseData.clues_for_suspect(suspect_id):
		if _investigation.is_discovered(clue_id):
			count += 1
	return count


func can_accuse(suspect_id: String) -> bool:
	if not CaseData.SUSPECTS.has(suspect_id):
		return false
	var threshold: int = CaseData.SUSPECTS[suspect_id]["threshold"]
	return case_strength(suspect_id) >= threshold
```

Register the autoload — in `godot/project.godot`, under `[autoload]`, add after the `Standing` line:
```
CaseFile="*res://autoload/case_file.gd"
```

- [ ] **Step 4: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_case_strength.gd`
Expected: `PASS: test_case_strength`

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: CaseFile — case strength + accusation gating"
```

---

### Task 4: `CaseFile.accuse` — ending result + standing fallout

**Files:**
- Modify: `godot/autoload/case_file.gd` (add `accuse`)
- Create: `godot/tests/test_accuse.gd`

**Interfaces:**
- Consumes: `CaseData`, injectable `_investigation`, `_standing` (Task 2/3).
- Produces: `CaseFile.accuse(suspect_id: String) -> Dictionary` returning
  `{accepted: bool, ending_id: String, strength: int, threshold: int}`. On accept, sets
  `resolved=true`, `accused_id=suspect_id`, drops the suspect's standing by 0.5 and each
  friend's by 0.3. On reject (below bar), drops the suspect's standing by 0.15.

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_accuse.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var inv = preload("res://autoload/investigation.gd").new()
	inv.set("persist_enabled", false)
	var st = preload("res://autoload/standing.gd").new()
	st.set("persist_enabled", false)
	var cf = preload("res://autoload/case_file.gd").new()
	cf.set("_investigation", inv)
	cf.set("_standing", st)
	var failures := 0

	# Reject when below the bar; suspect resents the baseless accusation.
	var r1: Dictionary = cf.accuse("riley")
	if r1["accepted"] != false:
		failures += 1; print("FAIL: should reject with no evidence")
	if absf(st.get_standing("riley") - (-0.15)) > 0.001:
		failures += 1; print("FAIL: rejected accusation should drop suspect standing by 0.15")
	if cf.resolved != false:
		failures += 1; print("FAIL: rejected accusation should not resolve the case")

	# Build the case, then accuse successfully.
	inv.discover_clue("clue_pills")
	inv.discover_clue("clue_medbook")
	var r2: Dictionary = cf.accuse("riley")
	if r2["accepted"] != true:
		failures += 1; print("FAIL: should accept once case is built")
	if r2["ending_id"] != "ending_riley":
		failures += 1; print("FAIL: ending_id should be ending_riley, got %s" % r2["ending_id"])
	if cf.resolved != true or cf.accused_id != "riley":
		failures += 1; print("FAIL: case should be resolved against riley")
	# fallout: riley -0.15 (earlier) -0.5 = -0.65; friend casey -0.3
	if absf(st.get_standing("riley") - (-0.65)) > 0.001:
		failures += 1; print("FAIL: accused standing wrong: %f" % st.get_standing("riley"))
	if absf(st.get_standing("casey") - (-0.3)) > 0.001:
		failures += 1; print("FAIL: friend standing should drop 0.3, got %f" % st.get_standing("casey"))

	inv.free(); st.free(); cf.free()
	if failures == 0:
		print("PASS: test_accuse")
	quit(failures)
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_accuse.gd`
Expected: FAIL/err — `accuse` not defined (Nonexistent function).

- [ ] **Step 3: Implement `accuse`**

Append to `godot/autoload/case_file.gd`:
```gdscript
func accuse(suspect_id: String) -> Dictionary:
	var threshold: int = CaseData.SUSPECTS[suspect_id]["threshold"] if CaseData.SUSPECTS.has(suspect_id) else 0
	var strength: int = case_strength(suspect_id)
	if strength < threshold or threshold == 0:
		if _standing != null and CaseData.SUSPECTS.has(suspect_id):
			_standing.adjust(suspect_id, -0.15)  # resentment at a baseless accusation
		return {"accepted": false, "ending_id": "", "strength": strength, "threshold": threshold}

	resolved = true
	accused_id = suspect_id
	if _standing != null:
		_standing.adjust(suspect_id, -0.5)
		for friend_id in CaseData.SUSPECTS[suspect_id]["friends"]:
			_standing.adjust(friend_id, -0.3)
	return {"accepted": true, "ending_id": "ending_%s" % suspect_id, "strength": strength, "threshold": threshold}
```

- [ ] **Step 4: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_accuse.gd`
Expected: `PASS: test_accuse`

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: CaseFile.accuse — ending result + standing fallout"
```

---

### Task 5: Spawn all clues in the dorm + full-flow integration test

**Files:**
- Modify: `godot/scenes/dorm/crestwood_hall.gd` (spawn hotspots from `CaseData.CLUES` instead of the 3 hardcoded)
- Create: `godot/tests/test_case_flow.gd`

**Interfaces:**
- Consumes: `CaseData.CLUES` (Task 1), `ClueHotspot` (Plan A), real autoloads `Investigation`, `CaseFile`.
- Produces: in-game, every clue in `CaseData.CLUES` is an examinable hotspot in its room.

- [ ] **Step 1: Replace the hardcoded clue list with CaseData**

In `godot/scenes/dorm/crestwood_hall.gd`, replace the body of `_spawn_clue_hotspots()` (the local `clues` array literal and its loop) with iteration over `CaseData.CLUES`:
```gdscript
func _spawn_clue_hotspots() -> void:
	# All authored clues become examinable hotspots, placed in their room.
	for clue_id in CaseData.CLUES:
		var data: Dictionary = CaseData.CLUES[clue_id]
		var hotspot := ClueHotspot.new()
		hotspot.clue_id = clue_id
		hotspot.clue_title = str(data["title"])
		hotspot.clue_description = str(data.get("truth", ""))
		hotspot.prompt_text = "Examine"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		hotspot.add_child(shape)
		add_child(hotspot)
		var room_id: String = str(data["room"])
		if room_markers.has(room_id):
			var marker: Marker2D = room_markers[room_id]
			hotspot.global_position = marker.global_position
```
(If multiple clues share a room they will overlap at the marker — acceptable for now; spacing is later polish.)

- [ ] **Step 2: Write the full-flow integration test**

Create `godot/tests/test_case_flow.gd`:
```gdscript
extends SceneTree

## End-to-end: discovering a suspect's clues (via the real Investigation autoload) raises
## CaseFile strength and unlocks the accusation, which returns the right ending.

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		var inv = root.get_node("Investigation")
		inv.reset()
		var cf = root.get_node("CaseFile")
		var failures := 0
		if cf.can_accuse("sam") != false:
			failures += 1; print("FAIL: sam not accusable initially")
		inv.discover_clue("clue_wiring")
		inv.discover_clue("clue_camera")
		if cf.case_strength("sam") != 2:
			failures += 1; print("FAIL: sam strength should be 2, got %d" % cf.case_strength("sam"))
		if cf.can_accuse("sam") != true:
			failures += 1; print("FAIL: sam should be accusable")
		var res: Dictionary = cf.accuse("sam")
		if res["accepted"] != true or res["ending_id"] != "ending_sam":
			failures += 1; print("FAIL: accuse sam should accept with ending_sam")
		if failures == 0:
			print("PASS: test_case_flow")
		quit(failures)
		return true
	return false
```

- [ ] **Step 3: Run to verify (import + flow + regressions)**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_case_flow.gd`
Expected: `PASS: test_case_flow`
Also re-run `test_examine_flow` and `test_detective_move` (Plan A) — expected PASS (hotspots still examinable; the dorm still boots).

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: spawn all clues as hotspots + full case-flow integration test"
```

---

## Self-Review

**Spec coverage (Plan B = Mystery Case Core):**
- Clue/suspect data → Task 1 (`CaseData`) ✅
- Case strength → Task 3 (`case_strength`) ✅
- Evidence-gated accusation → Task 3 (`can_accuse`) + Task 4 (`accuse` threshold) ✅
- Relationship fallout → Task 2 (`Standing`) + Task 4 (suspect −0.5, friends −0.3, baseless −0.15) ✅
- All-endings-wrong returns an ending id → Task 4 (`ending_<id>`); flashback/UI deferred to Plan D ✅
- Clues findable in-game → Task 5 ✅

**Deferred (intentional):** the accusation UI, the First Choice, and the flashback/ending content are **Plan D**. Interrogation that reveals clues via dialogue is **Plan C** (Plan B clues are found by examining hotspots, per Plan A).

**Placeholder scan:** none — all steps have concrete code/commands.

**Type/name consistency:** `CaseData.SUSPECTS/CLUES/get_suspect_ids/clues_for_suspect` consistent (Tasks 1,3,4,5); `Standing.get_standing/adjust` consistent (Tasks 2,4); `CaseFile.case_strength/can_accuse/accuse/_investigation/_standing/resolved/accused_id` consistent (Tasks 3,4,5). Accusation thresholds (2) and clue counts (2/suspect) match between `CaseData` and the tests.
