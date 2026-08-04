# Plan C — Interrogation & Catching Suspicious Activity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder NPC deflections with real interrogation — pick topics, present evidence, and (with enough trust) make a suspect let a clue slip — and add "catching suspicious activity": witness an NPC act off-routine and it reveals a clue + unlocks a topic to press them on.

**Architecture:** Static `InterrogationData` holds each suspect's topics, evidence reactions, and persona; pure functions resolve a topic/evidence into a response + optional clue reveal (trust-gated via `Standing`). An `InterrogationPanel` UI drives it and routes a free-text box through `AIClient` (LLM when available, graceful deflection otherwise — the hybrid). Static `SuspicionData` + a `SuspicionWatcher` node fire scheduled "suspicious moments" when the detective is near the NPC, calling `Investigation.discover_clue`. All evidence — examined, interrogated, or witnessed — flows through the same `Investigation`/`CaseFile` system from Plans A/B.

**Tech Stack:** Godot 4.7 (GDScript), `Control` UI. Builds on `Investigation`, `Standing`, `CaseFile`, `CaseData`, `Scheduler`, `AIClient`, `EventLog`.

## Global Constraints

- **Engine:** Godot 4.7 stable; project root `godot/`.
- **Warnings are errors:** no `:=` inference from `Variant`-returning calls; explicit types.
- **GDScript style:** snake_case funcs/vars, PascalCase classes; typed where practical.
- **Reuse:** `Investigation.is_discovered/discover_clue`, `Standing.get_standing/adjust`, `CaseData.SUSPECTS/CLUES`, `Scheduler` (`time_changed`, `get_hour()`), `EventLog.log_action`. Resolve autoload deps into injectable vars for tests.
- **Hybrid dialogue (spec):** authored topic/evidence responses are the reliable backbone; the free-text box uses the LLM via `AIClient` only when available and otherwise returns an authored deflection. Authored content must stand alone.
- **Evidence is source-agnostic (spec):** examining, interrogating, and witnessing all funnel into `Investigation.discover_clue` — the case system doesn't care how a clue surfaced.
- **Test runner:** `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd`; print `PASS: <name>`/`quit(0)` or `FAIL:`/`quit(<n>)`.
- **Git:** Task 1 creates branch `plan-c-interrogation` from `main`. Commit per task; end messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: `InterrogationData` — topics, evidence reactions, trust-gated reveals

**Files:**
- Create: `godot/scripts/interrogation/interrogation_data.gd`
- Create: `godot/tests/test_interrogation_data.gd`

**Interfaces:**
- Produces: `InterrogationData` (`class_name`, extends `RefCounted`):
  - `const SUSPECTS: Dictionary` — `suspect_id -> {persona: String, topics: Array, evidence: Dictionary}` where each topic is `{id, label, response, reveal_clue (String, "" if none), trust_min (float)}` and `evidence` is `clue_id -> response`.
  - `static topics_for(suspect_id) -> Array`
  - `static respond_to_topic(suspect_id, topic_id, standing: float) -> Dictionary` → `{text: String, reveal_clue: String}` (reveal only when `standing >= trust_min`; below that, a guarded line and `reveal_clue=""`)
  - `static respond_to_evidence(suspect_id, clue_id) -> String` (a generic line if unmapped)

- [ ] **Step 1: Create branch**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git checkout main && git checkout -b plan-c-interrogation
```

- [ ] **Step 2: Write the failing test**

Create `godot/tests/test_interrogation_data.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var id := preload("res://scripts/interrogation/interrogation_data.gd")
	var failures := 0
	# every CaseData suspect has interrogation content
	var case_data := preload("res://scripts/case/case_data.gd")
	for sid in case_data.get_suspect_ids():
		if not id.SUSPECTS.has(sid):
			failures += 1; print("FAIL: no interrogation data for %s" % sid)
		elif id.topics_for(sid).is_empty():
			failures += 1; print("FAIL: %s has no topics" % sid)
	# trust gating: riley's reveal topic hides the clue at low trust, reveals at high
	var low: Dictionary = id.respond_to_topic("riley", "the_pills", 0.0)
	if low["reveal_clue"] != "":
		failures += 1; print("FAIL: low trust should not reveal a clue")
	var high: Dictionary = id.respond_to_topic("riley", "the_pills", 0.9)
	if high["reveal_clue"] != "clue_medbook":
		failures += 1; print("FAIL: high trust should reveal clue_medbook, got '%s'" % high["reveal_clue"])
	# evidence reaction is non-empty
	if id.respond_to_evidence("riley", "clue_pills").is_empty():
		failures += 1; print("FAIL: riley should react to clue_pills")
	if failures == 0:
		print("PASS: test_interrogation_data")
	quit(failures)
