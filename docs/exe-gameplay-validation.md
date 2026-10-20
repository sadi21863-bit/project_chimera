# Packaged EXE Gameplay Validation — Full NPC Decision Cycle

**Scope:** one full NPC decision cycle inside the packaged binary: AI decision received → validated/published → action executed → observable world-state change → NPC re-enters eligibility → no duplicate responses / no lost responses.
**Constraint honored:** no source modifications; only this doc plus evidence artifacts were written.

| Part | Package | Date | Verdict |
|---|---|---|---|
| **1** — original build | `ProjectChimera.pck` 74,085,276 B (2026-10-15 13:55) | 2026-10-18 | **FAIL** — AI pipeline inert (pre-CHI-003 bytecode) |
| **2** — rebuilt package | `ProjectChimera.pck` 74,114,524 B (2026-10-20 18:27) | 2026-10-20 | **PASS** — full decision cycle completes (details below) |

**Current status: PASS on the rebuilt package (Part 2).** Part 1 is kept
unchanged as the record of why the earlier package failed.

---

## Part 1 — Original package (2026-10-15 build): **FAIL**

**Target:** `build\windows\ProjectChimera.exe` (109,137,408 B, 2026-10-15 13:26) + `ProjectChimera.pck` (74,085,276 B, 2026-10-15 13:55:45), Godot 4.7.2
**Date:** 2026-10-18

### Overall verdict: FAIL — re-export required

The shipped package **cannot complete even one AI decision cycle**. The cause is
established at three independent layers:

1. **Provenance:** the pck predates the CHI-003 fix by ~26 h (pck 2026-10-15
   13:55 vs commit `95fc102` 2026-10-16 19:12 — verified from git history; only
   `37252fd`/`ebc0481` precede the export).
2. **Bytecode:** parsed the GDPC v4 pack directory (4,318 entries), extracted
   and zstd-decompressed the shipped `request_ai_decision.gdc` and
   `awaiting_ai.gdc`. Their string constants are exactly the **pre-fix** set
   `{build_ai_context, ai_action, action, ai_source, source, unknown}` — the
   post-fix literals `ai_decision_seq` / `ai_decision_epoch` are absent, and the
   packaged gate file has no string constants at all.
3. **Runtime probes:** the live leaves lack the fixed scripts' state members
   (`RequestAIDecision._state == <null>`, `AwaitingAI._synced == <null>`), and
   the blackboard keys (`ai_action`, `ai_source`, `ai_decision_seq`) never
   appear on any NPC over the whole observation window.

Pre-fix defect being shipped (matches `git show 01897ea`): in
`RequestAIDecision.tick()`, the request branch
(`if not _pending: … issue … return RUNNING`) is entered whenever `_pending`
is false. RULE_BASED/LOCAL providers call back synchronously, so `_pending`
is false again on the next tick and the publish block (`blackboard.set_value("ai_action", …) → SUCCESS`)
is **dead code**: the leaf re-issues a request every frame and returns RUNNING
forever. `AwaitingAI` opens the 5 s gate, but the decision pipeline can never
finish, so `ExecuteAction` never runs and no AI action ever changes the world.

---

## Part 1 - Method

**Bridges (both confirmed in the shipped pck):**
- TCP `mcp_bridge.gd` — port **9879**, newline-delimited JSON
  (`{"command": …, "args": …}` → single JSON line). Used: `get_state`,
  `get_time`, `story_choice`, `screenshot`.
- `MCPRuntimeBridge` file IPC — `%APPDATA%\Godot\app_userdata\Project Chimera\mcp_runtime_req.json`
  → `mcp_runtime_res.json` (UI-bridge equivalent of the editor bridge). Used:
  `find_by_script`, `batch_get_properties`, `execute_script`. `execute_script`
  was the workhorse: expressions such as

  ```
  str([get_node("/root/Main/…/NPCs/NPC").npc_id,
       get_node("/root/Main/…/NPCs/NPC").current_room,
       get_node("/root/Main/…/NPCs/NPC").get_node("BehaviorTree")
           .get_blackboard().get_value("ai_action", "MISSING"), …])
  ```
  read NPC state, beehave blackboards, leaf internals
  (`RequestAIDecision._pending/_state`, `AwaitingAI._cooldown/_synced`),
  `AIClient` internals (`get_mode_label()`, `server_online`, `_queue.size()`,
  `_active`, `_requests.size()`), and `EventLog.get_filtered("all"/"ai"/"movement")`.

