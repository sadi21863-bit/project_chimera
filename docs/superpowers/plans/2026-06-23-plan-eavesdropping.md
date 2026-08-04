# Eavesdropping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** NPCs hold short conversations with each other; if the detective is close enough, you overhear them — and a revealing line surfaces a clue (a new evidence source via the living sim).

**Architecture:** Static `GossipData` holds authored two-person conversations (each with lines + an optional revealed clue). A pure `EavesdropWatcher.check` fires a conversation when its two NPCs are near each other AND the detective is near them. The dorm drives it each frame (like `SuspicionWatcher`): on fire it discovers the clue (so the existing `ClueToast` pops) and plays the lines through `DialogSystem` + the event log. Proximity-gated display = 2D eavesdropping, no 3D/audio needed.

**Tech Stack:** Godot 4.7 (GDScript). Builds on `Investigation`, `DialogSystem`, `EventLog`, `CaseData`, the dorm's existing per-frame watcher pattern.

## Global Constraints

- **Engine:** Godot 4.7 stable; project root `godot/`.
- **Warnings are errors:** no `:=` inference from `Variant`-returning calls; explicit types.
- **GDScript style:** snake_case funcs/vars, PascalCase classes; typed where practical.
- **Reuse:** `Investigation.discover_clue/is_discovered`, `DialogSystem.show_dialogue(speaker, text)`, `EventLog.log_action(text, category)`, `CaseData.CLUES`. Mirror `scenes/suspicion_watcher.gd` + the dorm's `_check_suspicion`.
- **Evidence is source-agnostic:** overheard reveals call `Investigation.discover_clue` — same case system.
- **Test runner:** `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd`; print `PASS: <name>`/`quit(0)` or `FAIL:`/`quit(<n>)`.
- **Git:** Task 1 creates branch `plan-eavesdropping` from `main`. Commit per task; end messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: `GossipData` — authored overheard conversations

**Files:**
- Create: `godot/scripts/interrogation/gossip_data.gd`
- Create: `godot/tests/test_gossip_data.gd`

**Interfaces:**
- Produces: `GossipData` (`class_name`, extends `RefCounted`):
  - `const CONVERSATIONS: Array` of `{id, npc_a, npc_b, reveal_clue, lines}` where `lines` is `[{speaker, text}, ...]` and `speaker` is an npc_id.
  - `static conversations() -> Array`

- [ ] **Step 1: Create branch**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git checkout main && git checkout -b plan-eavesdropping
```

- [ ] **Step 2: Write the failing test**

Create `godot/tests/test_gossip_data.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var gd := preload("res://scripts/interrogation/gossip_data.gd")
	var case_data := preload("res://scripts/case/case_data.gd")
	var failures := 0
	if gd.conversations().is_empty():
		failures += 1; print("FAIL: there should be conversations")
	for convo in gd.conversations():
		if convo["lines"].is_empty():
			failures += 1; print("FAIL: conversation %s has no lines" % convo["id"])
		var reveal: String = str(convo["reveal_clue"])
		if reveal != "" and not case_data.CLUES.has(reveal):
			failures += 1; print("FAIL: %s reveals unknown clue %s" % [convo["id"], reveal])
	if failures == 0:
		print("PASS: test_gossip_data")
	quit(failures)
```

- [ ] **Step 3: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_gossip_data.gd`
Expected: preload error — file does not exist.

- [ ] **Step 4: Implement `GossipData`**

Create `godot/scripts/interrogation/gossip_data.gd`:
```gdscript
extends RefCounted
class_name GossipData

## Authored two-person conversations. Overheard when the detective is near both speakers; a
## revealing line surfaces a clue (another evidence source). speaker values are npc_ids.

const CONVERSATIONS := [
	{"id": "morgan_casey_panic", "npc_a": "morgan", "npc_b": "casey", "reveal_clue": "clue_moved_object",
		"lines": [
			{"speaker": "morgan", "text": "I shouldn't have touched anything that morning."},
			{"speaker": "casey", "text": "You panicked. Anyone would have."},
			{"speaker": "morgan", "text": "If the detective finds out I moved that bottle..."},
		]},
	{"id": "jordan_riley_worry", "npc_a": "jordan", "npc_b": "riley", "reveal_clue": "clue_witness_jordan",
		"lines": [
			{"speaker": "jordan", "text": "I keep seeing him stumble in that hallway."},
			{"speaker": "riley", "text": "You were there? Jordan, you have to say something."},
			{"speaker": "jordan", "text": "And admit I walked past him? They'll think I did it."},
		]},
	{"id": "sam_alex_favor", "npc_a": "sam", "npc_b": "alex", "reveal_clue": "clue_camera",
		"lines": [
			{"speaker": "sam", "text": "I only killed the camera feed for the app."},
			{"speaker": "alex", "text": "Do not tell the detective that. It looks like a cover-up."},
			{"speaker": "sam", "text": "It wasn't. It just... is."},
		]},
]


static func conversations() -> Array:
	return CONVERSATIONS
```

