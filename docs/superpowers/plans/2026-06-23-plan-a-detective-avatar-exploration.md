# Plan A — Detective Avatar & Exploration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a player-controlled detective who walks the living Crestwood Hall dorm (click-to-move), finds the autonomous NPCs, examines clue hotspots that get logged, and can toggle between detective "play" mode and the existing observer mode.

**Architecture:** Reuse the project's existing `NavigationAgent2D` movement pattern for a `CharacterBody2D` detective with its own follow-camera. Add a lightweight two-component interaction layer (an `Interactor` Area2D on the detective + `Interactable` Area2D targets) modeled on the well-known Godot pattern ([MASSHUU12/godot-interaction-system](https://github.com/MASSHUU12/godot-interaction-system), [Ludonauta active/passive](https://ludonauta.itch.io/platformer-essentials)) but written in GDScript on our own autoloads. Clue discovery is recorded in a new `Investigation` autoload (a minimal store that Plan B's case core will build on). Mode switching lives in `main.gd`, which already owns the observer camera and input.

**Tech Stack:** Godot 4.7 (GDScript), `CharacterBody2D` + `NavigationAgent2D` + `NavigationRegion2D` (existing), `Area2D` interaction, `CanvasLayer` UI. No new addons.

## Global Constraints

- **Engine:** Godot 4.7 stable. Project runs from `godot/` (the Godot project root).
- **Warnings are errors:** never use `:=` inference on a `Variant`-returning call (e.g. `JSON.parse_string`, `ClassDB.instantiate`, `Dictionary.get`). Declare an explicit type (`var x: Variant = ...` / `var x: Dictionary = ...`). This project fails to compile otherwise.
- **GDScript style:** snake_case funcs/vars, PascalCase classes/nodes, `@onready` for node refs, typed signals/vars where practical. Comment non-obvious logic only.
- **Reuse, don't reinvent:** use existing autoloads `EventLog.log_action(text, category)`, `Scheduler`, `EventBus`, `LocalMemory`. Follow the `NavigationAgent2D` usage in `godot/scripts/behavior/move_to_marker.gd`.
- **Test runner (headless):** `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd` — each test script prints `PASS: <name>` and `quit(0)` on success, or prints `FAIL: ...` lines and `quit(<n>)` on failure.
- **Not yet a git repo:** Task 1 initializes git. Commit after every task.
- Existing scene facts (verified): `scenes/main.tscn` = `Main(Node2D)` → `DayNightModulate(CanvasModulate)`, `CrestwoodHall(instance)`, `Camera2D` (the OBSERVER camera, pos 640,360), `UI(CanvasLayer)` → `ObserverPanel`. `main.gd` drives the observer camera (WASD pan, wheel zoom, middle-drag) and routes NPC `ClickArea` left-clicks to `_observer.select_npc(npc)`. `crestwood_hall.gd` owns `$RoomMarkers`, `$NPCs`, `$NavigationRegion2D`, dict `room_markers`, array `npcs`, and spawns NPCs in code.

---

### Task 1: Repo init, test harness, and the `Investigation` clue store

**Files:**
- Create: `.gitignore`
- Create: `godot/tests/test_investigation.gd`
- Create: `godot/autoload/investigation.gd`
- Modify: `godot/project.godot` (register `Investigation` autoload — add under `[autoload]`, after `LocalMemory`)

**Interfaces:**
- Produces: autoload `Investigation` with `discover_clue(clue_id: String) -> bool`, `is_discovered(clue_id: String) -> bool`, `discovered_count() -> int`, `reset() -> void`, signal `clue_discovered(clue_id: String)`.

- [ ] **Step 1: Initialize git with a sensible ignore**

Create `.gitignore` (repo root):
```gitignore
# Godot
godot/.godot/
godot/models/*.gguf
# Python AI server
ai-server/.venv/
__pycache__/
*.pyc
# OS
Thumbs.db
.DS_Store
```
Run:
```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git init && git add -A && git commit -m "chore: initial commit of existing project + story design"
```
Expected: a commit is created (the gguf models and .godot cache are excluded).

- [ ] **Step 2: Write the failing test**

