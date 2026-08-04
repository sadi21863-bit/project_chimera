# Plan D — Structure & Endings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the case playable end-to-end: the First Choice (accident → short ending, or murder → investigate), an accusation panel that uses `CaseFile`, and the wrong-ending + flashback that recolors every discovered clue with its innocent truth.

**Architecture:** A `GameFlow` autoload is a small phase state machine (CHOICE → INVESTIGATION → ENDING). A static `EndingContent` module holds the accident ending, the six wrong endings, and builds the flashback from `CaseData` clue truths. Two UI scenes — `StoryScreen` (the First Choice + the ending/flashback display) and `CasePanel` (suspects, case strength, accuse buttons gated by `CaseFile.can_accuse`) — are driven by `GameFlow.phase`. `main.gd` wires phase → panel visibility and routes accusations through `CaseFile.accuse` → `GameFlow.trigger_ending`.

**Tech Stack:** Godot 4.7 (GDScript), `Control`/`Button` UI. Builds on Plan B autoloads `CaseFile`, `Investigation`, `Standing`.

## Global Constraints

- **Engine:** Godot 4.7 stable; project root is `godot/`.
- **Warnings are errors:** never `:=` infer from a `Variant`-returning call; use explicit types.
- **GDScript style:** snake_case funcs/vars, PascalCase classes, typed where practical.
- **UI buttons are fine:** Controls receive clicks via the GUI layer (the click-to-move bug was world-space `_unhandled_input`, not UI). Use `Button.pressed` signals directly.
- **Reuse:** `CaseFile.can_accuse(id)`, `CaseFile.case_strength(id)`, `CaseFile.accuse(id) -> {accepted, ending_id, strength, threshold}`, `CaseData.SUSPECTS`, `CaseData.CLUES`, `Investigation`, `EventLog.log_action`.
- **Test runner:** `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd`; each prints `PASS: <name>` + `quit(0)`, else `FAIL:` + `quit(<n>)`.
- **Git:** Task 1 creates branch `plan-d-structure-endings` from `main`. Commit after every task with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **Theme (from the Story Bible):** every "murder" ending is wrong; the flashback reveals the death was an accident and recolors each clue with its `truth`. The accident ending is the only non-tragic outcome.

---

### Task 1: `EndingContent` — endings + flashback builder

**Files:**
- Create: `godot/scripts/case/ending_content.gd`
- Create: `godot/tests/test_ending_content.gd`

**Interfaces:**
- Produces: `EndingContent` (`class_name`, extends `RefCounted`):
  - `const ACCIDENT: Dictionary` — `{title, body}`
  - `const WRONG: Dictionary` — `suspect_id -> {title, body}` (6 entries)
  - `static ending_for(ending_id: String) -> Dictionary` — accepts `"ending_accident"` or `"ending_<suspect>"`, returns `{title, body}` (empty dict if unknown)
  - `static build_flashback(discovered_clue_ids: Array) -> Array` — `[{title, truth}, ...]` for each discovered clue, in `CaseData.CLUES` order

- [ ] **Step 1: Create branch**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git checkout main && git checkout -b plan-d-structure-endings
```

- [ ] **Step 2: Write the failing test**

Create `godot/tests/test_ending_content.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var ec := preload("res://scripts/case/ending_content.gd")
	var failures := 0
	if not ec.ACCIDENT.has("body"):
		failures += 1; print("FAIL: accident ending missing body")
	if ec.WRONG.size() != 6:
		failures += 1; print("FAIL: expected 6 wrong endings, got %d" % ec.WRONG.size())
	if ec.ending_for("ending_accident") != ec.ACCIDENT:
		failures += 1; print("FAIL: ending_for(accident) wrong")
	var riley_end: Dictionary = ec.ending_for("ending_riley")
	if not riley_end.has("title"):
		failures += 1; print("FAIL: ending_for(ending_riley) should return riley's ending")
	if ec.ending_for("nonsense").size() != 0:
		failures += 1; print("FAIL: unknown ending should be empty")
	# flashback returns one entry per discovered clue, with its truth
	var fb: Array = ec.build_flashback(["clue_pills", "clue_keys"])
	if fb.size() != 2:
		failures += 1; print("FAIL: flashback should have 2 entries, got %d" % fb.size())
	else:
		var truths: Array = []
		for e in fb:
			truths.append(e["truth"])
		if not ("Riley gave the victim a harmless sleep aid." in truths):
			failures += 1; print("FAIL: flashback should include riley's clue truth")
	if failures == 0:
		print("PASS: test_ending_content")
	quit(failures)
