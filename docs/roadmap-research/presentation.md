# Presentation Track Research — Project Chimera (audio, VFX, UI polish, game feel)

**Date:** 2026-10-18. **Mode:** read-only research. No Godot run, no source edits.
**Inputs:** roadmap extract (`C:\Users\aditya\AppData\Local\Temp\opencode\roadmap.txt`,
extracted from the 15 Oct 2026 roadmap PDF), working-tree sources under `godot/`,
`docs/evidence-baseline-2026-10-16.md`. Every claim below was verified by reading the cited
file this session. Line numbers refer to the working tree at HEAD (`95fc102` + the two
2026-10-16 follow-up commits recorded in the evidence baseline).

**A note on framing:** the research brief described the game as "3D first-person"; the
codebase and roadmap both say otherwise. `godot/project.godot:18` —
`config/description="Isometric dorm simulation with 6 autonomous NPCs"` — and the roadmap
p.15 states "The game remains a 2D isometric Godot detective mystery" (S14, assumptions).
Everything here is written against the 2D isometric reality; the mismatch is reported in
section 5 (surprising findings / open questions).

---

## 1. CURRENT STATE — the presentation surface today

### 1.1 Renderer, window, and global presentation config

| Fact | Evidence |
|---|---|
| Godot 4.7, **Forward Plus** renderer | `godot/project.godot:20` (`config/features=PackedStringArray("4.7", "Forward Plus")`) |
| Fixed design resolution 1280x720, `canvas_items` stretch | `godot/project.godot:54-56` |
| Global custom theme: `res://resources/theme/detective_theme.tres` | `godot/project.godot:76` |
| **Nearest-neighbor** default texture filter (crisp pixels, no smoothing) | `godot/project.godot:152` (`textures/canvas_textures/default_texture_filter=0`) |
| Blender import disabled at project level | `godot/project.godot:72` |
| Input map: WASD pan/move, E interact, F talk, Tab mode, C case, M map, N notebook, B board, debug toggle | `godot/project.godot:78-143` |
| 26 autoloads incl. `MusicManager` (:35), `Effects` (:43), `SFXHelper` (:44), `Tutorial` (:41) | `godot/project.godot:23-50` |