```

- [ ] **Step 3: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_interrogation_data.gd`
Expected: preload error — file does not exist.

- [ ] **Step 4: Implement `InterrogationData`**

Create `godot/scripts/interrogation/interrogation_data.gd`:
```gdscript
extends RefCounted
class_name InterrogationData

## Authored interrogation content. Topics with trust_min reveal a clue only once the detective
## has earned enough standing — interrogation is a real evidence source (the same clues can also
## be examined or witnessed). evidence[clue_id] is how the suspect reacts when shown that clue.

const SUSPECTS := {
	"alex": {
		"persona": "Alex the RA: controlling, protective of authority, hiding a quietly failed semester — not a crime.",
		"topics": [
			{"id": "that_night", "label": "Where were you that night?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Doing my rounds. I have keys to every door — that's the job, not a motive."},
			{"id": "the_grade", "label": "What are you hiding about your record?", "trust_min": 0.3, "reveal_clue": "clue_logbook",
				"response": "...Fine. There's a gap in the logbook. I failed a class and quietly fixed the record. It has nothing to do with the death."},
		],
		"evidence": {
			"clue_keys": "Those are mine, yes. Everyone's fob is scuffed — we use them daily.",
			"clue_logbook": "That gap is me covering my own grade. Not the victim. Please leave it.",
		},
	},
	"jordan": {
		"persona": "Jordan the actor: dramatic, anxious, lied about being in the hallway because he froze, not because he's guilty.",
		"topics": [
			{"id": "that_night", "label": "Were you near the victim's room?", "trust_min": 0.0, "reveal_clue": "",
				"response": "No. I mean — I was rehearsing. In the hallway. That's all."},
			{"id": "the_lie", "label": "You lied about being there. Why?", "trust_min": 0.4, "reveal_clue": "clue_witness_jordan",
				"response": "Because I saw him stumble and I just... walked past. I thought he was drunk. I didn't help. I couldn't say that out loud."},
		],
		"evidence": {
			"clue_rehearsal": "My script, yes — proof I was rehearsing, not lurking.",
			"clue_witness_jordan": "Okay. I was there. I walked past him. That's my whole crime — walking past.",
		},
	},
	"sam": {
		"persona": "Sam the hacker: terse, evasive about the wiring and a borrowed camera feed for a secret app, owes Alex a favor.",
		"topics": [
			{"id": "that_night", "label": "What were you doing late?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Up. Coding. I'm always up. Ask anyone — actually, don't ask anyone."},
			{"id": "the_camera", "label": "Why was the camera disabled?", "trust_min": 0.4, "reveal_clue": "clue_camera",
				"response": "I borrowed the feed for my app. That's why it was off. I wasn't hiding a body, I was hiding a side project."},
		],
		"evidence": {
			"clue_wiring": "I was fixing the wiring for my app. That's all that was.",
			"clue_camera": "Yeah, I turned it off. For the feed. Bad timing, not bad intent.",
		},
	},
	"riley": {
		"persona": "Riley the pre-med: kind, anxious, wracked with guilt for giving the victim a harmless sleep aid.",
		"topics": [
			{"id": "that_night", "label": "How did the victim seem?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Stressed. Worn down. I wanted to help. I always want to help."},
			{"id": "the_pills", "label": "Did you give them anything?", "trust_min": 0.2, "reveal_clue": "clue_medbook",
				"response": "I gave them something to sleep. Over-the-counter. My notes are just exam prep — but I know how it looks."},
		],
		"evidence": {
			"clue_pills": "Those are mine — a mild sleep aid. I was trying to help, I swear.",
			"clue_medbook": "My pharmacology notes are for an exam, not a plan. Please don't twist this.",
		},
	},
	"morgan": {
		"persona": "Morgan the athlete: loyal, blunt, panicked when finding the body and moved one object, hiding an injury.",
		"topics": [
			{"id": "that_night", "label": "You were up early?", "trust_min": 0.0, "reveal_clue": "",
				"response": "Always am. Morning run. Found... I found things quiet."},
			{"id": "the_scene", "label": "Did you touch the scene?", "trust_min": 0.5, "reveal_clue": "clue_moved_object",
				"response": "I found him first. I panicked. I moved a bottle — I don't even know why. Then I called it in. That's it."},
		],
		"evidence": {
			"clue_moved_object": "I moved it. In the moment. I wasn't thinking. That's not murder, that's panic.",
			"clue_morgan_early": "I was up for a run, like every day. Being early isn't a crime.",
		},
	},
	"casey": {
		"persona": "Casey the artist: quiet, watchful, sketched the courtyard window the night before; knows everyone's secrets.",
		"topics": [
			{"id": "that_night", "label": "What did you see?", "trust_min": 0.0, "reveal_clue": "",
				"response": "I see a lot. People forget I'm there. That's not the same as doing anything."},
			{"id": "the_window", "label": "Tell me about the window sketch.", "trust_min": 0.3, "reveal_clue": "clue_portraits",
				"response": "I draw at night. I sketched the courtyard the evening before. The portraits... they're love, not surveillance. People never believe that."},
		],
		"evidence": {
			"clue_sketch": "I sketched the window the night before it happened. Coincidence is not guilt.",
			"clue_portraits": "Those portraits are how I pay attention to people. Not how I stalk them.",
		},
	},
}


static func topics_for(suspect_id: String) -> Array:
	if SUSPECTS.has(suspect_id):
		return SUSPECTS[suspect_id]["topics"]
	return []


static func respond_to_topic(suspect_id: String, topic_id: String, standing: float) -> Dictionary:
	for topic in topics_for(suspect_id):
		if topic["id"] == topic_id:
			var reveal: String = str(topic.get("reveal_clue", ""))
			var trust_min: float = float(topic.get("trust_min", 0.0))
			if reveal != "" and standing < trust_min:
				return {"text": "I've told you what I'm going to tell you.", "reveal_clue": ""}
			return {"text": str(topic["response"]), "reveal_clue": reveal}
	return {"text": "I don't know what you mean.", "reveal_clue": ""}


static func respond_to_evidence(suspect_id: String, clue_id: String) -> String:
	if SUSPECTS.has(suspect_id):
		var ev: Dictionary = SUSPECTS[suspect_id]["evidence"]
		if ev.has(clue_id):
			return str(ev[clue_id])
	return "I don't see what that has to do with me."
```

