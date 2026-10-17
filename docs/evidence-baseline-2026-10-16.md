# Evidence Baseline — 2026-10-16

## 1. Purpose and scope

This document is the in-repo point of record for Project Chimera's verified facts, replacing the
roadmap PDF (`C:\Users\aditya\Downloads\Project_Chimera_Next_Steps_Roadmap.pdf`) for that purpose:
the PDF sits outside the repository and is effectively read-only for us, so anything we confirm —
or later disconfirm — about it must live here instead. It records the trajectory from commit
`483251c` (the state the roadmap PDF was written against) through `95fc102` (current HEAD as of
2026-10-16), and codifies the P0 defect reproduction (CHI-002), its fix (CHI-003), the rebuilt test
harness, the native Windows export, and the items deliberately still open. It is not a plan or a
requirements document; the roadmap's non-code-confirmed items (art, dialogue, presentation) remain
tracked there. Every claim below is tagged:

- **[git]** — verified this session with read-only git commands (`git log --oneline -8`,
  `git show --stat <sha>`, `git branch -a`, `git status --porcelain`, commit-content diffs).
- **[worktree]** — verified by reading the current working-tree file, or the published release
  object (GitHub API), within this session.
- **[recorded]** — recorded from the 2026-10-16 working session (probe outputs, run tallies,
  suspension-state measurements) and not reproducible offline; these are quoted where stated.

Cross-checks behind the commit claims: the four SHAs all resolve on `main` [git]; HEAD =
`95fc102` [git]; tag `v0.2.0-archival-cutaway` exists [git]; release assets for that tag checked
via the GitHub API for `sadi21863-bit/project_chimera` [worktree].

## 2. Baseline and commit chain

Verified with `git log --oneline -8` and `git show --stat <sha>` [git]:

| Commit | Date | Subject |
|---|---|---|
| `483251c` | 2026-10-11 | `feat: Archival Cutaway visual redesign + continuous outdoor world` |
| `37252fd` | 2026-10-15 | `chore: native Windows export preset + visual QA rebaseline` |
| `ebc0481` | 2026-10-15 | `docs: document observer panel mode-label defect (not fixing yet)` |
| `95fc102` | 2026-10-16 | `fix: AI decision pipeline inert (CHI-003) + real test runner` (current HEAD) |

- `483251c` is the state the roadmap PDF was written against. It is the Archival Cutaway visual
  redesign plus the persistent outdoor world, and the release tag `v0.2.0-archival-cutaway`
  (created 2026-10-11, `target_commitish: main`) is published against that-generation content
  [git; release metadata verified via API].
- `37252fd` added the native Windows export preset, gitignored `build/`, and rebaselined all ten
  visual QA shots against the Archival Cutaway look (gate run 10/10 PASS at 0.000% change,
  per the commit message) [git].
- `ebc0481` documents the observer panel mode-label defect — recorded as known-but-not-yet-fixed —
  and its message also corrects an earlier misdiagnosis: HANDOFF.md was never encoding-corrupted
  (see section 11) [git].
- `95fc102` implements the CHI-002 reproduction and the CHI-003 fix, rebuilds the test runner, and
  un-hangs `test_tutorial.gd`; it touches `ai_client.gd` (100 lines), `awaiting_ai.gd` (31),
  `request_ai_decision.gd` (112), `test_all.gd` (118), adds
  `test_chi002_decision_lifecycle.gd` (455) and `test_tutorial.gd` (100) [git].

**Resolved repo risk — stale branch `clean-main`.** Deleted remote and local during the
2026-10-15 session after re-verifying immediately before the delete that it was 4 commits behind
`main` and `ahead_by=0` — it held nothing unique, so nothing was lost [recorded]. Today the state
is directly verifiable: `git branch -a` lists only `main` and `origin/main` (plus
`origin/HEAD -> origin/main`) [git].

**Follow-ups after this baseline table.** Two commits land on 2026-10-16 after `95fc102` and are
deliberately not SHAd here to avoid self-reference — `git log` is authoritative: one commits the
remaining untracked test files plus the missing `.uid` sidecars (section 10b), one fixes the
observer top-bar AI label (section 10a) together with this document.