Forward Plus is the heaviest of Godot's three renderers and requires Vulkan; the target
machine (AMD A9-9420 2-core, Radeon R5 M330 2GB, 7.5GB RAM —
`docs/evidence-baseline-2026-10-16.md` is the point of record for the machine class the
roadmap's "target low-end hardware" phrase refers to) is exactly the class where a
renderer switch to Mobile or Compatibility is the standard safety valve. This is a
decision point, not a measured defect — see section 3 and section 5.

### 1.2 Theme / typography

- `godot/resources/theme/detective_theme.tres` defines flat styleboxes: dark teal panels
  (`bg_color Color(0.03,0.07,0.09,0.94)`, `:72`), amber borders
  (`border_color Color(0.85,0.6,0.3,0.9)`, `:13`), a parchment "emphasis" popup style
  (`:88-93`), warm off-white label color (`Color(0.93,0.9,0.81,1)`, `:109`) with a text
  shadow (`:110-112`).
- **No custom font is loaded anywhere** — the theme sets only `default_font_size = 14`
  (`detective_theme.tres:100`). All "archival typography" is currently the engine default
  font. A generator script exists (`godot/tools/build_ui_theme.gd`) that prints a note to
  set the theme by hand (`:65`).
- NPC name labels are plain `Label`s with the default theme and `font_size = 12`,
  created with placeholder text `"NPC"` in the scene (`godot/scenes/npcs/npc.tscn:26-33`)
  and overwritten at runtime with the display name (`godot/scenes/npcs/npc.gd:57`).
  The detective sprite has no label at all (`godot/scenes/player/detective.tscn:13-20`).

### 1.3 Audio

**Architecture.** Three layers, all verified live:

1. **MusicManager autoload** (`godot/autoload/music_manager.gd`) — centralized music +
   ambience + SFX playback. On `_ready` it creates three buses if missing — Music, SFX,
   Ambience, each `set_bus_send(..., "Master")`, no bus effects added anywhere
   (`music_manager.gd:103-118`). It builds:
   - one `AudioStreamPlayer` for music (bus Music, default volume -6 dB, `:59-63`),
   - one for ambience (bus Ambience, -12 dB, `:65-69`),
   - a **pool of 4 `AudioStreamPlayer`s** for SFX (bus SFX, `:71-76`); `play_sfx`
     grabs a free player, else steals player 0 (`:323-332`).
   It connects to `Scheduler.time_changed` (:82-83), `LocationManager.location_changing`
   (:84-85), and `GameFlow.phase_changed` (:86-87), and pre-sets the startup location's
   ambience (`:89-92`).

2. **Procedural generation.** All music and most ambience is generated at runtime:
   `_make_pad_stream()` synthesizes sine-harmonic pads (22,050 Hz, mono, 16-bit,
   loop-forward) (`music_manager.gd:125-153`); five mood pads exist (dawn/day/dusk/
   night/ending, `:156-177`) plus server/hospital/bar ambience builders
   (`:180-192`). The mood is chosen by an hour-of-day map (`HOUR_MOOD`, `:29-36`) and
   overruled by GameFlow: ENDING phase forces the "ending" pad, CHOICE phase forces
   "dawn" (`:288-296`).
   - **One real audio asset is wired:** `ambient_dorm.ogg` is loaded for the
     "ambience_dorm" key when it exists (`:215-225`); every other ambience key falls
     back to a generated pad.
   - Crossfade is a 2.0 s tween down to -40 dB, swap stream, then up
     (`CROSSFADE_SECONDS := 2.0` at `:13`; `_crossfade_to` at `:246-255`).
   - Volume API: `set_music_volume` / `set_ambience_volume` + signals
     (`:303-320`). **There is no SFX-volume API.**

3. **SFXHelper autoload** (`godot/scripts/audio/sfx_helper.gd`) — thin convenience over
   `ProceduralSFX` (`godot/scripts/audio/procedural_sfx.gd`) + MusicManager. Eight
   categories (`sfx_helper.gd:9-16`): CLUE_FOUND, INTERROGATION_START,
   PRESSURE_INCREASE, SUSPICION, TRAVEL, SEARCH, ACCUSE, ENDING. Named helpers set
   per-category volumes (e.g. `accuse()` at +3 dB `:69-70`, `ending()` at -2 dB `:78-79`,
   `suspicion()` at -3 dB `:57-58`). The generator caches one `AudioStreamWAV` per
   category (`procedural_sfx.gd:21,24-26,82`).

**Where SFX actually fires (verified call sites):**

| Moment | Call | Evidence |
|---|---|---|
| Travel between locations (outdoor or interior) | `SFXHelper.travel()` | `godot/scenes/main.gd:119,135` |
| Accusation confirmed | `SFXHelper.accuse()` | `main.gd:415` |
| Ending triggered | `SFXHelper.ending()` | `main.gd:420` |
| Search action selected | `SFXHelper.search()` | `godot/scenes/ui/search_panel.gd:51` |
| Tutorial hint appears | `SFXHelper.search()` | `godot/autoload/tutorial.gd:116` |
| Clue toast appears | `SFXHelper.clue_found()` | `godot/scenes/ui/clue_toast.gd:29` |
| Interrogation opens | `SFXHelper.interrogation_start()` | `godot/scenes/ui/interrogation_panel.gd:42`; `godot/scenes/ui/dialogue_panel.gd:58`; `godot/scenes/ui/enhanced_interrogation_panel.gd:50` |
| Interrogation pressure step | `SFXHelper.pressure_increase()` | `enhanced_interrogation_panel.gd:148` |
| Suspicion gossip / interrogation start (in-world) | `SFXHelper.suspicion()` / `.interrogation_start()` | `godot/scenes/dorm/crestwood_hall.gd:129,141` |
| Accusation-reveal panel opens | `SFXHelper.accusation_reveal()` | `godot/scripts/ui/accusation_reveal.gd:44` |

**NPC footsteps (the only positional / asset-based SFX).** `AudioStreamPlayer2D` at
-8 dB, `max_distance = 600` (`godot/scenes/npcs/npc.tscn:72-74`). Per-room surface
variants — kitchen/bathroom=ceramic, hallway/common_room=linoleum, else carpet
(`npc.gd:7-13`) — with pitch randomization 0.92-1.08 every 0.4 s while walking
(`npc.gd:98-114`). All 9 ogg variants exist on disk
(`godot/assets/audio/footstep_{ceramic,linoleum,carpet}_{00,01,02}.ogg`); a Kenney CC0
license file sits alongside (`godot/assets/audio/LICENSE_kenney_rpg_audio.txt`).
The **player detective has no footstep sound** (`detective.tscn` has no audio node).

**Dead audio assets.** The "Chimera Audio Pass" delivered three more loops —
`ambient_dorm_loop.wav`, `ambient_server_loop.wav`, `ambient_outdoor_loop.wav`
(`godot/assets/audio/README_CHIMERA_AUDIO_PASS.md:3-7`, all on disk) — but a repo-wide
grep finds them referenced only by that README. MusicManager's ambience map keys
("ambience_outside", "ambience_server", `music_manager.gad:228-231`) still use generated
pads instead. The pass is half-wired.

**A silent cinematic.** The opening cinematic's script contains two explicit `{"type":
"sfx"}` steps — "thud" and "scream" (`godot/scenes/ui/opening_cinematic.gd:45,47`) —
but `_play_sfx()` only triggers visual reactions (tween shake for thud, dim-flash for
scream, `:161-182`). **No audio stream is ever played for them.** The death moment of
the intro is silent.

**Settings & persistence.** The settings screen offers difficulty presets plus Music and
Ambience dB sliders (`godot/scenes/ui/settings_screen.gd:24-53,81-102`) wired to
MusicManager's volume API. Gaps: **no SFX slider** (the SFX bus has no user-facing
control), and **no persistence** — a repo-wide grep finds `ConfigFile` only inside
addons/tools; all saved state under `user://` is game state (tutorial.json,
standing.json, etc.), never audio. Volumes reset to -6/-12 dB every launch.

**Dead script:** `godot/scripts/audio/sfx_data.gd` is a curated SFX catalogue (rich
envelopes, e.g. CLUE_FOUND C5->C6 sweep, `sfx_data.gd:29-43`) with a class_name
`SFXData`, but nothing calls it — `ProceduralSFX.generate()` reads its **own embedded,
different-parameter dict** (`procedural_sfx.gd:10-19`; e.g. its CLUE_FOUND is 880 Hz
0.4 s, not the C5 sweep). The two catalogues have drifted apart. `SFXData` is dead code
with a maintained twin.