Create `godot/tests/test_investigation.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var script := preload("res://autoload/investigation.gd")
	var inv = script.new()
	inv.set("persist_enabled", false)  # don't write user:// during tests
	var failures := 0

	if inv.discover_clue("clue_keys") != true:
		failures += 1; print("FAIL: first discover should return true")
	if inv.discover_clue("clue_keys") != false:
		failures += 1; print("FAIL: duplicate discover should return false")
	if inv.is_discovered("clue_keys") != true:
		failures += 1; print("FAIL: is_discovered should be true")
	if inv.discover_clue("") != false:
		failures += 1; print("FAIL: empty id should be rejected")
	if inv.discovered_count() != 1:
		failures += 1; print("FAIL: discovered_count should be 1")
	inv.reset()
	if inv.discovered_count() != 0:
		failures += 1; print("FAIL: reset should clear")

	if failures == 0:
		print("PASS: test_investigation")
	quit(failures)
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_investigation.gd`
Expected: error that `res://autoload/investigation.gd` does not exist (script load failure).

- [ ] **Step 4: Implement `Investigation`**

Create `godot/autoload/investigation.gd`:
```gdscript
extends Node

## Minimal discovered-clue store for the exploration slice.
## Plan B's CaseFile will build on this (case strength, accusation gating).

signal clue_discovered(clue_id: String)

const SAVE_PATH := "user://investigation.json"

var persist_enabled := true
var _discovered: Dictionary = {}  # clue_id -> true


func _ready() -> void:
	if persist_enabled:
		_load()


func discover_clue(clue_id: String) -> bool:
	if clue_id.is_empty() or _discovered.has(clue_id):
		return false
	_discovered[clue_id] = true
	clue_discovered.emit(clue_id)
	if persist_enabled:
		_save()
	return true


func is_discovered(clue_id: String) -> bool:
	return _discovered.has(clue_id)


func discovered_count() -> int:
	return _discovered.size()


func reset() -> void:
	_discovered.clear()
	if persist_enabled:
		_save()


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_discovered))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_discovered = parsed
```

Register the autoload — in `godot/project.godot`, under `[autoload]`, add after the `LocalMemory` line:
```
Investigation="*res://autoload/investigation.gd"
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_investigation.gd`
Expected output contains: `PASS: test_investigation`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: Investigation clue store + headless test harness"
```

---

### Task 2: Interaction components (`Interactable`, `Interactor`) and `ClueHotspot`

**Files:**
- Create: `godot/scripts/player/interactable.gd`
- Create: `godot/scripts/player/interactor.gd`
- Create: `godot/scripts/player/clue_hotspot.gd`
- Create: `godot/tests/test_interaction.gd`

**Interfaces:**
- Consumes: `Investigation` (Task 1).
- Produces:
  - `Interactable` (extends `Area2D`, `class_name Interactable`): `@export var prompt_text: String`; `get_prompt() -> String`; `interact() -> void`.
  - `Interactor` (extends `Area2D`, `class_name Interactor`): tracks overlapping `Interactable`s, exposes `current: Interactable`, `signal target_changed(target: Interactable)`, `try_interact() -> bool`, and `static _pick_nearest(items: Array, from: Vector2) -> Interactable`.
  - `ClueHotspot` (extends `Interactable`, `class_name ClueHotspot`): `@export clue_id/clue_title/clue_description`; examining calls `Investigation.discover_clue`.

- [ ] **Step 1: Write the failing test (nearest-pick logic + clue examine)**

Create `godot/tests/test_interaction.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var interactor_script := preload("res://scripts/player/interactor.gd")
	var interactable_script := preload("res://scripts/player/interactable.gd")
	var clue_script := preload("res://scripts/player/clue_hotspot.gd")
	var failures := 0

	# _pick_nearest returns the closest valid item
	var a = interactable_script.new(); a.position = Vector2(100, 0)
	var b = interactable_script.new(); b.position = Vector2(10, 0)
	var nearest = interactor_script._pick_nearest([a, b], Vector2.ZERO)
	if nearest != b:
		failures += 1; print("FAIL: nearest should be b (closest)")
	if interactor_script._pick_nearest([], Vector2.ZERO) != null:
		failures += 1; print("FAIL: empty list should give null")
	a.free(); b.free()

	# ClueHotspot.interact discovers its clue once
	var inv := preload("res://autoload/investigation.gd").new()
	inv.set("persist_enabled", false)
	var clue = clue_script.new()
	clue.clue_id = "clue_test"
	clue.clue_title = "Test Clue"
	clue.examine(inv)  # explicit-store form for testing
	if inv.is_discovered("clue_test") != true:
		failures += 1; print("FAIL: examine should discover the clue")
	clue.free()

	if failures == 0:
		print("PASS: test_interaction")
	quit(failures)
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_interaction.gd`
Expected: load error (scripts do not exist yet).

- [ ] **Step 3: Implement `Interactable`**

Create `godot/scripts/player/interactable.gd`:
```gdscript
extends Area2D
class_name Interactable

