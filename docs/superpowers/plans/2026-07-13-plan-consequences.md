# Consequences Implementation Plan

**Goal:** Close the loop the Access/Sneaking slice opened: getting caught repeatedly costs your job,
running out the deadline unsolved costs your job, and — on Extreme, in a specific signposted
situation — costs your life. All three route through the existing ending/flashback system (Plan D's
`StoryScreen` + `EndingContent`), so the player still gets the "it was always an accident" reveal
even on a game-over — reinforcing the theme instead of just punishing the player.

**Design call — the death ending stays thematically consistent:** the murder mystery's twist is that
*no one* is guilty; every accusation convicts an innocent person. A "the suspect kills you" death
would imply a real killer exists, contradicting that. Instead, `ending_death` mirrors the victim's
own fate: caught alone in a restricted area deep at night on Extreme, the detective has their own
scripted accident — the same building claims a second "accident" nobody connects to the first.

**Deferred (documented, not silently dropped):** "botched intrusive search" as a strike source (per
the original design doc) needs the SearchPanel to know live player position + witnesses, which it
doesn't today — wiring that cleanly is its own small slice, not bundled here. This slice's strike
source is getting caught trespassing (already hooked in `crestwood_hall.gd::_on_caught`) plus the
deadline.

## Global Constraints
- Godot 4.7 stable; warnings-as-errors; explicit types on `Variant`-returning calls.
- Reuse `Difficulty.get_value("strikes_to_fired")`, `has_deadline()`/`deadline_days`, and
  `consequence_ceiling` ("standing"/"fired"/"death") — don't hardcode difficulty behavior.
- Test pattern: grab the real autoloads via `root.get_node("...")` in a `SceneTree` test (matches
  `test_case_flow.gd`), not fakes — `Consequences` talks to `GameFlow`/`Scheduler`/`Difficulty`.
- Git: branch `plan-consequences` from `main`. Commit per task, `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Game-over endings

**Files:** Modify `godot/scripts/case/ending_content.gd`.

Add `const GAME_OVER := {"ending_fired_strikes": {...}, "ending_fired_deadline": {...},
"ending_death": {...}}` (title + body each, in the existing tone). In `ending_for()`, check
`GAME_OVER.has(ending_id)` before falling through to the `WRONG` suspect lookup. No changes needed
in `story_screen.gd` — `show_ending()` already shows the flashback truth-reveal for any
`ending_id != "ending_accident"`, which is exactly right here too.

Commit: `feat: game-over endings (fired, deadline, death)`

---

### Task 2: `Consequences` autoload

**Files:** Create `godot/autoload/consequences.gd`; modify `godot/project.godot` (register after
`GameFlow`); create `godot/tests/test_consequences.gd`.

`Consequences`: `var strikes := 0`, `signal strike_added(reason, count)`. In `_ready()`, connect
`GameFlow.phase_changed` (capture `_case_start_day = Scheduler.game_day` the first time the phase
becomes `INVESTIGATION`) and `Scheduler.time_changed` (deadline check).

`record_catch(hour: float) -> void`: no-op outside `INVESTIGATION`. If
`Difficulty.get_value("consequence_ceiling") == "death"` and `hour < 5.0` (deep night — the
signposted danger window), `GameFlow.trigger_ending("ending_death")` and return. Otherwise add a
strike: increment, emit `strike_added`, log to `EventLog`, and if `strikes_to_fired > 0` and
`strikes >= strikes_to_fired`, `GameFlow.trigger_ending("ending_fired_strikes")`.

Deadline check (on `Scheduler.time_changed`, `INVESTIGATION` only): if `Difficulty.has_deadline()`
and `day > _case_start_day + deadline_days`, `GameFlow.trigger_ending("ending_fired_deadline")`.

`reset()`: `strikes = 0`, `_case_start_day = -1` (for saves/replays).

`test_consequences.gd`: using the real autoloads, verify (a) reaching `strikes_to_fired` on Medium
fires via strikes, (b) passing the deadline on Medium fires via deadline, (c) a deep-night catch on
Extreme kills instead of adding a strike, (d) Easy never force-ends from either path.

Commit: `feat: Consequences — strikes, deadline, fired/death`

---

### Task 3: Wire the dorm's catch into Consequences + regression + playtest + merge

**Files:** Modify `godot/scenes/dorm/crestwood_hall.gd` (`_on_caught` calls
`Consequences.record_catch(Scheduler.get_hour())` alongside the existing standing hit + ejection).

Run the full `godot/tests/*.gd` suite (all green expected). Human playtest:
`"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot` — on Medium, get caught
trespassing repeatedly (5 times) and confirm you're fired with the flashback ending; separately, use
Scheduler speed controls to run the day counter past the deadline and confirm the same. On Extreme,
get caught trespassing deep at night and confirm the death ending fires instead of a strike.

Commit, then finish the branch (merge to `main`, delete branch, verify full suite on `main`).
