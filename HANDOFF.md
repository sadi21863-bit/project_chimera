# Project Echo — Shared Coordination Document

**This project is being built across two Claude surfaces at once, working in the same local
folder:**
- **Claude Code** (this VSCode-extension session, or any terminal Claude Code session) — full
  native file read/write, runs the Godot headless tests, does all the GDScript/scene implementation.
- **Claude Desktop** — connected to Blender via the Blender MCP connector for posing/rendering the
  CC0 3D character models into 2D sprites. **Also has direct local filesystem access** via
  filesystem MCP / Desktop Commander MCP / Windows MCP (configured by the user) — so it can read
  this file itself, browse the codebase, and potentially edit project files directly, not just
  export renders through Blender.

**Because both surfaces can now read/write files in this same folder, don't run both at once on
overlapping work** (e.g., both editing `godot/` at the same time) — treat it like two developers
sharing a working tree without a lock. Finish a piece of work, update the log, then hand off.

**If you are either one of these, starting a session on this project: read this whole file first.**
Then, before you finish your session, **append a dated entry to the Progress Log section below**
(newest at the top) — a few lines on what you did and what you're leaving for the other surface to
pick up. This is the only channel the two surfaces have to know what the other has done, since they
don't share memory or a runtime — treat this file as the handoff baton.

## Progress Log (append newest entries at the top)

- **2026-07-14, Claude Code**: Two follow-up passes after user feedback that the outdoor campus
  read as unfinished "AI slop" and after the goal-tracking hook flagged the interior-walls item
  below as not actually done (it had been logged as a deliberate deferral, not a completion).
  1. **Campus backdrop rework**: replaced the individually-placed flat building sprites (2017-era
     Buildings pack, flat grey/black materials that didn't come through Blender's FBX import with
     any color) with ONE composed backdrop image — a small city block assembled from Kenney's
     Starter Kit City Builder (`asset dump/Starter-Kit-City-Builder-main.zip`, sitting unused since
     it was first flagged as the intended campus seed) and rendered via Blender: roads, 3 properly-
     textured/colored buildings, grass, trees. Composing many small GLTF tiles into one Blender
     scene and rendering it as a single image, rather than placing separate sprites in Godot,
     turned out to matter a lot for visual coherence.
  2. **Interior walls, for real this time**: the previous entry said kitchen/hallway/bathroom being
     unwalled was "not broken, just unstarted" and left it there — the goal-tracking hook correctly
     called that out as incomplete. Built it, and along the way found and fixed a real bug in the
     nav-mesh technique used by *both* this and the earlier bedroom-corridor work: hand-appending
     separate `.polygons`/`.vertices` arrays per convex piece never actually produces a connected
     navmesh in Godot 4.7, no matter how exactly the coordinates line up or how much the pieces are
     made to overlap — confirmed via `NavigationServer2D.map_get_path()` reproducibly returning
     paths that dead-end exactly at the first polygon's edge. The fix: build a single outline (walls
     as notches carved directly into it where they touch the outer boundary, ordinary holes — same
     winding as the outer outline, not opposite — where they don't) and call
     `NavigationPolygon.make_polygons_from_outlines()`, letting Godot's own triangulator produce
     properly vertex-shared, actually-connected polygons. Full technique writeup + gotchas are in
     the `add_interior_walls.gd` file header. Practical consequence, confirmed directly: before the
     fix, an NPC forced away from their bedroom during a headless test got physically stuck at the
     new wall; after, they walk the real full path home and simply run out of time before the
     test's catch-window closes.
  3. Scaled the interior-walls design down from an original 4-room plan (kitchen/hallway/bathroom
     each separately walled) to one wall with one gap (kitchen/hallway/bathroom stay one connected
     space, just now separated from the common room) after hitting a second, narrower
     NavigationPolygon limitation: holes that touch each other at a T-junction (a vertical divider
     meeting a horizontal one) make the triangulator fail outright. Smallest working slice over a
     fragile larger one — the 4-room version is a reasonable future improvement once someone wants
     to hand-solve merging touching holes into single combined shapes.

  51/51 tests throughout both slices.

