# World Expansion W1 — Travel Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the single-location game into a multi-location one: a `LocationManager` + day counter, a fast-travel map, a scene-swap host in `main` that re-binds the UI to whatever location is loaded, and one minimal new location (the detective's room) to prove the architecture end-to-end.

**Architecture:** `main.tscn` replaces its fixed `CrestwoodHall` instance with an empty `LocationHost` node. A `LocationManager` autoload knows the locations and the current one; `travel(dest)` advances the day/time and emits a signal. `main` frees the current location scene, loads the destination, and calls `_bind_location()` to re-wire the persistent UI (prompt, interrogation, search, case panel) to the new location's detective + interactables. Each location scene is self-contained and exposes `detective` + `npcs` (the dorm already does). Day counter lives on `Scheduler`.

**Tech Stack:** Godot 4.7 (GDScript). Builds on the existing `main.gd`, `crestwood_hall.gd`, `Scheduler`, and all Plan A–detailed-exam systems.

## Global Constraints

- **Engine:** Godot 4.7 stable; project root `godot/`.
- **Warnings are errors:** no `:=` inference from `Variant`-returning calls; explicit types.
- **GDScript style:** snake_case funcs/vars, PascalCase classes; typed where practical.
- **Reuse:** `Scheduler` (`set_time`, `get_hour`, `game_day`), the dorm's self-contained pattern (spawns `detective`, exposes `npcs`), `Difficulty`. Autoload deps resolved into injectable vars for tests.
- **Do not break the dorm:** every existing test must still pass; the dorm remains the default starting location.
- **Scene work needs a human:** the scene-swap visuals (camera, transitions, the new room) can't be fully verified headlessly — each scene task ends with a run/playtest step.
- **Test runner:** `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd`; `PASS: <name>`/`quit(0)` or `FAIL:`/`quit(<n>)`.
- **Git:** Task 1 creates branch `plan-world-w1` from `main`. Commit per task; end messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: `LocationManager` autoload + day counter

**Files:**
- Create: `godot/autoload/location_manager.gd`
- Create: `godot/tests/test_location_manager.gd`
- Modify: `godot/autoload/scheduler.gd` (add `advance_days(n)` helper + confirm `game_day`)
- Modify: `godot/project.godot` (register `LocationManager` after `GameFlow`)

**Interfaces:**
- Produces: autoload `LocationManager`:
  - `const LOCATIONS: Dictionary` — `id -> {name, scene, travel_hours}`
  - `var current_id: String` (starts `"dorm"`)
  - `signal location_changing(dest_id: String)`
  - `travel(dest_id: String) -> bool` (unknown/same → false; else advances time by `travel_hours` via `Scheduler`, sets `current_id`, emits `location_changing`, returns true)
  - `location_name(id) -> String`, `location_scene(id) -> String`
  - injectable `var _scheduler: Node`
- `Scheduler.advance_days(n: int) -> void` and `Scheduler.advance_hours(h: float) -> void` (wrap `set_time`, rolling `game_day`).

- [ ] **Step 1: Create branch**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git checkout main && git checkout -b plan-world-w1
```

- [ ] **Step 2: Write the failing test**

Create `godot/tests/test_location_manager.gd`:
```gdscript
extends SceneTree

# Minimal fake scheduler so the manager's time-advance is testable in isolation.
class FakeScheduler:
	extends Node
	var hours := 0.0
	func advance_hours(h: float) -> void:
		hours += h