## Passive component: something the detective can interact with.

@export var prompt_text: String = "Examine"


func get_prompt() -> String:
	return prompt_text


func interact() -> void:
	pass
```

- [ ] **Step 4: Implement `Interactor`**

Create `godot/scripts/player/interactor.gd`:
```gdscript
extends Area2D
class_name Interactor

## Active component: lives on the detective, tracks nearby Interactables,
## and exposes the nearest one as the current interaction target.

signal target_changed(target: Interactable)

var current: Interactable = null
var _in_range: Array[Interactable] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and not _in_range.has(area):
		_in_range.append(area)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_in_range.erase(area)


func _physics_process(_delta: float) -> void:
	var nearest := _pick_nearest(_in_range, global_position)
	if nearest != current:
		current = nearest
		target_changed.emit(current)


func try_interact() -> bool:
	if current != null:
		current.interact()
		return true
	return false


static func _pick_nearest(items: Array, from: Vector2) -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for it in items:
		if not is_instance_valid(it):
			continue
		var d: float = from.distance_squared_to(it.global_position)
		if d < best_dist:
			best_dist = d
			best = it
	return best
```

- [ ] **Step 5: Implement `ClueHotspot`**

Create `godot/scripts/player/clue_hotspot.gd`:
```gdscript
extends Interactable
class_name ClueHotspot

## An examinable clue. On first examine it logs to the Investigation store + EventLog.

@export var clue_id: String = ""
@export var clue_title: String = ""
@export_multiline var clue_description: String = ""
@export var examined_prompt: String = "Examined"


func get_prompt() -> String:
	if clue_id != "" and Investigation.is_discovered(clue_id):
		return examined_prompt
	return prompt_text


func interact() -> void:
	examine(Investigation)


## Store-injectable form so logic is testable without the autoload.
func examine(store) -> void:
	if clue_id == "":
		return
	if store.discover_clue(clue_id):
		EventLog.log_action("Found: %s" % clue_title, "clue")
```

- [ ] **Step 6: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_interaction.gd`
Expected output contains: `PASS: test_interaction`

(Note: `EventLog` is an autoload; in `-s` test mode it is available on the tree. `examine` only calls it on first discovery, which happens once in the test — acceptable.)

- [ ] **Step 7: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: Interactable/Interactor components + ClueHotspot"
```

---

### Task 3: Detective avatar scene (click-to-move + follow camera + interactor)

**Files:**
- Create: `godot/scenes/player/detective.tscn`
- Create: `godot/scenes/player/detective.gd`
- Modify: `godot/project.godot` (add `interact` input action)

**Interfaces:**
- Consumes: `Interactor` (Task 2), existing `NavigationRegion2D` baked on the dorm.
- Produces: `Detective` (extends `CharacterBody2D`): `set_control_enabled(enabled: bool) -> void`, child `Interactor` named `Interactor`, child `Camera2D` named `Camera2D`.

- [ ] **Step 1: Add the `interact` input action**

In `godot/project.godot`, under `[input]`, add (physical keycode 69 = E):
```
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
```

- [ ] **Step 2: Implement the detective script**

Create `godot/scenes/player/detective.gd` (click-to-move pattern mirrors `scripts/behavior/move_to_marker.gd`):
```gdscript
extends CharacterBody2D

## Player-controlled detective. Left-click to move on the dorm nav mesh; camera follows.

const SPEED := 220.0

@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _camera: Camera2D = $Camera2D
@onready var _interactor: Interactor = $Interactor

var control_enabled := true


func _unhandled_input(event: InputEvent) -> void:
	if not control_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_agent.target_position = get_global_mouse_position()
	elif event.is_action_pressed("interact"):
		_interactor.try_interact()


func _physics_process(_delta: float) -> void:
	if not control_enabled or _agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var next: Vector2 = _agent.get_next_path_position()
	velocity = global_position.direction_to(next) * SPEED
	move_and_slide()