```

- [ ] **Step 3: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_ending_content.gd`
Expected: preload error — file does not exist.

- [ ] **Step 4: Implement `EndingContent`**

Create `godot/scripts/case/ending_content.gd`:
```gdscript
extends RefCounted
class_name EndingContent

## The endings. Every "wrong" ending convicts an innocent; the flashback (built from CaseData
## clue truths) reveals the death was an accident all along. The accident ending is the only
## non-tragic outcome — and the player only feels its weight in hindsight.

const ACCIDENT := {
	"title": "Case Closed — Accidental Death",
	"body": "You sign off: a tragic accident. The dorm grieves a little longer, then life closes "
		+ "over the gap like water. No one is ruined. You will never know how close you came to "
		+ "being right — because you were.",
}

const WRONG := {
	"alex": {"title": "The RA Falls",
		"body": "Alex is led out in front of the residents he kept safe. The keys that opened "
			+ "every door couldn't open the one cell that mattered."},
	"jordan": {"title": "The Understudy's Last Role",
		"body": "Jordan is arrested mid-rehearsal. The stage goes dark on a career that never "
			+ "got its opening night."},
	"sam": {"title": "The Quiet One, Convicted",
		"body": "They call Sam a mastermind. The boy who only ever talked to machines has no "
			+ "words left for the people taking him away."},
	"riley": {"title": "First, Do No Harm",
		"body": "Riley's hands — steady enough to heal — are cuffed. The kindness of a single "
			+ "pill becomes the proof that hangs her."},
	"morgan": {"title": "The Loyal One, Broken",
		"body": "Morgan goes without a fight. Loyalty looks like guilt when you're the one who "
			+ "found the body and touched the scene."},
	"casey": {"title": "Punished for Watching",
		"body": "Casey is believed precisely because they saw too much. The portraits — made out "
			+ "of love — are read aloud as the work of a stalker. The kindest one falls hardest."},
}


static func ending_for(ending_id: String) -> Dictionary:
	if ending_id == "ending_accident":
		return ACCIDENT
	var suspect_id := ending_id.trim_prefix("ending_")
	if WRONG.has(suspect_id):
		return WRONG[suspect_id]
	return {}


static func build_flashback(discovered_clue_ids: Array) -> Array:
	var result: Array = []
	for clue_id in CaseData.CLUES:  # CaseData order for stable presentation
		if clue_id in discovered_clue_ids:
			var data: Dictionary = CaseData.CLUES[clue_id]
			result.append({"title": str(data["title"]), "truth": str(data["truth"])})
	return result
```

- [ ] **Step 5: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_ending_content.gd`
Expected: `PASS: test_ending_content`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: EndingContent — endings + flashback builder"
```

---

### Task 2: `GameFlow` autoload — phase state machine

**Files:**
- Create: `godot/autoload/game_flow.gd`
- Create: `godot/tests/test_game_flow.gd`
- Modify: `godot/project.godot` (register `GameFlow` autoload after `CaseFile`)

**Interfaces:**
- Produces: autoload `GameFlow`:
  - `enum Phase { CHOICE, INVESTIGATION, ENDING }`
  - `var phase: Phase` (starts `CHOICE`), `var current_ending_id: String`
  - `signal phase_changed(phase: int)`
  - `choose_accident() -> void` (sets `current_ending_id="ending_accident"`, phase ENDING)
  - `choose_murder() -> void` (phase INVESTIGATION)
  - `trigger_ending(ending_id: String) -> void` (sets `current_ending_id`, phase ENDING)

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_game_flow.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var gf = preload("res://autoload/game_flow.gd").new()
	var failures := 0
	if gf.phase != 0:  # CHOICE
		failures += 1; print("FAIL: should start in CHOICE")
	gf.choose_murder()
	if gf.phase != 1:  # INVESTIGATION
		failures += 1; print("FAIL: choose_murder should go INVESTIGATION")
	gf.trigger_ending("ending_sam")
	if gf.phase != 2 or gf.current_ending_id != "ending_sam":  # ENDING
		failures += 1; print("FAIL: trigger_ending should set ENDING + id")
	var gf2 = preload("res://autoload/game_flow.gd").new()
	gf2.choose_accident()
	if gf2.phase != 2 or gf2.current_ending_id != "ending_accident":
		failures += 1; print("FAIL: choose_accident should set ENDING + accident id")
	gf.free(); gf2.free()
	if failures == 0:
		print("PASS: test_game_flow")
	quit(failures)
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_game_flow.gd`
Expected: preload error — file does not exist.

- [ ] **Step 3: Implement `GameFlow`**

Create `godot/autoload/game_flow.gd`:
```gdscript
extends Node