func _initialize() -> void:
	var lm = preload("res://autoload/location_manager.gd").new()
	var sched := FakeScheduler.new()
	lm.set("_scheduler", sched)
	var failures := 0

	if lm.current_id != "dorm":
		failures += 1; print("FAIL: should start at the dorm")
	if not lm.LOCATIONS.has("detective_room"):
		failures += 1; print("FAIL: detective_room should be a known location")

	var captured := {"dest": ""}
	lm.location_changing.connect(func(d): captured["dest"] = d)

	if lm.travel("nowhere") != false:
		failures += 1; print("FAIL: unknown destination should return false")
	if lm.travel("dorm") != false:
		failures += 1; print("FAIL: travelling to the current location should return false")

	if lm.travel("detective_room") != true:
		failures += 1; print("FAIL: valid travel should return true")
	if lm.current_id != "detective_room":
		failures += 1; print("FAIL: current_id should update")
	if captured["dest"] != "detective_room":
		failures += 1; print("FAIL: location_changing should fire with dest")
	if sched.hours <= 0.0:
		failures += 1; print("FAIL: travel should advance time")

	lm.free(); sched.free()
	if failures == 0:
		print("PASS: test_location_manager")
	quit(failures)
```

- [ ] **Step 3: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_location_manager.gd`
Expected: preload error — file does not exist.

- [ ] **Step 4: Implement scheduler helpers + LocationManager**

In `godot/autoload/scheduler.gd`, add (uses existing `set_time(hour, day)` + `game_day`, `get_hour()`):
```gdscript
func advance_hours(h: float) -> void:
	var total: float = get_hour() + h
	var day_gain: int = int(total) / 24
	var new_hour: float = fmod(total, 24.0)
	set_time(new_hour, game_day + day_gain)


func advance_days(n: int) -> void:
	set_time(get_hour(), game_day + n)
```

Create `godot/autoload/location_manager.gd`:
```gdscript
extends Node

## Which places exist and where the detective currently is. Travelling advances time.

const LOCATIONS := {
	"dorm": {"name": "Crestwood Hall", "scene": "res://scenes/dorm/crestwood_hall.tscn", "travel_hours": 0.0},
	"detective_room": {"name": "Your Room", "scene": "res://scenes/locations/detective_room.tscn", "travel_hours": 1.0},
}

signal location_changing(dest_id: String)

var current_id := "dorm"
var _scheduler: Node = null


func _ready() -> void:
	_scheduler = get_node_or_null("/root/Scheduler")


func travel(dest_id: String) -> bool:
	if not LOCATIONS.has(dest_id) or dest_id == current_id:
		return false
	var hours: float = float(LOCATIONS[dest_id]["travel_hours"])
	if _scheduler != null and hours > 0.0:
		_scheduler.advance_hours(hours)
	current_id = dest_id
	location_changing.emit(dest_id)
	return true


func location_name(id: String) -> String:
	return str(LOCATIONS[id]["name"]) if LOCATIONS.has(id) else id


func location_scene(id: String) -> String:
	return str(LOCATIONS[id]["scene"]) if LOCATIONS.has(id) else ""
```

Register the autoload — in `godot/project.godot`, under `[autoload]`, after the `GameFlow` line:
```
LocationManager="*res://autoload/location_manager.gd"
```

- [ ] **Step 5: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_location_manager.gd`
Expected: `PASS: test_location_manager`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: LocationManager + Scheduler day/hour advance"
```

---

### Task 2: Minimal `detective_room` location scene

**Files:**
- Create: `godot/scenes/locations/detective_room.gd`
- Create: `godot/scenes/locations/detective_room.tscn`

**Interfaces:**
- Produces: a self-contained location scene (root `Node2D`) that, like the dorm, exposes `var detective: CharacterBody2D`, `var npcs: Array` (empty here), and spawns a detective + a small nav region so movement works. A `SearchPoint` (your case board) + a "Rest (advance a day)" is optional flavor; keep it minimal for W1.

- [ ] **Step 1: Implement the room script**

Create `godot/scenes/locations/detective_room.gd`:
```gdscript
extends Node2D

## A minimal self-contained location: spawns the detective on a small nav region so travel +
## movement work. Mirrors the dorm's "exposes detective + npcs" contract.

const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")

@onready var _nav_region: NavigationRegion2D = $NavigationRegion2D

var detective: CharacterBody2D = null
var npcs: Array = []


func _ready() -> void:
	detective = DETECTIVE_SCENE.instantiate() as CharacterBody2D
	add_child(detective)
	detective.global_position = Vector2(400, 300)
```