**Driver:** a throwaway Python script (deleted after use) launched the exe in
the foreground, waited for both bridges, called `story_choice(is_murder=true)`
(retried through the intro), then sampled every ~5–6 s for ~190 s of real time
(≈ 07:15→09:40 game time), capturing 3 screenshots, and killed the game in a
`finally` block (verified no stray `ProjectChimera.exe`).

**Two runs.** Run 1 established the pipeline is inert and left artifacts;
run 2 re-ran the identical cycle with per-NPC identity + leaf-internals probes
and category-filtered EventLog dumps.

---

## Part 1 - Assertion results

### (a) Decision reaches blackboard and changes world state — **FAIL**

- Every blackboard probe for all 6 NPCs (`alex, jordan, sam, riley, morgan,
  casey`) returned the defaults for the whole window:

  ```
  alex:  ['alex','bedroom_1',True ,'MISSING','MISSING',-2]
  jordan:['jordan','bedroom_2',True,'MISSING','MISSING',-2]
  sam:   ['sam','bedroom_3',False,'MISSING','MISSING',-2]   … etc
  ```
  `MISSING` = key absent; `-2` = `ai_decision_seq` absent. Final dump at
  t≈187 s: identical.
- `EventLog.get_filtered("ai")` → `[]` (empty). No
  "…decided to move to…" lines ever appear (that string exists in the shipped
  `npc.gdc`, so only the publishing step is missing — the logger is fine).
- `AIClient` every sample: `["RULE_BASED", false, 0, 0, 0]`
  (mode / server_online / queue / active / HTTPRequests) — provider healthy,
  nothing flowing.
- The only world changes in the window were **schedule** moves (5 lines total
  across both runs: Alex/Riley/Morgan moving at 07:00, Jordan→bathroom 08:00,
  Casey→kitchen 09:00). Those go through `ScheduleBranch`, not AI.

### (b) NPC re-enters eligibility — **FAIL**

- The gate demonstrably runs: `AwaitingAI._cooldown` counts down from 5.0 and
  re-arms (jordan: 4.28 → 3.42 → 2.58 → 1.60 → re-armed 4.98 → …), i.e. the
  AI branch is entered and the gate opens every ~5 s.
- But nothing downstream ever consumes: `ai_decision_seq` never exists, so
  there is no decision to consume and no re-arm cycle. In three NPCs the
  branch actually wedges (see below), freezing the gate mid-cycle
  (alex: `_cooldown` locked at `0.0`; jordan: locked at `0.28352` for >100 s
  after her 08:00 move began).

### (c) No duplicate or lost responses — **NOT DEMONSTRABLE in this binary**

- In RULE_BASED mode callbacks are synchronous, so duplicates leave no
  external trace (`_queue`/`_active` remain 0).
- The packaged (old) leaf's structure itself proves the race is live: the
  request branch fires every tick (`_pending` read `false` in all ~330 leaf
  cross-sections across both runs), and the publish block under it is
  unreachable dead code. That means requests are silently re-issued at frame
  rate — the exact defect 95fc102 fixes with the
  `IDLE/WAITING/READY/CONSUMED/FAILED` state machine + `ai_decision_epoch`
  re-arm.
- Grading honestly: with zero published decisions, "duplicates and lost
  responses" cannot be observed, only inferred from bytecode. Re-validate
  (c) after re-export, where `ai_decision_seq` spacing and
  `AIClient._queue` growth can be measured directly.

### (d) Game stays alive & responsive — **PASS**