- [ ] **Step 5: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_interrogation_data.gd`
Expected: `PASS: test_interrogation_data`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: InterrogationData — topics, evidence reactions, trust-gated reveals"
```

---

### Task 2: `InterrogationPanel` UI

**Files:**
- Create: `godot/scenes/ui/interrogation_panel.gd`
- Create: `godot/scenes/ui/interrogation_panel.tscn`
- Create: `godot/tests/test_interrogation_panel.gd`

**Interfaces:**
- Consumes: `InterrogationData`, injectable stores.
- Produces: `InterrogationPanel` (extends `CanvasLayer`):
  - `open(suspect_id: String, investigation: Node, standing: Node) -> void` — shows the panel, builds a topic button per `topics_for`, sets the name header; tracks the three injected deps.
  - `close() -> void`
  - `signal free_text_submitted(suspect_id: String, text: String)` — emitted when the player submits the free-text box (the host routes it to `AIClient`)
  - `signal closed()`
  - selecting a topic calls `InterrogationData.respond_to_topic`, shows the text, and on a reveal calls `investigation.discover_clue` + `standing.adjust(suspect_id, 0.05)` and logs it
  - `present_evidence(clue_id: String) -> void` — shows `respond_to_evidence` (host wires an evidence menu later; the method is the seam)
  - `show_response(text: String) -> void` — used by the host to display an LLM/free-text answer

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_interrogation_panel.gd`:
```gdscript
extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var inv = preload("res://autoload/investigation.gd").new(); inv.set("persist_enabled", false)
		var st = preload("res://autoload/standing.gd").new(); st.set("persist_enabled", false)
		var panel = load("res://scenes/ui/interrogation_panel.tscn").instantiate()
		root.add_child(panel)
		var failures := 0

		panel.open("riley", inv, st)
		var topic_count: int = panel.get_node("Panel/VBox/Topics").get_child_count()
		if topic_count < 2:
			failures += 1; print("FAIL: riley should have >=2 topic buttons, got %d" % topic_count)

		# Low trust: pressing the reveal topic must NOT discover the clue.
		panel.select_topic("the_pills")
		if inv.is_discovered("clue_medbook"):
			failures += 1; print("FAIL: clue should stay hidden at low trust")

		# Raise trust, press again: the clue is revealed via interrogation.
		st.adjust("riley", 0.9)
		panel.select_topic("the_pills")
		if not inv.is_discovered("clue_medbook"):
			failures += 1; print("FAIL: high-trust topic should reveal clue_medbook")

		# Free-text submit emits a signal for the host to route to the LLM.
		var captured := {"text": ""}
		panel.free_text_submitted.connect(func(_sid, t): captured["text"] = t)
		panel.submit_free_text("did you hate him?")
		if captured["text"] != "did you hate him?":
			failures += 1; print("FAIL: free-text submit should emit the text")

		if failures == 0:
			print("PASS: test_interrogation_panel")
		quit(failures)
		return true
	return false
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_interrogation_panel.gd`
Expected: error — scene does not exist.

- [ ] **Step 3: Implement the panel script**

Create `godot/scenes/ui/interrogation_panel.gd`:
```gdscript
extends CanvasLayer

