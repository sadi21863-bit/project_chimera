# Save/Load Gaps — Implementation Plan

**Goal:** Fix two real bugs the research surfaced: (1) four autoloads built after `SaveManager` was
wired up — `GameFlow`, `Consequences`, `LocationManager`, `CaseFile` — have no `get_save_data`/
`load_save_data`, so loading a save silently resets phase/strikes/location/accusation state; (2) the
dorm-lookup in `observer_panel.gd`'s save/load handlers still hardcodes `"Main/CrestwoodHall"`, a
path that stopped existing when World Expansion W1 moved the dorm under `LocationHost` — so NPC save
data has been silently failing to bundle since that merge.

**Scope note:** `Standing`, `Investigation`, `Difficulty`, `LocalMemory` self-persist to their own
`user://*.json` files independent of save slots. That's a real inconsistency (a loaded slot can't
roll back trust/clue progress), but folding four independently-designed persistence stores into one
contract is a bigger, riskier refactor than this bug-fix slice warrants — out of scope here,
documented for later.

## Global Constraints
- Godot 4.7 stable; warnings-as-errors; explicit types on `Variant`-returning calls.
- Match the existing `get_save_data() -> Dictionary` / `load_save_data(data: Dictionary) -> void`
  contract already used by `Scheduler`/`EventLog`/`DormNpc` (see `scheduler.gd:100,109`).
- Git: branch `plan-save-load-fixes` from `main`. Commit per task, `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: `get_save_data`/`load_save_data` on the four missing autoloads

**Files:** Modify `godot/autoload/game_flow.gd`, `godot/autoload/consequences.gd`,
`godot/autoload/location_manager.gd`, `godot/autoload/case_file.gd`; create
`godot/tests/test_save_data_coverage.gd`.

- `GameFlow`: `{"phase": phase, "current_ending_id": current_ending_id}`; on load, restore both and
  re-emit `phase_changed` (so bound UI like `StoryScreen` re-syncs).
- `Consequences`: `{"strikes": strikes, "case_start_day": _case_start_day}`.
- `LocationManager`: `{"current_id": current_id}`; on load, restore `current_id` and re-emit
  `location_changing(current_id)` (the exact signal `main.gd` already listens to for scene-swapping —
  reusing it means loading mid-game correctly reloads the saved location, no new wiring needed).
- `CaseFile`: `{"resolved": resolved, "accused_id": accused_id}`.

`test_save_data_coverage.gd`: round-trips each autoload's own `get_save_data()` → `load_save_data()`
in isolation (set state, save, reset, load, assert restored) using the real autoloads via
`root.get_node(...)` (the `_process()`-deferred pattern, since some of these connect signals in
`_ready()`).

Commit: `feat: save/load for GameFlow, Consequences, LocationManager, CaseFile`

---

### Task 2: Fix the stale dorm path + wire the new autoloads into save/load

**Files:** Modify `godot/scenes/ui/observer_panel.gd`; create `godot/tests/test_save_load_roundtrip.gd`.

In `_on_save_pressed`/`_on_load_pressed`, replace `get_tree().root.get_node_or_null("Main/CrestwoodHall")`
with `get_tree().root.get_node_or_null("Main/LocationHost/CrestwoodHall")` (matches the path
established by the W1 `LocationHost` refactor — see `main.tscn`'s `LocationHost` node). Add
`"game_flow"`, `"consequences"`, `"location_manager"`, `"case_file"` entries to both the save
dictionary and the load restoration, using Task 1's new methods.

`test_save_load_roundtrip.gd`: instantiate `main.tscn`, drive the real game forward a bit (discover
a clue, add a strike, travel to a second location), call the save flow, mutate everything back to
defaults, call the load flow, assert `GameFlow.phase`, `Consequences.strikes`, and
`LocationManager.current_id` are all restored — this is the test that would have caught the stale
`Main/CrestwoodHall` path bug.

Run the full `godot/tests/*.gd` suite (all green expected), then finish the branch (merge to `main`,
delete branch, verify full suite on `main`). No human playtest checkpoint needed — this slice has no
new UI, and the round-trip test directly exercises the exact bug found.