- TCP round-trips (<1 s) and IPC probes succeeded across the full window;
  3 screenshots captured per run; the process was killed cleanly afterwards
  (`taskkill /F`, verified gone in `tasklist`). No pipeline-related errors in
  `%APPDATA%\Godot\app_userdata\Project Chimera\logs\godot.log`.

---

## Part 1 - Wedged branches (secondary defect visible through the broken pipeline)

| NPC | Observation |
|---|---|
| alex | `_navigating=true` continuously 07:15→09:35 (move to kitchen never resolves); `AwaitingAI._cooldown` frozen at `0.0` → branch stuck since ~5 s after scene start |
| jordan | schedule move *did* start at 08:00 (“Jordan moving to bathroom”) but `current_room` stayed `bedroom_2` with `_navigating=true` for >100 s; `_cooldown` frozen at `0.28352` |
| casey/sam | gate kept re-arming every ~5 s while never producing a decision; sam never navigates (activity = one long room block) |

Some transitions fire while same-mechanism ones are skipped (alex/riley's
07:30 entries, morgan's 09:00 entry never log) — consistent with Beehave
selector re-entry interacting with an ever-RUNNING AI leaf. All of this is
downstream of the unreachable SUCCESS block; a clean engine build (validated
2026-10-17, run-from-source) shows decisions streaming every interval, so the
package — not the engine logic — is what regressed.

---

## Part 1 - Harness anomalies (do not affect the verdict)

- **File-IPC race:** ~7 % of file-IPC requests returned `{"error": "bad request json"}`
  (atomic-replace vs the bridge's per-frame poll), marked per-probe and
  skipped for that sample; conclusion rests on dozens of clean probes.
- **`batch_get_properties`** returned no rows in the package — bypassed with
  direct `execute_script` expressions (which resolved everything, including
  the auto-renamed NPC nodes `@CharacterBody2D@61…65`).
- **`story_choice` drives `main._on_choice_made` directly**: the INVESTIGATION
  HUD takes over while the StoryScreen overlay stays behind it (cosmetic,
  driver-only).
- **Persisted case data on boot:** the package restores `user://` saves
  (`investigation.json`): 7/15 evidence and 7 discovered clues exist before any
  input — the screenshots show “EVIDENCE 07/15” from the start.
- Unrelated InputMap error: action `"notebook"` doesn't exist (UI polls a
  stale action name) — cosmetic engine error spam, unrelated to AI.
- `get_state.discovered_clues`/`evidence_count` therefore cannot be used as
  fresh-session purity signals for this test; NPC/bridge probes were the basis.

---

## Part 1 - Artifacts

- `driver_summary.json` — run 1 structured dump (blackboards `MISSING`/`-2`,
  final `AIClient ["RULE_BASED",false,0,0,0]`, EventLog totals).
- `run2_log_tail.txt` — packaged game's own log (ends clean; only the
  `notebook` InputMap spam).
- Screenshots — run 1: `01_after_choice.png`, `02_mid_window.png`,
  `03_final_window.png`; run 2: `run2_01_after_choice.png`,
  `run2_02_mid.png`, `run2_03_final.png`. `run2_02_mid.png` shows the live
  game at 8:23 AM (INVESTIGATION HUD, dorm rendered, NPC labels visible).

## Part 1 - Required fix (fulfilled by the 2026-10-20 re-export)

Re-export the pck from a tree containing `95fc102` (and any later
behavior-leaf changes), then re-run this same probe set. After re-export the
expected evidence is: `ai_decision_seq` incrementing per NPC (~1 per 5 s),
blackboards holding `{action, source}`, "ai"-category EventLog lines appearing
per decision, and `AIClient._queue`/`_active` staying at 0 in RULE_BASED —
then assertion (c) becomes directly measurable instead of inferred.

---

## Part 2 — Re-validation on the rebuilt package (2026-10-20): **PASS**

**Target:** `build\windows\ProjectChimera.exe` (109,137,408 B, 2026-10-20 18:23:33) + `ProjectChimera.pck` (74,114,524 B, 2026-10-20 18:27:20), Godot 4.7.2
**Run date:** 2026-10-20

