# Plan — Individual Suspect Bedrooms + Daniel's Locked Room

> Status: draft for review, not yet built. Sequenced after perimeter walls + brighter floor tint
> (done, `plan-floor-tileset` branch). Third of four slices from the 2026-07-14 "walls, rooms,
> buildings, roads, zoom" conversation — see HANDOFF.md for the other three.

## Goal

Right now the 6 suspect bedrooms are just `Marker2D` points inside Crestwood Hall's one open
floor — no walls, no distinct room, `SearchData` points spawn as floating hotspots near the
marker. Turn each into a real enterable room, and add a 7th room — **Daniel's** — that starts
locked and requires taking a master key off Alex first.

## Why this reuses almost everything already built

- `LocationManager.LOCATIONS` already treats a "place" as `{name, scene, travel_hours}` — a
  bedroom is just 7 more entries, same shape as the existing 4.
- `DoorTrigger` (`scripts/player/door_trigger.gd`) already does exactly "walk into me, load
  another location" — `main.gd:71-72` generically wires up **any** `DoorTrigger` found in whatever
  scene is loaded, not just Crestwood Hall's. A bedroom scene's own exit door needs zero new
  wiring code.
- `Investigation.is_discovered(id)` / `discover_clue(id)` is already a persisted boolean-flag
  store. Reusing it as "do you have the key" needs no new inventory system — a locked door just
  checks `Investigation.is_discovered("item_master_key")`.
- `SearchData` already keys points by `"room": "bedroom_1"` etc. — the room IDs don't change, only
  which scene hosts them.
- **The master key is already half-written.** `SearchData.POINTS["alex_desk"]`'s `look_under`
  action flavor text already says: *"A tangle of charging cables and a master-key lanyard hung on
  the chair."* — currently `reveal_clue: ""`. Wiring that to `reveal_clue: "item_master_key"` is a
  one-line change that turns existing flavor text into the key, rather than inventing a new prop.
  It also lines up with the story bible's true timeline (Alex used master keys that night for a
  mundane reason) — searching Alex's desk for the *key* is thematically the same beat as the
  in-fiction reason Alex had access at all.

## What's new

1. **`LockedDoorTrigger`** (`scripts/player/locked_door_trigger.gd`, extends `DoorTrigger`):
   `@export var required_clue: String`. `interact()` checks
   `Investigation.is_discovered(required_clue)` — if false, logs a "locked" message via `EventLog`
   and does *not* emit `door_triggered` (so no scene transition happens); if true, behaves exactly
   like `DoorTrigger`. `get_prompt()` returns `"Locked"` when the condition isn't met.
2. **One shared bedroom scene, six thin instances.** A `bedroom_base.tscn` (floor/walls/nav
   region/exit-door, same shape as `detective_room.tscn`) holds the common structure; 6 small
   scenes (`bedroom_alex.tscn` … `bedroom_casey.tscn`) inherit it and set a distinct floor tint +
   `suspect_id`, matching the "one template, per-suspect data" pattern already used for
   `npc.tscn`/`NpcProfile`.
3. **`daniel_room.tscn`** — same shape, but reached only via a `LockedDoorTrigger` with
   `required_clue = "item_master_key"`.
4. **`crestwood_hall.gd` changes**: `_spawn_search_points()` currently spawns every `SearchData`
   point (all rooms) into itself; it needs to skip `bedroom_*` room IDs once those points move to
   living inside the bedroom scenes themselves. Each bedroom scene's own `_ready()` spawns just its
   own room's points, reusing the same `SearchPoint` scene/pattern.
5. **Bedroom markers become doors.** Each `bedroom_N` `Marker2D` in Crestwood Hall gets a sibling
   `DoorTrigger` (`dest_id = "bedroom_alex"`, etc.) at the same position, so walking to where a
   bedroom marker already is now actually enters the room instead of just being an NPC-schedule
   waypoint. `AccessData`'s existing time-gate + owner-presence rule still governs whether entering
   counts as trespassing (unchanged — that logic lives in `crestwood_hall.gd`'s `_check_sneaking`,
   keyed off `_room_at(detective.global_position)`, which will need the same treatment: once the
   detective is inside a separate bedroom scene, "am I in a restricted area" has to be evaluated
   there too, not just inside Crestwood Hall's `_process`).

## What's in Daniel's room

Not the accident site (the story bible places that at "a maintenance/utility nook or a window
ledge" — a different, still-unbuilt location, out of scope here). Daniel's own bedroom is instead
where his hidden layers live: this is the natural place to seed 2-3 new `SearchData` points
revealing pieces of his double life, the quiet scheme, and the self-medication — the three threads
the story bible's victim section lays out. Exact clue text is a writing task, not a systems one;
proposing to draft 2-3 search points here as part of the build task, same authored-flavor-text
style as everything else in `SearchData`.

## Build order (own tasks, TDD + playtest checkpoint per project convention)

1. `LockedDoorTrigger` + test (mirrors `test_door_trigger.gd`).
2. `bedroom_base.tscn` + one real inherited scene (Alex's) end-to-end: door in Crestwood Hall →
   enters → search point works → exit door returns. Playtest checkpoint before repeating ×5.
3. Remaining 5 bedrooms (mechanical repeat of step 2).
4. `daniel_room.tscn` + wire `item_master_key` onto `alex_desk`'s `look_under` action + author its
   2-3 search points.
5. Move `_check_sneaking`'s restricted-area check so it applies inside bedroom scenes too, not just
   Crestwood Hall's open floor (needed so trespassing/catch mechanics still fire once bedrooms are
   separate scenes).
6. Full regression + human playtest (per-suspect room readable, key found on Alex, Daniel's room
   locked until then, unlocks correctly after).

## Open call for the user

- Confirm the master-key-via-Alex's-desk approach (vs. some other source).
- Confirm Daniel's room = double-life/scheme/self-medication clues, not the accident site itself.
- OK to draft placeholder clue text for Daniel's room as part of this build, subject to a later
  editing pass, rather than blocking on final prose now.
