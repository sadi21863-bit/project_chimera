# Roadmap Research — DIALOGUE & SOCIAL SYSTEMS (2026-10-18)

Read-only research for the roadmap re-plan. Every current-state claim was verified by reading the
working tree this session and is cited `path:line`. Roadmap demands are quoted verbatim from
`roadmap.txt` (the plain-text extract of the roadmap PDF, `C:\Users\aditya\AppData\Local\Temp\opencode\roadmap.txt`)
with line numbers from that file. Statuses: **DONE** (code-confirmed + tests), **PARTIAL**,
**MISSING**, **NOT-EVIDENCED** (no reproduced proof).

Companion research doc: `docs/roadmap-research/presentation.md`. Verified-facts baseline:
`docs/evidence-baseline-2026-10-16.md` (sections 3-6 set the CHI-002/CHI-003 context this doc
builds on).

---

## 1. CURRENT STATE — the dialogue/social surface today

### 1.1 Two distinct dialogue surfaces exist

**(A) Player-facing conversations** (authored, always offline-safe):

```
NpcInteractable.interact()                    scripts/player/npc_interactable.gd:17-18
  -> main._on_talk_requested(suspect_id)      scenes/main.gd:458-461
  -> DialoguePanel.open (authored intro card) scenes/ui/dialogue_panel.gd:46-58
  -> main._on_dialogue_finished               scenes/main.gd:464-467
  -> InterrogationPanel.open (enhanced)       scenes/main.tscn:49 (UI/InterrogationPanel is an
                                              instance of enhanced_interrogation_panel.tscn)
```

**(B) NPC-to-NPC simulation speech** (LLM-produced, only when AI is on):

```
AIClient.request_decision -> execute_action leaf -> npc.execute_action({"action":"speak",...})
  scenes/npcs/npc.gd:196-207
  -> DialogSystem.show_dialogue(display_name, text)   npc.gd:201 (bubble overlay,
     addons/dialog_system/dialog_system.gd:41-45 — self-contained CanvasLayer, 4 s timeout)
  -> EventLog.log_action('"says to %s"','dialogue')   npc.gd:202
  -> AIClient.record_memory(...)                      npc.gd:203
  -> EventBus "relationship_changed" (+0.05 NPC-NPC)  npc.gd:204-206
  -> LocalMemory.update_relationship (non-SERVER)     autoload/ai_client.gd:367-372
```

Important asymmetry: surface (A) is 100% authored content; surface (B) is 100% AI-generated —
there is **no authored NPC-to-NPC intercom that runs when the LLM is absent** (see the
zero-speak-fallback analysis in 3.3).

### 1.2 How NPCs decide actions (behavior tree + AI modes + rule fallback)

Behavior tree wiring (`scenes/npcs/npc.tscn:45-70`, Beehave):

```
RootSelector
 ├─ ScheduleBranch: ScheduleActive -> MoveToMarker -> IdleAtLocation   (schedule always wins
 │                                                                     while a target differs)
 └─ AIBranch: AwaitingAI -> RequestAIDecision -> ExecuteAction
```

- `ScheduleActive` (`scripts/behavior/schedule_active.gd:5-13`): SUCCESS while
  `schedule_target_room` differs from `current_room` — the scheduled routine pre-empts AI.
- `AwaitingAI` (`scripts/behavior/awaiting_ai.gd`): gate, `DECISION_INTERVAL := 5.0` (:15);
  cooldown restarts at **consumption** via `ai_decision_seq` (:7-11); each opening bumps
  `ai_decision_epoch` (:40), the only re-arm signal for the request leaf.
- `RequestAIDecision` (`scripts/behavior/request_ai_decision.gd`): explicit state machine
  `IDLE -> WAITING -> READY -> CONSUMED (| FAILED)` (:23, :38-80); publishes `ai_action`,
  `ai_source`, bumping `ai_decision_seq` on dark (:103-107). This is the CHI-003 fix — the
  contract is regression-tested in `tests/test_chi002_decision_lifecycle.gd` (455 lines: sync
  callback, deferred callback, bounded server callback <=5 s, exactly-once, invalid response,
  late-duplicate, real `npc.tscn` integration).
- `ExecuteAction` (`scripts/behavior/execute_action.gd:8-26`): publishes to
  `npc.execute_action(action)`, RUNNING while `is_action_running()`.

AI provider routing (`autoload/ai_client.gd`):

- Three modes: `SERVER` (HTTP -> FastAPI -> Ollama, `BASE_URL = http://localhost:8000`, :18),
  `LOCAL` (NobodyWho in-engine GGUF, :30/:45), `RULE_BASED` (always available). AUTO resolves
  SERVER -> LOCAL -> RULE_BASED (:62-69). Health re-probe every 15 s with 3 s bounds (:24-28,
  :96-122) — P1-03 is effectively DONE.
- LOCAL prompt (`ai_client.gd:184-209`): fills a one-line example JSON and asks for exactly one
  object; `{"action":"move|speak|idle|interact"}`. NobodyWho provider script
  (`scripts/ai/nobodywho_provider.gd:73-78`) parses only when the addon is installed — and the
  addon + `models/*` are **excluded from the shipped export**
  (`export_presets.cfg` exclude_filter, evidence-baseline section 9). So a release build can only
  ever run SERVER or RULE_BASED.
- Rule fallback (`ai_client.gd:402-414`) returns **only `move` or `idle`** ("schedule fallback").
  There is no speak fallback — an offline NPC never talks (see 3.3).

### 1.3 Interrogation content and mechanics (the richest dialogue system)

Two data layers, both `const` GDScript dictionaries (no Resources, no external files):

- `InterrogationData` (`scripts/interrogation/interrogation_data.gd`): "Plan B" flat layer —
  7 suspects incl. the dean (:8-112), per-topic `trust_min` and `reveal_clue`, per-clue evidence
  reactions; `respond_to_topic` (:121-129), `respond_to_evidence` (:132-137).