## Phase state machine for the story: the First Choice, investigation, and the ending.

enum Phase { CHOICE, INVESTIGATION, ENDING }

signal phase_changed(phase: int)

var phase: Phase = Phase.CHOICE
var current_ending_id := ""


func choose_accident() -> void:
	current_ending_id = "ending_accident"
	_set_phase(Phase.ENDING)


func choose_murder() -> void:
	_set_phase(Phase.INVESTIGATION)


func trigger_ending(ending_id: String) -> void:
	current_ending_id = ending_id
	_set_phase(Phase.ENDING)


func _set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)
```

Register the autoload — in `godot/project.godot`, under `[autoload]`, add after the `CaseFile` line:
```
GameFlow="*res://autoload/game_flow.gd"
```

- [ ] **Step 4: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_game_flow.gd`
Expected: `PASS: test_game_flow`

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: GameFlow autoload — phase state machine"
```

---

### Task 3: `CasePanel` — suspects, strength, gated accuse buttons

**Files:**
- Create: `godot/scenes/ui/case_panel.gd`
- Create: `godot/scenes/ui/case_panel.tscn`
- Create: `godot/tests/test_case_panel.gd`

**Interfaces:**
- Consumes: `CaseData.SUSPECTS`, `CaseFile.case_strength/can_accuse`.
- Produces: `CasePanel` (extends `CanvasLayer`):
  - `signal accuse_requested(suspect_id: String)`
  - `refresh(case_file: Node) -> void` — rebuilds a row per suspect: name, `case_strength`/threshold, an Accuse `Button` (disabled unless `can_accuse`)
  - `set_open(open: bool) -> void` — show/hide
  - row Accuse buttons emit `accuse_requested(suspect_id)`

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_case_panel.gd`:
```gdscript
extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		var inv = root.get_node("Investigation"); inv.reset()
		var cf = root.get_node("CaseFile")
		var panel = load("res://scenes/ui/case_panel.tscn").instantiate()
		root.add_child(panel)
		var failures := 0

		# Capture the emitted suspect id.
		var captured := {"id": ""}
		panel.accuse_requested.connect(func(sid): captured["id"] = sid)

		panel.refresh(cf)
		var rows: int = panel.get_node("Panel/VBox/Rows").get_child_count()
		if rows != 6:
			failures += 1; print("FAIL: expected 6 suspect rows, got %d" % rows)

		# Build sam's case, refresh, the accuse button should now be enabled.
		inv.discover_clue("clue_wiring"); inv.discover_clue("clue_camera")
		panel.refresh(cf)
		var btn = panel.find_accuse_button("sam")
		if btn == null:
			failures += 1; print("FAIL: no accuse button for sam")
		elif btn.disabled != false:
			failures += 1; print("FAIL: sam's accuse button should be enabled when accusable")
		else:
			btn.pressed.emit()
			if captured["id"] != "sam":
				failures += 1; print("FAIL: pressing accuse should emit accuse_requested('sam')")

		if failures == 0:
			print("PASS: test_case_panel")
		quit(failures)
		return true
	return false
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_case_panel.gd`
Expected: error — `case_panel.tscn` does not exist.

- [ ] **Step 3: Implement the panel script**

Create `godot/scenes/ui/case_panel.gd`:
```gdscript
extends CanvasLayer

## The detective's case board: each suspect with case strength and an evidence-gated Accuse button.

signal accuse_requested(suspect_id: String)

@onready var _rows: VBoxContainer = $Panel/VBox/Rows

var _accuse_buttons: Dictionary = {}  # suspect_id -> Button


func set_open(open: bool) -> void:
	visible = open


func find_accuse_button(suspect_id: String) -> Button:
	return _accuse_buttons.get(suspect_id, null)


func refresh(case_file: Node) -> void:
	for child in _rows.get_children():
		child.queue_free()
	_accuse_buttons.clear()
	for suspect_id in CaseData.SUSPECTS:
		var info: Dictionary = CaseData.SUSPECTS[suspect_id]
		var strength: int = case_file.case_strength(suspect_id)
		var threshold: int = info["threshold"]
		var can: bool = case_file.can_accuse(suspect_id)

		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s — evidence %d/%d" % [str(info["name"]), strength, threshold]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var btn := Button.new()
		btn.text = "Accuse"
		btn.disabled = not can
		btn.pressed.connect(_on_accuse_pressed.bind(suspect_id))
		row.add_child(btn)

		_rows.add_child(row)
		_accuse_buttons[suspect_id] = btn


func _on_accuse_pressed(suspect_id: String) -> void:
	accuse_requested.emit(suspect_id)
```