## Interrogation UI: authored topic buttons + present-evidence + a free-text box (routed to the
## LLM by the host). Trust-gated topics reveal clues into the Investigation store.

signal free_text_submitted(suspect_id: String, text: String)
signal closed()

@onready var _name: Label = $Panel/VBox/NameLabel
@onready var _topics: VBoxContainer = $Panel/VBox/Topics
@onready var _response: Label = $Panel/VBox/Response
@onready var _input: LineEdit = $Panel/VBox/InputRow/Input

var _suspect_id := ""
var _investigation: Node = null
var _standing: Node = null


func _ready() -> void:
	$Panel/VBox/InputRow/SubmitButton.pressed.connect(_on_submit_pressed)
	$Panel/VBox/CloseButton.pressed.connect(close)
	visible = false


func open(suspect_id: String, investigation: Node, standing: Node) -> void:
	_suspect_id = suspect_id
	_investigation = investigation
	_standing = standing
	_name.text = "Interrogating %s" % str(CaseData.SUSPECTS.get(suspect_id, {}).get("name", suspect_id))
	_response.text = ""
	for child in _topics.get_children():
		child.queue_free()
	for topic in InterrogationData.topics_for(suspect_id):
		var btn := Button.new()
		btn.text = str(topic["label"])
		btn.pressed.connect(select_topic.bind(str(topic["id"])))
		_topics.add_child(btn)
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func select_topic(topic_id: String) -> void:
	var standing: float = _standing.get_standing(_suspect_id) if _standing != null else 0.0
	var result: Dictionary = InterrogationData.respond_to_topic(_suspect_id, topic_id, standing)
	_response.text = str(result["text"])
	var reveal: String = str(result["reveal_clue"])
	if reveal != "" and _investigation != null and _investigation.discover_clue(reveal):
		if _standing != null:
			_standing.adjust(_suspect_id, 0.05)
		_log("%s let something slip: %s" % [_suspect_id, reveal])


func present_evidence(clue_id: String) -> void:
	_response.text = InterrogationData.respond_to_evidence(_suspect_id, clue_id)


func show_response(text: String) -> void:
	_response.text = text


func submit_free_text(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	free_text_submitted.emit(_suspect_id, text)
	_input.text = ""


func _on_submit_pressed() -> void:
	submit_free_text(_input.text)


func _log(text: String) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var node := (loop as SceneTree).root.get_node_or_null("EventLog")
		if node != null:
			node.call("log_action", text, "interrogation")
```

- [ ] **Step 4: Build the scene**

Create `godot/scenes/ui/interrogation_panel.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://interrogation_panel"]
[ext_resource type="Script" path="res://scenes/ui/interrogation_panel.gd" id="1"]

[node name="InterrogationPanel" type="CanvasLayer"]
script = ExtResource("1")

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -200.0
offset_right = 300.0
offset_bottom = 200.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="Panel"]