- `EnhancedInterrogationData` ("Plan C", the live layer, `enhanced_interrogation_data.gd`):
  3 styles `DIRECT / EMPATHETIC / CONFRONTATIONAL` (:7-13) with modifier deltas
  (trust/suspicion/resistance, :15-19); branching topics per suspect with per-style `text`,
  `reveal_clue`, `follow_up` unlocks, `trust_min`, `resistance_increase` (:22-418, four
  suspects deep in EID — alex :23-76, jordan :77-130, sam :131-188, riley :189-225, morgan
  :226-262, casey :263-316, dean :317-417); `get_branching_response` (:421-439),
  `get_available_topics` (:446-454).
- `InterrogationData` is still the evidence-presentation layer inside the enhanced panel
  (`enhanced_interrogation_panel.gd:153-158`) and the free-text persona source
  (`main.gd:502`).

Live UI (`scenes/ui/enhanced_interrogation_panel.gd`, instantiated as `UI/InterrogationPanel`,
main.tscn:49):

- Style buttons + style hint (:69-78, :185-191); trust display from `Standing` (:84, :226-247);
  topic buttons show `[GREEN]Ready` / `[LOCKED]Need rapport` by `trust_min` (:90-96); fresh
  follow-up appends `[New line of questioning unlocked]` (:132-134); pressure bar 0-10
  (:146-147, :200-204); clue reveal -> `discover_clue` + Standing +0.05 + EvidenceQuality
  STRONG/TESTIMONIAL (:135-140); confession button visible at standing >= 0.5 (:58-59).
- Older parallel panel `scenes/ui/interrogation_panel.gd` still exists (style row fixed to 3
  constants, :151-155) and is exercised only by `tests/test_interrogation_panel.gd:10`, kept
  alongside the enhanced one; `main.tscn` uses only the enhanced one.
- MCP agent tool `MCPBridge._interrogate` (`autoload/mcp_bridge.gd:247-290`) replays the same
  `get_branching_response` path for automated playtesting.

### 1.4 Evidence presentation — mechanic exists, UI does not

`present_evidence(clue_id)` is implemented in both panels
(`enhanced_interrogation_panel.gd:153-160`, `interrogation_panel.gd:117-123`) and mirrors the
+0.08-standing rule in the scripted playtest (`tools/agentic_playtest.gd:179-191`), **but no live
UI element calls it**: repo-wide, the only references are the two definitions plus the tooling.
Data responses DO exist for every clue (InterrogationData `evidence` maps, e.g.
interrogation_data.gd:17-20, 32-37, 49-53, 63-66, 76-79, 91-94) — the GUI hook is simply missing.

The roadmap playtest scenario explicitly involves this step (section 2, Group F) — "Question,
find clue, present it and re-question the suspect" — so one leg of the acceptance scenario is
currently reachable only by the external agent harness, not by a human player.

### 1.5 Accusation flow (player-facing, end to end)

```
CasePanel -> accuse_requested(sid)          scenes/ui/case_panel.gd:5, 46, 68-69
  -> main._on_accuse_requested              scenes/main.gd:392-396 (read-only preview)
  -> AccusationReveal.open(preview)         scenes/ui/accusation_reveal.gd (summary text :30,
                                            confirm/cancel); wired main.gd:69-70, 414-428
  -> CaseFile.accuse                        autoload/case_file.gd:77-94
       rejected: Standing -0.15 (:82-84)
       accepted:  accused -0.50, friends -0.30 (:89-92), ending "<suspect>_id"
  -> _determine_ending                      case_file.gd:97-117 (truth/partial/cover-up/tabloid
                                            variants by discovery ratio + average standing)
  -> EndingContent                          scripts/case/ending_content.gd:8-92 — 16 endings
                                            (6 special + 3 game-over + 6 wrong-suspect; count
                                            asserted at :127-129)
  -> GameFlow.trigger_ending                main.gd:414-421 (SFX + screen shake + ending screen)
```

Gates: `can_accuse` = quality-weighted strength >= threshold 2 (:59-65);
`accusations_unlocked` requires >=1 clue on EVERY suspect (:68-74). All deterministic and
LLM-independent (P1-05). Confession path: ConfessButton -> `confess_triggered` ->
`Consequences.trigger_sacrifice()` (main.gd:181-182, 568-569) -> SACRIFICE ending.

### 1.6 Relationship models — THREE parallel systems, partially wired

| System | Scale | What feeds it | Who consumes it |
|---|---|---|---|
| `Standing` (autoload/standing.gd:3-4, persist `user://standing.json`) | [-1,1] detective<->NPC | interrogation reveals +0.05 (:137), style deltas (:143-145), evidence +0.08 (:156-158), accusation fallout (case_file.gd:82-92), eavesdrop -0.05 (crestwood_hall.gd:136-137), caught trespassing -0.2 (crestwood_hall.gd:92) | interrogation gating (topic `trust_min`, confess >= 0.5), endings |
| `NPCRelationships` (autoload/npc_relationships.gd:5-13, `NPC_IDS` incl. dean :11) | 0..1 trust/suspicion/cooperation | `adjust_resistance` from Confrontational style paths (panel :141-142), MCP bridge (:267-274) | **nothing gameplay-critical**: shown in NPCRelationshipPanel (:46-61) + debug panel; `is_willing_to_talk`/`will_reveal_information`/`get_resistance_modifier` (:95-111) have test callers only |
| `LocalMemory._relationships` (`autoload/local_memory.gd:15-23`, seeds :15-23, :73-78) | [-1,1] NPC<->NPC pairs | NPC `speak` actions +0.05 (npc.gd:204-206, via EventBus) | LLM context + observer relationship graph (`ai_client.gd:349-364`, `scenes/ui/relationship_graph.gd:3`) |

