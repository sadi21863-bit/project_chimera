# Design — Difficulty, World, Detailed Examination, Sneaking & Consequences

> Status: design blueprint for the heavy slices (world expansion, access/sneaking, consequences,
> detailed examination). No code yet — this is the spec the build slices implement against.

## 0. The unifying idea: difficulty drives everything

Every "hybrid" decision is resolved by a single **Difficulty** config. The player picks a mode
(and can fine-tune individual settings). The mode sets the parameters that every other system
reads; **situation and location can override** within the mode.

| Parameter | Easy | Medium | Hard | Extreme |
|-----------|------|--------|------|---------|
| **Deadline** | none | 14 days | 10 days | 7 days |
| **Catch model** | off (free roam) | suspicion meter | vision + proximity | vision, tighter cones |
| **Consequence ceiling** | standing only | can be fired | fired (fewer strikes) | fired **+ possible death** |
| **Risk hints** | explicit ("RISKY") | shown | subtle | hidden — you judge |
| **Careless search** | always safe | minor risk | risky if seen | risky, faster detection |
| **Strikes before fired** | n/a | 5 | 3 | 2 |

A `Difficulty` autoload holds these as fields; a "Settings" screen lets the player pick a preset
or override any single field (your "changeable in settings"). Every system below reads from it —
so we build the systems once and difficulty tunes them.

## 1. World & travel

**Locations (each its own scene):**
- **Crestwood Hall (dorm)** — exists; gets enterable bedrooms + washroom (Section 2).
- **Police station** — your allies/antagonists; where accusations are weighed (ties to Plan B/D).
- **Detective's room** — your hub: case board, rest (advance time), difficulty/settings.
- **University** — the victim's double-life paper trail, the dean/advisor.

**Travel = hybrid, settings-selectable:**
- **Default — fast-travel map:** a map screen; click a location to load it. Simple, scales, testable.
- **Optional — walk-through:** walk to an exit door that loads the adjacent area (toggle in settings).
Travel **costs time** (advances the Scheduler), which matters once a deadline exists.

## 2. Detailed examination

Examining becomes **multi-step**, not one tap. Each room/scene has **search points** (objects),
and each object offers **actions**:

- **Look under** (bed, rug, desk) · **Move/Shift** (furniture, boxes) · **Open** (drawer, locker,
  fridge) · **Search** (pockets, bag, bin).

Each action resolves to one of: *nothing*, *a clue* (`Investigation.discover_clue`), or *a flavor
note*. Data lives in a `SearchData` table: `location -> [ {object, action, label, reveal_clue, risk} ]`.

**Risk on examination:** some actions are **intrusive** (opening someone's private drawer, searching
a bag). Doing them is fine in **public/owned** space or when **no one's watching**, but in a
**private room** while a witness is near (or after hours) it's a **risky** action — see Section 4.
This is where "look under / move / open" meets the sneak layer.

## 3. Access rules (time-gated areas)

Each location/room has an **access window** (open/close hours) and an **ownership** (public, or a
specific NPC's private space):
- Public during the day (common room, kitchen, station lobby, university halls).
- Private/closed after hours (bedrooms, evidence room, dean's office).

Entering an area **outside its window**, or doing an **intrusive search in a private space**, is
**trespassing**. Trespassing is allowed — but it's where getting caught lives.

`AccessData`: `area_id -> { open_hour, close_hour, owner }`. A helper `is_restricted(area, hour,
owner_present)` returns whether being there right now is a violation.

## 4. Sneaking, risk assessment & getting caught

**Risk assessment (the "is this risky" UI):** before/while acting, the game computes a **risk level**
— *Safe · Risky · Dangerous* — from: is the area restricted right now? is the action intrusive? who
can see you (nearby NPCs / a guard's vision)? plus the difficulty's hint setting. On Easy it's
labeled outright; on Extreme you get little warning.

**Catch model (per difficulty):**
- **Easy:** off — roam and search freely.
- **Medium — suspicion meter:** being somewhere restricted (or doing intrusive searches while seen)
  fills a meter; full = caught. Leave/stop to let it fall.
- **Hard/Extreme — vision + proximity:** NPCs (and station guards) have a facing **vision cone** +
  a close **proximity** radius; being inside one while trespassing = caught. Sneak = stay out of
  cones, use timing (the living sim means NPCs come and go), and the dark (day/night already exists).

**Getting caught → a strike** (Section 5), plus immediate fallout (ejected from the area, a standing
hit with the owner/police). `CatchModel` reads `Difficulty` to pick none/meter/vision and the ranges.

## 5. Risk & consequences (mistakes → job → life)

A **strike** is recorded for: getting **caught trespassing**, a **false accusation** (already costs
standing), or a **botched intrusive search**. A `Consequences` system tracks strikes and a **day
counter**:
- **Warnings** at the first strike(s): the chief warns you, standing with police drops.
- **Fired** at the difficulty's strike threshold → a "job lost" game-over (the family pulls your
  mandate). Also fired if the **deadline** passes unsolved (you're taken off the case).
- **Death** (Hard/Extreme only): specific **dangerous late-game situations** (e.g., confronting the
  wrong person alone after hours) can end fatally — a scripted, signposted risk, not random.

Game-over routes to an ending screen (reuse the Plan D `StoryScreen`) with the appropriate text;
the player restarts (or, soft modes, continues with penalties).

## 6. Time & deadline

Reuse the existing `Scheduler` (already drives schedules/day-night). Add a **day counter** and a
**deadline** (from `Difficulty`). **Resting in your room** and **traveling** advance time. When the
deadline hits, force the case closed (an ending). On Easy (no deadline) time still flows but never
forces an end.

**Deadlines are generous on purpose** (14 / 10 / 7 days) because the investigation is *deep* —
trust with each LLM-driven suspect builds over **repeated** interrogations across days, suspicious
moments only happen at specific hours (so catching them all takes several days), and there are four
locations to work. These are **tunable balance values**: a "day" is a full sim day the player moves
through with speed controls + resting, and we'll re-balance the exact numbers during playtesting
once the systems exist. The deadline should feel like *pressure to be efficient*, never *a rush*.

## 7. New systems (what the build slices will create)

| System | Responsibility |
|--------|----------------|
| `Difficulty` (autoload) | the parameter table + current settings; everything reads it |
| `SettingsScreen` (UI) | pick preset / override fields |
| Location scenes + `LocationManager` | the four locations + travel (map default) |
| `SearchData` + detailed-examine UI | multi-step object interactions |
| `AccessData` + `is_restricted` | time/ownership gating |
| `RiskAssessor` | computes Safe/Risky/Dangerous |
| `CatchModel` (meter + vision) | detection, difficulty-scaled |
| `Consequences` (autoload) | strikes, day counter, fired/death/deadline → endings |

## 8. Recommended build order (each its own plan → build → test → merge)

1. **`Difficulty` + Settings** — the spine; small, unblocks everything. *(build first)*
2. **Detailed examination** (`SearchData` + UI) — self-contained, high player-felt value.
3. **World expansion** — locations + fast-travel + enterable rooms + the day counter.
4. **Access + sneaking + risk** — `AccessData`, `RiskAssessor`, `CatchModel` (meter then vision).
5. **Consequences** — strikes, fired/death/deadline → endings (depends on 1 + 4).
6. **Plan E subplots** — last, on top of the bigger world.

## Open questions (resolve per-slice, not now)

- Exact university/station floor plans + which clues live where.
- Vision-cone implementation (Area2D cone vs raycast) — decide in slice 4.
- Default difficulty on first launch (proposed: **Medium**).