[node name="NameLabel" type="Label" parent="Panel/VBox"]
text = "Interrogating"

[node name="Response" type="Label" parent="Panel/VBox"]
autowrap_mode = 3
custom_minimum_size = Vector2(580, 80)

[node name="Topics" type="VBoxContainer" parent="Panel/VBox"]

[node name="InputRow" type="HBoxContainer" parent="Panel/VBox"]

[node name="Input" type="LineEdit" parent="Panel/VBox/InputRow"]
size_flags_horizontal = 3
placeholder_text = "Ask your own question..."

[node name="SubmitButton" type="Button" parent="Panel/VBox/InputRow"]
text = "Ask"

[node name="CloseButton" type="Button" parent="Panel/VBox"]
text = "End interrogation"
```

- [ ] **Step 5: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_interrogation_panel.gd`
Expected: `PASS: test_interrogation_panel`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: InterrogationPanel UI (topics, evidence, free-text, trust-gated reveals)"
```

---

### Task 3: Wire interrogation into the game (F opens it; free-text → AIClient)

**Files:**
- Modify: `godot/scenes/main.tscn` (add `InterrogationPanel` under `UI`)
- Modify: `godot/scenes/main.gd` (open the panel on NPC talk; route free-text to `AIClient`; present evidence from the case)
- Modify: `godot/scripts/player/npc_interactable.gd` (emit a talk request instead of a deflection)
- Create: `godot/tests/test_interrogation_wiring.gd`

**Interfaces:**
- Consumes: `InterrogationPanel.open/select_topic/show_response/free_text_submitted/closed`, `AIClient`, `Investigation`, `Standing`.
- Produces: `npc_interactable.gd` exposes `signal talk_requested(suspect_id)`; `main._on_talk_requested(suspect_id)` opens the panel; `main._on_free_text(suspect_id, text)` routes to AIClient or a deflection.

- [ ] **Step 1: Make NPC talk request an interrogation instead of a canned line**

Replace the body of `interact()` in `godot/scripts/player/npc_interactable.gd` and add the signal + an `npc_id`:
```gdscript
extends "res://scripts/player/interactable.gd"
class_name NpcInteractable

signal talk_requested(suspect_id: String)

@export var npc_name := "Someone"
@export var npc_id := ""


func get_prompt() -> String:
	return "Talk to %s" % npc_name


func interact() -> void:
	talk_requested.emit(npc_id)
```
And in `godot/scenes/dorm/crestwood_hall.gd`, set `npc_id` in `_add_talk_area` (after `talk.npc_name = npc.display_name`):
```gdscript
	talk.npc_id = npc.npc_id
```

- [ ] **Step 2: Add the panel to main.tscn**

In `godot/scenes/main.tscn`, add to the `ext_resource` header:
```
[ext_resource type="PackedScene" uid="uid://interrogation_panel" path="res://scenes/ui/interrogation_panel.tscn" id="8"]
```
And under `UI` (sibling of `CasePanel`):
```
[node name="InterrogationPanel" parent="UI" instance=ExtResource("8")]
```

- [ ] **Step 3: Wire main.gd**

In `godot/scenes/main.gd`, add an `@onready`:
```gdscript
@onready var _interrogation: CanvasLayer = $UI/InterrogationPanel
```
At the end of `_ready()` (after the existing connections), connect the panel and each NPC's talk areas:
```gdscript
	_interrogation.free_text_submitted.connect(_on_free_text)
	for npc in _hall.npcs:
		for ch in npc.get_children():
			if ch is NpcInteractable:
				ch.talk_requested.connect(_on_talk_requested)
```
Add the handlers:
```gdscript
func _on_talk_requested(suspect_id: String) -> void:
	_interrogation.open(suspect_id, Investigation, Standing)