## 3. CHI-002 — the reproduced P0 defect (evidence)

`request_ai_decision.gd` used a single `_pending` boolean for BOTH "not requested yet" and
"response completed" [git: commit message of `95fc102`; reproduced and confirmed in source during
the session]. The callback cleared it the moment a response landed, so the tick after a completed
callback re-entered the request branch, wiped `_result`, issued a duplicate request and returned
RUNNING. The SUCCESS block — the only place the blackboard key `ai_action` is ever published —
was therefore unreachable.

Consequence: NPC AI was completely inert, NOT merely degraded, because the rule-based fallback
flows through the same leaf [git: commit message]. Whatever the provider answered — server, local
model, or rule fallback — nothing ever left the leaf a second time.

The leaf is live code wired in `godot/scenes/npcs/npc.tscn` [worktree, verified this session]:

```
BehaviorTree/RootSelector            npc.tscn:45
BehaviorTree/RootSelector/AIBranch   npc.tscn:60
  AwaitingAI           npc.tscn:63
  RequestAIDecision    npc.tscn:66
  ExecuteAction        npc.tscn:69
```

Two further confirmed findings, both later fixed in `95fc102`:

- `awaiting_ai.gd` armed `_cooldown = DECISION_INTERVAL` (5.0 s, `awaiting_ai.gd:15`) at
  gate-open instead of at decision consumption — the interval was spent before the provider had
  answered [worktree: the fixed file's own header comment records the old behavior].
- `ai_client.gd:40` called `_check_health()` exactly once in `_ready()` with no periodic re-probe;
  a server started later was never discovered and one that died stayed latched [git: the `95fc102`
  diff removes the single call and replaces it with a 15 s `Timer`].

## 4. Defect #2 — found during CHI-002, not in the roadmap

`AIClient` set no `HTTPRequest.timeout` and discarded `request()`'s return code [git: `95fc102`
commit message; the diff shows the un-honored `req.request(...)` return]. On an unreachable
backend, `request()` returns OK and `request_completed` only ever fires on timeout — so `_active`
pinned at 1 and no callback was ever delivered. A server dying after boot wedged every NPC
decision permanently, with no fallback and no retry exit.

Probe evidence, recorded during the 2026-10-16 session [recorded; quoted verbatim — the
nothing-listening state can no longer be reconstructed]:

- A raw `HTTPRequest` to `http://localhost:8000/npc/decide` returned **0** from `request()` and
  `request_completed` fired at **3.00 s** with **result=13 (RESULT_TIMEOUT)**.
- A raw TCP connect to `127.0.0.1:8000` measured **"refused" after 2287 ms** — connection refusal
  alone is slow on this machine, so any retry ladder overruns the 5 s acceptance bound.
- Nothing was listening on port 8000 at probe time (`Get-NetTCPConnection` returned empty).

## 5. CHI-002 test suite

`godot/tests/test_chi002_decision_lifecycle.gd` (455 lines, committed in `95fc102` [git]);
**30 checks** in the committed version, **28 pre-fix**; **RED 14/28 failures before the fix**,
GREEN after [recorded: HANDOFF.md 2026-10-16 entry and the `95fc102` commit message state the
same counts]. Coverage areas:

- Rule-based sync callback.
- Local instant callback.
- Local deferred callback.
- Server async bounded <= 5 s.
- Exactly-once: no duplicate request while waiting or after consumption.
- Invalid/empty response resolves instead of hanging RUNNING.
- Late duplicate callback cannot overwrite a settled decision.
- Real `npc.tscn` branch integration: `BehaviorTree` processing disabled immediately via
  `set_process(false)` (`test_chi002_decision_lifecycle.gd:410` [worktree]), gate cooldown zeroed
  manually, asserted via `npc.is_action_running()` and the `EventLog.entries` delta as observable
  world state (lines 431/446–447 [worktree]).

## 6. CHI-003 — the fix (commit 95fc102)

`request_ai_decision.gd` [git + worktree: `State` enum at :23, header at :7]:

- Explicit **IDLE -> WAITING -> READY -> CONSUMED (| FAILED)** state machine (single `_state`
  field, no shared boolean).
- Publication deliberately deferred to the next tick, so "request issued" reports RUNNING exactly
  once even when the callback is synchronous (`request_ai_decision.gd:54` [worktree], recorded in
  the commit message [git]).
- Late/duplicate deliveries are ignored once settled ("ticks that follow a consumed decision can
  never fire a second request", :30 [worktree]).
- `CONSUMED` re-arms only when `AwaitingAI` bumps `ai_decision_epoch` (keys
  `ai_decision_seq`/`ai_decision_epoch`, `request_ai_decision.gd:28,31` [worktree]).

`awaiting_ai.gd`: restarts its cooldown at the **consumption** boundary via `ai_decision_seq`, not
at gate-open [worktree: `awaiting_ai.gd:8` records the old behavior; `:15-17` define
`DECISION_INTERVAL := 5.0` and the two blackboard keys].

`ai_client.gd` [git diff verified; constants re-read in the working tree]:

- `DECIDE_TIMEOUT_SECONDS := 3.0` (`ai_client.gd:24` [worktree]) — hard bound on a single
  `/npc/decide` HTTP call; without it a request that is accepted but never answered keeps `_active`
  pinned forever and the queue freezes.
- `request()`'s return code honored synchronously: `err != OK` releases the request and delivers
  the rule-based fallback immediately [git: `_send_decide_request` in the diff].
- Unreachable results (`CANT_RESOLVE` / `CANT_CONNECT` / `CONNECTION_ERROR` / `TIMEOUT` /
  `TLS_HANDSHAKE_ERROR`, `_is_unreachable` in the diff [git]) short-circuit straight to the
  rule-based fallback with **NO retries** — retrying an absent backend only froze NPCs, because
  connection refusal alone measures ~2.3 s on this machine and any retry ladder overruns the 5 s
  acceptance bound (probe evidence in section 4). The retry ladder is retained only for reachable
  backends that fail with a real response error (`_retry_or_fallback` [git]).
- `_retry_counts` is now cleared on terminal delivery (`_deliver_fallback` [git]); previously one
  exhausted chain poisoned every later decision for that NPC.
- Health re-probe every 15 s (`HEALTH_INTERVAL_SECONDS := 15.0` [git, in the diff]) with
  `HEALTH_TIMEOUT_SECONDS := 3.0` (`ai_client.gd:27` [worktree]), an in-flight guard
  `_health_busy` (`ai_client.gd:41` [worktree]), and synchronous-error handling so the guard
  cannot wedge — a synchronous `request()` failure resolves the probe immediately, since
  `request_completed` will never fire [git: comment + code in the diff].
- `get_mode_label()` now lives at `ai_client.gd:77` and `resolve_mode()` at `ai_client.gd:62`
  [worktree]. (HANDOFF and `ebc0481` cite `:59`; the `95fc102` insertions shifted the line number
  with no behavior change.)

## 7. Test harness

The OLD `godot/tests/test_all.gd` counted `script.new()` inside `_initialize()`, which never
executes under `--script` — so its reported "15/15" proved only that 15 files PARSE; zero
assertions ever ran under it [git: `95fc102` commit message]. (Not even the release page escaped
this: the `v0.2.0-archival-cutaway` release notes claim "test_all 15/15" at that commit — that run
was parse-only [worktree: verified release body]. The ~66 pre-existing tests it nominally covered
now actually execute since `95fc102`.)

The NEW runner [git: `test_all.gd | 118 +++++` in `95fc102`]:

- Discovers `test_*.gd` files.
- Spawns each in its own Godot process via `OS.execute` and uses the **exit code** as truth.
- Prints the first `FAIL:` / `SCRIPT ERROR` lines for triage.
- Supports `-- --filter=<substring>` and `-- --shard=k/n`; sharding exists to keep one invocation
  short, because there is no hard per-test timeout (`OS.execute` blocks), so each test must
  enforce its own deadline.

**First version of the rebuild self-recursed**: discovery matched the runner itself
(`test_all.gd` starts with `test_`) and re-executed the whole suite from inside itself —
**114 runaway Godot processes** before being caught. Discovery now skips `test_all.gd`
[git: commit message]. [recorded: process count from the live session.]

`test_tutorial.gd` was a permanent hang. Two-layer root cause [git: commit message; fixes show as
`test_tutorial.gd | 100 +++++` new file]:

1. `preload()` of `res://autoload/tutorial.gd` at COMPILE time resolved before autoload
   identifiers were registered (SFXHelper is an autoload, declared in `project.godot`), producing
   "Identifier not found" — which made the test script itself fail to compile, so `.new()` threw.
2. Because `_phase` was set to 1 BEFORE the throwing line, the next frame fell through to
   `return false` and `quit()` was never reached — the process ran forever.

Fixed with a runtime `load()`, null guards, and an 8 s deadline guard so any future throw still
terminates [git].

## 8. Current verification status (2026-10-16)

- **71 test files executed, 71/71 green** [recorded] — re-run AFTER the observer label fix, so it
  covers the final state of both follow-up commits. On-disk cross-check: 72 `test_*.gd` files
  exist, of which one is the runner itself (`test_all.gd`, excluded by discovery) — 71 executed
  [worktree]. Run as three shards: **24 + 24 + 23** [recorded].
- **CHI-002 suite: 30 checks / 0 failures** [recorded] on top of a RED 14/28 pre-fix run (section 5).
- **Observer top-bar label suite: 27 checks / 0 failures** [recorded]
  (`godot/tests/test_observer_topbar_label.gd`): per-mode token mapping, no "AI OFF" in any mode,
  pause state preserved, and a 1280x720 layout assert with the longest token active (every TopBar
  child inside the bar, no overlaps, speed slider not crushed).
- **Visual QA gate re-verified after CHI-003: 10/10 PASS at 0.000% drift, exit 0** [recorded] —
  no baselines were refreshed; a single orchestrator run.
- **Real game scene headless boot** (`--quit-after 420`) exits 0 with **zero script errors**
  [recorded]. The only warning is the known benign one: missing
  `res://addons/nobodywho/nobodywho.gdextension` (unused local-LLM addon; its weights are
  deliberately excluded from the shipped build, section 9).

## 9. Native Windows export (commit 37252fd)

- Preset verified in `godot/export_presets.cfg` [worktree]: **Windows Desktop, x86_64**,
  `exclude_filter="tools/*, tests/*, qa/*, addons/nobodywho/*, models/*"`, export path
  `../build/windows/ProjectChimera.exe`. `build/` is gitignored (`37252fd`, `.gitignore | 4 +++`
  [git]).
- Build artifacts verified on disk [worktree]: `build/windows/ProjectChimera.exe`
  **109,137,408 bytes (104.1 MB)** and `ProjectChimera.pck` **74,085,276 bytes (70.7 MB)**,
  both dated 2026-10-15.
- Release assets verified via the GitHub API for tag `v0.2.0-archival-cutaway` [worktree]:
  - `project-chimera-windows-x64.zip` — **103,391,637 bytes (98.6 MB; quoted as 99 MB)**,
    added 2026-10-15 — the native build.
  - `project-chimera-playable.zip` — **284,617,354 bytes (271.5 MB; quoted as 271 MB)**,
    added 2026-10-11 — run-from-source fallback.

**Two separate facts, deliberately kept apart:**

- (a) The released `ProjectChimera.exe` was **BOOT-VERIFIED standalone** — launched and produced
  zero script errors [git: `37252fd` commit message "Exported and verified: ProjectChimera.exe
  boots standalone with no script errors"; recorded in HANDOFF 2026-10-15].
- (b) **Full gameplay was NOT validated inside the exe.** No end-to-end play, interrogation, or
  accusation flow has been exercised in the packaged binary.
- (c) The engine remains externally exercised end-to-end via the run-from-source path
  (headless boot green at HEAD, section 8) — evidence about the *engine* is strong; evidence about
  the *packaged export* stops at the boot check. Do not treat (a) as covering (b).

**Accepted limitation — LOCAL model inference unavailable in the release.** The export excludes
`models/*` (the 3.1 GB `.gguf` weights) [worktree: exclude filter verified], so the shipped build
can only run **SERVER or RULE_BASED** AI; LOCAL inference is unavailable in the release [follows
from the filter + the mode fallback ordering]. This is effectively forced by archive size and is
recorded as an accepted limitation pending a product decision.

## 10. Still open

**(a) Observer panel mode-label defect — FIXED on 2026-10-16** (was documented as known-but-not-
fixed in commit `ebc0481` [git]; the defect as it existed: `godot/scenes/ui/observer_panel.gd:73`
was `var ai_text := "AI ON" if AIClient.server_online else "AI OFF"`, keying the top bar off
server reachability instead of `resolve_mode()`, so LOCAL and RULE_BASED both rendered as
"AI OFF" and the player could not tell "local model works fine" from "degraded to rules").

The fix, committed together with this document:

- New `AIClient.get_mode_short_label()` returns the compact token — `SERVER` / `LOCAL` / `RULE`
  (`get_mode_label()` still returns the full `RULE_BASED` for logs).
- `_update_status()` now renders `RUNNING | AI: <mode> | 1.0x`.
- Short tokens were chosen over full labels because `TopBar` is an `HBoxContainer` at 1280x720:
  the abbreviated worst case (`RUNNING | AI: SERVER | 1.0x`, 25 chars) stays near the old width
  (23 chars), while the full form (31 chars) is +35%.
- Covered by `godot/tests/test_observer_topbar_label.gd` — 27 checks (section 8), including the
  TopBar fit/overlap/slider-width layout assert with the longest token active.

**(b) Untracked test files — RESOLVED on 2026-10-16.** The brief said ~7; the verified count was
**9 untracked `.gd` test files** plus **17 untracked `.uid` sidecars** under `godot/tests/`
[git: `git status --porcelain godot/tests`]. The `.gd` files — `test_effects.gd`,
`test_enhanced_interrogation.gd`, `test_evidence_quality.gd`, `test_music_manager.gd`,
`test_new_dorm_scenes.gd`, `test_npc_relationships.gd`, `test_particles.gd`,
`test_scheduled_events.gd`, `test_sfx.gd` — were verified individually (7 of 9 run one-by-one,
all PASS exit 0; all 9 exercised again in the 71/71 suite, section 8) and committed together with
the 17 `.uid` sidecars, 8 of which belong to already-tracked tests whose sidecars were missing
(fresh clones could not parse them). Committed in the untracked-test follow-up commit named in
section 2.

**(c) Non-code-confirmed roadmap items remain unstarted by design** (art, dialogue, presentation).
The acceptance criterion gating them: an NPC receives, validates, executes and changes world
state, then becomes eligible again with no duplicate requests and no lost responses. The CHI-002
`npc.tscn` branch integration check (test 8, section 5) now covers exactly this, so the gate can
be evaluated mechanically rather than by eyeball.

## 11. Environment lessons that cost time

(Recorded so nobody re-derives them; the first one is independently corroborated by commit
`ebc0481`'s message [git], the others are session-recorded [recorded].)

- **Windows console is code page 850** and renders Unicode (em-dash, arrows, degrees) as garbage.
  Validate bytes with a strict UTF-8 decode before claiming file corruption: a previous session
  reported HANDOFF.md as encoding-corrupted (mojibake `?` in the title), which was wrong — the
  bytes decode clean and the git blob renders correctly; the "damage" was cp850 console output.
  The retraction is recorded in the `ebc0481` commit message. The same encoding class is visible
  in the `v0.2.0-archival-cutaway` release notes as served by the GitHub API (an em-dash stored
  as mojibake in the body); which write path produced that was not investigated.
- **PowerShell 5.1 `Set-Content -Encoding utf8` writes a BOM** that polluted a commit subject.
  Use `[IO.File]::WriteAllText(path, text, [Text.UTF8Encoding]::new($false))` for commit-message
  files.
- **Detached `Start-Process` children die when the parent tool call is interrupted** — run long
  jobs in the foreground or shard them (the test harness sharding exists partly for this), and
  always check a log's mtime before trusting its contents.