**Verdict: PASS.** The shipped binary now completes a full NPC AI decision
cycle: 4 of 6 NPCs published and consumed decisions, executed AI actions that
changed observable world state, and re-entered eligibility on every cycle.
No duplicate/stacked requests, no gdextension or AI-decision error spam, mode
resolved to RULE_BASED as expected.

### Build provenance (verified before the run)

The pck was re-parsed (GDPC v4, 4,324 entries) and the relevant scripts were
extracted and zstd-decompressed:

| Script in pck | Markers found | Meaning |
|---|---|---|
| `scripts/behavior/request_ai_decision.gdc` | `ai_decision_seq`, `ai_decision_epoch`, `ai_action`, `ai_source`, `build_ai_context` | fixed state-machine leaf **is** in the package |
| `scripts/behavior/awaiting_ai.gdc` | `ai_decision_seq`, `ai_decision_epoch` | fixed gate **is** in the package |
| `scripts/behavior/execute_action.gdc` | `ai_action` | consumer present |
| `autoload/local_ai.gdc` | `nobodywho` | new `LocalAI` autoload shipped |
| `autoload/ai_client.gdc` | `npc/decide`, `nobodywho` | server path + provider script present |
| `autoload/mcp_bridge.gdc` | `story_choice` | bridge present |

NobodyWho entries in the pck: **only the provider script**
(`scripts/ai/nobodywho_provider.gdc` + `.remap`) — no `.gdextension`/DLL,
matching the "loaded on demand" design. `build\windows\addons\nobodywho\` is
empty and `user://models` is empty, so LOCAL cannot be live and the runtime
resolves to **RULE_BASED**.

### Method

Same protocol as Part 1 (previous drivers and workarounds reused):

- Launch the packaged exe in the foreground, wait for the TCP bridge (9879) and
  the file-IPC bridge, then `story_choice(is_murder=true)` — accepted on the
  first call, phase 0 → 1.
- Sample every ~5–9 s for ~300 s of real time (**game time 07:18 → 12:01, Day 1**):
  per-NPC blackboards (`ai_action`, `ai_source`, `ai_decision_seq`), leaf internals
  (`RequestAIDecision._state`, `AwaitingAI._cooldown`), NPC state (`current_room`,
  `_navigating`, `_action_running`, `global_position`), `AIClient` internals,
  `LocalAI` state, and the complete EventLog.
- 3 screenshots; the packaged `godot.log` captured at the end (mtime-checked to
  belong to this run).
- The file-IPC "bad request json" race was worked around with retries (26 of 348
  calls hit it; all recovered).
- Game killed in `finally`; no stray processes; port 9879 free afterwards.

### Per-assertion results

#### (a) A decision is consumed and an action changes observable world state — **PASS**

All evidence from the packaged build:

- 4 of 6 NPCs published decisions with `ai_source = rule_based` and
  `ai_action = {"action":"move","target_room":…}` on the blackboard.
  `ai_decision_seq` is 0-based (the fix publishes `get_value(KEY_SEQ,-1)+1`), so
  the final value N means N+1 decisions:

| NPC | final `ai_decision_seq` | decisions in window | first decision (game time) |
|---|---|---|---|
| sam | 22 | 23 | 07:07 |
| casey | 18 | 19 | 07:07 |
| morgan | 11 | 12 | 09:05 |
| jordan | 4 | 5 | 07:07 |
| alex | key absent (`-2`) | 0 | never (see anomaly 1) |
| riley | key absent (`-2`) | 0 | never (see anomaly 1) |

- 29 AI actions ran to completion (source category `ai`):
  `[07:07] Jordan decided to move to bedroom_1`, `[07:09] Sam decided to move to
  bedroom_1`, `[07:15] Casey decided to move to bedroom_1`, … 29 lines across
  4 NPCs. The remaining decisions were `idle` actions (morgan's blackboard shows
  `{"action":"idle","reason":"schedule fallback"}`) which log nothing by design.