func _on_free_text(suspect_id: String, text: String) -> void:
	# Hybrid: use the LLM when the AI layer is live, else an authored deflection.
	if AIClient.use_ai and AIClient.resolve_mode() != AIClient.AiMode.RULE_BASED:
		var persona: String = str(InterrogationData.SUSPECTS.get(suspect_id, {}).get("persona", ""))
		AIClient._local_decide(suspect_id, {"name": suspect_id, "personality": persona,
			"schedule_goal": "answer the detective", "current_room": "", "nearby_npcs": [],
			"recent_events": [text], "secrets": []}, func(resp):
			var action: Dictionary = resp.get("action", {})
			var line: String = str(action.get("text", action.get("reason", "")))
			_interrogation.show_response(line if line != "" else "I won't dignify that.")
		)
	else:
		_interrogation.show_response("Ask me something specific, detective.")
```
> Note: the LLM path reuses the existing decision pipeline as a best-effort chat; on this hardware it will usually fall back. The authored topics carry interrogation.

- [ ] **Step 4: Write the wiring test**

Create `godot/tests/test_interrogation_wiring.gd`:
```gdscript
extends SceneTree

var _phase := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		var inv = root.get_node("Investigation"); inv.reset()
		var st = root.get_node("Standing"); st.reset()
		var failures := 0

		main._on_talk_requested("riley")
		var panel = main.get_node("UI/InterrogationPanel")
		if not panel.visible:
			failures += 1; print("FAIL: talk should open the interrogation panel")

		# High trust + reveal topic -> clue surfaces via interrogation.
		st.adjust("riley", 0.9)
		panel.select_topic("the_pills")
		if not inv.is_discovered("clue_medbook"):
			failures += 1; print("FAIL: interrogation should reveal clue_medbook at high trust")

		# Free-text with AI off -> a deflection string is shown (no crash).
		main._on_free_text("riley", "did you do it?")
		if main.get_node("UI/InterrogationPanel").get_node("Panel/VBox/Response").text.is_empty():
			failures += 1; print("FAIL: free-text should produce some response")

		if failures == 0:
			print("PASS: test_interrogation_wiring")
		quit(failures)
		return true
	return false
```

- [ ] **Step 5: Run to verify (import + wiring + regressions)**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_interrogation_wiring.gd`
Expected: `PASS: test_interrogation_wiring`
Also re-run `test_examine_flow` and `test_flow_wiring` — expected PASS (NpcInteractable still detected; main still boots).

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: wire interrogation panel (F to interrogate; free-text via AIClient with deflection fallback)"
```

---

### Task 4: `SuspicionData` + `SuspicionWatcher` (catching suspicious activity)

**Files:**
- Create: `godot/scripts/interrogation/suspicion_data.gd`
- Create: `godot/scenes/suspicion_watcher.gd`
- Create: `godot/tests/test_suspicion.gd`

**Interfaces:**
- Produces:
  - `SuspicionData` (`class_name`, extends `RefCounted`): `const MOMENTS: Array` of `{id, npc_id, hour, description, reveal_clue}`; `static moments() -> Array`.
  - `SuspicionWatcher` (extends `Node`): `static check(moments: Array, hour: float, detective_pos: Vector2, npc_positions: Dictionary, fired: Dictionary, catch_range: float) -> Array` — returns the ids of moments that should fire now (hour reached, detective within `catch_range` of that moment's NPC, not already in `fired`).

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_suspicion.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var sd := preload("res://scripts/interrogation/suspicion_data.gd")
	var sw := preload("res://scenes/suspicion_watcher.gd")
	var failures := 0
	if sd.moments().is_empty():
		failures += 1; print("FAIL: there should be suspicious moments")

	var moments := [
		{"id": "m1", "npc_id": "sam", "hour": 2.0, "description": "x", "reveal_clue": "clue_camera"},
	]
	var npc_pos := {"sam": Vector2(100, 100)}
	# too early -> nothing
	var early: Array = sw.check(moments, 1.0, Vector2(100, 100), npc_pos, {}, 40.0)
	if not early.is_empty():
		failures += 1; print("FAIL: should not fire before the hour")
	# right time but detective far away -> nothing
	var far: Array = sw.check(moments, 2.0, Vector2(900, 900), npc_pos, {}, 40.0)
	if not far.is_empty():
		failures += 1; print("FAIL: should not fire when detective is far")
	# right time, detective near -> fires
	var near: Array = sw.check(moments, 2.0, Vector2(110, 100), npc_pos, {}, 40.0)
	if near != ["m1"]:
		failures += 1; print("FAIL: should fire m1 when caught")
	# already fired -> nothing
	var again: Array = sw.check(moments, 2.0, Vector2(110, 100), npc_pos, {"m1": true}, 40.0)
	if not again.is_empty():
		failures += 1; print("FAIL: should not re-fire")

	if failures == 0:
		print("PASS: test_suspicion")
	quit(failures)
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_suspicion.gd`
Expected: preload error — files do not exist.