- [ ] **Step 4: Build the panel scene**

Create `godot/scenes/ui/case_panel.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://case_panel"]
[ext_resource type="Script" path="res://scenes/ui/case_panel.gd" id="1"]

[node name="CasePanel" type="CanvasLayer"]
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -220.0
offset_top = -160.0
offset_right = 220.0
offset_bottom = 160.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="Panel"]

[node name="Title" type="Label" parent="Panel/VBox"]
text = "CASE FILE — accuse only with enough evidence"
horizontal_alignment = 1

[node name="Rows" type="VBoxContainer" parent="Panel/VBox"]
```

- [ ] **Step 5: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_case_panel.gd`
Expected: `PASS: test_case_panel`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: CasePanel — suspects + strength + gated accuse buttons"
```

---

### Task 4: `StoryScreen` — First Choice + ending/flashback display

**Files:**
- Create: `godot/scenes/ui/story_screen.gd`
- Create: `godot/scenes/ui/story_screen.tscn`
- Create: `godot/tests/test_story_screen.gd`

**Interfaces:**
- Consumes: `EndingContent.ending_for/build_flashback`, `Investigation`.
- Produces: `StoryScreen` (extends `CanvasLayer`):
  - `signal choice_made(is_murder: bool)`
  - `show_choice() -> void` — shows the intro + two buttons (Accident / Murder); buttons emit `choice_made(false/true)`
  - `show_ending(ending_id: String, discovered_clue_ids: Array) -> void` — shows the ending title/body, then the flashback (each clue title + its truth)
  - `hide_screen() -> void`

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_story_screen.gd`:
```gdscript
extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var screen = load("res://scenes/ui/story_screen.tscn").instantiate()
		root.add_child(screen)
		var failures := 0

		var captured := {"is_murder": null}
		screen.choice_made.connect(func(m): captured["is_murder"] = m)
		screen.show_choice()
		screen.get_node("Center/VBox/Buttons/MurderButton").pressed.emit()
		if captured["is_murder"] != true:
			failures += 1; print("FAIL: murder button should emit choice_made(true)")

		# Ending display includes the wrong-ending body and the discovered clue's truth.
		screen.show_ending("ending_riley", ["clue_pills"])
		var text: String = screen.get_node("Center/VBox/Body").text
		if not ("First, Do No Harm" in text or "Riley" in text):
			failures += 1; print("FAIL: ending body should mention riley's ending")
		if not ("harmless sleep aid" in text):
			failures += 1; print("FAIL: flashback should reveal the clue truth")

		if failures == 0:
			print("PASS: test_story_screen")
		quit(failures)
		return true
	return false
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_story_screen.gd`
Expected: error — `story_screen.tscn` does not exist.

- [ ] **Step 3: Implement the script**

Create `godot/scenes/ui/story_screen.gd`:
```gdscript
extends CanvasLayer

## The framing screens: the First Choice (accident vs murder) and the ending + flashback.

signal choice_made(is_murder: bool)

@onready var _title: Label = $Center/VBox/Title
@onready var _body: Label = $Center/VBox/Body
@onready var _buttons: HBoxContainer = $Center/VBox/Buttons


func _ready() -> void:
	$Center/VBox/Buttons/AccidentButton.pressed.connect(func(): choice_made.emit(false))
	$Center/VBox/Buttons/MurderButton.pressed.connect(func(): choice_made.emit(true))
	hide_screen()


func show_choice() -> void:
	visible = true
	_buttons.visible = true
	_title.text = "Crestwood Hall — A Death"
	_body.text = ("The police called it an accident, and the dorm has already begun to move on. "
		+ "But the Crestwood family — whose name is on the building — wants a murderer found, "
		+ "and they've brought in you.\n\nWhat is your finding?")