- [ ] **Step 5: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_gossip_data.gd`
Expected: `PASS: test_gossip_data`

- [ ] **Step 6: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: GossipData — authored overheard conversations"
```

---

### Task 2: `EavesdropWatcher.check` — proximity firing logic

**Files:**
- Create: `godot/scenes/eavesdrop_watcher.gd`
- Create: `godot/tests/test_eavesdrop.gd`

**Interfaces:**
- Produces: `EavesdropWatcher` (extends `Node`): `static check(conversations: Array, npc_positions: Dictionary, detective_pos: Vector2, fired: Dictionary, pair_range: float, hear_range: float) -> Array` — returns ids of conversations to play now (both speakers present and within `pair_range` of each other, detective within `hear_range` of speaker A, not already in `fired`).

- [ ] **Step 1: Write the failing test**

Create `godot/tests/test_eavesdrop.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var ew := preload("res://scenes/eavesdrop_watcher.gd")
	var failures := 0
	var convos := [
		{"id": "c1", "npc_a": "morgan", "npc_b": "casey", "reveal_clue": "x", "lines": []},
	]
	var pos := {"morgan": Vector2(100, 100), "casey": Vector2(120, 100)}  # near each other

	# detective far -> nothing
	var far: Array = ew.check(convos, pos, Vector2(900, 900), {}, 60.0, 120.0)
	if not far.is_empty():
		failures += 1; print("FAIL: should not fire when detective is far")
	# speakers apart -> nothing
	var apart := {"morgan": Vector2(100, 100), "casey": Vector2(900, 100)}
	var sep: Array = ew.check(convos, apart, Vector2(110, 100), {}, 60.0, 120.0)
	if not sep.is_empty():
		failures += 1; print("FAIL: should not fire when speakers are apart")
	# near + detective near -> fires
	var near: Array = ew.check(convos, pos, Vector2(130, 100), {}, 60.0, 120.0)
	if near != ["c1"]:
		failures += 1; print("FAIL: should fire c1 when overheard")
	# already fired -> nothing
	var again: Array = ew.check(convos, pos, Vector2(130, 100), {"c1": true}, 60.0, 120.0)
	if not again.is_empty():
		failures += 1; print("FAIL: should not re-fire")

	if failures == 0:
		print("PASS: test_eavesdrop")
	quit(failures)
```

- [ ] **Step 2: Run to verify it fails**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_eavesdrop.gd`
Expected: preload error — file does not exist.

- [ ] **Step 3: Implement `EavesdropWatcher`**

Create `godot/scenes/eavesdrop_watcher.gd`:
```gdscript
extends Node

## Fires a conversation when both speakers are near each other and the detective is near them.

static func check(conversations: Array, npc_positions: Dictionary, detective_pos: Vector2,
		fired: Dictionary, pair_range: float, hear_range: float) -> Array:
	var result: Array = []
	for convo in conversations:
		var cid: String = str(convo["id"])
		if fired.has(cid):
			continue
		var a: String = str(convo["npc_a"])
		var b: String = str(convo["npc_b"])
		if not npc_positions.has(a) or not npc_positions.has(b):
			continue
		var pa: Vector2 = npc_positions[a]
		var pb: Vector2 = npc_positions[b]
		if pa.distance_to(pb) > pair_range:
			continue
		if detective_pos.distance_to(pa) <= hear_range:
			result.append(cid)
	return result
```

- [ ] **Step 4: Run to verify it passes**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_eavesdrop.gd`
Expected: `PASS: test_eavesdrop`

- [ ] **Step 5: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: EavesdropWatcher.check — proximity firing logic"
```

---

### Task 3: Wire eavesdropping into the dorm (overhear → clue + dialogue)

**Files:**
- Modify: `godot/scenes/dorm/crestwood_hall.gd` (check each frame; on fire reveal the clue + play lines)
- Create: `godot/tests/test_eavesdrop_wiring.gd`

**Interfaces:**
- Consumes: `EavesdropWatcher.check`, `GossipData.conversations`, `Investigation.discover_clue`, `DialogSystem`, `EventLog`, the detective + npcs.
- Produces: in `crestwood_hall.gd` — `_conversation_fired: Dictionary` and `_check_eavesdrop()` (called from the existing `_process`), discovering the clue synchronously and playing lines async.

- [ ] **Step 1: Add eavesdrop checking to the dorm**

In `godot/scenes/dorm/crestwood_hall.gd`, add a preload near the others:
```gdscript
const EAVESDROP_WATCHER := preload("res://scenes/eavesdrop_watcher.gd")
```
Add a member next to `_suspicion_fired`:
```gdscript
var _conversation_fired: Dictionary = {}
```
In the existing `_process`, add the eavesdrop check after `_check_suspicion()`:
```gdscript
func _process(_delta: float) -> void:
	if detective == null or npcs.is_empty():
		return
	_check_suspicion()
	_check_eavesdrop()