func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	_camera.enabled = enabled
```

- [ ] **Step 3: Build the detective scene**

Create `godot/scenes/player/detective.tscn` with this exact node tree and script:
```
[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scenes/player/detective.gd" id="1"]

[sub_resource type="CircleShape2D" id="body_shape"]
radius = 12.0

[sub_resource type="CircleShape2D" id="reach_shape"]
radius = 40.0

[node name="Detective" type="CharacterBody2D"]
script = ExtResource("1")

[node name="Sprite" type="ColorRect" parent="."]
offset_left = -10.0
offset_top = -10.0
offset_right = 10.0
offset_bottom = 10.0
color = Color(0.95, 0.85, 0.25, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("body_shape")

[node name="NavigationAgent2D" type="NavigationAgent2D" parent="."]
path_desired_distance = 6.0
target_desired_distance = 6.0

[node name="Camera2D" type="Camera2D" parent="."]

[node name="Interactor" type="Area2D" parent="."]
script = ExtResource("res://scripts/player/interactor.gd")

[node name="ReachShape" type="CollisionShape2D" parent="Interactor"]
shape = SubResource("reach_shape")
```
> If the editor requires the `Interactor` script as a separate `ext_resource`, add it to the header `load_steps` and `[ext_resource ... id="2"]`, then set `script = ExtResource("2")` on the `Interactor` node.

- [ ] **Step 4: Verify the scene loads headlessly**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Expected: no `SCRIPT ERROR` / `Failed to load` lines referencing `detective` or `interactor`.

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: detective avatar scene (click-to-move + interactor + camera)"
```

---

### Task 4: Interaction prompt UI

**Files:**
- Create: `godot/scenes/ui/interaction_prompt.gd`
- Create: `godot/scenes/ui/interaction_prompt.tscn`

**Interfaces:**
- Consumes: `Interactor.target_changed` (Task 2/3).
- Produces: `InteractionPrompt` (extends `CanvasLayer`): `bind(interactor: Interactor) -> void` — shows `"[E] <prompt>"` when a target exists, hides otherwise.

- [ ] **Step 1: Implement the prompt script**

Create `godot/scenes/ui/interaction_prompt.gd`:
```gdscript
extends CanvasLayer

@onready var _label: Label = $Label


func bind(interactor: Interactor) -> void:
	interactor.target_changed.connect(_on_target_changed)
	_on_target_changed(interactor.current)


func _on_target_changed(target: Interactable) -> void:
	if target == null:
		_label.visible = false
		return
	_label.visible = true
	_label.text = "[E] %s" % target.get_prompt()
```

- [ ] **Step 2: Build the prompt scene**

Create `godot/scenes/ui/interaction_prompt.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/ui/interaction_prompt.gd" id="1"]

[node name="InteractionPrompt" type="CanvasLayer"]
script = ExtResource("1")

[node name="Label" type="Label" parent="."]
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -120.0
offset_top = -64.0
offset_right = 120.0
offset_bottom = -32.0
horizontal_alignment = 1
text = "[E] Examine"
visible = false
```

- [ ] **Step 3: Verify it imports cleanly**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Expected: no errors referencing `interaction_prompt`.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: interaction prompt UI"
```

---

### Task 5: Wire the detective + clue hotspots into the dorm (end-to-end exploration)

**Files:**
- Modify: `godot/scenes/dorm/crestwood_hall.gd` (spawn detective + clue hotspots; expose `detective`)
- Modify: `godot/scenes/main.tscn` (add the `InteractionPrompt` under `UI`)
- Modify: `godot/scenes/main.gd` (bind the prompt to the detective's interactor after spawn)

**Interfaces:**
- Consumes: `Detective` scene (Task 3), `ClueHotspot` (Task 2), `InteractionPrompt` (Task 4).
- Produces: `crestwood_hall.gd` exposes `var detective: CharacterBody2D` and `signal detective_ready(detective)`.

- [ ] **Step 1: Spawn the detective and clue hotspots in the dorm**

In `godot/scenes/dorm/crestwood_hall.gd`: add the preloads near the top (after the existing `NPC_SCENE` const):
```gdscript
const DETECTIVE_SCENE := preload("res://scenes/player/detective.tscn")
const CLUE_HOTSPOT_SCRIPT := preload("res://scripts/player/clue_hotspot.gd")
```
Add the signal + var (near the existing `npcs_ready` signal / `npcs` var):
```gdscript
signal detective_ready(detective)
var detective: CharacterBody2D = null
```
At the end of `_ready()` (after `_setup_ambient_audio()`), add:
```gdscript
	_spawn_detective()
	_spawn_clue_hotspots()
```
Add these methods:
```gdscript
func _spawn_detective() -> void:
	detective = DETECTIVE_SCENE.instantiate()
	# Start in the hallway marker if present, else center.
	var spawn: Vector2 = Vector2(450, 120)
	if room_markers.has("hallway"):
		spawn = room_markers["hallway"].global_position
	detective.global_position = spawn
	add_child(detective)
	detective_ready.emit(detective)


func _spawn_clue_hotspots() -> void:
	# Authored exploration-slice clues. Plan B replaces this with the full clue dataset.
	var clues := [
		{"id": "clue_keys", "title": "Scuffed master-key fob", "room": "hallway",
			"desc": "An RA key fob, recently used. Someone had access that night."},
		{"id": "clue_pills", "title": "Unlabeled pill bottle", "room": "common_room",
			"desc": "Half-empty, no pharmacy label. Whose were these?"},
		{"id": "clue_sketch", "title": "Torn sketch corner", "room": "kitchen",
			"desc": "A fragment of a charcoal drawing of the courtyard window."},
	]
	for c in clues:
		var hotspot := Area2D.new()
		hotspot.set_script(CLUE_HOTSPOT_SCRIPT)
		hotspot.clue_id = c["id"]
		hotspot.clue_title = c["title"]
		hotspot.clue_description = c["desc"]
		hotspot.prompt_text = "Examine"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		hotspot.add_child(shape)
		var room_id: String = c["room"]
		if room_markers.has(room_id):
			hotspot.global_position = room_markers[room_id].global_position
		add_child(hotspot)
```

- [ ] **Step 2: Add the InteractionPrompt to main and bind it**

In `godot/scenes/main.tscn`, add the prompt instance under the existing `UI` `CanvasLayer`. Add to the header `ext_resource` list:
```
[ext_resource type="PackedScene" path="res://scenes/ui/interaction_prompt.tscn" id="4"]
```
And add the node (sibling of `ObserverPanel`, under `UI`):
```
[node name="InteractionPrompt" parent="UI" instance=ExtResource("4")]
```

In `godot/scenes/main.gd`, add an `@onready` ref near the others:
```gdscript
@onready var _prompt: CanvasLayer = $UI/InteractionPrompt
```
In `_ready()`, after `await _hall.npcs_ready` and the NPC wiring loop, bind the prompt once the detective exists:
```gdscript
	if _hall.detective != null:
		_prompt.bind(_hall.detective.get_node("Interactor"))
```

- [ ] **Step 3: Run the game and verify exploration works**

Run (interactive, not headless): `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot`
Expected: the yellow detective appears in the hallway; left-clicking moves it across the dorm; walking onto a clue hotspot shows `[E] Examine`; pressing E logs `Found: <title>` (visible in the observer panel's event log) and the prompt changes to `[E] Examined`.

- [ ] **Step 4: Verify no headless errors**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --quit-after 180`
Expected: no `SCRIPT ERROR` lines.

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: detective + clue hotspots wired into the dorm (playable exploration)"
```

---

### Task 6: Play / Observer mode toggle

**Files:**
- Modify: `godot/scenes/main.gd` (mode state; camera + control switching)
- Modify: `godot/project.godot` (add `toggle_mode` input action)
- Create: `godot/tests/test_mode_state.gd`

**Interfaces:**
- Consumes: `Detective.set_control_enabled` (Task 3), existing observer `Camera2D` + `ObserverPanel`.
- Produces: in `main.gd` — `enum Mode { PLAY, OBSERVER }`, `var mode: Mode`, `set_mode(m: Mode) -> void`, and a pure helper `static _next_mode(m: int) -> int`.

- [ ] **Step 1: Add the `toggle_mode` input action**

In `godot/project.godot`, under `[input]`, add (physical keycode 4194306 = Tab):
```
toggle_mode={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194306,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
```

- [ ] **Step 2: Write the failing test for the pure mode helper**

Create `godot/tests/test_mode_state.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var main := preload("res://scenes/main.gd")
	var failures := 0
	# 0 = PLAY, 1 = OBSERVER; toggling alternates.
	if main._next_mode(0) != 1:
		failures += 1; print("FAIL: PLAY should toggle to OBSERVER")
	if main._next_mode(1) != 0:
		failures += 1; print("FAIL: OBSERVER should toggle to PLAY")
	if failures == 0:
		print("PASS: test_mode_state")
	quit(failures)
```

- [ ] **Step 3: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_mode_state.gd`
Expected: error that `_next_mode` is not found / not a static function.

- [ ] **Step 4: Implement mode switching in `main.gd`**

In `godot/scenes/main.gd`, add near the top (after `extends Node2D`):
```gdscript
enum Mode { PLAY, OBSERVER }

var mode: Mode = Mode.PLAY
```
Add the pure helper (top-level func):
```gdscript
static func _next_mode(m: int) -> int:
	return Mode.OBSERVER if m == Mode.PLAY else Mode.PLAY
```
At the end of `_ready()`, start in PLAY once the detective exists:
```gdscript
	set_mode(Mode.PLAY)
```
Add the toggle handling — extend the existing `_unhandled_input` (add this branch at the top of that function):
```gdscript
	if event.is_action_pressed("toggle_mode"):
		set_mode(_next_mode(mode))
		return
```
Add `set_mode`:
```gdscript
func set_mode(m: Mode) -> void:
	mode = m
	var playing := m == Mode.PLAY
	_camera.enabled = not playing  # observer camera only in OBSERVER mode
	if _hall.detective != null:
		_hall.detective.set_control_enabled(playing)
	_observer.visible = not playing
	EventLog.log_action("Mode: %s" % ("PLAY (detective)" if playing else "OBSERVER"), "system")
```
Guard the observer camera pan so it only runs in OBSERVER mode — change `_process` body to:
```gdscript
func _process(delta: float) -> void:
	if mode == Mode.OBSERVER:
		_pan_camera(delta)
```
Guard NPC selection so left-clicking an NPC only selects in OBSERVER mode — in `_on_npc_input`, wrap the body:
```gdscript
func _on_npc_input(_viewport: Node, event: InputEvent, _shape_idx: int, npc: DormNpc) -> void:
	if mode != Mode.OBSERVER:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_observer.select_npc(npc)
```

- [ ] **Step 5: Run to verify the test passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_mode_state.gd`
Expected output contains: `PASS: test_mode_state`

- [ ] **Step 6: Run the game and verify the toggle**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot`
Expected: starts in PLAY (control the detective, observer panel hidden, camera follows detective). Press Tab → OBSERVER (detective frozen, observer panel visible, WASD pans the free camera, clicking an NPC selects it). Press Tab again → back to PLAY.

- [ ] **Step 7: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: play/observer mode toggle"
```

---

## Self-Review

**Spec coverage (Plan A scope):**
- Detective avatar + roaming → Tasks 3, 5 ✅
- Find autonomous NPCs (sim keeps running) → unchanged sim + detective coexist; NPC talk is a Plan C concern (NPCs remain clickable in observer mode) ✅ (interrogation explicitly deferred to Plan C)
- Examine clue hotspots, logged → Tasks 1, 2, 5 ✅
- Observer ↔ play toggle ("Both") → Task 6 ✅
- Reuse existing systems (nav pattern, EventLog) → Tasks 3, 2 ✅

**Deferred to later plans (intentional):** real interrogation/dialogue (Plan C), case-strength + accusation (Plan B), the First Choice / endings (Plan D). Task 5 NPCs are not yet `Interactable` "Talk" targets — that lands in Plan C alongside the dialogue UI.

**Placeholder scan:** none — every step has concrete code/commands.

**Type/name consistency:** `Investigation.discover_clue/is_discovered/discovered_count/reset` consistent across Tasks 1–2; `Interactor.try_interact/target_changed/current/_pick_nearest` consistent across Tasks 2–4; `Detective.set_control_enabled` consistent across Tasks 3, 6; `crestwood_hall.detective` consistent across Tasks 5–6; `_next_mode` consistent in Task 6.

**Risk note:** `.tscn` text is hand-authored here; if Godot rejects an inline sub-resource/script ref, open the scene in the editor and re-link (the script paths are correct). The detective spawns programmatically (matching the existing NPC-spawn pattern), minimizing `.tscn` editing.