So the player-visible "relationship" surface is mostly the interrogation trust display +
accusation preview; the trust/suspicion/cooperation system and NPC-NPC scores are simulation
furniture that never gate a conversation.

### 1.7 Event log as narrative surface

`EventLog` (`autoload/event_log.gd:7-22`): 200-entry ring; categories in active use —
`system/movement/ai/dialogue/interrogation/overheard/witness/case/caught/injection/error`.
Feeds back into NPC AI as `recent_events` = last 5 filtered entries (`npc.gd:169`), i.e. the
log doubles as NPC short-term memory input. The observer panel renders it
(`observer_panel.gd` head comment: "Observer dashboard: speed, event log, injection,
relationships, NPC info"). No player-accessible archive UI beyond the observer (scrollable, dev
oriented).

### 1.8 Authored social content outside interrogation

- **Gossip/eavesdropping** (`scripts/interrogation/gossip_data.gd:7-68`): 10 authored 3-line
  conversations, each `reveal_clue`; fired when both speakers are within pair_range and the
  detective within hear_range (`scenes/eavesdrop_watcher.gd:5-22`), played through
  `DialogSystem` bubbles sequentially + `[Overheard]` log lines, standing -0.05 both speakers
  (`crestwood_hall.gd:118-147`).
- **Suspicion moments** (`scripts/interrogation/suspicion_data.gd:7-30`): 11 scheduled creepy
  behaviors; caught ones log "You witnessed: ..." and reveal clues (`crestwood_hall.gd:100-116`).
- **Search flavor** (`scripts/interrogation/search_data.gd:8+`): multi-action examination with
  `flavor` text + `reveal_clue` + risk hints.
- **Dialogue card openers** (`dialogue_panel.gd:31-39`): one authored line per suspect.
- **Endings/cinematics**: ending bodies in `ending_content.gd`; quit/sacrifice/walk-away flows
  via `Consequences`.

### 1.9 University NPC content (the dean)

`scenes/locations/university.gd:3-5,42-57`: lore-only NPC — no schedule, always in office,
secrets list for AI context, EID + InterrogationData topics (:96-111 / :317-417 include the
double-life, Crestwood family, cover-up, two-ID threads — the university-side mystery);
explicitly **not** in `CaseData.SUSPECTS` (test asserts `test_university_npc.gd:31-33`).
Also a *standalone dean conversation UI* exists in the old interrogation panel flows
(`interrogation_data.gd:96-111`).

### 1.10 Tutorial

`autoload/tutorial.gd:16-47` — 10 one-time hints keyed to progress triggers, persisted
(`user://tutorial.json`), incl. `interrogation_styles` (:41-43) and `standing` (:44-46), fired by
`on_interrogation_started()` (main.gd:466). Regression-tested by `tests/test_tutorial.gd:53-55`.

### 1.11 Localization / authoring surface

- **None.** No `.csv`/`.po`/`translation` resources exist anywhere in `godot/` (glob returned
  zero files). Every string lives in `const` dictionaries inside GDScript. Godot's
  internationalization is unused.
- Third-party addons are an accepted risk here: the real "Locker" addon was **never adopted** —
  `addons/locker/save_manager.gd` is a hand-written API-compatible stub
  (HANDOFF.md:400-403, 512-513), though it is still autoloaded/registered
  (`project.godot:39, 68`). The `dialog_system` addon in-tree (:38) is a trivial self-written
  bubble, not a downloaded plugin. NobodyWho is excluded from the shipped export
  (evidence-baseline section 9). Net precedent: the repo keeps script-level dependencies tiny
  and in-house.

### 1.12 Tests as behavior documentation

- `tests/test_chi002_decision_lifecycle.gd` — the decision contract (see 1.2).
- `tests/test_enhanced_interrogation.gd:15-70` — style buttons, pressure bar, pressure-up on
  topic and free text, branching response presence, style modifier, follow-up unlock.
- `tests/test_interrogation_wiring.gd:14-30` — talk -> dialogue card -> interrogation;
  high-trust topic reveals clue; free text never leaves an empty response.
- `tests/test_npc_relationships.gd` — trust/suspicion/clamp/summary/hostile-grade behavior of
  NPCRelationships (panel-shaped; no gameplay consumer asserted).
- `tests/test_accuse.gd:13-37`, `tests/test_accusations.gd`, `tests/test_case_flow.gd`,
  `tests/test_case_strength.gd`, `tests/test_flow_wiring.gd:20-32` — accusation gates,
  standing fallout, reveal-then-confirm flow, ending resolution.
- `tests/test_full_playthrough.gd:60-98` — end-to-end: interrogation reveal via high trust ->
  accusations unlock -> correct/accident resolution.
- `tests/test_university_npc.gd` — dean spawn/talk area/lore-only status.

---

## 2. ROADMAP DEMANDS — verbatim, with status

Quotes are from `roadmap.txt` (line refs in that file).

### Group A — decision/simulation foundation (P0)

- "Fix NPC decision execution and prove a full game loop." (:7); "A player can launch the tagged
  build with no AI server, finish a case without a softlock, and observe six NPCs making valid,
  applied decisions. The same result must be reproducible with a scripted harness." (:22-23) —
  **DONE** (CHI-003; test_chi002 integration check; harness = agentic_playtest/MCP).
- P0-01 contract + exit gate (:108-124) — **DONE** (explicit lifecycle, exactly-once, bounded;
  test file exists and is described as the regression guard).