```
Add the methods:
```gdscript
func _check_eavesdrop() -> void:
	var npc_positions: Dictionary = {}
	for npc in npcs:
		npc_positions[npc.npc_id] = npc.global_position
	var heard: Array = EAVESDROP_WATCHER.check(
		GossipData.conversations(), npc_positions, detective.global_position,
		_conversation_fired, 90.0, 120.0)
	for cid in heard:
		_conversation_fired[cid] = true
		for convo in GossipData.conversations():
			if str(convo["id"]) == cid:
				var clue: String = str(convo["reveal_clue"])
				if clue != "" and Investigation.discover_clue(clue):
					EventLog.log_action("You overheard something revealing...", "overheard")
				_play_conversation(convo)


func _play_conversation(convo: Dictionary) -> void:
	for line in convo["lines"]:
		var speaker_id: String = str(line["speaker"])
		var speaker_name: String = _npc_display_name(speaker_id)
		DialogSystem.show_dialogue(speaker_name, str(line["text"]))
		EventLog.log_action("[Overheard] %s: %s" % [speaker_name, str(line["text"])], "overheard")
		await get_tree().create_timer(2.5).timeout


func _npc_display_name(npc_id: String) -> String:
	for npc in npcs:
		if npc.npc_id == npc_id:
			return npc.display_name
	return npc_id
```

- [ ] **Step 2: Write the wiring test**

Create `godot/tests/test_eavesdrop_wiring.gd`:
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
		# Put morgan + casey together and the detective next to them.
		for npc in _hall.npcs:
			if npc.npc_id == "morgan":
				npc.global_position = Vector2(400, 400)
			elif npc.npc_id == "casey":
				npc.global_position = Vector2(420, 400)
		_hall.detective.global_position = Vector2(430, 400)
		return false
	_frames += 1
	if _frames < 5:
		return false
	var inv = root.get_node("Investigation")
	if inv.is_discovered("clue_moved_object"):
		print("PASS: test_eavesdrop_wiring — overheard morgan+casey, revealed clue_moved_object")
		quit(0)
	else:
		print("FAIL: overhearing morgan+casey should reveal clue_moved_object")
		quit(1)
	return true
```

- [ ] **Step 3: Run to verify (import + wiring + regressions)**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/test_eavesdrop_wiring.gd`
Expected: `PASS: test_eavesdrop_wiring`
Then re-run `test_suspicion_wiring` and `test_examine_flow` — expected PASS (the dorm still boots; suspicion still fires).

- [ ] **Step 4: Commit**

```bash
cd "c:/Users/aditya/Desktop/project-chimera" && git add -A && git commit -m "feat: wire eavesdropping into the dorm (overhear -> reveal clue + play conversation)"
```

- [ ] **Step 5: Human playtest**

Run: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot`
Expected: choose murder, speed up time in observer mode, and position the detective near two NPCs who are together (e.g. Morgan + Casey). Their conversation plays out in dialogue + the event log, and a clue is revealed (toast). Move far away and you won't catch it.

---

## Self-Review

**Spec coverage (eavesdropping):**
- NPCs converse → `GossipData` (Task 1) + `_play_conversation` (Task 3) ✅
- Overhear only when near → `EavesdropWatcher.check` proximity gating (Tasks 2, 3) ✅
- Overheard secret = evidence → `discover_clue` on fire (Task 3) ✅

**Deferred (intentional):** emergent conversation *generation* (these are authored), LLM-written gossip, and visual speech bubbles above heads (lines play via the existing `DialogSystem` + event log) — later polish.

**Placeholder scan:** none — all steps have concrete code/commands.

**Type/name consistency:** `GossipData.CONVERSATIONS/conversations` (Tasks 1–3); `EavesdropWatcher.check(conversations, npc_positions, detective_pos, fired, pair_range, hear_range)` consistent (Tasks 2–3); reveal clue ids (`clue_moved_object`, `clue_witness_jordan`, `clue_camera`) all exist in `CaseData.CLUES`; mirrors the proven `_check_suspicion` pattern already in `crestwood_hall.gd`.
```