- **2026-07-14, Claude Code**: Two more small slices on top of the three below, closing out the
  rest of what was tracked as unfinished. Both merged, 51/51 throughout:
  - **Shared UI theme**: the last unchecked item from the original hybrid art pipeline plan. Same
    situation as the floor tiles turned out to be — no visual Kenney UI Pack was actually
    downloaded into `asset dump/` (only `kenney_ui-audio.zip`, which is sound), so
    `godot/tools/build_ui_theme.gd` generates a `Theme` procedurally (`StyleBoxFlat` panels/buttons,
    warm dark palette matching the detective-noir tone) instead of waiting on another download.
    Applied via `[gui] theme/custom` in `project.godot` — edited that file with a surgical text
    insert, not a `ConfigFile` load/modify/save round-trip of the whole file, since the latter risks
    reformatting sections (like `[autoload]`) it has no business touching.
  - **Campus trees**: 8 trees (headless-rendered from the Textured Stylized Trees pack) scattered
    around the outdoor campus for atmosphere — purely cosmetic, no collision.

  Still left, deliberately not done: interior dividing walls for Crestwood Hall's open
  kitchen/bathroom/common-room area. Unlike the bedroom corridor (added because a real user
  complaint made the doors read as floating triggers), nothing here was reported broken, and
  retrofitting walls onto that space means reconciling 4+ existing marker/door positions plus a
  multi-polygon nav-mesh rebuild (see the corridor entry below for why that's needed, not optional)
  across a well-tested, already-shipped area — a real risk of a subtle regression for a purely
  cosmetic gain. Worth doing eventually, but as its own careful slice, not a rushed add-on.

- **2026-07-14, Claude Code**: Finished the rest of the hybrid art pipeline plan and then kept
  going past it. Three more slices, each its own branch, tested, merged to `main` (51/51
  throughout):
  1. **Floor tileset + perimeter walls**: no CC0 pack in `asset dump/` actually contains floor/wall
     tiles for this game's straight top-down camera — `kenney_roguelike-indoors` looked like it did
     from a low-res thumbnail but turned out to be furniture-only on close inspection (chairs,
     beds, kitchen units, all on transparent tiles, no floor/ground graphics anywhere in the sheet).
     Rather than wait on another download, generated a simple tileable floor texture procedurally
     (`godot/tools/build_floor_tiles.gd`) and gave every location `StaticBody2D` perimeter walls —
     previously nothing stopped the player from walking off the edge of a room's floor into empty
     space, since the Detective is a plain WASD `CharacterBody2D` that never reads the
     `NavigationPolygon` (NPC-pathfinding only). Floor tint brightened per user feedback after the
     first playtest (was near-black; each location's original dark `ColorRect` color is preserved as
     a `TileMapLayer.modulate`, just brightened).
  2. **Enterable suspect bedrooms + Daniel's locked room + a corridor**: the 6 `bedroom_N` markers
     inside Crestwood Hall are now real `LocationManager` locations (reuses the existing
     `{name, scene, travel_hours}` shape — no new location concept needed), plus a 7th: Daniel's
     room, locked until the player takes a master key from Alex's desk (wiring flavor text that
     already existed — "a master-key lanyard hung on the chair" — to actually grant
     `item_master_key`, checked via a new `LockedDoorTrigger` that reuses `Investigation`'s
     discovered-clue store as a lightweight inventory check, no new item system). Daniel's room
     holds 3 new lore-only clues (double life / the quiet scheme / self-medication, straight from
     the story bible's victim section) — case-strength-neutral like the existing ghost-master red
     herrings, not wired into `CaseData.CLUES`. Also fixed a real regression: Crestwood Hall's
     trespassing/catch check only ran while that scene was loaded, so it silently stopped applying
     the instant the detective stepped into a bedroom's own separate scene — each bedroom now runs
     its own version, deriving "is the owner home" from their authored schedule (no live NPC exists
     in a bedroom's own scene to check proximity against). User feedback after first pass: the
     bedroom doors read as disconnected triggers floating in open floor space — added a walled
     corridor along the bedroom row (`godot/tools/add_corridor.gd`) and rebuilt Crestwood Hall's
     `NavigationPolygon` into three linked rectangles (above the wall / the door gap / the corridor)
     so NPCs pathing to their bedroom marker route through the gap instead of physically getting
     stuck on the new wall — this part is easy to miss (nav mesh and physics collision are separate
     systems in Godot; adding a wall doesn't teach the nav mesh anything).
  3. **Outdoor campus + camera zoom fix**: a new "campus" location — grass + a road `TileMapLayer`
     connecting Crestwood Hall, the University, and the Police Station, each now a static top-down
     sprite (headless Blender render of Kenney's *Buildings pack*: Hospital/Bank/Flat models
     reskinned as police station/university/dorm exteriors) instead of nothing at all. All three
     interiors gained a `DoorTrigger` to campus; the existing fast-travel map needed zero new code
     since it's already fully data-driven off `LocationManager.LOCATIONS`. Also: camera zoom
     existed (`ZOOM_MIN`/`ZOOM_MAX`, mouse wheel) but only worked in the separate free-fly Observer
     mode — `main.gd`'s zoom handler always zoomed its own `Camera2D` regardless of which camera the
     viewport was actually showing, and that one is disabled during normal play. Fixed to zoom
     `get_viewport().get_camera_2d()` instead.

  **Left for next time**: interior walls for Crestwood Hall's kitchen/bathroom/common-room (they're
  still one open floor with just labels, no dividing walls — lower priority than the bedroom
  corridor since nothing there was reported broken). The UI theme and campus decoration mentioned
  here were done in a follow-up pass the same day — see the entry above this one.

- **2026-07-14, Claude Code**: **The Blender MCP blocker is resolved — differently than planned.**
  Blender MCP still won't connect from this surface either (`claude mcp list` still shows
  `blender: ✗ Failed to connect`), but Blender 5.1 is installed locally and can be driven
  **headlessly** via `blender.exe --background --python <script>`, no MCP connector needed at all.
  User approved a **hybrid split**: headless scripting (this surface) does the bulk automated
  pre-rendering; Claude Desktop's live Blender MCP is kept for interactive spot-checks/pose tuning
  if something needs a human-in-the-loop touch-up. Built `godot/tools`-adjacent script (currently
  in scratch, not yet committed into the repo proper — see below) that: imports a Kenney
  Mini-Characters GLB, strips the non-rigged "Icosphere" light-probe helper object Kenney embeds in
  each file (was polluting bounding-box/render — filtered by checking for an Armature modifier),
  fixes armature rotation (glTF import leaves `rotation_mode` as quaternion, so naively setting
  `rotation_euler` was a silent no-op — script now forces `rotation_mode = "XYZ"` first), frames an
  orthographic camera at a shallow ~30° elevation (55° was too steep and let the oversized
  toy-block head occlude the whole body), and renders idle-facing-down (1 frame) + 4-directional
  walk cycle (6 frames each, sampled from the pack's built-in baked `walk` action) as transparent
  256×256 PNGs. **Validated on the Detective first** (composited a frame-by-frame grid to visually
  confirm the walk cycle actually animates — it does, arms/legs swing correctly), then batch-rendered
  the remaining 7: alex (female-a), jordan (male-b), sam (female-b), riley (male-c), morgan
  (female-c), casey (male-d), dean (female-d) — all from `kenney_mini-characters.zip` in
  `asset dump/`, all distinct models, all CC0. All 8 are now in `godot/assets/characters/<id>/`.
  Built `godot/tools/build_sprite_frames.gd` (headless-runnable via `-s`) that turns those PNG
  folders into `SpriteFrames` .tres resources in `godot/resources/sprite_frames/`. Wired it all the
  way through: `NpcProfile.sprite_frames` field added, `NpcProfileFactory` and the dean's ad-hoc
  profile in `university.gd` both load the matching `.tres`, `npc.tscn`/`detective.tscn` swapped
  their `ColorRect` for `AnimatedSprite2D` (named `Sprite`, matching the plan doc), `npc.gd`/
  `detective.gd` pick `walk_down/up/left/right` vs `idle_down` from movement direction each physics
  frame. Added `test_npc_sprite_frames.gd` (asserts every profile + the detective has all 5
  required animations) — **50/50 tests pass** (49 existing + 1 new), no regressions. On branch
  `plan-character-sprites`, not yet merged to `main`. **Left for whoever picks this up next**: the
  sprite scale (`0.15`) and vertical offset (`-20`) on both `AnimatedSprite2D` nodes are my best
  estimate from the render geometry, not yet eyeballed in a live playtest — I launched the real
  (non-headless) game at the end of this session for that check but didn't get to see the result
  before writing this entry. Also not yet done: the tile/floor and UI-theme parts of the plan doc. The render script itself is
  now at `godot/tools/render_character.py` alongside `build_sprite_frames.gd`, so the whole
  render → wire pipeline is reproducible from a repo checkout (given Blender 5.1 + Godot 4.7
  installed locally) — invoke as `blender --background --python godot/tools/render_character.py --
  <glb_path> <char_id> <out_dir>` (add `--dirtest` to sanity-check the direction mapping before a
  full run on a new model).

- **2026-07-13, Claude Code**: User bulk-downloaded ~40 extra CC0 asset packs into `asset dump/`
  (Kenney + Quaternius, all audited and confirmed CC0 1.0 Universal; two "Starter-Kit" zips turned
  out to be Kenney's own official Godot templates, MIT licensed). Full category breakdown is in
  chat history. One approved follow-up beyond the current art plan: an **outdoor campus** location,
  seeded from `Starter-Kit-City-Builder-main.zip` (a complete pre-built, already-imported Godot
  scene) plus the exterior-suited packs (Buildings pack, Ultimate Textured Building Pack, Public
  Transport Pack, Textured Stylized Trees, Ultimate Nature Pack, `kenney_retro-urban-kit.zip`) —
  **sequenced after the indoor art pass below is finished, not before.** See the "Approved
  follow-up" section in `docs/superpowers/plans/2026-07-13-plan-hybrid-art-pipeline.md`.

- **2026-07-13, Claude Code**: Wrote this document. Nothing rendered yet — Blender 5.1.2 is
  installed and the BlenderMCP addon is running (was showing port 9876 in this session), but the
  Blender MCP connector needs Claude Desktop specifically (see "Why this handoff exists" below).
  User has confirmed Claude Desktop has filesystem access (filesystem/Desktop Commander/Windows
  MCP), so it can read this file directly instead of needing context pasted inline. Godot project
  itself is fully built and tested (49/49) up through the Consequences/World/Access slices — see
  "Everything that's built" below. Next concrete action is on Claude Desktop: connect to the
  running Blender server, download the Kenney + Quaternius asset packs if not already done
  (kenney.nl/assets/mini-characters, quaternius.com, kenney.nl/assets/furniture-kit,
  kenney.nl/assets/ui-pack), and start rendering the 9 characters per the spec below — one
  character (the Detective) first, to validate the render style/export path before doing all 9.

## What this is

**Project Echo** (repo name "project-chimera") is a Godot 4.7 (GDScript) detective-mystery dorm-sim.
A rich, influential student (Daniel) dies in a college dorm; police call it accidental; the family
overrules them and hires the player as a detective. The core twist, revealed only at the very end:
**it was always an accident.** Every accusation ending convicts an innocent person — a flashback
recolors each clue as innocent after the player commits to naming a suspect. The only "correct"
ending is calling it an accident at the very start, which the player doesn't know until it's too
late to matter emotionally.

Full narrative bible: `docs/superpowers/specs/2026-06-23-project-echo-story-bible-design.md`.
Systems design blueprint: `docs/superpowers/specs/2026-06-23-difficulty-world-stealth-design.md`.

## Everything that's built (all merged to `main`, all tested)

- **Core loop**: First Choice (accident/murder) → free-roam investigation → evidence-gated
  accusation → suspect-specific wrong ending + flashback truth-reveal, OR a forced game-over.
- **Hybrid AI for NPCs**: `AIClient` autoload routes AUTO → SERVER (Python/Ollama, separate
  `ai-server/`) → LOCAL (NobodyWho GDExtension, embedded llama.cpp) → RULE_BASED fallback.
- **Living dorm sim**: 6 NPCs (suspects) each on individual daily schedules, NavigationAgent2D
  movement, a day/night `Scheduler`.
- **Difficulty system** (`Difficulty` autoload): easy/medium/hard/extreme presets parameterize
  deadline length, catch model, consequence severity, risk-hint visibility — every other system
  reads from this rather than hardcoding its own logic.
- **World**: 13 locations via `LocationManager` + a `LocationHost` scene-swap host in `main.tscn` —
  dorm (Crestwood Hall), detective's room, police station, university, the 6 suspect bedrooms,
  Daniel's (locked) room, and an outdoor campus connecting the first three; fast-travel map (M key,
  marks unvisited locations, fully data-driven off `LocationManager.LOCATIONS` so new locations
  never need UI changes) *and* walk-through-door connections between most of them.
- **Detailed examination**: `SearchData`-driven multi-action object search (look under/dig/open),
  each action flavor text + optional clue, with a `risk` field.
- **Access + sneaking**: `AccessData` (time-gated + owned private rooms), `RiskAssessor`
  (Safe/Risky/Dangerous), `CatchModel` (off / suspicion-meter / vision-cone+proximity by difficulty).
- **Consequences**: `Consequences` autoload — strikes from getting caught trespassing *or* a
  botched risky search, a deadline that forces a game-over, and (Extreme only) a thematically-safe
  death ending for deep-night trespassing (mirrors the victim's own accident — never implies a real
  killer, preserving the twist).
- **Interrogation**: trust-gated topics + "present evidence" reactions, data-driven per suspect
  (`InterrogationData`), plus a lore-only, non-accusable university dean NPC and two hint-giver
  sources (Casey, Jordan).
- **Subplots**: a ghost-master/media-pressure red herring (Jordan's paid fake hauntings), family/
  police interference content at the station — all flavor-only, none affect case strength.
- **Save/load**: `SaveManager` (a hand-rolled Locker-API-compatible stub, not the real third-party
  addon) bundles `Scheduler`/`EventLog`/`GameFlow`/`Consequences`/`LocationManager`/`CaseFile`/dorm
  NPCs. `Standing`/`Investigation`/`Difficulty`/`LocalMemory` self-persist independently to their
  own `user://*.json` files — a known, accepted inconsistency, not a bug.
- **~51 headless tests** in `godot/tests/*.gd`, including one full end-to-end playthrough test.
- **Art**: all 9 characters (detective + 6 suspects + dean) have idle + 4-directional walk-cycle
  sprites (Blender-rendered from Kenney Mini Characters, CC0); every location has a tiled floor +
  perimeter walls; the 3 street-level buildings have rendered exteriors + tree decoration on the
  outdoor campus; a shared UI theme applies project-wide. Not yet done: interior dividing walls for
  Crestwood Hall's open kitchen/bathroom/common-room area (not broken, just unstarted).

## How to run things

- Import/verify after any change:
  `"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" --headless --path godot --import`
- Run one test: `... -s res://tests/<name>.gd` (prints `PASS:`/`FAIL:`, exits with failure count)
- Run everything: a `run_all_tests.sh` pattern iterating `godot/tests/*.gd` with a ~25s per-test
  timeout works well (some tests need `_process()`-deferred timing — see below).
- Playtest for real: same executable without `--headless --path godot -s ...` (the plain
  `Godot_v4.7-stable_win64.exe --path godot` launches the actual game).

**Gotcha worth knowing**: a bare `SceneTree`-extending test's `_initialize()` runs *before*
autoloads' `_ready()` fires — any test that depends on cross-autoload signal wiring (most of them)
needs the `_process()`-deferred pattern (`_done` flag, act on the first `_process` call instead of
in `_initialize()`), not `_initialize()` directly. Grep any existing test (e.g.
`test_consequences.gd`) for the exact shape.

## Working conventions established this whole project (please keep these)

- **superpowers workflow**: brainstorm → write a plan doc under `docs/superpowers/plans/` →
  execute task-by-task with TDD (failing test → implement → passing test → commit) → full
  regression → human playtest checkpoint for anything UI/visual/risky → merge to `main` locally,
  delete the branch, re-verify the full suite on `main`. One git branch per slice.
- The user prefers **merge locally** (not push/PR) every time it's come up.
- Always confirm scope/risk before destructive git ops; never force-push, never rewrite history
  without explicit permission (a stray 78MB DLL backup file made it into history once — it was
  removed going forward and gitignored, but the blob wasn't purged from past history, since that's
  a destructive rewrite the user didn't ask for).
- Don't over-scope: several slices deliberately cut things (e.g., "botched intrusive search"
  strikes only came later as its own small slice; walk-through doors got exactly one connection as
  a proof, not a full network) — match this "smallest coherent slice" instinct rather than
  gold-plating.
- Art/visual polish was explicitly deferred for most of this project ("we can do the art thing
  later") — that phase has now started (see below).

## Current phase: mostly done — one piece left (UI theme), plus optional polish

The hybrid 2D/3D art pipeline (full plan: `docs/superpowers/plans/2026-07-13-plan-hybrid-art-pipeline.md`)
is done except the shared UI `Theme`. The "Why this handoff exists" blocker below is **resolved** —
turned out headless `blender --background --python <script>` works fine from this surface, no MCP
connector needed; see the 2026-07-14 log entries above for what actually got built. Left as
historical record since the reasoning (why Claude Desktop was the original plan) may still matter
if a future session wants live/interactive Blender work. Original plan summary, for reference:

- **Everything is CC0** (public domain — no attribution, no commercial restriction, no share-alike)
  per the user's explicit requirement ("no problem for us to use in any way"): Kenney's Furniture
  Kit + Isometric/Library tiles + UI Pack for 2D environments/UI; Kenney's Mini Characters (primary)
  or Quaternius (supplement, more variety + pre-rigged animations) for 3D character models.
- **Technique**: pre-render the CC0 3D character models into 2D sprite sheets (via Blender) rather
  than live 3D-in-2D rendering — keeps runtime cost identical to plain 2D sprites, important given
  the target hardware is known-weak (AMD A9-9420, 2 cores, 1.7GB VRAM GPU — see the local-AI
  performance-ceiling finding below).
- **Codebase audit already done** (see the plan doc for full detail): no test asserts on sprite
  visuals, so the swap is safe. `detective.tscn`'s `Sprite` (ColorRect) has zero code dependencies —
  direct swap to `AnimatedSprite2D`. `npc.gd`'s `_sprite.color = p.color` is the one real code
  dependency — plan is to add `sprite_frames: SpriteFrames` to `NpcProfile`
  (`godot/resources/npc_profiles/npc_profile.gd`) and set that instead, keeping `color` as a
  harmless fallback. Room floors (currently flat ColorRects) become `TileMapLayer`s from the Kenney
  tile packs. No UI scene sets an explicit `Theme` — one shared Kenney-UI-Pack `Theme` resource
  applied project-wide is the plan.
- **Character rendering spec**: 9 characters total (detective + alex/jordan/sam/riley/morgan/casey +
  the dean) each need idle-facing-down + a 4-directional walk cycle (~4-6 frames each), orthographic
  top-down, transparent background, consistent scale across all 9.
- **Folders already scaffolded**: `godot/assets/{tiles,ui,characters}` (empty, ready).

### Why this handoff exists (the actual blocker)

The plan was to drive Blender live via the official Blender MCP connector
(github.com/ahujasid/blender-mcp) — `uvx`/`uv` are already installed, the connector was registered
via `claude mcp add blender -- uvx blender-mcp`, and the user got the addon running in Blender 5.1.2
(port 9876). **But the Claude Code VSCode-extension environment this session ran in does not
support arbitrary local stdio MCP servers** — only 5 pre-configured connector/plugin-style servers
ever showed up in `/mcp` or `claude mcp list`, and `blender` was invisible to both even after a
restart. The registration is still sitting (harmlessly, inertly) in `.claude.json` — not worth
manually excising, it does nothing there.

**The plan going forward**: continue this in **Claude Desktop**, where the Blender MCP connector is
the intended, supported client. Blender should already have the addon installed and the server
startable (port 9876 last time). Once connected there, the next concrete steps are:

1. Download the asset packs listed above (Kenney + Quaternius) if not already done.
2. Pose/render each of the 9 characters per the rendering spec.
3. Export sprite sheets into `godot/assets/characters/<npc_id>/`.
4. Build `SpriteFrames` resources, wire into `NpcProfileFactory` (and the dean's ad-hoc profile in
   `university.gd`) via the new `NpcProfile.sprite_frames` field.
5. Build a `TileSet` from the tile packs, swap it into each location's floor.
6. Build and apply the shared UI `Theme`.
7. Each of the above as its own small tested slice, following the conventions above — TDD where
   there's logic to test (the `sprite_frames` wiring), playtest-and-eyeball where it's pure visual
   (the tileset, the theme).

## Known issues / things to keep in mind

- **Local AI has a real performance ceiling on this hardware**, found by empirical testing (not
  guessed): forcing `NobodyWhoModel.use_gpu_if_available = false` fixed the actual freeze/crash
  (GPU offload to the 1.7GB-VRAM GPU was the cause), but a single NPC decision still doesn't
  complete within 90+ seconds of real generation against the actual game's prompt on this 2-core
  CPU. The model file is deliberately left in `godot/models/disabled/` (not the active
  `godot/models/` path) so headless tests stay fast — moving it back is a manual, deliberate step
  for playtesting AI behavior specifically, not something to do by default.
- `Standing`/`Investigation`/`Difficulty`/`LocalMemory` bypass `SaveManager` entirely (their own
  JSON files) — a known inconsistency, low priority to unify.
- The real third-party "Locker" Godot addon was never adopted; `godot/addons/locker/save_manager.gd`
  is a hand-written stub matching its API shape.

---

**Reminder to whichever Claude is reading this**: add your entry to the Progress Log at the top of
this file before you finish your session, so the other surface (and the user) can see what changed.