### 1.4 VFX / game feel (juice)

**Effects autoload** (`godot/autoload/effects.gd`) is a complete, shader-free,
tween-driven juice library. Everything renders as `ColorRect`s on a dedicated canvas —
deliberately cheap (good for the R5 M330):

| Effect | Behavior | Evidence |
|---|---|---|
| `shake(intensity, duration)` + presets `shake_dramatic()` (8.0, 0.4) / `shake_subtle()` (2.0, 0.1) | random camera offset, decays linearly, applied in `_process` via `camera.offset` | `effects.gd:45-58,231-242` |
| `flash(color, duration)` | 1280x720 ColorRect, alpha tween to 0 | `effects.gd:60-71` |
| `fade_out / fade_in / fade_transition` | persistent black overlay ColorRect (z 200), tween alpha; `fade_transition` wraps a callback (e.g. scene travel) | `effects.gd:75-110` |
| `spawn_particles(pos, color, count=8)` | tweened 4x4 ColorRects burst | `effects.gd:117-132` |
| `sparkle(pos)` (12), `dust(pos)` (10), `glow(pos)` (pulsing ring 3 s), `trail(a,b)` (8 steps), `burst(pos, count=16)` (+shake 3.0) | same technique | `effects.gd:134-229` |
| `show_vignette / hide_vignette` | black ColorRect, z 150 | `effects.gd:252-282` |
| `freeze(duration)` | `Engine.time_scale = 0.0` then restore | `effects.gd:286-289` |

The particles live on `ParticleCanvas` (CanvasLayer layer 100, mouse-ignore, registered
back into Effects) instantiated at `Main/UI/ParticleCanvas` (`godot/scenes/ui/particle_canvas.gd:7-14`;
`godot/scenes/main.tscn:67`; Effects falls back to searching that path, `effects.gd:24-31`).

**No shaders exist in the project** — a glob for `*.gdshader` returns nothing. No
GPUParticles/CPUParticles nodes, no WorldEnvironment, no post-processing. All "VFX" is
the ColorRect library above plus `CanvasModulate`.

**Where Effects is wired today (all 17 call sites):** travel fades (`main.gd:65`,
`main.gd:263`, `godot/scenes/dorm/bedroom.gd:132`), accusation (`main.gd:416` shake
dramatic + `accusation_reveal.gd:45` shake subtle), clue discovered (`main.gd:454-455`
shake subtle + blue flash; `clue_toast.gd:31` screen-center sparkle; `search_panel.gd:59`
shake subtle), search panel open (`main.gd:473` glow on detective), search action dust
(`search_panel.gd:65`), interrogation vignette show/hide (`interrogation_panel.gd:43,58`;
`enhanced_interrogation_panel.gd:51,65`), HUD clock events (flash on event
`godot/scenes/ui/hud_clock.gd:68`; shake dramatic on deadline warning `:75`).

**Camera behavior.** Two `Camera2D` exist per session: the detective's own
(`godot/scenes/player/detective.tscn:29-30`, made current in PLAY mode via
`detective.gd:55-60`) and a free-fly scene camera for OBSERVER mode, panned at 300 px/s
(`main.gd:28,271-282`). Wheel zoom is a 1.1x factor clamped to 0.5-6.0, applied to
whichever camera the viewport actually shows (`main.gd:303-319`); middle-drag pans the
free camera (`main.gd:307-309,322-324`). On interior location load, both cameras zoom
so the room floor fills ~85% of the viewport (padding 0.85), clamped 0.5-6.0
(`ZOOM_MAX` was raised for small bedrooms, `main.gd:30-33,159-175`). Outdoor bounds set
camera limits (`main.gd:148-156`).

**Day/night.** A single `CanvasModulate` (`main.tscn:28`) is re-colored by an hour-phase
interpolation through night -> dawn-orange -> white -> dawn-orange -> night
(`main.gd:327-347`); indoor locations dampen the effect to 30% (`main.gd:344-346`).

**Opening cinematic** (`godot/scenes/ui/opening_cinematic.gd`): 30-step authored script
with an atmosphere-overlay color system (10 keyed colors, `:24-68`), portrait frames +
emotion **emoji labels** via `PortraitGenerator` (`:137-158,203-222`), tween shake/flash
on thud/scream beats (`:161-182`), a 2.5 s / 3.5 s step timer, and a fade-out finish
(`:229-238`). The typewriter effect is an explicit stub — "just show text immediately
for now" (`:197-200`).

**Pacing today:** travel has a fade (0.4 s out/in via `Effects.fade_transition`,
`main.gd:64-66,262-263`); interrogation entry has SFX + vignette; accusation has a
0.22 s panel fade-in + SFX + shake (`accusation_reveal.gd:39-45`). **Not paced:** the
ending screen is a bare label/text swap (`godot/scenes/ui/story_screen.gd:37-51` — no
fade, no timing), the first-choice screen likewise (`story_screen.gd:26-34`), the
clue-toast *disappears* abruptly after 4 s (`clue_toast.gd:34-38` — no exit tween), and
"New Game" reloads the scene instantly with no fade (`main.gd:545-557`).

### 1.5 UI surface inventory (all live CanvasLayers under `Main/UI/`)

Wired in `main.gd:10-27`, instantiated in `main.tscn`:

| Panel | Role | Notes |
|---|---|---|
| `ObserverPanel` | OBSERVER-mode dashboard: time, status (`RUNNING / AI: SERVER / 1.0x`), event log + filter, event injection, speed slider 0.5-8.0, relationship graph, NPC info + memory recall | `godot/scenes/ui/observer_panel.gd:5-12,71-79,157-183`; mode-label defect documented then FIXED (evidence doc §10a) |
| `StoryScreen` | First choice (accident/murder), ending + flashback text, quit-case confirmation | `story_screen.gd:26-68` |
| `SettingsScreen` | Difficulty presets + Music/Ambience sliders | `settings_screen.gd` |
| `CasePanel`, `NotebookPanel`, `EvidenceBoard` | investigation references | board has card-connect with highlight (`godot/scenes/ui/evidence_board.gd:232,282-289`) |
| `InterrogationPanel`, `EnhancedInterrogationPanel`, `DialoguePanel` | suspect conversation chain (dialogue card -> interrogation) | |
| `InvestigationHUD` | top bar: location / phase / time / day; evidence `xx / yy`; pulsing `CASE READY` badge (`modulate.a = 0.86 + sin(t*3)*0.14`) | `godot/scripts/ui/investigation_hud.gd:40-43,68-77` |
| `HudClock` | clock + upcoming-event / deadline warnings | `hud_clock.gd:39-78` |
| `ClueToast` | 4 s clue banner incl. notebook-linkage hint "(C: case file / N: notebook)" | `clue_toast.gd:25-28` |
| `InteractionPrompt` | text prompt, up to two lines: `[E] Examine ...` and `[F] Talk to ...` | `godot/scenes/ui/interaction_prompt.gd:20-27` |
| `TutorialPanel` | one hint at a time, dim + 0.3 s fade in, 0.2 s fade out | `godot/scenes/ui/tutorial_panel.gd:24-54` |
| `TravelMap` = **v2** | node map with connections, NPC dots colored per profile, hover tooltip with travel time | `main.tscn:55` instances `travel_map_v2.tscn`; hover at `travel_map_v2.gd:252-275`, dots `:198-236` |
| `OpeningCinematic` | see 1.4 | |
| `ParticleCanvas` | Effects canvas | `main.tscn:67` |
| `AccusationReveal` | pre-confirmation accusation preview with portrait + strength/threshold readout | `accusation_reveal.gd:23-51` |
| `DebugPanel` (scene file exists; not wired in `main.gd`) | — | `godot/scenes/ui/debug_panel.tscn`; roadmap Section 06 wants a diagnostics overlay — see section 2 |

`travel_map.tscn` (v1) is still on disk but not instanced by `main.tscn:55` (which uses
v2) — dead-or-kept duplicate.

### 1.6 QA tooling that pins presentation (the visual gate)

- `tools/run_visual_shots.py` captures **10 deterministic shots** (cinematic,
  story_choice, dorm, bedroom, case_panel, interrogation, dialogue, accusation,
  travel_map, settings) — one fresh windowed Godot process per shot, `--fixed-fps 30`,
  45 settle frames, seed 1337 (`tools/run_visual_shots.py:28-44,46-70`); then
  `visual_diff.gd` compares captures vs `godot/qa/baseline/` headless.
- `godot/tools/visual_diff.gd`: per-channel pixel tolerance 24/255 (`:21`), gate = max
  0.5% changed pixels (`tools/run_visual_shots.py` default, `visual_diff.gd:23`),
  red-overlay diffs written to `godot/qa/diffs/`, **exit code non-zero on drift**
  (`visual_diff.gd:40-45`) — the gate CI can enforce.
- Current state: `godot/qa/diff_report.json` — 10/10 PASS at 0.0% change, tolerance 0.5
  (`:2-104,105-106`); re-verified after CHI-003 at 0.000% drift
  (`docs/evidence-baseline-2026-10-16.md:219-220`). Baselines = the Archival Cutaway
  look, rebaselined in commit `37252fd` (evidence doc §2, `:41-43`).
- `godot/qa/visual_verify_report.json` is a **dry-run heuristic verifier** (7 entries,
  `pass_auto: 7`, `dry_run: true`, `:5-15`) — an assist layer, not the gate.
- **Consequence for any presentation work: every visual change requires an explicit
  rebaseline pass** (`run_visual_shots.py --init` refreshes only the shots captured,
  `:108-118`) — the roadmap's CHI-011 DoD ("update approved visual captures") refers to
  exactly this.
- The capture harness has **no time-of-day parameter** (`visual_capture.gd:59-70` args:
  shot/settle/seed only) — all 10 baselines are captured at whatever hour the scripted
  path happens to reach. Day/night variant QA (roadmap demand) has no tooling.

### 1.7 Tests as behavior documentation

- `godot/tests/test_music_manager.gd` (76 lines): asserts buses exist (`:23-25`),
  players + 4-player SFX pool (`:28-30`), generated streams non-empty
  (`:33-42`), volume API round-trip (`:44-48`), `stop_all` (`:51-53`), and that
  hour->mood keys and location->ambience keys change correctly (`:56-69`). This pins
  **the wiring contract** of the audio system.
- `godot/tests/test_sfx.gd` (49 lines): all 8 categories generate non-empty 16-bit
  22,050 Hz WAVs (`:21-28`), cache identity (`:31-33`), `generate_raw` works (`:36-38`),
  SFXHelper autoload present (`:40-42`).
