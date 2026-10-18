# Packaged EXE Gameplay Validation — Full NPC Decision Cycle

**Date:** 2026-10-18
**Target:** shipped package — `build\windows\ProjectChimera.exe` (109,137,408 B, 2026-10-15 13:26) + `ProjectChimera.pck` (74,085,276 B, 2026-10-15 13:55:45), Godot 4.7.2
**Scope:** one full NPC decision cycle inside the packaged binary: AI decision received → validated/published → action executed → observable world-state change → NPC re-enters eligibility → no duplicate responses / no lost responses.
**Constraint honored:** no source modifications; only this doc plus evidence artifacts were written.

---

## Overall verdict: FAIL — re-export required

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

## Method

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

## Assertion results

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

## Wedged branches (secondary defect visible through the broken pipeline)

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

## Harness anomalies (do not affect the verdict)

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

## Artifacts (this folder)

- `driver_summary.json` — run 1 structured dump (blackboards `MISSING`/`-2`,
  final `AIClient ["RULE_BASED",false,0,0,0]`, EventLog totals).
- `run2_log_tail.txt` — packaged game's own log (ends clean; only the
  `notebook` InputMap spam).
- Screenshots — run 1: `01_after_choice.png`, `02_mid_window.png`,
  `03_final_window.png`; run 2: `run2_01_after_choice.png`,
  `run2_02_mid.png`, `run2_03_final.png`. `run2_02_mid.png` shows the live
  game at 8:23 AM (INVESTIGATION HUD, dorm rendered, NPC labels visible).

## Required fix

Re-export the pck from a tree containing `95fc102` (and any later
behavior-leaf changes), then re-run this same probe set. After re-export the
expected evidence is: `ai_decision_seq` incrementing per NPC (~1 per 5 s),
blackboards holding `{action, source}`, "ai"-category EventLog lines appearing
per decision, and `AIClient._queue`/`_active` staying at 0 in RULE_BASED —
then assertion (c) becomes directly measurable instead of inferred.
