# Map Markers + Full Playthrough Test

**Goal:** Two small, no-art-needed items: mark unvisited locations on the fast-travel map (inspired
by NLT Media's "!" location markers — adapted to a text marker since there's no icon asset), and a
single end-to-end headless test that plays a full case (Choice -> travel -> clues -> interrogation
-> a sneaking catch -> a botched search -> accusation -> ending) — complementing, not replacing, the
many focused per-system tests already in place.

## Global Constraints
- Godot 4.7 stable; warnings-as-errors; explicit types on `Variant`-returning calls.
- Git: branch `plan-map-markers-e2e` from `main`. Commit per task,
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Unvisited-location markers on the fast-travel map

**Files:** Modify `godot/autoload/location_manager.gd` (`visited: Dictionary`, starts
`{"dorm": true}`; `travel()` marks the destination visited; `is_unvisited(id) -> bool`; fold
`visited` into `get_save_data`/`load_save_data`); modify `godot/scenes/ui/travel_map.gd` (prefix
`"! "` to the button label when `LocationManager.is_unvisited(id)`); extend
`godot/tests/test_location_manager.gd` and `godot/tests/test_travel_map.gd`.

Commit: `feat: mark unvisited locations on the fast-travel map`

---

### Task 2: Full end-to-end playthrough test

**Files:** Create `godot/tests/test_full_playthrough.gd`.

Using the real autoloads (the established `_process()`-deferred pattern): reset state, First
Choice -> murder, travel to the detective's room and back, discover two of Sam's clues (case
strength check), a high-trust interrogation topic reveal, a trespass catch (`Consequences.record_catch`),
a botched risky search (`Consequences.record_risky_search`), one clue for every other suspect
(unlocking accusations), accuse Sam, reach `Phase.ENDING` with `ending_sam`, and confirm
`EndingContent.build_flashback()` produces entries from the discovered clues.

Run the full `godot/tests/*.gd` suite (all green expected). No human playtest needed — this task
*is* the playtest, expressed as a repeatable automated check.

Commit, then finish the branch (merge to `main`, delete branch, verify full suite on `main`).
