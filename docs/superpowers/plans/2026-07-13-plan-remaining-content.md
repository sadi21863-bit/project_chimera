# Remaining Content Implementation Plan

**Goal:** Close the last four items from the punch-list research: a University NPC (the dean, tied
to Daniel's double life), one walk-through-door connection as a proof of the optional travel mode,
"botched intrusive search" as a real strike source, and one more hint-giver source. All four are
content/wiring on top of already-tested systems — no new architecture beyond one small reusable
`DoorTrigger` component.

## Global Constraints
- Godot 4.7 stable; warnings-as-errors; explicit types on `Variant`-returning calls.
- The dean is lore-only: an `InterrogationData.SUSPECTS["dean"]` entry with no `CaseData.SUSPECTS`
  or `CaseData.CLUES` entry — confirmed by prior research that neither system requires the other.
- Git: branch `plan-remaining-content` from `main`. Commit per task,
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: University dean NPC

**Files:** Modify `godot/scenes/locations/university.gd`/`.tscn`; modify
`godot/scripts/interrogation/interrogation_data.gd`; create `godot/tests/test_university_npc.gd`.

Add a `RoomMarkers` node (one marker, `office`) to `university.tscn`. In `university.gd`, add
`room_markers: Dictionary`, `_collect_markers()`, and `_spawn_dean()` — mirrors
`crestwood_hall.gd::_spawn_npcs()`'s exact pattern (construct an `NpcProfile` with `npc_id="dean"`,
no `schedule` — the dean has no bedroom/routine, they're always in their office — `add_child`,
`npc.setup(...)`, attach an `NpcInteractable` talk area), called from `_ready()` alongside the
existing detective spawn.

`InterrogationData.SUSPECTS["dean"]`: persona + 2 trust-gated topics (flavor, `reveal_clue: ""`)
about Daniel's double life and the pressure to keep it quiet + an `evidence` reaction or two.

`test_university_npc.gd`: instantiate `university.tscn`, assert `npcs.size() == 1`, the dean has a
talk `NpcInteractable` child, and `InterrogationData.topics_for("dean")` is non-empty.

Commit: `feat: university dean NPC (lore-only, no accusation arc)`

---

### Task 2: One walk-through-door connection (dorm hallway <-> university)

**Files:** Create `godot/scripts/player/door_trigger.gd`; modify `godot/scenes/dorm/crestwood_hall.tscn`
(add a `DoorTrigger` near the hallway marker), `godot/scenes/locations/university.tscn` (add a
`DoorTrigger` back to the dorm); modify `godot/scenes/main.gd` (`_bind_location` wires
`door_triggered` the same way it already wires `SearchPoint`/`RestPoint`); create
`godot/tests/test_door_trigger.gd`.

`DoorTrigger extends Interactable`: `signal door_triggered(dest_id: String)`, `@export var
dest_id := ""`, `@export var dest_label := "through the door"`, `get_prompt() -> "Go to %s" %
dest_label`, `interact()` emits `door_triggered`. In `main.gd::_bind_location`, alongside the
existing `SearchPoint`/`RestPoint` branches: `elif ch is DoorTrigger: ch.door_triggered.connect(func(d): LocationManager.travel(d))`
— reuses the exact same travel path the fast-travel map already uses, so time still advances
correctly and no new location-swap logic is needed.

`test_door_trigger.gd`: pure unit test (prompt text, signal fires on `interact()`), plus extend
`test_location_swap.gd`-style wiring is optional — a plain unit test is enough since the actual
travel call is the already-tested `LocationManager.travel()`.

Commit: `feat: DoorTrigger — one walk-through-door connection (dorm <-> university)`

---

### Task 3: Botched intrusive search -> a real strike

**Files:** Modify `godot/autoload/consequences.gd` (new `record_risky_search(restricted: bool,
witnessed: bool)` method — mirrors `record_catch`'s strike/death branching but doesn't eject/move
the detective, since a search isn't a location violation); modify `godot/scenes/main.gd`
(`_on_search_requested`/a new handler computes `restricted` via `AccessData` + the location's
`_room_at`-equivalent and `witnessed` via nearby NPCs, passed to `search_panel.open()`); modify
`godot/scenes/ui/search_panel.gd` (`select_action` calls back to `main.gd` via a new
`action_selected(point_id, action_id, risk)` signal instead of resolving+strike-checking itself —
keeps the panel a pure UI/data view, matching the research's recommended "Option C" architecture);
create `godot/tests/test_botched_search.gd`.

Only `risk == "risky"` actions restricted-or-witnessed trigger a strike (mirrors
`RiskAssessor.assess()`'s existing "safe" vs "risky"/"dangerous" split) — a risky action performed
safely (unrestricted, no witnesses) never strikes, matching the existing risk-hint semantics.

`test_botched_search.gd`: drives the real autoloads — a risky action while restricted/witnessed
adds a `Consequences` strike; the same action while safe does not.

Commit: `feat: botched intrusive search adds a Consequences strike`

---

### Task 4: One more hint-giver source (Jordan)

**Files:** Modify `godot/scripts/interrogation/interrogation_data.gd` (Jordan's `topics`).

A trust-gated topic (`trust_min: 0.5`, `reveal_clue: ""`) where Jordan — guilt-adjacent and
anxious, not a bullying victim by name but plausibly one given "froze and walked past" — offers a
grounded nudge toward the university thread (fits "someone with guilty knowledge" from the Bible).

Commit: `feat: Jordan as a second hint-giver source`

---

### Task 5: Regression + playtest + merge

Run the full `godot/tests/*.gd` suite (all green expected). Human playtest:
`"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot` — travel to University (M),
confirm the dean is there and talkable with working topics; from the dorm hallway, find and use the
door to University and back; select a risky search action while restricted/witnessed and confirm a
strike is logged; raise trust with Jordan and confirm the new hint topic appears.

Commit, then finish the branch (merge to `main`, delete branch, verify full suite on `main`).