- Observable world-state change (positions and rooms, not just logs):
  - casey: `bedroom_6 → bedroom_1 → bedroom_6 → …` (6 round trips), 793 px of x-travel
  - morgan: `bedroom_5 → bedroom_1 → bedroom_5 → kitchen`, 633 px
  - sam: `bedroom_1 ↔ bedroom_3` (4 round trips), 377 px
  - jordan: 223 px
  - 29 schedule arrivals ("arrived at") interleaved — both the AI path and the
    schedule path executed.

#### (b) The NPC re-enters decision eligibility — **PASS**

- `ai_decision_seq` climbs monotonically for 4 NPCs across the whole window
  (sam 0→22, casey 0→18, morgan 0→11, jordan 0→4): each NPC went round the
  cycle many times, not once.
- The fixed state machine is observed cycling and is never stuck:
  `RequestAIDecision._state` samples = IDLE(0) ×71, READY(2) ×63, CONSUMED(3) ×45.
  (WAITING(1) is sub-frame in RULE_BASED — the provider answers synchronously —
  so a 5 s sampler cannot catch it.)
- The gate re-arms every window: `AwaitingAI._cooldown` took 75 distinct values
  spanning 0.00–5.00 s, and the epoch/seq handshake (`ai_decision_epoch` +
  `ai_decision_seq`) is what re-arms the consumed leaf.

#### (c) No duplicate / stacked requests — **PASS**

- `AIClient` at every one of the 30 samples:
  `["RULE_BASED","RULE", server_online=false, local_available=false, _queue=0,
  _active=0, _requests=0, LocalAI.is_available=false, LocalAI._last_error=""]` —
  nothing queued, nothing in flight, no HTTP request objects.
- Publish spacing (the duplicate detector): the minimum gap between two AI
  publishes for the same NPC was **14 game-minutes**
  (casey 30/30/30/56/14/40/30/30; jordan 22/22; morgan 14/36/28/28;
  sam 24×9/54/16) — **zero** violations of the 5 s gate window and zero
  back-to-back duplicate action starts for the same room.
- `ai_decision_seq` deltas between consecutive samples are only 0, 1 or 2
  (2 = two separate windows elapsed between samples) — never a burst.
- Honest limitation: in RULE_BASED the provider answers synchronously, so
  requests never enter the HTTP queue and no raw request counter is exposed.
  (c) is therefore graded on the observable proxies (publish spacing,
  start/completion pairing, queue depths), not on a direct request count.
  A SERVER-mode run (FastAPI on :8000) would make it directly countable.

#### (d) Game stays alive and responsive — **PASS**

37 TCP commands, 348 file-IPC round-trips, 3 screenshots and 118 new EventLog
lines during the window; the process was killed cleanly and verified gone
(`tasklist`), port 9879 free.

#### (e) Mode is RULE_BASED and there is no gdextension / AI-decision error spam — **PASS**

- Mode probe at every sample: `RULE_BASED` (short label `RULE`),
  `server_online=false` (no FastAPI running), `local_available=false`,
  `LocalAI.is_available()=false`, `LocalAI._last_error=""` (empty — the runtime
  never attempted and failed an extension load).
- The packaged `godot.log` for this run (9 lines, copied verbatim to
  `2026-10-20_rebuild_godot.log`):

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
Vulkan 1.2.170 - Forward+ - Using Device #0: AMD - AMD Radeon (TM) R5 M330

MCPBridge: Listening on port 9879
MCPBridge: Client connected
ERROR: The InputMap action "notebook" doesn't exist. Did you mean "toggle_notebook"?
   at: event_get_action_status (core/input/input_map.cpp:292)
ERROR: The InputMap action "notebook" doesn't exist. Did you mean "toggle_notebook"?
   at: event_get_action_status (core/input/input_map.cpp:292)