- `godot/tests/test_particles.gd` (67 lines) and `test_effects.gd` (95 lines): mostly
  **"doesn't crash"** assertions (`test_particles.gd:37-64`) and internal-state checks;
  `test_effects.gd` even contains a tautology (asserts `Color.WHITE.a == 1.0`, `:86-92`).
  They document that the systems *exist*, not that effects *read correctly or occur at
  the right moments* — consistent with the evidence doc's rule that behavior must be
  asserted, not presence.
- `godot/tests/test_ui_node_paths.gd` (51 lines): every `$Node/Path` referenced by a UI
  script must exist in its matching `.tscn` — added after a missing node crashed
  accusation_reveal's `_ready` silently (`:3-6`). **Only 3 script/scene pairs are
  covered** (`:8-12`): accusation_reveal, investigation_hud, dialogue_panel. New UI
  work (or edits to the other ~15 panels) is not protected by this test.
- Suite status: 71/71 test files green, three shards (`docs/evidence-baseline-2026-10-16.md:210-213`).

---

## 2. ROADMAP DEMANDS — every presentation-related item, verbatim

Extracted from the roadmap extract; status assessed against section 1.

**Roadmap page 2 (Section 01, order of operations):**
> "• 5. Polish only proven gaps. Fix onboarding, readability and art mismatches surfaced by actual sessions."

Status: gate is still "surfaced by actual sessions" — presentation polish is explicitly
last; the roadmap says "Do not treat the next milestone as another art pass" (p.2).

**Roadmap page 7 (Section 07, player promises):**
> "• Responsive: examinations, feedback and menus communicate clearly; long AI processing never blocks basic movement."
> "• Atmospheric: the archival cutaway art, sound and UI reinforce one identity across all rooms."

Status: partially met (Responsive: menus exist and are readable; examinations have SFX
and particles; Atmospheric: theme + day/night + ambient exist but **sound identity is
procedural pads**, and "one identity" is un-audited). Unstarted: any formal audit of
consistency across rooms.

**Roadmap page 8 (Section 08, manual playtest matrix — two rows are presentation
rows):**
> "Transitions and navigation | Move through campus, courtyard and each building interior. | Collision, camera, doors and spawn locations are stable."

Status: partially verifiable today — camera fit/zoom/limits exist (section 1.4); the
row is a manual QA task, no automated camera-stability check exists.

> "Visual and accessibility | Try window resize, low resolution, keyboard-only, longer reading times. | Readable prompts, distinguishable clues, legible text, no off-screen UI."

Status: **unstarted**. The window is a fixed 1280x720 `canvas_items` stretch
(`project.godot:56`) — resizing *scales* but no shot/test exercises low resolution or
keyboard-only navigation; no focus-order handling is implemented anywhere in the UI
scripts. Longer reading times (a text-speed/hold-time accessibility option) does not
exist — cinematic step timers are hard-coded 2.5/3.5 s (`opening_cinematic.gd:134,158`)
and the clue toast a hard 4 s (`clue_toast.gd:28`).

**Roadmap page 10 (Section 09 — the core presentation section), verbatim:**
> "Polish is valuable only after the interaction loop is demonstrably intact. Preserve the distinctive Archival Cutaway direction."

> "Target the release's documented rough edges first"
> "• Replace detective/NPC placeholder labels and normalize room name labels in the archival typography system."
> "• Assess day/night variants room by room for contrast and visible search objects; do not rely only on screenshot similarity."
> "• Use consistent evidence readability (highlight, hover, sound and notebook linkage); allow non-color-only cues."
> "• Check presentation pacing: interrogation entry, accusation confirmation, loading fades and ending timing."
> "• Audit licensed/CC0 asset provenance, source Blender files and reproducible 2D export settings."

Status line by line:
1. *Labels/typography* — **partial / code-confirmed as rough**: NPC labels are default-font
   12 px placeholders styled nothing like the archival look (`npc.tscn:26-33`); no
   custom font exists at all (`detective_theme.tres:100`); "room name labels"
   normalization unstarted.
2. *Day/night per-room contrast* — **unstarted**: day/night rendering exists
   (`main.gd:327-347`) but there is no room-by-room assessment and no hour-parameterized
   capture tool (`visual_capture.gd:59-70`).
3. *Evidence readability* — **partial**: sound = yes (`clue_toast.gd:29`); notebook
   linkage = text hint in the toast (`clue_toast.gd:25`); highlight/hover = **only
   inside the evidence board** (`evidence_board.gd:232,282-289`) and travel-map hover
   (`travel_map_v2.gd:252-275`) — **nothing in the world highlights search points,
   clues, or NPCs on hover**; non-color-only cues = not designed (the sparkle/dust are
   motion cues, which helps, but the readability spec was never applied).
4. *Presentation pacing* — **partial**: travel fades + interrogation vignette +
   accusation reveal tween exist; **ending timing, choice-screen entry, toast exit, and
   new-game transition have zero pacing** (section 1.4 last paragraph); cinematic
   typewriter is a stub (`opening_cinematic.gd:197-200`).
5. *Provenance audit* — **partial**: Kenney audio has a license file
   (`godot/assets/audio/LICENSE_kenney_rpg_audio.txt`); a project-wide audit (art, the
   free-asset catalog `godot/assets/FREE_ASSETS_MASTER_CATALOG.md`) is unstarted.

