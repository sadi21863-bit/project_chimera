# World Expansion W2 — Content Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans style — task-by-task, TDD, commit per task.

**Goal:** Fill in the content W1 deferred: detailed examination of the dorm's bedrooms + bathroom
(already-placed `RoomMarkers` that had no search points), a "Rest" action in the detective's room
that advances the day counter, and two new minimal locations (police station, university) reachable
from the fast-travel map.

**Key finding:** the dorm's `RoomMarkers` already include `bathroom` and `bedroom_1..6` (three of
which — 4/5/6 — already host a `ClueHotspot` via `CaseData.CLUES`). `crestwood_hall.gd::_spawn_search_points()`
already iterates `SearchData.point_ids()` and places one per room marker — so adding rows to
`SearchData` is enough to make every bedroom + the bathroom examinable in detail. No new scenes,
no scene-swap, no access/sneaking logic (that's a later slice) — this stays pure content + one new
small interactable type.

**Deferred out of scope (per the original design doc):** access/time-gating, risk/sneak/catch model,
consequences (strikes/fired/death), walk-through-doors travel. Those are separate future slices.

## Global Constraints
- Godot 4.7 stable; warnings-as-errors; explicit types on `Variant`-returning calls.
- New bedroom/bathroom search actions are **flavor-only** (`reveal_clue: ""`) — the six suspects'
  clue graph (`CaseData.CLUES`) is balanced and already tested end-to-end; don't touch it here.
- Test runner: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd`.
- Git: branch `plan-world-w2` from `main`. Commit per task, `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Detailed examination for bedrooms + bathroom

**Files:** Modify `godot/scripts/interrogation/search_data.gd`; modify `godot/tests/test_search_data.gd`.

Add 7 rows to `SearchData.POINTS`: `bathroom_cabinet` (room `bathroom`), `alex_desk` (`bedroom_1`),
`jordan_dresser` (`bedroom_2`), `sam_nightstand` (`bedroom_3`), `riley_closet` (`bedroom_4`),
`morgan_desk` (`bedroom_5`), `casey_shelf` (`bedroom_6`) — 1-2 flavor actions each, `reveal_clue: ""`,
`risk` "safe" or "risky" per how intrusive the action reads (closets/drawers = risky, flavor for later).

Extend `test_search_data.gd` to assert the 7 new ids exist with the right `room` field. Re-run
`test_search_wiring` (unaffected point still resolves) + a quick instantiate check that
`crestwood_hall` now spawns 10 `SearchPoint`s (3 existing + 7 new) — extend the existing spawn-count
assertion in `test_search_wiring.gd` if one exists, else add it inline to the new data test.

Commit: `feat: detailed examination for bedrooms + bathroom`

---

### Task 2: Rest (advance a day) in the detective's room

**Files:** Create `godot/scripts/player/rest_point.gd`; modify `godot/scenes/locations/detective_room.tscn`
(+`.gd` if a marker position is needed); modify `godot/scenes/main.gd` (`_bind_location` wiring);
create `godot/tests/test_rest_point.gd`.

`RestPoint extends Interactable`: `signal rest_requested()`, `get_prompt() -> "Rest (advance a day)"`,
`interact()` emits `rest_requested`. Add one `RestPoint` node (a `CollisionShape2D` circle, radius ~20)
to `detective_room.tscn` near the spawn point. In `main.gd::_bind_location`, alongside the existing
`SearchPoint` loop: `if ch is RestPoint: ch.rest_requested.connect(_on_rest_requested)`; add
`_on_rest_requested()` that calls `Scheduler.advance_days(1)` and logs to `EventLog`.

`test_rest_point.gd`: pure unit test on the interactable (prompt text, signal fires on `interact()`).
Then a quick functional check: instantiate `main.tscn`, travel to `detective_room`, call
`try_examine()` on the interactor once positioned on the RestPoint, assert `Scheduler.game_day`
incremented by 1.

Commit: `feat: Rest action in the detective's room advances the day`

---

### Task 3: Police station + university locations

**Files:** Create `godot/scenes/locations/police_station.gd`/`.tscn`, `godot/scenes/locations/university.gd`/`.tscn`;
modify `godot/autoload/location_manager.gd` (`LOCATIONS` += `police_station`, `university`);
modify `godot/tests/test_location_manager.gd` (assert the two new ids are known locations).

Both scenes mirror `detective_room.gd`'s minimal self-contained pattern (spawn a detective on a nav
region, expose `detective`/`npcs`). `travel_hours`: 1.0 for both (same as the detective's room).

Commit: `feat: police station + university locations`

---

### Task 4: Full regression + playtest checkpoint

Run the whole `godot/tests/*.gd` suite (all green expected). Then human playtest:
`"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot` — walk to a bedroom/the bathroom
and examine (E) the new search points; press M, travel to Police Station and University and back;
in the detective's room, rest and confirm the day counter advances (case panel / event log).

Commit (if anything changed during playtest fixups), then finish the branch (merge to `main` per
standing preference, delete branch, verify full suite on `main`).
