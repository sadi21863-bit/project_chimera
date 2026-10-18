# Art Track Research — Project Chimera (visuals, environments, assets, materials, lighting)

**Date:** 2026-10-18. **Mode:** read-only research. No Godot run, no source edits, no builds.
**Inputs:** roadmap extract (`C:\Users\aditya\AppData\Local\Temp\opencode\roadmap.txt`, extracted
from the 15 Oct 2026 roadmap PDF), working-tree sources under `godot/`, `git show 483251c`
(+ repo log), the QA baselines in `godot/qa/baseline/` (10 PNGs, visually inspected this session),
`docs/evidence-baseline-2026-10-16.md`, sibling research: `docs/visual_redesign_research.md`,
`docs/open_world_map_research.md`, `docs/roadmap-research/presentation.md`.
Every claim below was verified by reading the cited file this session; line numbers refer to the
working tree at HEAD (`4fad7eb` = `95fc102` + the 2026-10-16 follow-ups recorded in the
evidence baseline section 2 "Follow-ups").

**Framing correction (affects the whole track):** the research brief described the game as
"3D first-person". It is not. `godot/project.godot:18` says
`config/description="Isometric dorm simulation with 6 autonomous NPCs"` and roadmap p.15 states
"The game remains a 2D isometric Godot detective mystery using Blender-produced art where it
adds value" (roadmap.txt:583). Runtime visuals are 2D at HEAD; the 3D material is prototype-only
(`archival_cutaway_room.glb`, `civic_model_spike.tscn`) and the 2026-09-25 prototype measurement
**rejected live 3D** on this hardware (`docs/visual_redesign_research.md:979-995`). Blender runs
only as an offline render tool. Anything "first-person" belongs to a different game.

**Machine constraints for this track** (brief + `docs/visual_redesign_research.md:4`):
AMD A9-9420 (2 cores), Radeon R5 M330 2 GB (legacy driver line, last Windows driver 2022),
7.5 GB RAM. Consequences sourced in sections 3-5: low-poly authoring budgets,
baked-not-realtime lighting, max 2048 atlases, no 3D migration, and one open renderer
decision (Forward+ vs Compatibility — the top perf item in sibling `presentation.md:33-38`).

---

## 1. CURRENT STATE — what the art actually is today

### 1.1 Rendering config and global surface rules

| Fact | Evidence |
|---|---|
| Godot 4.7, **Forward Plus** feature flag | `godot/project.godot:20` |
| 1280x720 viewport, `canvas_items` stretch | `godot/project.godot:54-56` |
| Nearest-neighbor default texture filter (crisp pixels everywhere) | `godot/project.godot:152` (`textures/canvas_textures/default_texture_filter=0`) |
| Blender import disabled at project level (3D is authoring-only by configuration) | `godot/project.godot:72` (`import/blender/enabled=false`) |
| Global theme `detective_theme.tres`; **no custom font anywhere** (engine default font) | `godot/project.godot:76`; theme sets sizes only (`detective_theme.tres`) |
| One `CanvasModulate` drives the whole game's day/night tint | `godot/scenes/main.tscn:28-30`; `godot/scenes/main.gd:327-347` |

The visual runtime is sprites, `TileMapLayer`s, `ColorRect`/`Polygon2D` primitives,
`CanvasModulate`, and theme styling. There are **no 2D light nodes**, no gameplay shaders, no
runtime post-processing — matching the recorded guidance "single full-screen tint, no per-light
calculations" (`docs/performance-notes.md:27`).

### 1.2 The five visual layers (TL;DR)

1. **Archival Cutaway room plates** — Blender-rendered, ink-treated background images behind
   whole multi-room interiors. Exactly ONE plate exists: Crestwood Hall dorm (day + night).
2. **Legacy tile/ColorRect rooms** — every space without a plate still shows the old tan tile
   floor + dark wall rectangles (`godot/scenes/dorm/bedroom_1.tscn:46-107`).
3. **Prop sprites** — pre-rendered isometric furniture PNGs placed by script over hidden legacy
   furniture, plus 10 SVG location props, plus Kenney sprites in the courtyard.
4. **Characters** — 32x32 generated chip-style sprites (8 cast members, 3 frames per animation),
   plus flat SVG portrait avatars in dialogue UI.
5. **UI/typography** — slate/paper/amber theme, engine default font, ad-hoc map glyphs.

### 1.3 Environment scenes and their scope