Also Section 09, the asset production route (relevant because it defines the acceptance
route for presentation changes):
> "1. Reference — One visual guide: palette, line treatment, scale, lighting, shadows, prop silhouette rules."
> "5. Scene QA — Compare all active rooms in-game at day/night; approved visual baselines replace obsolete ones."
> "Art change acceptance gate — No new asset is accepted merely because the file exists. It must appear at the right scale and layer in the relevant scene, have usable collision/interaction behavior, match the release style and pass scene QA."

Status: no visual guide exists in-repo; scene QA exists only for the 10 fixed shots.

**Roadmap page 10 also demands pacing as a *check*, not a feature** — i.e., audit
existing timings rather than add effects wholesale.

**Roadmap page 11 (Section 10, milestone M4):**
> "M4 Experience polish | Tutorial, UI, scene clarity, lighting, dialogue/audio consistency. | Critical issues closed; target-platform gameplay reviewed."

Status: unstarted (M4 follows M3 "complete player loop"; M0-M1 evidence is green per the
evidence doc, so the path to M4 exists).

**Roadmap page 11 (Section 11, backlog):**
> "CHI-011 / P2 | Fix known label/UI rough edges; update approved visual captures. | Readable/consistent scene QA at tested resolutions."

Status: **unstarted** — and it is the only backlog item that is presentation-track.

**Roadmap page 6 (Section 06, dev-tools overlay — UI-adjacent):**
> "A small in-game diagnostics overlay" with readouts for "NPC / mode / action state", "Request ID, provider and last latency", "Target room/object and rejection reason", "Evidence count, case flags and terminal state", "Simulation seed / speed / frame time".

Status: partially exists — ObserverPanel already shows time/AI-mode/speed/log/injection
(`observer_panel.gd:71-108`), `CHI-006 / P1` "Add temporary debug overlay and JSON
decision trace" is unstarted; the `debug_panel.tscn` file exists but is not wired.

**Roadmap page 13 (Section 13, release gate — presentation checks):**
> "• Windowed Windows build launch and controls verified independently; monitor startup time, FPS and memory on target low-end hardware."
> "• UI controls, fonts and clues checked at supported resolutions; input hints reflect actual controls."
> "• Assets/licenses/third-party notices packaged; scripts do not expose dev-only logs or API secrets."

Status: unstarted; note "input hints reflect actual controls" is already mostly true
(the `[E]`/`[F]` prompt matches the input map, `interaction_prompt.gd:23-25` vs
`project.godot:104-112`), and the built-in `InputMap` help overlay Godot provides is not
exposed.

**Gating context** (evidence doc, section 10c):
> "Non-code-confirmed roadmap items remain unstarted by design (art, dialogue, presentation). The acceptance criterion gating them: an NPC receives, validates, executes and changes world state, then becomes eligible again with no duplicate requests and no lost responses."

Status: that gate is now mechanically green (CHI-002 test 8, npc.tscn branch
integration — evidence doc §5, `:126-129`), so **presentation work is unblocked** —
though the roadmap's own page-2 rule ("polish only proven gaps") still argues for
proof-driven, gap-targeted polish rather than a general art pass.

---

## 3. GAP ANALYSIS — demands vs state, costed against the R5 M330 2GB

Constraint recap (`docs/evidence-baseline-2026-10-16.md`, target-machine facts): AMD
A9-9420 (2 cores), Radeon R5 M330 (2 GB VRAM, old GCN-class), 7.5 GB RAM. Presentation
work must therefore: (a) keep the shader-free ColorRect/tween particle approach — it is
CPU-cheap and GPU-trivial and already proven; (b) treat Forward Plus as a risk to
re-measure, not to build on; (c) avoid any post-processing (WorldEnvironment glow,
screen-space effects) and realtime lighting expansion; (d) keep asset weight in check
(the shipped .pck is already 70.7 MB — evidence doc §9).

| # | Roadmap demand | Today | Gap verdict | Cost on target GPU |
|---|---|---|---|---|
| G1 | Archival typography for NPC/room labels | default font everywhere; 12 px placeholder-style NPC labels | **Missing** (needs a licensed font + label restyle) | S-M — font render cost negligible; the work is licensing + placement |
| G2 | Day/night per-room contrast assessment | rendering exists; no per-room/hour QA tooling | **Missing tooling + missing audit** | S for tool (add `hour=` param to visual_capture + shot matrix); the audit itself is human time |
| G3 | Evidence readability: highlight, hover, sound, notebook linkage, non-color cues | sound + toast text exist; world-side highlight/hover absent; board-only highlight | **Partial** — biggest missing piece is world-side hover/highlight on SearchPoint/Interactable/NPC | S — modulate pulse on hover using existing tween patterns; zero GPU cost |
| G4 | Pacing: interrogation entry, accusation confirmation, loading fades, ending timing | travel + interrogation + accusation exist; ending/choice/toast-exit/new-game are abrupt; typewriter stub | **Partial** — the *ending* is the largest unpaced moment | S — all wiring of existing Effects functions; no new systems |
| G5 | Cinematic sound (thud/scream) | silent visual-only steps | **Missing** | S — reuse ProceduralSFX.generate_raw + existing ambience assets |
| G6 | Dead ambience WAVs (dorm/server/outdoor loops) | on disk, unwired | **Half-wired asset pass** | S — map 2 keys to the real files, keep pads as fallback |
| G7 | SFX volume control + audio persistence | SFX bus exists, no slider, nothing persists | **Missing** | S |
| G8 | M4 "dialogue/audio consistency" review | 8-category procedural set; player has no footsteps; only NPC footsteps use assets | **Partial** | M — a mixing/walkthrough pass + a few added categories |
| G9 | Visual/accessibility QA (resize, low-res, keyboard-only, reading times) | fixed 1280x720; nothing exercised | **Missing** — and cheap to fake in the capture harness (scale/shot variants) rather than in-game first | M |
| G10 | CHI-011 label/UI rough-edge fixes + rebaseline | baselines current at 0.000% drift | **Unstarted**; every fix above needs its rebaseline ritual | — |
| G11 | Diagnostics overlay (CHI-006) | ObserverPanel partial; debug_panel.tscn unwired | **Partial** | M |
| G12 | Provenance/license audit | Kenney file for audio only | **Partial** | S per asset batch, M overall |
| — | Particle/PostFX upgrade temptation | ColorRect tweens only | **Keep as-is.** GPUParticles2D and shader post-processing are the wrong direction on a 2 GB card; the current approach already passes the visual gate | anti-gap |