- P0-02: "'thinking'/safe-idle behavior that cannot interrupt or overwrite an in-flight request"
  (:128); "Check AI branch precedence against schedules" (:129) — **DONE for precedence**
  (ScheduleBranch is first in RootSelector, npc.tscn:48-70; awaiting gate cannot lose a decision
  since cooldown restarts at consumption); **PARTIAL for counters** — "Add counters: requested,
  completed, timed out, applied, dropped, fallback and average latency per provider" (:130) —
  no counters exist in `ai_client.gd` or anywhere else. **MISSING**.

### Group B — trustworthy simulation (P1 section 05, "make simulation trustworthy")

- P1-01: "Authoritative action gate: define a typed/validated action schema; room, actor,
  target, availability and distance checks must pass inside Godot" (:194-197) — **PARTIAL**:
  `move` validates the room marker (`npc.gd:129-131` logs `error` on unknown room) but `speak`
  has no target validation (`npc.gd:196-206` — `_find_npc` null just labels the name
  `target_id`), no distance checks, no occupancy; CHI-007 "Implement authoritative action
  validation and object reservations if needed" (:462-464) — **MISSING** (P1-02 reservations,
  no-op).
- P1-04: "Memory quality: assign stable event IDs, write durable consequences once, sample
  routine actions, add retention/recall caps. No duplicate key facts; relevant events rank above
  routine 'walked to kitchen' noise." (:211-214) — **PARTIAL**: cap exists
  (`LocalMemory.MAX_PER_NPC := 200`, local_memory.gd:8,41-43) and keyword+recency recall
  (:46-70); CHI-009 "Deduplicate/pin semantic memories by event ID; cap routine events" (:469-472)
  — **MISSING**: no stable event IDs, no dedupe, every move memoralized verbatim (npc.gd:195).
- P1-05: "Deterministic case core: keep clue unlock, accusation eligibility, endings, and save
  state rules engine-owned." (:216-217) with acceptance "Offline play and AI-on play can both
  complete the same authored mystery." (:218-219) — **DONE** (CaseFile gates are
  Investigation-derived; endings deterministic; rule-mode full playthrough test green).
- Architecture principle: "The LLM proposes intent; the game validates and executes it. NPC
  personality may vary, but time, objects, facts, clues and consequences remain canonical in
  game state." (:226-227) — **PARTIAL** (proposes/executes yes; validation thin).

### Group C — design lock (section 07) — the dialogue/social "experience" contract

- "Understandable: the first 5-10 minutes teach movement, examination, notebook and
  interrogation without a wall of text." (:272-273) — **PARTIAL** (hint system exists and is
  tested; but the interrogation-style hint text is wrong — see finding 3.5 — and the tutorial
  hints are a stick of prose, not interactive).
- "Fair: ... the player can reason toward accusations; essential clues are never lost to AI
  randomness." (:274-275) — **DONE** (all 15 clues obtainable through authored examinables /
  gossip / interrogation; accusation requires >=1 clue per suspect).
- "Responsive: examinations, feedback and menus communicate clearly; long AI processing never
  blocks basic movement." (:276-277) — **PARTIAL** (decisions are async; no AI wait blocks the
  player; but interrogation free text can silently return machine-ish strings — 3.4).
- "Consequential: accusations and endings reflect evidence strength and decisions, including
  failure or uncertainty." (:278-279) — **DONE** (quality-weighted strength, wrong-accusation
  standing fallout, 16 endings, accepted evidence-reviewed preview screen).
- "Atmospheric: the archival cutaway art, sound and UI reinforce one identity across all
  rooms." (:279-280) — **NOT-EVIDENCED** for dialogue prose tone (no style guide exists for
  dialogue voice).
- "Role of autonomous AI: Optional flavor and believable behavior; never the sole path to a
  required clue." (:286-287) — **DONE** structurally (all clue sources are authored), with the
  caveat of the free-text path quirk (3.4).
- "Narrative branching: A small number of highly readable outcomes rather than many thinly
  authored endings." (:288-289) — **DONE** (16 authored, all currently reachable; the count
  matches "small" only loosely; each is ~3 sentences — genuinely authored, not procedural).

### Group D — manual playtest matrix (section 08)

- "Interrogation / clue loop — Question, find clue, present it and re-question the suspect. /
  Responses, trust, notebook and case strength update coherently." (:317-321) — **PARTIAL**:
  question/find/re-question works (follow-up unlocks + re-ask); **"present it" is not reachable
  by a human player** (1.4); trust updates standing (yes); notebook/case updates
  (notebook shows discovered clues; case strength gates). NOT-EVIDENCED as a real human session.
- "Wrong accusation — Accuse with incomplete/contradictory evidence. Consequences are explicit
  and save state remains valid." (:322-324) — **DONE mechanically** (standing -0.15, explicit
  reveal screen text, save tests cover resolved/accused_state) — human-run not-evidenced
  (evidence-baseline (b): full gameplay never validated inside the packaged exe).

### Group E — polish/plumbing that names dialogue directly

- "Check presentation pacing: interrogation entry, accusation confirmation, loading fades and
  ending timing." (:359) — **PARTIAL**: interrogation entry got the asset-pass flow
  (authored dialogue card -> interrogation, main.gd:458-467 + test_interrogation_wiring);
  accusation confirmation got the reveal screen; **ends/flashback timing and pacing constants
  are untouched**; no measured pacing at all.
- M4 milestone scope: "Tutorial, UI, scene clarity, lighting, dialogue/audio consistency."
  (:407) — the only place the word "dialogue" appears as a deliverable. **MISSING/UNSTARTED**:
  there is no dialogue audio (only SFX stings `interrogation_start`/`accusation_reveal`,
  sfx_helper.gd:49, 73-74), no text presentation standard (no typewriter, no line pacing),
  no consistency pass over the ~500 authored dialogue strings.
- M3 exit: "Every clue, interrogation, accusation, save/load and ending pathway. Scripted paths
  green; manual first-run path reaches an ending." (:401-405) — **NOT-EVIDENCED** (scripted
  paths are green; no recorded manual first-run).