**The redesigned interior — Crestwood Hall.** `godot/scenes/dorm/crestwood_hall.tscn` is one
1280x720 cutaway plan (kitchen, hallway, common room, lounge, bathroom, 6 bedroom strips) that
wires `godot/scripts/ui/archival_backdrop.gd:
- paints the day/night plate at `z_index = -100` (`:32`), textures
  `archival_dorm_backdrop_{day,night}_inked.png` (`:8-9`);
- **hides** the legacy tile graphics by node paths — `Floor/TileBase`, four `Walls/*Visual`
  rects, corridor + interior wall rects (`:14-24`) — while leaving collision, navigation,
  doors, markers and NPCs untouched (header comment `:4-6`);
- swaps day/night from `Scheduler.time_changed` (`:38-81`); `DAY_START := 6.0`,
  `DAY_END := 19.0` (`:11-12`);
- guards `has_texture()` / `covers_room()` expecting a plate >= 1280x720 (`:96-104`).

**Every other space still shows the legacy look:**

| Scene family | Files | Visual layer today |
|---|---|---|
| 6 suspect bedrooms + daniel_room | `godot/scenes/dorm/bedroom_1..6.tscn`, `daniel_room.tscn` | tan `floor.tres` TileMapLayer (`bedroom_1.tscn:46-49`), dark `ColorRect` walls (`:65-107`), prop sprites (sec 1.5), engine-font name `Label` (`:51-56`) |
| Hallway, bathroom, kitchen, common_room | `godot/scenes/dorm/{hallway,bathroom,kitchen,common_room}.tscn` (untracked files on disk) | same legacy layering; props via `PropVisuals.decorate_generic` |
| Locations | `godot/scenes/locations/{bar,campus,courtyard,detective_room,hospital,library,police_station,server_room,university}.tscn`, 98-162 lines each | legacy tiles or a backdrop PNG + SVG/Kenney props |
| Investigative rooms | `detective_room.tscn`, `police_station.tscn` | same |

**The outdoors — the "continuous world".** `godot/scenes/locations/outdoor_world.tscn` composes
two resident scenes — `Campus`, and `Courtyard` offset at `position = Vector2(1400, 0)`
(`outdoor_world.tscn:15-18`) — joined by a `NavigationRegion2D` bridge polygon (x 1280->1520)
with a flat green `Polygon2D` visual (`:20-25`). `outdoor_world.gd` keeps the shared edges
disabled (`_open_boundary`, `:60-66`), holds a 2600x900 world bound and camera limits
(`:3`, `:69-80`). `main.gd` hosts it permanently in `$OutdoorWorldHost`, activates it for
outdoor ids, and lets outdoor-to-outdoor travel move the detective without a scene reload
(`main.gd:95-147`, return-positions map `:46`, `:103-117`). Interiors still scene-swap.

Two outdoor looks coexist: `campus.tscn` uses a large backdrop PNG
(`godot/assets/buildings/campus_backdrop.png`, scale 0.875, `campus.tscn:37-40`) plus a
`GrassLayer` on the **untracked** `pipoya_outdoor.tres` (`campus.tscn:43-44`); `courtyard.tscn`
is Kenney sprites (`kenney_furniture/bench_SE.png`, `benchCushion_SE.png`, `bear_SE.png`,
`courtyard.tscn:5-7`) over a green-tinted `floor.tres` (`:27-29`).

### 1.4 The Archival Cutaway redesign — what commit 483251c actually changed

`git show 483251c --stat`: 55 files, +4,517/-652, "Archival Cutaway visual redesign +
continuous outdoor world"; published as tag `v0.2.0-archival-cutaway` (2026-10-11). Art content,
verified:

1. **Blender dorm backdrop generator** `tools/blender/generate_archival_dorm_backdrop.py`
   (304 lines): builds the Crestwood plan from `box()`/`cylinder()` primitives in a fixed
   14-color institutional palette (`:10-30`); ortho camera, `ortho_scale = 1280`, with the
   explicit clip fix `clip_start=1.0` / `clip_end=4000` (`:237-238`; the commit message records
   that the default `clip_end=100` erased everything at the camera height z=1100);
   "flat illustrative lighting" = one sun + window wash + warm lamp-disk area lights by day,
   moon + seven warm lamp pools by night (`setup()`, `:229-263`); Eevee, 1280x720 RGBA
   (`render()`, `:266-281`); rebuild + render for the night plate (`:284-303`).
2. **Post-treatment** `tools/blender/apply_archival_treatment.py` (Pillow, 80 lines): 0.78
   color desaturation, 1.16 contrast, FIND_EDGES ink pass in `(14,24,32)`, halftone dot lattice
   (spacing 8), seeded grain (`:9-18`), blurred-edge vignette (`:21-33`); stronger ink + darker
   variant for night (`treat()`, `:50-64`). Deterministic (seeds 1337/7331, `:62`).
3. **Runtime backdrop node** (above) + suite test `godot/tests/test_archival_backdrop.gd`
   (94 lines).
4. **Character restyle** — all 8 SpriteFrames regenerated as 32x32 ink-outlined sprites,
   same layout contract "five animations, three frames" with the promise that every consumer
   "keeps working because only the pixels change"
   (`tools/art/generate_archival_characters.py:1-9`).
5. **Global theme** moved to the archival slate/paper/amber style (today: dark-slate buttons
   `Color(0.16,0.23,0.29,0.96)` with amber borders `Color(0.85,0.6,0.3,0.9)`,
   `detective_theme.tres:10-20`).
6. **Outdoor world** added as above; doors became `BuildingPortal` metadata carriers
   (`godot/scripts/player/building_portal.gd`, new in the commit).
7. **A hero prototype** `godot/scenes/prototypes/archival_cutaway_hero.gd` (413 lines) that
   mocks the *target* presentation with hand-built panels: top rail "ARCHIVE / CRESTWOOD HALL",
   case-file column, evidence cards, labeled character sprites, and an amber diamond evidence
   marker that pulses and turns green after examination
   (`_build_evidence_marker` `:158-164`, `_complete_search` `:344-347`).
   Capture `godot/assets/prototypes/archival_cutaway_hero_capture.png` (viewed this session) is
   the style the redesign points at.
8. **A rejected 3D spike**: `civic_model_spike.gd` loads the same room via GLB with a
   Camera3D (`:3-16`). Measured (`docs/visual_redesign_research.md:983-987`):

| Path | Evidence | Draw calls | Primitives | Verdict |
|---|---|---:|---:|---|
| Archival Cutaway 2.5D | `archival_cutaway_hero_capture.png` | 122 | 5,662 | **chosen** |
| Civic Model live 3D | `civic_model_spike_capture.png` | 137 | 61,618 | **rejected**: one room already exceeds the recommended 100-draw-call budget and loses character readability top-down |

9. **Asset manifest** `godot/assets/prototypes/asset_manifest.json` (87 lines): each generated
   asset carries `source` (its generator script) and a `license` of "Project-owned generated
   asset"; dorm plates are `status: "live-crestwood-hall"`, hero plates
   "approved-for-prototype", room glb + 3D spike "spike-only". `external_assets: []` (`:86`) —
   only generated files are graded; the third-party pile below is NOT in it (gap, section 3).

What the redesign did **not** touch: bedrooms/subrooms/locations visuals, the travel map, the
dialogue portrait, evidence hotspot visuals, the particle canvas — those still show their
pre-redesign state, which is why room-to-room identity is uneven (section 3).

### 1.5 Props, materials, textures

Three placement systems overlap:

1. **Placement-agnostic legacy furniture nodes** still exist inside every room scene
   (`bedroom_1.tscn` furniture subtree `:118+`) and are simply hidden at runtime.
2. **`godot/scripts/ui/prop_visuals.gd`** (new in 483251c) — holds `ROOT := "res://assets/2d/dorm_props/"` (`:4`). `add_sprite(parent, asset, at, scale_factor=0.2, z, tint)` loads `ROOT + asset + ".png"` with `TEXTURE_FILTER_NEAREST` (`:6-16`); `hide_legacy_furniture(root)` null-safe hides the five legacy nodes `Furniture/{Bed,Desk,Chair,Bookcase,Dresser}/Visual` (`:18-25`); `decorate_bedroom(root, room_id)` lays a fixed item set (bed, desk, chair, bookshelf, locker, lamp, suitcase) with Daniel's room getting its own larger layout at scales 0.17-0.30 and suspect bedrooms a compact layout at 0.11-0.18 (`:27-50`); `add_location_sprite(..., scale_factor=0.5)` loads `location_props/<asset>.svg` with `TEXTURE_FILTER_LINEAR` (`:52-61`); `decorate_generic(root, location_id)` dresses every non-bedroom room by `location_id` with a script comment noting coordinates are *"fitted to OUR generated room sizes ... the source pass assumed larger rooms"* (`:63-136` incl. NOTE `:70-72`).
3. **`godot/scenes/ui/scene_decorator.gd`** — a decorative overlay keyed by room-type id constants (`:9-50`), wired from `crestwood_hall.gd` `_decorate_scene` (`:97-105`).

Textures live in four places:
- `godot/assets/2d/dorm_props/` — **20 PNG furnishing sprites** (bed, desk, chair, bookshelf,
  locker, lamp, suitcase, evidence_board, trash_bin, security_camera, ...) pre-rendered by
  `tools/render_glb_sprites.py` rasterizing the `godot/assets/3d/dorm/*.glb` meshes produced
  by `tools/blender/generate_chimera_assets.py`.
- `godot/assets/2d/location_props/` — exactly **10 SVG props** (bar_booth, couch, counter,
  courtyard_tree, hospital_cart, lab_easel, noticeboard, server_rack, terminal, vending).
- `godot/assets/2d/kenney_furniture/`, `godot/assets/2d/interior/`,
  `godot/assets/2d/investigation/`, `godot/assets/2d/detective_items/` — third-party sprite
  piles already copied into the tree (untracked, provenance unaudited; section 3).
- Core gameplay tiles: `godot/assets/tiles/floor.tres` (single tan tone); walls are
  `ColorRect` fills sitting between room rects (e.g. `daniel_room.tscn:65-107`),
  the "flat institutional feel" the docs call the pre-Cutaway look.

Reproducibility facts: `tools/render_glb_sprites.py` is deterministic (orthographic iso
projection matrix `:14-16`, camera-aligned face sort `:72`, drop shadows only `:62-69`,
2048 output), so dorm prop PNGs can be regenerated byte-identical. **No `.blend` source file is
checked in** — `tools/blender/generate_archival_dorm_backdrop.py` synthesizes geometry in
Python, and the prompt's ***provenance and reproducible export settings*** requirement is
satisfied there only for the dorm plate (track gap #DDD in section 3).

### 1.6 Characters, portraits, the scale/read problem

- `godot/assets/characters/`: `alpha.tres`, `beta.tres`, `victoria.tres`, `james.tres`,
  `kofi.tres`, `refreshed.tres`, `urban.tres`, `sonya.tres` — 8 characters x 5 animations
  (idle, walk, work, look, gesture) x 3 frames, 32x32 nearest-filtered.
  Regenerated by `tools/art/generate_archival_characters.py:1-9` with wardrobe palettes at
  `:27-36`.
- Portrait avatars in dialogue: `godot/assets/ui/portraits/` holds exactly **7 SVGs** named
  after the suspect aliases (alex, casey, dean, jordan, morgan, riley, sam — flat vector
  head-and-shoulders chips, untracked) rendered in the dialogue UI.
- On screen, `npc.tscn:24` sets `scale = Vector2(0.5, 0.5)`, so a 32x32 sprite renders at
  **16 px**; `detective.tscn:16-18` uses `scale = 0.15`, so the detective renders around
  **5 px** in the Crestwood plate shot. `docs/visual_redesign_research.md:139` requires
  **80-110 px** for facial readability at conversational zoom; the recorded mitigation was a
  "targeted bedroom camera zoom" (HANDOFF.md 2026-09-22 item 4), still marked open.
  This is the single most user-visible art defect at HEAD: characters read as colored chips
  against the 1280x720 plate (compare baseline `dorm.png`).

### 1.7 UI, typography, travel map

- Global theme: `detective_theme.tres` — `StyleBoxFlat` button/panel styles: dark-slate fills
  `Color(0.16,0.23,0.29,0.96)` with amber borders `Color(0.85,0.6,0.3,0.9)`, hover/pressed
  variants, corner radii, content margins (`:10-20` and following).
- **Typography**: zero font files. All text uses the engine default font; the UI strike
  list in the roadmap ("UI scale, accessibility, fonts, localization" — roadmap.txt:535-543)
  and the "archival document" mood (`roadmap.txt:330, :364-365`) are both unmet.
- Travel map: `godot/scenes/ui/travel_map_v2.gd` draws destination cells as circles whose
  color encodes state — current = green `Color(0.2,0.9,0.3)`, visited = blue
  `Color(0.3,0.6,0.9)`, unvisited = flat gray `Color(0.5,0.5,0.5)` (`:160-165`), with 10-pt
  font labels overriden per state (`:177-181`). The older modal
  `godot/scenes/ui/travel_map.gd` coexists behind `UIRouter.route_package(..., "modal")`
  fallbacks (`travel_map_v2.gd:64-78`); no swatches, icons or art — pure colored primitives.

### 1.8 Animation, VFX, audio in the visual track

- SpriteFrames only (5 humanoid animations x 3 frames x 8 characters), generated by script.
- VFX is a hand-rolled autoload, not particle nodes: `godot/autoload/effects.gd`
  ("screen shake, flash, particles, fade transitions" header `:2`), whose
  `spawn_particles(pos, color, count=8)` fills `godot/scenes/ui/particle_canvas.gd`
  (six emitters: dust/sparkle/glow/trail/burst/clear; exercised end-to-end by
  `godot/tests/test_particles.gd`). `main.gd:346-384` also pulses a screen flash
  overlay on suspicion transitions.
- Audio is out of my lane here (sibling presentation.md) — only noting 12 tracked
  `godot/assets/audio/` files present alongside the art-layer changes.

### 1.9 The visual QA gate and its captured baselines

`tools/run_visual_shots.py` drives `godot/tools/visual_capture.gd` and then runs
`godot/tools/visual_diff.gd`:

- 10 shots exactly, matching the key list hardcoded in `visual_capture.gd:20` and the
  `Step` enum `:25-41`: `cinematic`, `story_choice`, `dorm`, `bedroom`, `case_panel`,
  `interrogation`, `dialogue`, `accusation`, `travel_map`, `settings`; the harness pins
  `--fixed-fps 30`, settle 45, `seed=1337` (`tools/run_visual_shots.py:41-43`).
- `visual_diff.gd`: 24/255 per-channel tolerance (`:21`), scene-level allowance 0.5% of
  pixels (`:23`), writes `diff_report.json`, exits non-zero on a red capture (`:40-45`).
- Baselines **tracked** in `godot/qa/baseline/` (10 PNGs, refreshed by commit `37252fd`
  and re-verified 10/10 PASS, 0.000% pixels at `4fad7eb` — `diff_report.json`).
- Coverage gaps, verified against the capture script: only the dorm plate and bedroom_1 are
  real rooms; every capture lands on the day-lit default hour (the Scheduler autoload's
  start constant is `START_HOUR := 7.0` — `godot/autoload/scheduler.gd:11` — and
  `visual_capture.gd` never calls `Scheduler.set_time`), so **night plates, the nine
  location scenes, the outdoor world, the seven portraits and the five remaining suspect
  rooms have no baselines at all**. The `godot/tools/visual_qa.gd` "live monitor"
  scaffolding (`dry_run := true`) exists but is not wired anywhere, and
  `.github/workflows/ci.yml` has **no visual-diff job at HEAD** (file exists; grep for
  `visual-diff|run_visual` returns nothing), so the gate runs locally/manually only
  (roadmap.txt:374-376 demands exactly this gate).
- Read this session: `dorm.png` (clean plate, correct slate/amber UI), `bedroom.png`
  (almost-empty tile room with a scale-0.15 detective), `interrogation.png` (portrait SVG
  chips over the slate panel), `travel_map.png` (flat gray circles, no art), `dialogue.png`
  — they confirm the layer inventory above.

### 1.10 The asset layer on disk vs what git actually tracks

`git ls-files` (HEAD, 4fad7eb) shows **117 tracked files under `godot/assets/`**: 92
`characters/` legacy files (the pre-restyle sweep: 8 chars x 5 anims incl. both png-era and
tres-era siblings), 12 `audio/`, 6 `prototypes/` (5 plates + manifest), 1 `buildings/`
(campus backdrop), 1 `tiles/` (floor.tres). Everything else in `godot/assets/` is
**untracked**; a truncated `git status --porcelain` count shows roughly 199 untracked
entries across:

- `godot/assets/2d/` — `dorm_props/` (20 PNGs, generated), `location_props/` (10 SVGs),
  `kenney_furniture/`, `interior/`, `investigation/`, `detective_items/` (third-party piles)
- `godot/assets/3d/` — the six `dorm/` GLB source meshes **plus** `house_interior.fbx`
  (source assets other scenes may depend on regenerating from)
- `godot/assets/ui/portraits/` (7 SVGs), `godot/assets/textures/`, `godot/assets/fonts/`
  (README only), plus several referenced-in-scenes-adjacent scripts and
  `godot/README_ASSET_PASS.md`, `godot/README_ENVIRONMENTAL_PASS.md`

Consequence documented in section 3: a fresh clone of `main` cannot render the courtyard,
campus grass, bedroom props, portraits, or several UI pieces (courtyard.tscn, campus.tscn
both reference untracked resources). This is the roadmap's reproducibility / provenance
strike already live at HEAD.

---

## 2. THE ROADMAP'S VERBATIM ART DEMANDS (and their status today)

Extracted from the 15 Oct 2026 roadmap PDF (text anchor file:
`roadmap.txt`, lines refer to that extract). All quotes verbatim.

### 2.1 Section 09 "Visuals, audio and Blender pipeline" — the five documented rough edges

Framing sentences (p.10, extract :351-354): **"Visuals, audio and Blender pipeline / Polish
is valuable only after the interaction loop is demonstrably intact. Preserve the distinctive
Archival Cutaway direction. Target the release's documented rough edges first."** The five
bullets (verbatim, :355-360) and their HEAD status:

| Verbatim bullet | Extract line | Status at HEAD `4fad7eb` |
|---|---|---|
| "Replace detective/NPC placeholder labels and normalize room name labels in the archival typography system." | :355 | **OPEN.** Room-name labels are engine-default-font `Label` nodes (`bedroom_1.tscn:51-56`); no "archival typography system" exists anywhere in the repo (no font files at all — `godot/assets/fonts/` holds only a README). Detective/NPC label styling is ad hoc per scene. |
| "Assess day/night variants room by room for contrast and visible search objects; do not rely only on screenshot similarity." | :356-357 | **PARTIAL.** Exactly one painted room (Crestwood Hall) has day AND night plates; the swap is a single global texture change in `archival_backdrop.gd:38-81`, not a per-room assessment; every other room inherits the one `CanvasModulate` tint (`main.gd:327-347`); no room-by-room contrast audit exists at HEAD, and the current capture suite takes no night shot at all (sec 1.9). |
| "Use consistent evidence readability (highlight, hover, sound and notebook linkage); allow non-color-only cues." | :358 | **OPEN.** `godot/scripts/ui/search_point.gd` and `clue_hotspot.gd` are logic-only (no `_draw`, no sprite, no shader). The hero prototype's amber-diamond marker that pulses and turns green after examination (`godot/scenes/prototypes/archival_cutaway_hero.gd:158-164`, complete-search `:344-347`) is the designed read, graded "approved-for-prototype" in `asset_manifest.json` — it is not wired into live scenes. `godot/README_ENVIRONMENTAL_PASS.md` claims a "magnifier marker" and "green evidence marker" exist; they do not (verified: zero `_draw`/marker code in `godot/scripts`). |
| "Check presentation pacing: interrogation entry, accusation confirmation, loading fades and ending timing." | :359 | **OUT OF SCOPE HERE** (dialogue/pacing track = sibling `presentation.md`), but the *visual* halves — loading fades, ending visuals — touch this doc; no fade/transition asset or spec exists in `godot/` at HEAD (only `Effects.fade`). |
| "Audit licensed/CC0 asset provenance, source Blender files and reproducible 2D export settings." | :360 | **OPEN.** `asset_manifest.json` grades generated assets but `external_assets: []` (`:86`); the Kenney furniture pile, PIPOYA tileset, interior/investigation/detective_items sheets sit untracked with no LICENSE note or source mapping; no `.blend` files are checked in (generators synthesize geometry in Python — reproducible yes, auditable provenance docs no). |

### 2.2 The five-step asset production route (verbatim, :362-374)

| Step (roadmap table) | Deliverable / check (verbatim) | Where HEAD already does something |
|---|---|---|
| 1. Reference | "One visual guide: palette, line treatment, scale, lighting, shadows, prop silhouette rules." | **No.** No visual guide doc exists; palette/lights live *inside* `generate_archival_dorm_backdrop.py:10-30` and the theme, never written down as a guide. |
| 2. Modular Blender source | "Repeatable source .blend or generator with object naming, pivots, consistent axes and naming." | **Partially.** Generators ARE the source (`generate_archival_dorm_backdrop.py`, `generate_chimera_assets.py`, `render_glb_sprites.py`); naming is consistent; no `.blend` files, which matches the roadmap's "or generator" branch. |
| 3. Export + 2D render | "Deterministic isometric angle, lighting, scale, day/night render variants, transparent PNG where needed." | **Partially.** Deterministic Eevee exports with day/night exist for the dorm backdrop; `render_glb_sprites.py` gives deterministic isometric transparent PNGs for props; character sheets are Python-drawn, not Blender-rendered. |
| 4. Godot import | "Centralized import and placement conventions; automated resource-reference scan." | **NO.** There is no importer script or placement convention doc; the automated resource-reference scan does not exist (and its absence is live-bug-proven: `campus.tscn`/`courtyard.tscn` reference untracked resources right now). |
| 5. Scene QA | "Compare all active rooms in-game at day/night; approved visual baselines replace obsolete ones." | **PARTIAL.** Baselines exist (10 shots) but cover 2 rooms, day-only; replacement flow (rerun + commit baselines) works locally; not in CI (sec 1.9). |

### 2.3 The art change acceptance gate (verbatim, :375-377)

> "No new asset is accepted merely because the file exists. It must appear at the right
> scale and layer in the relevant scene, have usable collision/interaction behavior, match
> the release style and pass scene QA."

Stress-tested against HEAD: the dorm plate passes all four clauses; bedroom prop sprites
have no in-scene collision to collapse; the grayscale label state on travel maps violates
"match the release style" (gray primitives vs slate/amber); and "pass scene QA" is pinned
to only-10-2-room daytime coverage (section 4 maps this into the QA expansion).

### 2.4 Supporting demands for this track

- **Art direction lock** (Section 07 decisions table, :290-292): "Art direction — The
  October 2026 archival cutaway release is the visual baseline; reject inconsistent
  older/neon assets." At HEAD the baseline tag exists (`v0.2.0-archival-cutaway`) but the
  ~13 rooms that still show the legacy tan-tile look ARE the inconsistent assets the
  roadmap says to reject.
- **Atmospheric pillar** (:279): "the archival cutaway art, sound and UI reinforce one
  identity across all rooms." One-of-~15-rooms styled today; identity fails on
  rooms without plates.
- **Section 08 playtest rows** (:328-341): "Transitions and navigation — Move through
  campus, courtyard and each building interior (pass: Collision, camera, doors and spawn
  locations are stable)" and "Visual and accessibility — Try window resize, low resolution,
  keyboard-only, longer reading times (pass: Readable prompts, distinguishable clues,
  legible text, no off-screen UI)" — both rows hit art-layer defects already recorded
  (untracked outdoors; engine-font legibility; character chip size).
- **CHI-011** (:478-482, P2, verbatim): "Fix known label/UI rough edges; update approved
  visual captures" with pass condition "Readable/consistent scene QA at tested
  resolutions." This ticket IS the label-normalization bullet plus the baseline refresh,
  confirmable straight from the repo (CI: no captures in CI at HEAD).
- **CHI-012** (:483-486, P2): "Produce reproducible signed-off Windows release candidate"
  pass: "Hashes, install instructions, test report and **license audit**" — the license
  audit only exists in `asset_manifest.json` for generated assets.
- **Section 13 release checklist** (:535-543): "UI controls, fonts and clues checked at
  supported resolutions; input hints reflect actual controls" (:542) and
  "Assets/licenses/third-party notices packaged" (:543). Directly blocked by: zero font
  files (engine default at 720p will not scale), untracked/packaging-invisible third-party
  piles.
- **Regression gate requirement** (:374): "approved visual baselines replace obsolete ones"
  and the sibling baseline report (`docs/evidence-baseline-2026-10-16.md`) documents the
  current 10/10 PASS, 0.000% pixels local rerun — none of it is a CI gate at HEAD.

## 3. GAP ANALYSIS — art demand vs HEAD reality

Roadmap demand (sections 2) and the actual visual state (sections 1) are now collated.
For each gap: cheapest feasible route on this machine, what is NOT feasible, and where
effort should NOT be spent. Rejected routes live in G10 (do-not-do list).

### 3.1 The gap list

| # | Gap | Evidence gap exists | Cheapest feasible route on this machine | Not feasible / not worth it |
|---|---|---|---|---|
| G1 | **Room-to-room identity**: one designed plate vs ~13 rooms still displaying tan tiles/ColorRect walls and placeholder proportions | `crestwood_hall.tscn` (redesigned) vs `bedroom_1..6`, hallways, 9 locations (sec 1.3), Atmospheric pillar (:279), art-direction lock (:290-292) | Extend the ONE proven generator (`generate_archival_dorm_backdrop.py` already parameterizes palette/light boxes by room box input, 304 lines) to emit 1280x720 plates per remaining room; run `apply_archival_treatment.py` pipeline; treat via existing `ArchivalBackdrop` node per scene. One offline Blender render per plate (minutes on this CPU), captured ONCE then stored as PNG | Live 3D rooms (measured worse: 122 draws vs 137 draws on 61,618 prims — `docs/visual_redesign_research.md:983-987`); hand-painting in Krita/Photoshop (no artist on staff; risks style drift) |
| G2 | **Character readability**: 32x32 chip at world scale ~16 px (NPCs) and ~5 px (detective) vs 80-110 px demand | `npc.tscn:24` scale 0.5; `detective.tscn:16-18` scale 0.15; `docs/visual_redesign_research.md:139` | Two-free combined: (a) re-render target-res SprFrames at 64 px via the existing `generate_archival_characters.py` (same 5-anim contract, only pixel volume changes, `:1-9` promised this contract); (b) raise scene scale factors OR camera zoom; e.g. re-render the sheet at 64 px and raise the detective's `detective.tscn` scale factor accordingly, then compare against a camera-zoom variant before choosing | Any redraw by hand (no artist skills); upscaling 32->128 (nearest aliasing, blocky); 3D avatar overlays (unproven; pace) |
| G3 | **Evidence hotspots invisible to search**: no marker code, hero prototype has the design unapproved-for-live | `search_point.gd` / `clue_hotspot.gd` logic-only; marker design approved-in-manifest only (sec 1.4, G-5 item) | Port `archival_cutaway_hero.gd` marker pattern (413-line file, zero external deps: an `Area2D` + pulsing diamond `Polygon2D` in amber, switches to green sprite on completion + optional sound via `Effects`) into a small autoloaded `EvidenceMarker.tscn` consumed by `search_point.gd`; wire a colorblind-safe glyph overlay flagging (differs by SHAPE not hue: diamond vs circle) | Realtime shaders / light halos (R5 M330 Vulkan/older; risks alphas); HUD icons only (roadmap rejects color-only cues, :358) |
| G4 | **Typography system absent**: bytes-free engine default font; travel map / labels tiny and unreadable at 720p | `detective_theme.tres` sizes only; `travel_map_v2.gd:177` font_size 10; roadmap :535-543 | Bundled open-font (e.g. Atkinson Hyperlegible OFL — CC0-class, tiny TTF) + label template (small LabelStyle in theme) then scale UP not built per screen | Any paid/commissioned font; variable-font complexity; SVG glyph sprites per character |
| G5 | **Travel map / destination identity**: flat colored circles by state only, placeholder geometry | `travel_map_v2.gd:160-165` current=green/visited=blue/unvisited=gray; capture baseline confirms | Add a minimal plate art pass (one render of the campus+city outline via the SAME Blender generator with a top-down city silhouette, ~3 box primitives) + color-coded pins using existing classes | Full city map with buildings/roads mesh (time sink, no artist); dynamic pathfinding lines (out of art lane) |
| G6 | **No night variant authored for anything except the dorm plate**; scenes never publish dark adjectives | `START_HOUR := 7.0` default; same global tint everywhere; sec 1.9 | Hero-1 generator already supports a night mode (moon + 7 warm lamp pools, `generate_archival_dorm_backdrop.py` `setup()` night lights) — SAME generator parameters re-run for remaining rooms once G1 route lands | Realtime per-room 2D lights (R5 M330 lacks Vulkan reliably; risk stacking with OpenGLES3 + camera swaps already in `outdoor_world.gd`); baking lightmaps into 3D scenes (no live 3D) |
| G7 | **Portraits are generic SVG chips; interrogations/discoveries use no unique facial art** | 7 alias SVGs (sec 1.6); interrogation baseline visually identical to chip | Keep SVG2 minimal: add uniform archival "ink outline + amber-washed background" treatment to each SVG via a single converter pass (same `apply_archival_treatment.py` param set), no new assets until chip readability fixed (G2 first) | Hand-drawn portraits; AI image gen (no licensing/provenance path accepted by roadmap Step 5 acceptance gate; and historical evidence in `docs/visual_redesign_research.md` tests) |
| G8 | **Untracked / non-reproducible asset layer breaks fresh clones**: campus tileset, Kenney courtyard, dorm_props, portraits, house_interior.fbx, README docs all outside git | campus.tscn:43-44 references untracked `pipoya_outdoor.tres`; `courtyard.tscn:5-7` refs untracked Kenney PNGs; sec 1.10 list; roadmap :360 provenance bullet | 2-hour fix: `git add` the generated + PROJECT-OWNED assets (dorm_props, location_props, portraits, plate successors, house_interior.fbx, READMEs); for THIRD-party piles (kenney, pipoya, interior, investigation, detective_items) either commit with attribution note or vendor a manifest and document their origin zip; add an automated `assert_tracked_references` scan step as the roadmap's Step 4 "automated resource-reference scan" suggests (single greppable godot script runnable in CI once CI wiring exists) | VFS git-lfs unless the binary pack size analysis says so (dorm_props PNGs are small (~KB); big files are only GLBs + backdrop plates ~2-4 MB each; use direct commit) |
| G9 | **The release product does not yet hold "matches release style"** across UI (color-blind cues, grays) and labels per the acceptance gate | acceptance gate text :375-377; travel_map grayscale collision; `archival_backdrop.gd` colors the plate over `main.gd`'s tint (double-darkening at night when both apply — audit needed) | A per-scene style audit checklist post-G2/G4 (style lock docs) verifying amber/slate + label system + evidence markers exist in EVERY active scene, then update baseline captures | Pixel-polish beyond the style lock (perf regressions, HD 4K renders) |
| G10 | **Visualization of evidence at scene QA has no night, no location, no suspect-room baselines** | sec 1.9 gap list; roadmap :354 demands room-by-room assessment | Extend `tools/run_visual_shots.py` with 5 more shots (night dorm, campus, courtyard, police_station, interrogation night) + extend `visual_diff.gd` tolerance matrix if needed (max 2048 PNG each, baseline storage ~15 PNGs at 1280x720 ~ 3 MB not bloated) | Running all 15 scenes every commit (git confirmed 2-core build/test box; keep 10-12 per-commit shots, run the wider set on PR/labeled runs) |

### 3.2 Effort sizing / what maps to cheap work on THIS 2-core, 2-ab VRAM-class GPU (similar notes in performance-notes.md)

- G1 is the "scale-up route": measured numbers say 2.5D plate route barely moved draw calls
  for ~13 rooms (every plate = 2 textures swapped, like `archival_backdrop.gd` already does).
  Blender renders are CPU-bound but occur ONCE per asset, off-device.
- G3 is code-first, no new assets requires; no Milestone-y sizing beyond an evening.
- G2 is the only gap where scale changes gameplay feel mid-scene — needs a focused camera
  decision alongside pixel-scale decision, and a baseline refresh in the same PR
  (roadmap-changed asset -> capture update, matching CHI-011 wording "update approved
  visual captures").
- G4/G5/G9 pair into one "archival typography + map polish" milestone once a font choice is
  user-approved.
- G8 is a chop-block, day-one fix: it removes ALL fresh-clone/reproducibility landmines
  before any new art work touches the repo.
- Out of scope (documented for completeness, rejected elsewhere): live 3D rooms, live
  3D lighting, 3D camera parallax, hand-painted assets, AI/franchise/investigation art
  (provenance gate rejects; and G2's scale solution must not block G7's treatment).

## 4. PROPOSED BUILD LIST (ordered)

Each item: what ships, why for (roadmap hook), effort (S = hours, M = 1-3 days, L = a week+),
dependencies, and an acceptance criteria line ready for a PR. Items marked [CODE] are
scripting-level art tooling; [ART] generate binary art; [DOC] checklists. No item assumes a
live-artist run; every item regenerates through the existing script pipeline, meeting
Step 2 "Repeatable source .blend or generator".

### First three (this week, each S, each independent)

**P1 [ART+DOC] Commit and license-stamp the untracked asset layer (G8).**
- Ships: every referenced asset tracked (`dorm_props`, `location_props`, `portraits`,
  `captured` plates, `3d/`, READMEs); manifest rows for each third-party source (kenney,
  pipoya, interior/investigation/detective_items) with origin + license; a first
  `godot/tools/assert_asset_refs.py` (roadmap Step 4) that `git ls-files` checks scan of
  every `res://` referenced in .tscn + `prop_visuals.gd` ROOT paths and exits non-zero on
  untracked deps. Wired as a CI job when the visual gate lands.
- Roadmap hook: :360 provenance + Step 4 scan + :543 packaging + CHI-012 license audit.
- Effort: S (1 day, mostly bookkeeping).
- Acceptance: `git clone` on a fresh directory + `godot --headless --quit` parses ALL
  scenes; `assert_asset_refs.py` exit 0; zero missing references - i.e. every
  `res://assets/**` file referenced by a committed .tscn or gd script appears in
  `git ls-files` with a manifest row.

**P2 [CODE] Validate and switch the renderer: Forward+ -> Compatibility (per sibling docs/
presentation.md, top perf item on the R5 M330).**
- Ships: a documented `Compatibility` mode test on the target machine; compare the
  `docs/visual_redesign_research.md:983-987` draw-call numbers before/after; monitor
  startup time/`FPS`/memory per roadmap :540-541.
- Roadmap hook: :540-541 "release-candidate checklist" (monitor startup time/`FPS`/memory
  on target low-end hardware), plus baseline-unchanged draw calls per visual path.
- Effort: S up front (toggle + capture rerun; keep `archival_backdrop.gd` intact as it
  only draws `TextureRect`s).
- Acceptance: same 10 captures pass with 0.5% pixel tolerance after toggle; startup time
  from README operational numbers regresses by less than 10%; VRAM headroom measured
  (`docs/open_world_map_research.md:67` math sanity-checked at `Compatibility`).

**P3 [CODE] Archival label + typography system (G4, CHI-011 verbatim).**
- Ships: the first bundled font (CC license, e.g. Atkinson Hyperlegible or Inter, OFL
  license carried in `godot/assets/fonts/LICENSE`), a LabelStyle family in
  `detective_theme.tres` (room-title, UI caption, interrogation "case-card" variants at
  several sizes with a documented min size at 720p), and a pin "detective/NPC label"
  template; then update every Label (scene label nodes) to reference the theme style labels.
- Roadmap hook: :355 verbatim + :542 fonts scaled + CHI-011.
- Effort: S (font choice + theme + scene label swaps; no scene layouts changed).
- Acceptance: every UI label and room-title uses a theme style (no raw default-font
  overrides); captures refreshed (`archival_cutaway` plate style anchored to new labels),
  baseline diff green.

### Next (queued after the first three)

**P4 [CODE] Searchable-object markers (G3).** Port the hero marker pattern into
`evidence_marker.tscn` + wire `search_point/clue_hotspot`; diamond vs circle for non-color
cues. Effort: S-M. Acceptance: captures for a bright search state AND a green completed
state; color-blind-safe shape encoding documented; roadmap :358 satisfied.

**P5 [ART+CODE] Day/night room-by-room pass against the prompt criteria (G1 component
+ G6).** Run `generate_archival_dorm_backdrop.py` with a small room-parameter extension: add a
`--room crestwood_hall` to **generate plates for each suspect room**, hallway, and the
kitchen etc., rerun with day and night lights via `apply_archival_treatment.py`;
wire each `ArchivalBackdrop` to the new plate per scene (plates 1280x720 "cutaway 2D"
models, NOT 3D). First batch: the six suspect bedrooms (same room archetype = one box
input, fastest to pull). Effort: M-L (L if all ~13 rooms; first 6 bedrooms = M). Acceptance:
room-by-room night AA tests (captures shown in a table in `docs/roadmap-research/art.md`
follow-ups doc? NO - acceptance in captures, per sec 1.9 extended shot list) plus the plate
swap negates double-darkening from `main.gd` tint (verify).

**P6 [ART] Backdrop plates for the nine locations (G1 second half), reusing P5's
parameterization with location-specific colors/silhouettes from `scene_decorator.gd`
constants. Effort: M over 2-3 sessions (Blender render + verify on device one at a time).
Dependencies: P5's scene wiring pattern proven once. Acceptance: all nine locations read
in plate style; captures refreshed; roadmap :290-292 "reject inconsistent older/neon
assets" satisfied for the room layer.

**P7 [CODE] Travel map / map identity pass (G5).** Minimal plate render + pins that reuse
the existing colored-circle logic (green/blue/gray semantics preserved), plus a single
unambiguous "current" state read. Effort: S-M. Acceptance: travel_map capture refreshed;
state-meaning table documented.

**P8 [CODE] Visual QA gate expansion (sec 1.9 gaps, G10).** Extend `run_visual_shots.py`
to 15 shots (add: night dorm, campus, courtyard, one location w/ markers active, suspect
bedroom w/ new plates) + one context `--night` flag targeting `Scheduler.set_time`.
Effort: S-M (mostly harness bookkeeping). Dependencies: P4/P5 for markers/plates to have
something to capture. Acceptance: baselines committed; diff_report.json shows PASS when
PRs restyled assets change visuals intentionally, FAIL on un-intended drift (proven by a
sabotage-injection test in a test commit).

**P9 [ART] Character scale/read fix (G2).** Bump SprFrames from 32 to 64 px + scene scale
audit (detective 5 px -> 40 px body chip, NPC 16 px -> 48 px option B via camera 2x in
interior scenes). Decides camera zoom vs baked size after a capture comparison like
`docs/visual_redesign_research.md:139` prescribes. Effort: S-M with a visual round-trip.
Acceptance: detective >= 80 px in a bedroom capture; no clipped door/waypoint collisions
in the six suspect rooms; `visual_diff` tolerances updated after baseline refresh.

**P10 [ART+CODE] Portraits upgrade via treatment pass (G7).** Run the existing
`apply_archival_treatment.py` (adjust params for small output) across the 7 SVGs rendered
to PNGs at 2x, unify ink outline + slate/amber background. Effort: S. Acceptance:
interrogation capture refreshed; portraits track visually with plates; no new events or
new loc Ning in asset_manifest.json ("generator re-runnable" equals reproducible).

**P11 [DOC] Art bible / visual guide stub (G1+G9 check, Step 1 Reference row).** One MD
file: palette table (exact hexes from the generator), ink/threshold params, label type
scale, marker shape code, plate pixel size, silhouette rules; cross-linked from
`detective_theme.tres` header comment. Effort: S. Acceptance: any later asset patch can be
verified against it without reading code; CHI-011 rider "update approved visual captures"
has a checklist to test against. (Not mandatory before P1-P3; recommended before P5/P6.)

### Explicitly NOT done in this roadmap (and why)

- **Live 3D rooms / parallax** — measured loss at HEAD hw (sec 1.4 vs sec 3.1 G1 table).
- **Any live shading per room** (shaders + lights) — R5 M330 Vulkan/older risk; plates bake
  day/night into texture pairs (the already-tested pattern).
- **Hand-drawn artist assets** (#G2, G7) — no artist lane, style-drift risk, and roadmap's
  Step 2/acceptance gate prices regeneration in scripts.
- **AI-generated raster art** — provenance gate (:360) + Step 5 QA plus no license path
  currently in `asset_manifest.json`; keep out until an explicit decision is made, which is
  an OPEN QUESTION OQ5 for the discussion board.
- **Replacing the `archival_backdrop.gd` plate approach with per-room TileSet paragraph
  re-theme** — the one-room plate already passes acceptance in-scene; the plate route scales
  with the SAME generator contract; tile re-theme would double the authoring path and
  split QA coverage (two pipelines to verify instead of one).

---

## 5. OPEN QUESTIONS for user approvals (with suggested defaults)

| # | Question | Why it blocks work | Suggested default if no answer soon |
|---|---|---|---|
| OQ1 | **Font choice** for the archival label system (G4/P3): Atkinson Hyperlegible (readability-first, OFL), Inter (UI-familiar), or a display serif (archival flavor, less readable)? Direct trade: readability today (max one lock per sentence: :355 + :542 demand legibility) vs season of flavor | Blocks P3 | Default: **Atkinson Hyperlegible**, rationale: release gate demands legibility over mood; flavor comes from ink/plate style, not font |
| OQ2 | **Scope of the art-bible style lock** (P11): do we write the `art.md` art-bible doc AFTER the three S-tickets land, or earlier as agent time-sink pre-P5? P5/P6 MUST have it | Blocks P5/P6 sequencing, not P1-P3 | Default: write the doc immediately after P3 lands (P5's first plates use the labels to check against) |
| OQ3 | **Where does the archival plate style STOP** (G1/G6 scale-up route): all ~13 rooms plate-style (full uniformity) or as budget plates for the highest-travel rooms only (crestwood_hall, suspect rooms + hallway, kitchen/common/bathroom (interior only), 9 locations stay legacy)? | Blocks P5/P6 scope sizing | Default: ALL rooms move to plates (P5+P6); the legacy tile layer stays hidden behind `archival_backdrop.gd`'s hide-legacy node guards as a removal target AFTER baselines refresh; effort sized at 1-2 evenings per bath of six rooms |
| OQ4 | **Renderer decision** (P2): does the team accept the Compatibility switch if draw calls drop but the draw-level 0.5% pixel diff tolerance breaks (AA differences)? | Blocks P2 merge-out even if switches pass | Default: Compatibility IF the diff passes with a *documented tolerance* change; if it fails structurally, keep Forward+ and revisit with a narrower-renderer note |
| OQ5 | **AI-generated art permission** (explicitly raised by no roadmap bullet but the AI-builder framing; adjacent asset lane): is AI-gen raster art allowed for portraits/props as long as we document it? Today's answer in the repo (no: manifest policy + provenance bullet) stays | Blocks G7 if extended to new art, not the treatment pass | Default: NO new AI-gen art; treatment of generated/3rd-party assets only |
| OQ6 | **Character scale strategy** (P9): baked pixel size vs camera zoom; both change the detective/NPC readability. Which is preferred before I do the capture round? | Blocks P9 round choice | Default: bake 64 px Sheets AND add a camera zoom option; compare captures; pick winner visually |
| OQ7 | **Travel map art style** (P7/P3 undermine): stylized plate (campus mini render) OR flat archival document palette with pictogram pins? | Blocks P7 | Default: flat archival palette w/ documented pins (cheapest; plate map only if it reads poorly at 720p based on captures) |
| OQ8 | **Who owns the visual QA gate tolerance matrix** when plates upgrade (gap: 0.5% scene / 24/255 pixel is tight for plate swaps): increase scene tolerance for intentional plate swaps, or refresh the whole frame per scene to a new baseline? Wording question for all P4-P10 acceptance criteria | Blocks P4/P7/P9 acceptance criteria wording | Default: intentional visual change => NEW baseline captured in the same PR (the CHI-011 verbatim: "update approved visual captures"); unintentional drift => failure stays at current values |

## 6. SUMMARY (the answer in ten lines)

1. **The game is 2D isometric**, not 3D first-person (brief error). 3D exists only as a
   rejected prototype spike on this hardware; art lies through Blender-generated plates,
   props and sheets - all scripted-blender, no .blend files, fully scripted.
2. At HEAD (`4fad7eb`), the **Archival Cutaway redesign exists and shines but covers ONE
   interior** (Crestwood Hall dorm); everything else ~13 rooms still shows legacy
   tan-tile/ColorRect "chunks" and the general UI uses a placeholder-grayscale map.
3. **Characters are 32x32 chips at 5-16 px on screen** vs the documented 80-110 px
   readability demand; portraits are 7 generic SVG icons.
4. **No font file exists anywhere** (engine default), no label template, no
   archival typography system; travel map is gray circles. This is CHI-011 + roadmap
   bullet 1 verbatim.
5. **The provenance gate is already broken**: ~199 untracked asset files, an
   external_assets: [] manifest, third-party piles without license notes; fresh clone of
   the current tag cannot render the courtyard/campus/bedroom props/portraits.
6. **No evidence/backdrop markers exist in live scenes** despite the hero prototype having
   the exact amber-diamond pattern designed (tested only in a prototype capture); the
   README claiming "magnifier markers" is aspirational, not implemented.
7. Night exists for exactly one painted room; the QA gate takes no night captures,
   no location captures; 10/10 local `PASS` with 0.000% drift at HEAD is masked by this
   narrow coverage; none of the gate runs in CI.
8. The roadmap's five art rough edges (labels/typography, day/night per-room,
   evidence markers, pacing visuals, provenance) map onto this gap list 1:1; the
   acceptance gate text prices new art in regeneration + scene QA, not new files.
9. **The cheapest high-impact path order**: commit/track/license assets (P1), validate
   renderer on real GPU (P2), label/typography system (P3) -> markers (P4), per-room
   day/night plates via the existing generator (P5/P6), map pass (P7), QA widen (P8),
   character size (P9), portrait treatment (P10), art bible (P11).
10. Hardware reality anchors every choice: 2 cores, R5 M330 2 GB, 7.5 GB RAM => paper-/
    texture-swap plates beat any live pipeline (measured live 3D = 137 draws/61,618 prims
    on ONE room). The plate-based generator route is both the cheapest path and the one
    most likely to hold.

### Biggest blocker / surprising finding (for the report-back)

- **Biggest blocker:** nothing is actually blocked by a missing tool - the block is a
  DECISION layer (OQ1/OQ3/OQ4/OQ6 style-lock scope, font, renderer, character scale) plus
  the G8 tech-debt chop-block: untracked assets break fresh clones and the provenance
  audit right now.
- **Surprising finding:** the README_ENVIRONMENTAL_PASS.md under `godot/` CLAIMs working
  "magnifier + green evidence marker" implementations, but zero marker code exists anywhere
  in `godot/scripts` - the "magnifier evidence layer" from the PR pass was never written;
  the ONLY designed marker lives in the hero prototype scene (`archival_cutaway_hero.gd`,
  graded approved-for-prototype) and has never been wired into another scene. Any
  documentation of completed work in this area is fiction until P4 lands.