Also worth flagging: `SFXData` vs `ProceduralSFX.SFX` catalogue drift (section 1.3) is a
latent defect for any audio work — the curated catalogue is dead code whose parameters
no longer match what players hear.

---

## 4. PROPOSAL — prioritized plan

Sequencing principle: the roadmap says polish "only proven gaps" and presentation pacing
is listed as a *check* — so the plan below (a) wires existing systems into existing
moments wherever possible, (b) defers any new system, (c) ends every item with the
visual-gate rebaseline ritual so the QA gate stays meaningful.

### First three builds (recommended order)

**P1 — "Audio plumbing" (S; ~1 session).** Three small fixes with zero design risk:
1. Add an **SFX slider** to the settings screen and a `set_sfx_volume` on
   MusicManager (volume applied to the SFX bus, not per-player), mirroring the
   existing Music/Ambience pattern (`settings_screen.gd:33-53` template).
2. **Persist all three volumes** (Music/Ambience/SFX) in a small `user://audio.json`
   load/save on MusicManager `_ready`/change, same pattern as
   `tutorial.gd:144-157`.
3. **Wire the dead ambience assets**: `ambience_outside` ->
   `ambient_outdoor_loop.wav`, `ambience_server` -> `ambient_server_loop.wav`
   (keep the generated pads as fallback, copying the `ambient_dorm.ogg`
   ResourceLoader.exists pattern at `music_manager.gd:219-225`).
4. **Give the cinematic its sound**: make `_play_sfx` ("thud"/"scream",
   `opening_cinematic.gd:161-182`) call `SFXHelper.play_raw(...)` (low thump / noise
   sting) in addition to the existing visuals.
   - Dependencies: none. Visual gate impact: none (audio-only) except none of the 10
     shots show changes.
   - Acceptance: extended `test_music_manager.gd` asserts SFX volume API +
     persistence; a new check that ambience keys resolve to the wav files; boot test
     unchanged; manual listen pass on the intro.

**P2 — "Evidence-moment consistency" (S-M; ~1 session).** The roadmap's
"highlight, hover, sound and notebook linkage" demand, satisfied by wiring what exists:
1. **World-side hover/pulse highlight** on `SearchPoint` / `Interactable` nodes
   (modulate pulse + already-existing `Effects.glow` or `sparkle` on the target when
   the `InteractionPrompt` shows a target — the prompt already learns the nearest
   targets via `targets_changed`, `interaction_prompt.gd:10-27`; emit the highlight
   from the same event).
2. **Non-color cue:** on clue discovery the toast already sparkles and beeps; add a
   brief camera `shake_subtle` on *toast appearance* (it exists for the search panel,
   `search_panel.gd:59`) so motion confirms color.
3. **Graceful toast exit:** replace the abrupt `visible = false`
   (`clue_toast.gd:34-38`) with a 0.3 s alpha tween (same pattern as
   `tutorial_panel.gd:45-54`).
4. Extend `test_ui_node_paths.gd` PAIRS to at least the panels touched.
   - Dependencies: none. Visual gate impact: the world shots (dorm, bedroom) could
     capture a highlight state — capture staging must keep the prompt empty at capture
     time or baselines must be refreshed deliberately.
   - Acceptance: hovering/being near a search point visibly highlights it without
     color alone (pulse = alpha modulation); toast fades; visual gate re-run 10/10.

**P3 — "Pacing pass on the unpaced moments" (M; ~1-2 sessions).** All existing
mechanisms, no new ones:
1. **Ending:** wrap `show_ending` in `Effects.fade_transition`
   (`story_screen.gd:37-51` + `main.gd:440-442`); keep the ending pad + ending SFX
   already wired (`music_manager.gd:288-296`, `main.gd:420`).
2. **New game:** `reload_current_scene` (`main.gd:545-557`) inside a
   `fade_transition` so the reset is not a hard cut.
3. **First choice screen:** fade in on `show_choice` (0.3-0.4 s, tutorial-panel
   pattern) so the cinematic -> choice handoff is continuous (cinematic already fades
   out via `_finish`, `opening_cinematic.gd:229-238`).