### Group F — guardrails and release constraints that bind dialogue design

- "Keep the narrative critical path deterministic / Do not do yet: ... Require an LLM to make
  clues or endings possible" (:42-46) — binding rule for any new branching dialogue.
- "The Python/Ollama/ChromaDB and NobodyWho providers remain optional; core narrative
  progression must work without them." (:583-585)
- Risk table: "LLM-dependent progression -> Deterministic evidence gates and rule-based
  fallback completion tests." (:552-556)
- Release checklist: "AI modes are correctly presented as optional: no missing GGUF weights in
  a standard release" (:538-539).
- Assignment contract for the first task: "Do not: add new UI, change narrative data, alter
  asset pack..." (:512-513) — i.e., the roadmap deliberately defers dialogue-content work until
  the P0/P1 gates pass.

### Group G — internal plan not in the roadmap PDF (context: `godot/EXPANSION_PLAN.md`)

- "#### 4.1 NPC Relationship Graph — Track relationships between NPCs (not just detective-NPC);
  NPCs can warn each other about the detective; Relationships affect what they say in
  interrogation; Visual relationship graph in notebook" (:188-192) — partially built
  (NPC-NPC scores exist; **"relationships affect interrogation" NOT implemented**; graph lives
  in the observer, not the notebook).
- "11. Branching interrogation paths" (:260, unchecked) — mostly done via EID styles.
- "4.4 Environmental Storytelling — Ambient dialogue between NPCs" (:207) — partial (eavesdrop
  conversations exist but fire once each, scripted).

---

## 3. GAP ANALYSIS — demands vs state

### 3.1 What is genuinely missing (player-visible dialogue/social gaps)

| # | Gap | Evidence | Cost |
|---|---|---|---|
| G1 | **Present-evidence is unreachable by a human.** The mechanic (data + standing rule) is built and playtested via harness; no button/step exists in the panel. Roadmap scenario leg "present it"(:319) fails for a person. | 1.4 | **S** |
| G2 | **NPCRelationshipPanel is a dead UI.** It listens for an input action literally named `"notebook"` which does not exist in the input map (`project.godot` defines `toggle_notebook` among others; grep shows zero `is_action_pressed("notebook")` elsewhere); its own header comment promises "Press R" with no R binding. `main.gd:22` instantiates it but never opens it. | npc_relationship_panel.gd:4,29-31; project.godot:109-137 | **S** |
| G3 | **Free-text interrogation is only an authored deflection offline, and machine-flavored text when AI is on.** DETAILS in 3.4. | main.gd:499-511 | **S-M** |
| G4 | **Offline案件中 NPC 从不说话。** RULE_BASED fallback emits only move/idle (`ai_client.gd:402-414`); no authored `speak` fallback exists, so in a release build (SERVER down, LOCAL excluded) the dorm is mute and the "living world" promise rests entirely on eavesdrop/gossip one-shots. Roadmap "NPC routines make the world feel alive" (:270) is offline-degraded. | 1.2 + 1.8 | **M** |
| G5 | **Tutorial advertises 4 questioning styles; the system implements 3.** `tutorial.gd:41-43` lists "Direct / Indirect / Confrontational / Sympathetic"; `EnhancedInterrogationData.Style` has only DIRECT/EMPATHETIC/CONFRONTATIONAL. New players receive wrong instructions in the very screen the roadmap pillar (:272-273) promises to teach. | 1.10 + 1.3 | **S** |
| G6 | **No authored NPC-to-NPC ambient dialogue beyond 10 once-per-run gossip scenes**; once fired, pairs never speak again. Roadmap/EXPANSION ambient-dialogue intent (:207) is one-shot. | gossip_data.gd (10 entries) | **M** |
| G7 | **Relationships do not affect interrogation** (EXPANSION 4.1 promise) — EID gates on `Standing` only; `NPCRelationships.is_willing_to_talk/will_reveal_information/get_resistance_modifier` are never called by gameplay. | 1.6 | **M** |
| G8 | **No dialogue audio or text-presentation standard** (M4 "dialogue/audio consistency", :407). Bubbles are 4 s timed labels; no typewriter, no read-time support, no VO hooks. | 1.11 | **M** |
| G9 | **No localization infrastructure.** All strings are in GDScript consts; Godot i18n unused. Any localization desire is a rewrite of ~600 strings across 8+ data files. | 1.11 | **L** |
| G10 | **Action validation (P1-01/CHI-007) thin** — speak actions (including LLM free-text style answers) hit the world unvalidated. | 1.2/2-Group B | **M** |
| G11 | **Decision counters/diagnostics absent** (roadmap P0-02 counters + CHI-006 JSON trace for "Tester can explain any NPC action"). Dialogue-attribution questions ("why did Sam say that?") are unanswerable in-game. | :130, :459-461 | **M** |

### 3.2 The three-mode constraint — the decisive design filter

Roadmap demands offline completion (:22-23, :583-585) and the release build ships with LOCAL and
GGUF excluded (evidence-baseline section 9). Therefore every dialogue/social feature must be
gradable in each mode:

| Feature | SERVER | LOCAL (dev-only) | RULE_BASED (release default) |
|---|---|---|---|
| Interrogation topics/styles/present-evidence/gossip/suspicion | authored data — identical | identical | identical (DONE) |
| Dialogue card + confession + accusation endings | authored | authored | authored (DONE) |
| NPC `speak` actions | LLM text | LLM text | **nothing (G4)** |
| Free-text answers | (see 3.4 bug) | model JSON `text` (unreliable on 1B models) | single deflection line (G3) |
| NPC-NPC relationship drift | Python GM owns (`ai_client.gd:367-372`) | LocalMemory | LocalMemory |