func show_ending(ending_id: String, discovered_clue_ids: Array) -> void:
	visible = true
	_buttons.visible = false
	var ending: Dictionary = EndingContent.ending_for(ending_id)
	_title.text = str(ending.get("title", "The End"))
	var text: String = str(ending.get("body", ""))
	if ending_id != "ending_accident":
		text += "\n\n— THE TRUTH —\n"
		text += "It was an accident. Every sign you read as guilt was something innocent:\n"
		for entry in EndingContent.build_flashback(discovered_clue_ids):
			text += "\n• %s: %s" % [str(entry["title"]), str(entry["truth"])]
		text += "\n\nYou were the only thing that turned a tragedy into a crime."
	_body.text = text


func hide_screen() -> void:
	visible = false
```

- [ ] **Step 4: Build the scene**

Create `godot/scenes/ui/story_screen.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://story_screen"]
[ext_resource type="Script" path="res://scenes/ui/story_screen.gd" id="1"]

[node name="StoryScreen" type="CanvasLayer"]
script = ExtResource("1")

[node name="Dim" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 0.85)

[node name="Center" type="CenterContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="VBox" type="VBoxContainer" parent="Center"]
custom_minimum_size = Vector2(700, 0)

[node name="Title" type="Label" parent="Center/VBox"]
horizontal_alignment = 1
text = "Title"

[node name="Body" type="Label" parent="Center/VBox"]
autowrap_mode = 3
custom_minimum_size = Vector2(700, 0)
text = "Body"

[node name="Buttons" type="HBoxContainer" parent="Center/VBox"]
alignment = 1

[node name="AccidentButton" type="Button" parent="Center/VBox/Buttons"]
text = "Rule it an accident (close the case)"

[node name="MurderButton" type="Button" parent="Center/VBox/Buttons"]
text = "Call it murder (investigate)"
```

- [ ] **Step 5: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_story_screen.gd`
Expected: `PASS: test_story_screen`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: StoryScreen — First Choice + ending/flashback display"
```

---

### Task 5: Wire the flow into `main` (playable end-to-end)

**Files:**
- Modify: `godot/scenes/main.tscn` (add `StoryScreen` + `CasePanel` under `UI`)
- Modify: `godot/scenes/main.gd` (drive panels from `GameFlow.phase`; route choice + accusation)
- Modify: `godot/project.godot` (add `toggle_case` input action, key C)
- Create: `godot/tests/test_flow_wiring.gd`

**Interfaces:**
- Consumes: `GameFlow` (Task 2), `CasePanel` (Task 3), `StoryScreen` (Task 4), `CaseFile` (Plan B).
- Produces: in `main.gd` — `_on_choice_made(is_murder)`, `_on_accuse_requested(suspect_id)`, `_on_phase_changed(phase)`, `_collect_discovered_clue_ids() -> Array`.

- [ ] **Step 1: Add `toggle_case` input action**

In `godot/project.godot`, under `[input]` (after the `toggle_mode` block), add (physical keycode 67 = C):
```
toggle_case={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":67,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
```

- [ ] **Step 2: Add the panels to main.tscn**

In `godot/scenes/main.tscn`, add to the `ext_resource` header:
```
[ext_resource type="PackedScene" path="res://scenes/ui/story_screen.tscn" id="5"]
[ext_resource type="PackedScene" path="res://scenes/ui/case_panel.tscn" id="6"]
```
And add under the `UI` `CanvasLayer` (siblings of `InteractionPrompt`):
```
[node name="StoryScreen" parent="UI" instance=ExtResource("5")]

[node name="CasePanel" parent="UI" instance=ExtResource("6")]
```

- [ ] **Step 3: Wire main.gd**

In `godot/scenes/main.gd`, add `@onready` refs near the others:
```gdscript
@onready var _story: CanvasLayer = $UI/StoryScreen
@onready var _case_panel: CanvasLayer = $UI/CasePanel
```
At the end of `_ready()` (after `set_mode(Mode.PLAY)` and the existing wiring), add:
```gdscript
	_story.choice_made.connect(_on_choice_made)
	_case_panel.accuse_requested.connect(_on_accuse_requested)
	GameFlow.phase_changed.connect(_on_phase_changed)
	_case_panel.set_open(false)
	_on_phase_changed(GameFlow.phase)  # show the First Choice on start
```
Extend `_unhandled_input` — add this near the top (after the `toggle_mode` branch):
```gdscript
	if event.is_action_pressed("toggle_case") and GameFlow.phase == GameFlow.Phase.INVESTIGATION:
		_case_panel.refresh(CaseFile)
		_case_panel.set_open(not _case_panel.visible)
		return
```
Add the handlers (top-level funcs):
```gdscript
func _on_choice_made(is_murder: bool) -> void:
	if is_murder:
		GameFlow.choose_murder()
	else:
		GameFlow.choose_accident()


func _on_accuse_requested(suspect_id: String) -> void:
	var result: Dictionary = CaseFile.accuse(suspect_id)
	if result["accepted"]:
		_case_panel.set_open(false)
		GameFlow.trigger_ending(result["ending_id"])
	else:
		EventLog.log_action("Not enough evidence to accuse %s (%d/%d)" % [
			suspect_id, result["strength"], result["threshold"]], "case")


func _on_phase_changed(phase: int) -> void:
	match phase:
		GameFlow.Phase.CHOICE:
			_story.show_choice()
		GameFlow.Phase.INVESTIGATION:
			_story.hide_screen()
		GameFlow.Phase.ENDING:
			_story.show_ending(GameFlow.current_ending_id, _collect_discovered_clue_ids())


func _collect_discovered_clue_ids() -> Array:
	var ids: Array = []
	for clue_id in CaseData.CLUES:
		if Investigation.is_discovered(clue_id):
			ids.append(clue_id)
	return ids
```

- [ ] **Step 4: Write the end-to-end wiring test**

Create `godot/tests/test_flow_wiring.gd`:
```gdscript
extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		var gf = root.get_node("GameFlow")
		var inv = root.get_node("Investigation"); inv.reset()
		var failures := 0

		# Start at CHOICE; the story screen is visible.
		if gf.phase != 0:
			failures += 1; print("FAIL: should start at CHOICE")
		# Choose murder -> INVESTIGATION.
		main._on_choice_made(true)
		if gf.phase != 1:
			failures += 1; print("FAIL: choosing murder should go INVESTIGATION")
		# Accuse with no evidence -> rejected, still investigating.
		main._on_accuse_requested("sam")
		if gf.phase != 1:
			failures += 1; print("FAIL: baseless accusation should not end the game")
		# Build the case, accuse -> ENDING with sam's ending.
		inv.discover_clue("clue_wiring"); inv.discover_clue("clue_camera")
		main._on_accuse_requested("sam")
		if gf.phase != 2 or gf.current_ending_id != "ending_sam":
			failures += 1; print("FAIL: built accusation should trigger ending_sam")

		if failures == 0:
			print("PASS: test_flow_wiring")
		quit(failures)
		return true
	return false
```

- [ ] **Step 5: Run to verify (import + wiring + full regression)**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_flow_wiring.gd`
Expected: `PASS: test_flow_wiring`
Then re-run the full suite (Plan A + B + D tests) — all expected PASS.

- [ ] **Step 6: Human playtest**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot`
Expected: on start, the **First Choice** screen appears. "Rule it an accident" → the accident ending. "Call it murder" → the screen clears and you investigate (WASD, examine clues with E). Press **C** to open the case file → accuse buttons are disabled until you've found both of a suspect's clues → accusing triggers that suspect's ending + the flashback revealing the truths.

- [ ] **Step 7: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: wire First Choice + accusation + endings into main (playable)"
```

---

## Self-Review

**Spec coverage (Plan D = Structure & Endings):**
- The Call / framing → folded into `StoryScreen.show_choice` intro text (Task 4) ✅
- The First Choice (accident → short ending / murder → investigate) → Tasks 2, 4, 5 ✅
- Accusation UI using CaseFile (evidence-gated) → Task 3 + Task 5 routing ✅
- Wrong endings + flashback recoloring clue truths → Tasks 1, 4 ✅
- Accident ending = only non-tragic outcome → Task 1 (`ACCIDENT`), Task 4 (no flashback for accident) ✅

**Deferred (intentional):** richer ending art/audio and the subplots (ghost-master, media, interference, hint-giver) are **Plan E**. Interrogation-driven clue discovery is **Plan C** (clues here are found by examining, per Plan A).

**Placeholder scan:** none — all steps have concrete code/commands.

**Type/name consistency:** `EndingContent.ACCIDENT/WRONG/ending_for/build_flashback` consistent (Tasks 1,4); `GameFlow.phase/Phase/current_ending_id/choose_accident/choose_murder/trigger_ending/phase_changed` consistent (Tasks 2,4,5); `CasePanel.refresh/set_open/find_accuse_button/accuse_requested` consistent (Tasks 3,5); `CaseFile.accuse(...)["accepted"|"ending_id"|"strength"|"threshold"]` matches Plan B's return shape; main handlers `_on_choice_made/_on_accuse_requested/_on_phase_changed/_collect_discovered_clue_ids` consistent (Task 5 + test).
```