4. **Cinematic typewriter:** implement the stub (`opening_cinematic.gd:197-200`) as a
   per-character reveal with a fixed chars/sec, keeping capture determinism (the
   capture freezes the cinematic on a fixed beat, `visual_capture.gd:114-128`, so the
   baselines remain valid if the frozen text is set directly as it is now).
   - Dependencies: none hard; ideally after P2 so one rebaseline covers both.
   - Acceptance: no abrupt cuts on ending/new-game/choice; capture pipeline stays
     deterministic (identical byte-for-byte captures across two runs before
     rebaselining).

### Then, in priority order

| ID | Item | Effort | Dependencies | Acceptance |
|---|---|---|---|---|
| P4 | **Day/night QA tooling**: add `hour=` param to `visual_capture.gd`, capture dorm/bedroom at 4 hour bands, add a brightness-contrast check to the report (the diff tool already computes brightness, `visual_diff.gd:132-139`) | M | P1-P3 done (avoids rebaseline churn) | per-room, per-hour shots exist; contrast readout recorded; roadmap's "do not rely only on screenshot similarity" honored by adding the numeric check |
| P5 | **Archival typography**: pick a CC0/OFL font, add `FontFile` to the theme, restyle NPC labels (bigger size, theme label color, outline), normalize room-name labels | M | **user decision** (font choice + licensing, section 5) | no default font remains in UI; visual gate rebaselined; `test_ui_node_paths` still green |
| P6 | **Diagnostics overlay (CHI-006)**: wire `debug_panel.tscn` (or extend ObserverPanel) with the roadmap readouts; this is dev-UI, so no rebaseline needed if toggled off by default | M | none | tester can explain any NPC action/failure (roadmap DoD) |
| P7 | **Accessibility pass**: keyboard-only navigation sweep of all panels (focus order + dismissibles), capture variants at 800x450 to prove scaling, optional "slow text" multiplier feeding cinematic timers and toast duration | M | P3 (timers centralized) | roadmap row pass conditions: "Readable prompts, distinguishable clues, legible text, no off-screen UI" |
| P8 | **Audio consistency review (M4)**: mixing walkthrough — category volumes relative to each other, footsteps for the player, ambience level under interrogation | M | P1 | documented mix sheet; test_sfx still green |
| P9 | **Provenance audit**: per-directory license notes + a LICENSES.md; verify FREE_ASSETS_MASTER_CATALOG entries actually used | M | none | release-gate item closed |
| P10 | **Renderer decision test**: measure boot time, FPS, memory for Forward Plus vs Mobile vs Compatibility on the target machine (roadmap release-gate item) — presentation-neutral change with a mandatory full rebaseline | L | access to target hardware | numbers recorded in evidence doc; decision made or risk accepted |

**Explicitly not proposing** (anti-scope, per roadmap guardrails): GPUParticles,
post-processing/glow/DoF, realtime lights, new shaders, new panels beyond the roadmap's
diagnostics overlay, new locations/assets before M3 loop completeness, and any "art
pass" beyond the five named rough edges.

---

## 5. OPEN QUESTIONS for the user

1. **Music direction.** Today's music is generated sine pads — serviceable but
   monophonic-drone in character. Is the intended identity (a) keep procedural pads
   (zero licensing, zero MB), (b) license/CC0 composed loops in the Archival Cutaway
   mood (a few MB, needs the provenance audit), or (c) hybrid (pads as fallback,
   authored loops for choice/ending moments — GameFlow already has those hooks,
   `music_manager.gd:288-296`)? Any style references (e.g. "slow-noir piano", "campus
   indie")?
2. **Font for the archival typography (P5).** Any preferred open-licensed font?
   Constraint: must bundle in a 70 MB .pck (a font is ~100 KB-2 MB, negligible) and
   license must allow redistribution (OFL/CC0). Also: should the cinematic's **emoji
   emotion labels** (`opening_cinematic.gd:203-222`) be kept, or replaced with text
   tags ("worried")? Emoji glyph coverage in the default engine font is not
   guaranteed and should be verified on the target build before P5.
3. **Accessibility scope.** Is "longer reading times" (roadmap p.8) meant as an
   options-menu text-speed setting, or just that current timings must be audited?
   Keyboard-only play is currently unimplemented in any explicit way — is that in
   scope for this milestone or deferred to M5's release-gate check?
4. **Presentation timing taste.** For P3: acceptable fade durations (default plan:
   0.4 s travel — unchanged; 0.3-0.4 s choice/ending entry; 0.3 s toast exit;
   ~40-60 chars/sec typewriter)?
5. **Renderer.** Should the P10 renderer measurement happen *before* more
   presentation work lands (it invalidates baselines), or after P1-P3 so audio/feel
   improvements land first? (Read-only recommendation: after P1-P3; audio is
   renderer-independent.)
6. **Dead code cleanup** is out of this track's write scope but needs a decision:
   `scripts/audio/sfx_data.gd` (curated catalogue, dead, drifted from the embedded
   dict) — adopt it as the single source of truth (point `ProceduralSFX.generate` at
   it) or delete it? Similarly `travel_map.tscn` (v1, unused since v2 is instanced at
   `main.tscn:55`).
7. **Was the "3D first-person" description intentional?** Roadmap p.15 and
   `project.godot:18` both describe a 2D isometric detective mystery. If a 3D pivot is
   actually intended, this entire document's cost model (and most of the UI) is
   obsolete — please confirm before P1-P3 are assigned.