The current authored layer already satisfies "critical path deterministic"; the gaps (G3, G4,
G6) are all in the *flavor* layer — exactly where the roadmap brands AI as "optional flavor"
(:286-287). Conclusion: build the flavor layer **authored-first** and let LLM modes substitute
or enrich, never gate.

### 3.3 G4 mechanics — why offline NPCs are mute

`npc.execute_action` speaks only for `action == "speak"` (npc.gd:196-207). A decision reach it
via three sources: (1) SERVER JSON; (2) LOCAL model JSON; (3) `_fallback_action`
(`ai_client.gd:402-414`) which structurally **cannot** return `"speak"`. The local prompt
examples only show `"move"` (`ai_client.gd:200`), so even with a live 1B model, speech is
rare. Net: the `DialogSystem` bubble path is effectively unreachable in release builds. Any
"speak" fallback must come from authored barks, not from more prompt engineering — which also
keeps G4 passable in all modes by construction.

### 3.4 G3 mechanics — the free-text path has two concrete defects

`main.gd:499-511`:
1. **SERVER mode is never used for free text.** The guard is
   `AIClient.use_ai and resolve_mode() != RULE_BASED`, then it calls
   `AIClient._local_decide(...)` directly — a private path that always routes to the
   NobodyWho provider, bypassing the FastAPI server that resolve_mode() just reported as
   active. A player typing into the interrogation box while `AI: SERVER` is shown gets
   bottom-tier LOCAL behavior or nothing.
2. **Fallback leakage as dialogue.** If the local provider is busy/unavailable, `_local_decide`
   resolves the callback with `{"action":"idle","reason":"schedule fallback"}`; main then shows
   `action.get("text", action.get("reason",""))` (main.gd:506-508) — the suspect literally says
   **"schedule fallback"**. Also seen whenever the UX falls between AI on + local not ready.
   This is a player-visible string leak, and it contradicts "Responsive ... communicate clearly"
   (:276-277).

Offline (release) is the *safe* case today (authored deflection, main.gd:511), but a transient
mode flip mid-interrogation (health probe every 15 s flips SERVER<->RULE_BASED) can strand the
player mid-conversation.

### 3.5 Authoring-approach evaluation for THIS repo

The question for the next layer of dialogue (post-interrogation: relationship-gated lines,
ambient barks, maybe evidence-sequenced conversations) — custom data-driven resources vs
Ink/Yarn via addons.

**Option A — keep the current pattern (const GDScript dictionaries), extend it.**
- Precedent is strong: InterrogationData/EID/Gossip/Suspicion/Search/EndingContent/DialoguePanel
  are all this. Tests already assert on them headlessly (the runner green box is 71/71,
  evidence-baseline section 8).
- Pros: zero new deps; parse-time type errors surface in the test harness; works headless and
  offline trivially; mode-agnostic by construction; matches the Locker lesson (the repo
  stubs external addons instead of adopting them).
- Cons: not designer-friendly (no tree preview); follow_up/branch graphs get hand-rolled
  (EID's `follow_up` chain is already at the edge of what flat dicts express cleanly —
  `enhanced_interrogation_data.gd:28-40: follow_up: "the_keys"`); localization impossible
  without a rewrite.
- Fit: **highest for next 2-3 slices**.

**Option B — Godot custom Resources (`.tres` DialogueLine/DialogueChoice/DialogueGate) with a
small runner script.**
- Pros: editor UI for authoring (Inspector), built-in resource validation, still zero addons,
  still headless-testable (`ResourceLoader` in tests), keeps the Locker/NobodyWho precedent
  (no third-party at runtime).
- Cons: migration cost for existing EID content or dual-maintenance during transition;
  read-time/UI presentation still hand-built.
- Fit: **the medium-term target** if dialogue volume grows (relationship-gated lines, rematch
  conversations).

**Option C — third-party narrative runtime (Ink via godot-ink / Yarn Spinner / DialogueManager).**
- Weighed against this repo's demonstrated tradeoffs:
  - The repo **rejected** the real Locker addon (kept an API-shaped stub instead,
    HANDOFF.md:512-513) — evidence the project prefers owning thin infrastructure.
  - The repo **excludes** its other heavyweight addon (NobodyWho) from the release binary
    (evidence-baseline section 9) — a shipped dev-feature pattern. A dialogue runtime cannot be
    excluded this way: it must ship in every build.
  - Ink/Yarn force content into an external export/compiler step that bypasses the existing
    test surface; the 71-test headless harness would need an interpreter harness to cover it.
  - Weight/size and license-audit cost lands in the release checklist the roadmap already
    constrains (:543).
- Pros: real branching grammar (weave/conditional line alternation), author-ergonomic,
  localization tooling exists in some runtimes.
- Fit: **poor now**; revisit only if the branching scope in section 5's open questions expands
  beyond "small number of readable outcomes" (:288-289). If it ever happens, DialogueManager
  (pure GDScript, MIT) is the least-bad candidate; Ink+C# is the worst fit for a GDScript-only
  test suite.

**Recommended: Option A now (this cycle), Option B as a contained refactor once authored
  volume grows** — i.e., start by giving EID topics a `label` field and a per-suspect
  `styleHints` map (kills the duplicated label dictionaries at
  enhanced_interrogation_panel.gd:103-121), then introduce a `DialogueLineResource` only if the
  ambient-bark system (3.5/G4) proves out.

### 3.6 Dependency ordering

Any new dialogue surface sits **behind** the roadmap's own gate: "an NPC receives, validates,
executes and changes world state..." (evidence-baseline section 10(c)) — satisfied at HEAD per
test_chi002 test 8. Presentation research doc (`docs/roadmap-research/presentation.md`) owns the
read-hability/typewriter side; this doc defers text presentation to it (avoids duplicate work).

---

## 4. PROPOSAL — prioritized plan

