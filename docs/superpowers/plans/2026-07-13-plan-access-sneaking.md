# Access Rules + Sneaking Implementation Plan

**Goal:** Time-gated private areas (the six bedrooms), a computed risk level (Safe/Risky/Dangerous),
and a difficulty-scaled catch model — off (easy) / suspicion meter (medium) / vision+proximity
(hard/extreme). Getting caught ejects you and costs standing with the room's owner; recording it
as a strike toward getting fired is the next slice (Consequences), not this one.

**Key finding:** the dorm's `RoomMarkers` already give every bedroom a position and `DormNpc` already
tracks `current_room` and has a `velocity` (usable as a facing vector while moving). No new scenes —
this is a data table + two pure-function modules + one `_process` hook in `crestwood_hall.gd`,
mirroring the existing `SuspicionWatcher`/`EavesdropWatcher` pure-`check()` pattern.

## Global Constraints
- Godot 4.7 stable; warnings-as-errors; explicit types on `Variant`-returning calls.
- Reuse `Difficulty.get_value("catch_model")` (off/meter/vision) and `risk_hints`
  (explicit/shown/subtle/hidden) — don't hardcode difficulty behavior.
- Test runner: `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot -s res://tests/<file>.gd`.
- Git: branch `plan-access-sneaking` from `main`. Commit per task, `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: `AccessData` + `is_restricted`

**Files:** Create `godot/scripts/access/access_data.gd`, `godot/tests/test_access_data.gd`.

`AccessData.AREAS`: `area_id -> {open_hour, close_hour, owner}`. Common areas (`kitchen`,
`common_room`, `hallway`, `bathroom`) are public, always open (`owner: ""`). Each `bedroom_1..6` is
owned by its suspect (`alex`/`jordan`/`sam`/`riley`/`morgan`/`casey`), open `8.0..22.0`.
`is_restricted(area_id, hour, owner_present) -> bool`: `false` if `owner_present`; else `false` for
unknown/public areas; else `true` when `hour` is outside `[open_hour, close_hour)`.

Commit: `feat: AccessData — time-gated + owned areas`

---

### Task 2: `RiskAssessor` + difficulty-aware risk hints in the SearchPanel

**Files:** Create `godot/scripts/access/risk_assessor.gd`, `godot/tests/test_risk_assessor.gd`;
modify `godot/scenes/ui/search_panel.gd`.

`RiskAssessor.assess(restricted: bool, intrusive: bool, witnesses: int) -> String` → `"safe"` /
`"risky"` / `"dangerous"` (restricted-or-intrusive with a witness present escalates to dangerous).
`RiskAssessor.hint_for(risk: String, risk_hints: String) -> String` → the UI suffix: `""` for safe;
`"  [RISKY]"`/`"  [DANGEROUS]"` for `explicit`/`shown`; `"  [?]"` for `subtle`; `""` for `hidden`.

In `search_panel.gd::open()`, replace the hardcoded `"[RISKY]"` suffix with
`RiskAssessor.hint_for(risk, Difficulty.get_value("risk_hints", "shown"))` so easy/medium spell it
out and hard/extreme make the player judge for themselves. Re-run `test_search_panel`.

Commit: `feat: RiskAssessor + difficulty-aware risk hints in the search panel`

---

### Task 3: `CatchModel` pure detection math

**Files:** Create `godot/scripts/access/catch_model.gd`, `godot/tests/test_catch_model.gd`.

`CatchModel.update_meter(meter: float, restricted: bool, delta: float) -> float` — fills while
restricted, drains otherwise, clamped `[0,1]` (medium).
`CatchModel.check_vision(restricted: bool, detective_pos: Vector2, npc_states: Array, cone_range:
float, cone_half_angle_deg: float, proximity_range: float) -> bool` — `npc_states` are
`{"position": Vector2, "facing": Vector2}`; caught if `restricted` and inside any NPC's close
proximity OR its facing cone (hard/extreme).

Commit: `feat: CatchModel — suspicion meter + vision-cone detection`

---

### Task 4: Wire sneaking into the dorm + regression + playtest + merge

**Files:** Modify `godot/scenes/dorm/crestwood_hall.gd` (`_check_sneaking()`, `_on_caught()`, a
`_room_at(pos)` helper using `room_markers` + a fixed radius, called from `_process`); create
`godot/tests/test_sneaking_wiring.gd`.

`_room_at(pos)`: nearest room marker within `90.0` px, else `"hallway"` (so casual hallway traffic
near the bedroom row never misclassifies as trespassing). `_check_sneaking()`: skip if
`Difficulty.get_value("catch_model") == "off"`; else compute `area_id`/`restricted`/`owner_present`
(owner's `current_room == area_id`) and branch on `catch_model` (`meter` vs `vision`) using
`CatchModel`. `_on_caught(owner_id)`: `Standing.adjust(owner_id, -0.2)` if an owner, teleport the
detective to the `hallway` marker (naturally clears `restricted` next frame — no extra debounce
state needed), `EventLog.log_action(...)`.

`test_sneaking_wiring.gd`: instantiate `main.tscn`, force `Difficulty` to `"medium"`, place the
detective inside a bedroom after its close hour with the owner elsewhere, run enough frames for the
meter to fill, assert the detective was ejected back to the hallway and standing with the owner
dropped.

Run the full `godot/tests/*.gd` suite (all green expected). Human playtest:
`"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot` — set difficulty to Medium in
Settings, visit a bedroom late at night while its owner is elsewhere, confirm you get ejected with an
event-log entry and a standing hit; then try Hard and confirm proximity to an NPC while trespassing
catches you.

Commit, then finish the branch (merge to `main`, delete branch, verify full suite on `main`).