- [ ] **Step 3: Implement the data + watcher logic**

Create `godot/scripts/interrogation/suspicion_data.gd`:
```gdscript
extends RefCounted
class_name SuspicionData

## Scheduled "suspicious moments." Catch one (be near the NPC at/after the hour) and it reveals a
## clue you can then press them on in interrogation — another evidence source via the living sim.

const MOMENTS := [
	{"id": "sam_night", "npc_id": "sam", "hour": 2.0, "reveal_clue": "clue_camera",
		"description": "Sam slips out of the victim's room, pocketing something"},
	{"id": "morgan_dawn", "npc_id": "morgan", "hour": 6.0, "reveal_clue": "clue_moved_object",
		"description": "Morgan wipes down a surface and pockets a small bottle"},
	{"id": "casey_late", "npc_id": "casey", "hour": 23.0, "reveal_clue": "clue_portraits",
		"description": "Casey sketches the dorm from a darkened corner, watching everyone"},
]


static func moments() -> Array:
	return MOMENTS
```

Create `godot/scenes/suspicion_watcher.gd`:
```gdscript
extends Node

## Fires suspicious moments when the detective is near the acting NPC at/after the moment's hour.
## Runtime wiring is added in Task 5; the pure check() is what the test exercises.

static func check(moments: Array, hour: float, detective_pos: Vector2, npc_positions: Dictionary,
		fired: Dictionary, catch_range: float) -> Array:
	var result: Array = []
	for m in moments:
		var mid: String = str(m["id"])
		if fired.has(mid):
			continue
		if hour < float(m["hour"]):
			continue
		var npc_id: String = str(m["npc_id"])
		if not npc_positions.has(npc_id):
			continue
		var npc_pos: Vector2 = npc_positions[npc_id]
		if detective_pos.distance_to(npc_pos) <= catch_range:
			result.append(mid)
	return result
```

- [ ] **Step 4: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_suspicion.gd`
Expected: `PASS: test_suspicion`

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: SuspicionData + SuspicionWatcher.check (catching suspicious activity logic)"
```

---

### Task 5: Wire suspicion into the dorm (catch → reveal clue + toast)

**Files:**
- Modify: `godot/scenes/dorm/crestwood_hall.gd` (instantiate a `SuspicionWatcher` node and drive it each frame)
- Create: `godot/tests/test_suspicion_wiring.gd`

**Interfaces:**
- Consumes: `SuspicionWatcher.check` (Task 4), `Scheduler.get_hour()`, `Investigation.discover_clue`, the detective + npcs, `EventLog`.
- Produces: in `crestwood_hall.gd` — a `_suspicion_fired: Dictionary` and `_check_suspicion()` that fires caught moments (discover clue + log a "You witnessed ..." line).

- [ ] **Step 1: Add suspicion checking to the dorm**

In `godot/scenes/dorm/crestwood_hall.gd`, add a preload near the others:
```gdscript
const SUSPICION_WATCHER := preload("res://scenes/suspicion_watcher.gd")
```
Add a member:
```gdscript
var _suspicion_fired: Dictionary = {}
```
Add a `_process` that checks each frame (the dorm is a Node2D):
```gdscript
func _process(_delta: float) -> void:
	if detective == null or npcs.is_empty():
		return
	_check_suspicion()


func _check_suspicion() -> void:
	var npc_positions: Dictionary = {}
	for npc in npcs:
		npc_positions[npc.npc_id] = npc.global_position
	var caught: Array = SUSPICION_WATCHER.check(
		SuspicionData.moments(), Scheduler.get_hour(), detective.global_position,
		npc_positions, _suspicion_fired, 56.0)
	for mid in caught:
		_suspicion_fired[mid] = true
		for m in SuspicionData.moments():
			if str(m["id"]) == mid:
				var clue_id: String = str(m["reveal_clue"])
				if Investigation.discover_clue(clue_id):
					EventLog.log_action("You witnessed: %s" % str(m["description"]), "witness")
```