Effort: **S** <= half day, **M** 1-3 days, **L** > 3 days. Each item lists dependencies and
acceptance criteria (behavior assertions, not absence-of-crash).

### Wave 1 — the first 3 things to build (all unblock roadmap matrix rows)

**D1. Wire present-evidence into the interrogation UI (G1) — S.**
- Do: in `enhanced_interrogation_panel.tscn/gd`, add an `EvidenceRow` HBox listing
  *discovered* clues that `CaseData.clues_for_suspect(suspect)` implicates; one-shot per clue
  (disable after use); calls the existing `present_evidence(clue_id)`; mirrors +=1 pressure;
  log via InterrogationData evidence map.
- Depends: nothing (data + method already exist).
- Acceptance (extend `test_interrogation_wiring.gd` or new `test_present_evidence_ui.gd`):
  open riley with `clue_pills` discovered -> Present button enabled -> on press,
  `respond_to_evidence` text renders, Standing +0.08 exactly once, button disabled after;
  a clue that does not implicate the suspect shows the deflection text with no standing change;
  works with `AIClient.use_ai = false` (offline path identical).

**D2. Repair the free-text interrogation path (G3) — S.**
- Do: route through the public `AIClient.request_decision()` (mode-aware) instead of the
  private `_local_decide`; add an authored per-suspect fallback map (`unknown_answer` per
  persona in InterrogationData) used when source == rule_based or the action carries no `text`;
  clamp: never render `reason` strings in the interrogation response.
- Depends: none. Independent of AI modes.
- Acceptance: regression test asserting (a) `AI: SERVER` + typed text -> decision request shows
  SERVER source (use FakeProvider-style stub as in test_chi002), (b) with
  `use_ai = false` the authored per-persona deflection appears, (c) the string
  `"schedule fallback"` never reaches the panel's `show_response()` / `$Panel/VBox/Response`
  label in any provider outcome
  (the exact junit-style leak guard for the `action.reason` hole at main.gd:506-508).

**D3. Authored offline NPC speech — schedule-aware barks (G4 + part of G6) — M.**
- Do: add `BARKS := {npc_id: {activity: [lines...]}}` (or per-activity generic barks) to a new
  `scripts/interrogation/bark_data.gd` following the InterrogationData house pattern; extend
  `_fallback_action` contract at the module boundary (not inside AIClient): when RULE_BASED
  selects a speak-capable context (a co-located NPC pair is available; gating data comes from
  existing eavesdrop/suspicion neighbor checks, never from the LLM), return
  `{"action":"speak","target_npc":...,"text":<bark>,"reason":"ambient"}`
  with a small cooldown so pairs don't loop. Co-locator: pair selected from `nearby_npcs`
  already in context (npc.gd:152-173).