- [ ] **Step 2: Build the scene**

Create `godot/scenes/locations/detective_room.tscn` (a floor `ColorRect`, a baked `NavigationRegion2D` rectangle, a label):
```
[gd_scene load_steps=3 format=3 uid="uid://detective_room"]

[ext_resource type="Script" path="res://scenes/locations/detective_room.gd" id="1"]

[sub_resource type="NavigationPolygon" id="navpoly"]
vertices = PackedVector2Array(120, 120, 680, 120, 680, 480, 120, 480)
polygons = [PackedInt32Array(0, 1, 2, 3)]

[node name="DetectiveRoom" type="Node2D"]
script = ExtResource("1")

[node name="Floor" type="ColorRect" parent="."]
offset_left = 120.0
offset_top = 120.0
offset_right = 680.0
offset_bottom = 480.0
color = Color(0.16, 0.15, 0.2, 1)

[node name="NameLabel" type="Label" parent="."]
offset_left = 130.0
offset_top = 128.0
text = "Your Room"

[node name="NavigationRegion2D" type="NavigationRegion2D" parent="."]
navigation_polygon = SubResource("navpoly")
```

- [ ] **Step 3: Verify it imports + instantiates**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Expected: no `SCRIPT ERROR` / `Failed to load` referencing `detective_room`.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: minimal detective_room location scene"
```

---

### Task 3: Scene-swap host in `main` (re-bind UI to the loaded location)

**Files:**
- Modify: `godot/scenes/main.tscn` (replace the fixed `CrestwoodHall` instance with a `LocationHost` Node2D that starts by containing the dorm)
- Modify: `godot/scenes/main.gd` (extract `_bind_location(loc)`; load the dorm into the host on start; swap on `location_changing`)
- Create: `godot/tests/test_location_swap.gd`

**Interfaces:**
- Consumes: `LocationManager.location_changing`/`location_scene` (Task 1), the location scenes (dorm, Task 2 room).
- Produces: `main.gd` — `var _location: Node2D` (the current loaded location), `_load_location(id)`, `_bind_location(loc)` (all the detective/prompt/interactable/npc wiring that `_ready` used to do against `_hall`, now against the passed location).

- [ ] **Step 1: Restructure main.tscn**

In `godot/scenes/main.tscn`, replace the `CrestwoodHall` instance node with an empty host. Remove the `[node name="CrestwoodHall" ...]` line and the dorm `ext_resource`, and add:
```
[node name="LocationHost" type="Node2D" parent="."]
```
(The dorm is now loaded into the host at runtime, not baked into main.)

- [ ] **Step 2: Refactor main.gd to load + bind locations**

In `godot/scenes/main.gd`, replace the `@onready var _hall` line with:
```gdscript
@onready var _host: Node2D = $LocationHost
var _location: Node2D = null
```
Add at the very start of `_ready()` (before anything uses the location):
```gdscript
	_load_location(LocationManager.current_id)
	LocationManager.location_changing.connect(_load_location)
```
Add `_load_location` + move the per-location wiring out of `_ready` into `_bind_location`:
```gdscript
func _load_location(id: String) -> void:
	if _location != null:
		_location.queue_free()
	var scene: PackedScene = load(LocationManager.location_scene(id))
	_location = scene.instantiate()
	_host.add_child(_location)
	_bind_location(_location)


func _bind_location(loc: Node2D) -> void:
	if loc.detective != null:
		_prompt.bind(loc.detective.get_node("Interactor"))
	set_mode(Mode.PLAY)
	_observer.bind_npcs(loc.npcs)
	for npc in loc.npcs:
		var area: Area2D = npc.get_node("ClickArea")
		area.input_pickable = true
		area.input_event.connect(_on_npc_input.bind(npc))
		for ch in npc.get_children():
			if ch is NpcInteractable:
				ch.talk_requested.connect(_on_talk_requested)
	for ch in loc.get_children():
		if ch is SearchPoint:
			ch.search_requested.connect(_on_search_requested)