- [ ] **Step 2: Write the wiring test**

Create `godot/tests/test_suspicion_wiring.gd`:
```gdscript
extends SceneTree

var _phase := 0
var _hall
var _frames := 0

func _process(_delta: float) -> bool:
	if _phase == 0:
		_phase = 1
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		root.get_node("Investigation").reset()
		_hall = main.get_node("CrestwoodHall")
		# Force time to Sam's moment and put Sam + detective together.
		var sched = root.get_node("Scheduler")
		sched.set("game_hour", 2.0)
		for npc in _hall.npcs:
			if npc.npc_id == "sam":
				npc.global_position = Vector2(300, 300)
		_hall.detective.global_position = Vector2(305, 300)
		return false
	# let a few _process frames run so the dorm's _check_suspicion fires
	_frames += 1
	if _frames < 5:
		return false
	var inv = root.get_node("Investigation")
	if inv.is_discovered("clue_camera"):
		print("PASS: test_suspicion_wiring — caught Sam, revealed clue_camera")
		quit(0)
	else:
		print("FAIL: catching Sam should reveal clue_camera")
		quit(1)
	return true
```
> If `Scheduler` has no `game_hour` field, set the hour via its actual API — check `godot/autoload/scheduler.gd` and use the matching property/method.

- [ ] **Step 3: Run to verify (import + wiring + regressions)**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_suspicion_wiring.gd`
Expected: `PASS: test_suspicion_wiring`
Then run the full suite — all expected PASS.

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: wire suspicion watcher into the dorm (catch -> reveal clue + witness log)"
```

- [ ] **Step 5: Human playtest**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot`
Expected: choose murder → walk up to an NPC, press **F** → the **interrogation panel** opens with topic buttons; pressing a topic gives a real authored answer, and a trust-gated topic eventually makes them reveal a clue (toast + case file updates). The free-text box returns a deflection (LLM off). Speed up time in observer mode and stand near **Sam ~2:00 / Morgan ~6:00 / Casey ~23:00** to **witness** them and have a clue revealed.

---

## Self-Review

**Spec coverage (Plan C = interrogation + catching suspicious activity):**
- Authored interrogation (topics + evidence reactions) → Tasks 1, 2 ✅
- Trust-gated clue reveal via interrogation (evidence-from-interrogation) → Tasks 1, 2, 3 ✅
- Hybrid free-text → LLM-or-deflection → Task 3 (`_on_free_text` via `AIClient`) ✅
- Catching suspicious activity → reveals a clue you can press on → Tasks 4, 5 ✅
- All evidence funnels through `Investigation`/`CaseFile` → Tasks 2, 5 (both call `discover_clue`) ✅

**Deferred (intentional):** eavesdropping on NPC-to-NPC conversations (excluded by the user — its own later slice); richer LLM free-text (needs a stronger machine / a Python interrogation endpoint); presenting-evidence UI menu (the `present_evidence` seam exists; a button list can be added when desired).

**Placeholder scan:** none — all steps have concrete code/commands. (The Scheduler note in Task 5 Step 2 is a verification instruction, not a code placeholder.)

**Type/name consistency:** `InterrogationData.SUSPECTS/topics_for/respond_to_topic/respond_to_evidence` consistent (Tasks 1–3); `InterrogationPanel.open/select_topic/present_evidence/show_response/submit_free_text/free_text_submitted/closed` consistent (Tasks 2–3); `NpcInteractable.talk_requested/npc_id` consistent (Task 3); `SuspicionData.moments` + `SuspicionWatcher.check(...)` signature consistent (Tasks 4–5); reveal clue ids (`clue_medbook`, `clue_camera`, `clue_moved_object`, `clue_portraits`) all exist in `CaseData.CLUES` from Plan B.
```