```

- **Zero** gdextension / nobodywho / AI-decision error lines (grep for
  "gdextension"/"nobodywho" → 0 hits). The only 2 errors are the pre-existing
  `notebook` InputMap typo, identical to the 2026-10-15 build and unrelated to
  the AI pipeline.

### Anomalies (do not change the verdict)

1. **3 of 6 NPCs never reach the AI branch — navigation wedge (pre-existing, not
   an AI defect).** `alex` and `riley` published no decision at all
   (`ai_decision_seq` key absent), and `morgan` only started at 09:05 game time.
   Diagnosis (dedicated follow-up run): their `ScheduleBranch` is stuck inside
   `MoveToMarker` because `_navigating` never clears. The nav agent is *not*
   broken — it holds a valid path (`path=4..6` points,
   `is_target_reachable=true`) with a next waypoint 12–20 px away, but the body
   does not advance (`alex` position identical at (500,520) across 45 s;
   `riley` at (639,272)). The `CharacterBody2D` is physically blocked, so
   `move_and_slide()` cannot progress → `_navigating` stays true → the root
   selector never reaches the AIBranch → the NPC is never AI-eligible. The nav
   mesh itself is present (20 vertices / 12 polygons). This is a world/collision
   issue, independent of CHI-003, and it explains the identical symptom in the
   2026-10-15 build (Part 1).
2. **The rule-based fallback drags every bedroom-dwelling NPC to `bedroom_1`.**
   `_fallback_action()` maps any schedule goal containing "bedroom" to
   `bedroom_1` regardless of whose bedroom it is, so the AI keeps pulling
   sam/casey/jordan/morgan out of their own rooms and the schedule drags them
   back — 29 "decided to move to bedroom_1" lines and 6 round trips for casey
   alone within 5 game hours. A wart in the fallback (not a pipeline bug), but
   it makes the RULE_BASED simulation churn.
3. **Time-to-bridge-ready grew**: 113 s in the first run of the new build (cold
   shader cache) and 66 s in the next, versus 26–54 s for the 2026-10-15 build.
   Possibly the `LocalAI` autoload or new asset shader compilation — worth
   watching.
4. **The file-IPC race persists** — 26 of 348 calls (7.5 %) returned
   `{"error":"bad request json"}`; retries recovered all but one NPC probe in a
   single sample. Harness-only, same as Part 1.
5. **`EventLog.get_filtered(x)` filters by NPC id, not category** — the first
   probes used `"ai"`/`"movement"` and correctly returned empty (no NPC is named
   that). Categories are stored per entry but not exposed as a filter, so the
   AI-vs-schedule distinction in this report is made on the message text
   ("decided to move to" = AI action, "arrived at" = schedule arrival).
6. `story_choice` again leaves the StoryScreen overlay behind the INVESTIGATION
   HUD (cosmetic, driver-only; unchanged from Part 1).
7. The follow-up "re-target the wedged agent" experiment was aborted by a
   harness bug (a multi-statement `Expression` is invalid in Godot, and each
   retry burned 20 s), so the wedge's recoverability is **untested** — the
   diagnosis above is measurement-based, not a fix.

### Artifacts (Part 2)

- `2026-10-20_rebuild_summary.json` — full structured dump of the run
  (per-sample NPC state, blackboards, leaf states, gate cooldowns, seq history,
  every new EventLog line, log analysis).
- `2026-10-20_rebuild_godot.log` — the packaged game's own log for this run.
- `2026-10-20_rebuild_01_after_choice.png` — INVESTIGATION phase right after the choice.
- `2026-10-20_rebuild_02_mid.png` — mid-window (≈09:5x game time, NPCs mid-move).
- `2026-10-20_rebuild_03_final.png` — end of window (≈12:0x game time).

### Still open (outside this validation)

- The navigation wedge (anomaly 1) is the biggest remaining gameplay defect —
  it silently removes NPCs from the AI loop. It needs its own fix + regression test.
- The `bedroom_1` fallback mapping (anomaly 2) should key off the NPC's own bedroom.
- Assertion (c) would be stronger with a SERVER-mode run so raw request counts
  are visible.
- The `notebook` InputMap typo is a one-line UI-layer fix.