```
Everywhere else in `main.gd` that referenced `_hall`, use `_location` instead (e.g. `set_mode` reads `_location.detective`; `toggle_case`/observer logic unchanged). Delete the old `await _hall.npcs_ready` block — locations are loaded synchronously here so `loc.npcs` is ready immediately after `_bind_location` runs (the dorm populates `npcs` in its own `_ready`, which fires on `add_child`).

- [ ] **Step 3: Write the swap test**

Create `godot/tests/test_location_swap.gd`:
```gdscript
extends SceneTree

var _phase := 0
var _main
var _frames := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		# starts in the dorm
		var loc = _main.get_node("LocationHost").get_child(0)
		if loc.name != "CrestwoodHall":
			print("FAIL: should start in the dorm (got %s)" % loc.name); quit(1); return true
		# travel to the detective's room
		root.get_node("LocationManager").travel("detective_room")
		return false
	_frames += 1
	if _frames < 3:
		return false
	var host = _main.get_node("LocationHost")
	var loaded := host.get_child_count() >= 1 and host.get_child(host.get_child_count() - 1).name == "DetectiveRoom"
	if loaded:
		print("PASS: test_location_swap — travelled dorm -> detective room")
		quit(0)
	else:
		print("FAIL: location did not swap to the detective room")
		quit(1)
	return true
```

- [ ] **Step 4: Run to verify (import + swap + regressions)**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_location_swap.gd`
Expected: `PASS: test_location_swap`
Then re-run `test_flow_wiring`, `test_examine_flow`, `test_search_wiring`, `test_interrogation_wiring` — expected PASS (the dorm still loads + wires exactly as before, just via the host).

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: LocationHost scene-swap in main + _bind_location re-wiring"
```

---

### Task 4: Fast-travel map UI

**Files:**
- Create: `godot/scenes/ui/travel_map.gd`
- Create: `godot/scenes/ui/travel_map.tscn`
- Modify: `godot/scenes/main.tscn` (add `TravelMap` under `UI`)
- Modify: `godot/scenes/main.gd` (open on a `toggle_map` key; a location button calls `LocationManager.travel`)
- Modify: `godot/project.godot` (add `toggle_map` input action, key M)
- Create: `godot/tests/test_travel_map.gd`

**Interfaces:**
- Consumes: `LocationManager.LOCATIONS`/`travel`/`current_id`.
- Produces: `TravelMap` (extends `CanvasLayer`): `open()`, `signal travel_requested(dest_id)`; one button per location (the current one disabled). `main` routes `travel_requested` → `LocationManager.travel` + closes the map.

- [ ] **Step 1: Implement the map script**

Create `godot/scenes/ui/travel_map.gd`:
```gdscript
extends CanvasLayer

signal travel_requested(dest_id: String)

@onready var _list: VBoxContainer = $Panel/VBox/List


func _ready() -> void:
	$Panel/VBox/CloseButton.pressed.connect(close)
	visible = false


func open() -> void:
	for child in _list.get_children():
		child.queue_free()
	for id in LocationManager.LOCATIONS:
		var btn := Button.new()
		btn.text = LocationManager.location_name(id)
		btn.disabled = id == LocationManager.current_id
		btn.pressed.connect(_on_pick.bind(id))
		_list.add_child(btn)
	visible = true


func close() -> void:
	visible = false


func _on_pick(dest_id: String) -> void:
	travel_requested.emit(dest_id)
	close()
```

- [ ] **Step 2: Build the scene**

Create `godot/scenes/ui/travel_map.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://travel_map"]
[ext_resource type="Script" path="res://scenes/ui/travel_map.gd" id="1"]

[node name="TravelMap" type="CanvasLayer"]
layer = 2
script = ExtResource("1")