- Depends: D1/D2 not required; ship after P1 counters/diagnostics or together.
- Acceptance: 10-min accelerated 6-NPC offline soak (reuse the roadmap's own exit-gate pattern
  from P0-02 :131-132) shows >= N authored bubbles in `DialogSystem`/EventLog "dialogue"
  category, zero repeats of the same line within M minutes, EventLog unchanged else; memory cap
  still holds (`LocalMemory.MAX_PER_NPC`). Mode matrix: SERVER unchanged, LOCAL unchanged,
  offline now speaks. (This is literally roadmap-satisfying for :270 "NPC routines make the
  world feel alive" offline.)

### Wave 2 — fidelity and consistency (roadmap Group E polish + misleads)

**D4. Fix the tutorial style mismatch (G5) — S.**
- Align tutorial.gd:41-43 to the three shipped styles (or add a fourth EID style and re-perf
  test). Prefer text change; keep test_tutorial green.

**D5. Counters + decision diagnostics overlay for explainability (P0-02 counters, CHI-006) — M.**
- Increment the counters inside `AIClient.request_decision`/`_deliver_fallback`/:`_send_decide_request`
  (requested/completed/timeout/dropped/fallback per provider-source), surface in the observer
  panel; approval test = a scripted run where a malformed response increments `dropped` and
  `fallback` and the overlay explains one NPC action's source per UI coordinates.

**D6. Relationship-gated interrogation flavor (G7) — M.**
- Minimum viable: consume `NPCRelationships.get_resistance_modifier(...)` inside
  `EnhancedInterrogationData.get_branching_response` (additive `trust_min` modifier) plus a
  per-suspect "cold" replacement line when `is_willing_to_talk` is false (data-owned, all
  three modes).
- Acceptance: test where the same topic yields a different line/extra resistance under
  high-suspicion vs base with everything else constant; offline.

**D7. NPCRelationshipPanel rebinding (G2) — S.**
- Bind to a real action (new input action `toggle_relationships`, or fold into an existing
  panel's tab); remove the dead `"notebook"` listener; assert open/close in a UI wiring test
  (pattern: `test_ui_node_paths.gd` style).

**D8. Presentation pacing pass for dialogue (Group E) — with presentation.md owner — M.**
- Interrogation entry/accuse confirm/loading fade/ending timing constants in one place; defer
  typewriter/read-time to `presentation.md`; test = scripted capture of wall-time deltas.

### Wave 3 — content and later-system decisions (opinionated, gated)

**D9. Extend ambient social sim: second-run gossip + NPC warn-each-other (G6, EXPANSION 4.1) — M.**
Only after Wave 1 lands.

**D10. Validate speak actions at the author of execute (P1-01/CHI-007 for the speak leg) — M.**
`speak` requires a `target_npc` that exists and is within a distance budget; reject to FALLBACK
log with reason (pairs with CHI-006 trace).

**D11. Authoring migration to a .tres resource layer or external runtime — L, blocked on the
scope answer to Open Question 2.**

**D12. Localization infrastructure — L, blocked on Open Question 3.**

### Explicitly NOT doing now (roadmap discipline)

- No new interrogation data content before the playtest matrix (Groups D) is human-run: the
  roadmap's own "Do not do yet" list (:36-46) and the CHI-010 offline playtest (:474-477) come
  first.
- No new locations/NPCs ahead of a complete reviewed case (:293-294).

---

## 5. OPEN QUESTIONS for the user

1. **Voice/tone standard.** All ~500 authored strings are in one dry-wry detective register.
   Is there a target voice bible (per-NPC vocabulary quirks?), or should a style guide be
   authored before Wave 3 content lands?
2. **Branching scope.** Roadmap :288-289 says "small number of highly readable outcomes". Does
   that stay binding after M3, or is deep player-authored branching (e.g., accuse-path
   cross-examination) desired? This decides Option A/B/C in 3.5.
3. **Localization.** English-only for release? If any other language is even plausible, it is
   far cheaper to introduce `tr()` + const->CSV extraction **during** Wave 2 refactors than
   after (G9/L).
4. **The 4th interrogation style.** The tutorial promises Indirect/Sympathetic (4 styles);
   code ships 3. Which is canonical — change the tutorial or add the styles?
5. **NPC social visibility in release builds.** Should offline NPC-to-NPC speech be barked
   text (D3) only, or should release builds ALSO be allowed a small local LLM path someday
   (undoing the `models/*` exclusion)? That is a release drama decision, not a code one.
6. **Prompt/track discrepancy.** This research track described the game as "a 3D first-person
   Godot 4.7 university-life deduction game", but the repo and the roadmap itself define the
   game as a 2D isometric dorm mystery (`project.godot:18` "Isometric dorm simulation with 6
   autonomous NPCs"; roadmap section 14, roadmap.txt:583 "The game remains a 2D isometric
   Godot detective mystery"). Confirm which descriptor the next milestone should treat as
   canonical; if a 3D first-person remake is on the table, that invalidates several roadmap
   assumptions beyond dialogue and deserves its own research doc.

---

## 6. SURPRISING FINDINGS (shortlist)

1. **Present-evidence exists, works, is tested — and cannot be triggered by any human input**
   (only the agent harness calls it). A full roadmap playtest scenario leg (:319) is
   person-unreachable. (`enhanced_interrogation_panel.gd:153` has zero live callers.)
2. **The relationship panel is a keyboard dead UI** — it listens for an input action named
   `"notebook"` that does not exist in the input map (`project.godot` defines
   `toggle_notebook`, not `notebook`), and its comment claims an "R" key even less implemented.
   (`npc_relationship_panel.gd:4,29-31` vs `project.godot:129-137`.)
3. **The free-text interrogation path never uses SERVER mode** (calls the private
   `_local_decide` even when AUTO reports SERVER, `main.gd:501-503`) and can leak
   the literal string **"schedule fallback"** as a suspect's spoken line through the
   `action.reason` fallback hole (`main.gd:506-508` + `ai_client.gd:402-414`).
4. **A release build ships a mute dorm.** Because the export excludes NobodyWho + weights, and
   the rule fallback returns only move/idle, zero NPC speech is producible without a dev
   AI server (`ai_client.gd:402-414`). The "six NPCs making valid, applied decisions"
   acceptance (:22-23) is silent on whether *moving* islands count.
5. **The tutorial lies about the mechanics** — 4 styles promised in the interrogation hint,
   3 shipped (`tutorial.gd:41-43` vs `enhanced_interrogation_data.gd:7-13`).
6. **Three relationship models** with different scales ship side by side; exactly one
   (Standing) gates anything player-visible. `NPCRelationships.is_willing_to_talk`,
   `will_reveal_information`, `get_resistance_modifier` (`npc_relationships.gd:95-111`)
   have zero gameplay callers — tests pass on them while the systems remain decorative.

---

## Appendix — 10-line executive summary

1. Player-facing conversation today = authored dialogue card -> 3-style branching interrogation
   (trust-gated topics, follow-up chains, evidence reactions) -> accusation on a reveal screen;
   ALL authored and fully offline-safe — the roadmap's deterministic-core rule is already met.
2. That contract is regression-tested end to end (71/71 suite, CHI-002 decision lifecycle,
   full playthrough, accusation, enhanced interrogation tests).
3. The social sim NPC reads are one-sided: NPC `speak` actions are LLM-only; the offline rule
   fallback can only move/idle, so a shipped release build is a dorm of mute NPCs.
4. Free-text interrogation: offline gets one authored deflection line; ONLINE has two concrete
   defects — SERVER mode bypassed in favor of the private LOCAL path, and "schedule fallback"
   can render as dialogue.
5. Two dead player-facing UIs: present-evidence (implemented + tested, no UI trigger) and the
   NPC relationship panel (bound to a non-existent `"notebook"` input action).
6. Relationships exist in three independent scales (Standing / NPCRelationships /
   LocalMemory pairs); only Standing gates conversation content.
7. Tutorial promises 4 questioning styles, code ships 3 — a first-timer-facing lie in the
   exact loop the roadmap's "Understandable" pillar names.
8. Authoring tech is 8 hand-rolled const-GDScript dictionaries; zero localization or dialogue
   audio; deliberate small-dependency precedent (Locker stub, NobodyWho excluded from release)
   argues for extending in-house data, not adopting Ink/Yarn now.
9. Top 3 builds: (D1) present-evidence UI strip, (D2) free-text mode-correct repair + fallback
   speech guarantee, (D3) authored offline barks so offline NPCs speak — all S-to-M and each
   unblocks a named roadmap matrix line.
10. Blocker to resolve in conversation, not code: scope decisions on branching/localization/
   voice (Open Questions 1-5) plus the prompt-vs-repo "3D first-person vs 2D isometric"
   discrepancy (Open Question 6).