[node name="Dim" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 0.8)

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -180.0
offset_top = -140.0
offset_right = 180.0
offset_bottom = 140.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="Panel"]

[node name="Title" type="Label" parent="Panel/VBox"]
text = "Travel"
horizontal_alignment = 1

[node name="List" type="VBoxContainer" parent="Panel/VBox"]

[node name="CloseButton" type="Button" parent="Panel/VBox"]
text = "Stay here"
```

- [ ] **Step 3: Add the input action + wire main**

In `godot/project.godot`, under `[input]` (after `toggle_case`), add (physical keycode 77 = M):
```
toggle_map={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":77,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
```
In `main.tscn`, add the ext_resource + a `[node name="TravelMap" parent="UI" instance=ExtResource("<id>")]`.
In `main.gd`: `@onready var _travel_map: CanvasLayer = $UI/TravelMap`; in `_ready` connect `_travel_map.travel_requested.connect(func(d): LocationManager.travel(d))`; in `_unhandled_input`, add near the other toggles:
```gdscript
	if event.is_action_pressed("toggle_map") and GameFlow.phase == GameFlow.Phase.INVESTIGATION:
		_travel_map.open()
		return
```

- [ ] **Step 4: Write the test**

Create `godot/tests/test_travel_map.gd`:
```gdscript
extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var map = load("res://scenes/ui/travel_map.tscn").instantiate()
		root.add_child(map)
		var lm = root.get_node("LocationManager")
		var failures := 0
		var captured := {"dest": ""}
		map.travel_requested.connect(func(d): captured["dest"] = d)
		map.open()
		var btns: int = map.get_node("Panel/VBox/List").get_child_count()
		if btns != LocationManager.LOCATIONS.size():
			failures += 1; print("FAIL: one button per location expected")
		# find the detective_room button and press it
		for b in map.get_node("Panel/VBox/List").get_children():
			if b.text == LocationManager.location_name("detective_room"):
				b.pressed.emit()
		if captured["dest"] != "detective_room":
			failures += 1; print("FAIL: picking a location should emit travel_requested")
		if failures == 0:
			print("PASS: test_travel_map")
		quit(failures)
		return true
	return false
```

- [ ] **Step 5: Run (import + map test + full suite)**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run the map test (expect `PASS: test_travel_map`), then the whole suite — all expected PASS.

- [ ] **Step 6: Human playtest**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot`
Expected: choose murder, press **M** → the travel map lists Crestwood Hall (disabled) + Your Room. Pick Your Room → the dorm unloads and you're standing in the (blank) detective's room; press M again to travel back. Movement/E/F/C still work in the dorm after returning.

- [ ] **Step 7: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: fast-travel map (M) between locations"
```

---

## Self-Review

**Spec coverage (W1 foundation):**
- Multiple locations + travel → `LocationManager` (Task 1) ✅
- Day/time advances on travel → `Scheduler.advance_hours` + `travel` (Task 1) ✅
- Scene swapping without breaking the dorm → `LocationHost` + `_bind_location` (Task 3) ✅
- Fast-travel map (default travel mode) → `TravelMap` (Task 4) ✅
- A second location proving it → `detective_room` (Task 2) ✅

**Deferred to W2 (intentional):** police station + university scenes, enterable dorm bedrooms/washroom (search points there), the "rest to advance a day" action, and the walk-through-doors travel option. This W1 slice is the reusable spine those build on.

**Placeholder scan:** none — all steps have concrete code/commands (the scene `.tscn` blocks are complete).

**Type/name consistency:** `LocationManager.LOCATIONS/current_id/travel/location_changing/location_name/location_scene` consistent (Tasks 1,3,4); location scenes expose `detective` + `npcs` matching `_bind_location` (Tasks 2,3); `Scheduler.advance_hours` used by `travel` (Task 1). Risk: the `main.gd` refactor (Task 3) is the load-bearing change — the swap test + re-running the four wiring tests guard it, and Task 4's playtest confirms the visuals.
```
