# Plan E Subplots Implementation Plan

**Goal:** Close out the four subplots named in the Story Bible but never designed in detail: the
ghost-master, media/press pressure, family/police interference, and the hint-giver. All four turn
out to be **content**, not new systems — `SuspicionData`/`SuspicionWatcher`,
`SearchData`/`SearchPanel`, and `InterrogationData`'s trust-gated topics + evidence reactions
already do everything needed. No new autoloads, no new UI.

**Design calls:**
- **Ghost-master + media/press, combined.** Per the Bible, Jordan is a theater kid; per Section
  "Supporting cast," reporters are already circling for a story. The two subplots fold into one
  self-contained arc: a tabloid reporter paid **Jordan** to fake ghost sightings for clicks —
  unrelated to Daniel's death, but discoverable in Jordan's room, and it looks damning until you
  find the note. This is flavor-only (not added to `CaseData.CLUES`) so it never affects Jordan's
  actual accusation strength — it's a red herring by construction, not just by name.
- **Family/police interference** lands in the Police Station (built in World Expansion W2, empty
  until now) as three flavor search points: the chief was overruled, the family's lawyer is reading
  everything you find, and the department is split between resenting you and rooting for you.
- **Hint-giver** is Casey (named as the primary hint-giver in the Bible) getting one new
  trust-gated interrogation topic (`reveal_clue: ""`, flavor response only) that nudges the player
  toward both new content areas above — Casey "sees everything," narratively earning the role with
  zero new mechanics.
- All new clues are flavor-only (empty or non-`CaseData` `reveal_clue`s) — this slice adds texture
  and reveals interference/misdirection; it does not change any suspect's case strength or add a
  new ending.

## Global Constraints
- Godot 4.7 stable; warnings-as-errors; explicit types on `Variant`-returning calls.
- Reuse the exact `SuspicionData`/`SearchData`/`InterrogationData` table shapes already tested.
- Git: branch `plan-e-subplots` from `main`. Commit per task, `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: The ghost-master (Jordan's paid haunting) + media/press

**Files:** Modify `godot/scripts/interrogation/suspicion_data.gd`, `godot/scripts/interrogation/search_data.gd`,
`godot/scripts/interrogation/interrogation_data.gd`; extend `godot/tests/test_search_data.gd`.

`SuspicionData.MOMENTS` += `{"id": "jordan_ghost", "npc_id": "jordan", "hour": 1.0,
"reveal_clue": "clue_ghost_sighting", "description": "Jordan slips a white sheet over their
shoulders near the courtyard, practicing a moan under their breath"}`.

`SearchData.POINTS` += `"jordan_costume_trunk"` (room `bedroom_2`, label "the trunk under Jordan's
bed"): two actions — `"look_under"` reveals `clue_ghost_costume` (a cheap costume, tags still on),
`"dig"` reveals `clue_ghost_note` (a reporter's payment note/venmo screenshot naming the outlet).
Both flavor clues, not in `CaseData.CLUES`.

`InterrogationData.SUSPECTS.jordan.evidence` += reactions for `clue_ghost_costume` and
`clue_ghost_note` (Jordan admits the paid-haunting gig, embarrassed, insists it's unrelated to
Daniel).

Commit: `feat: ghost-master + media/press subplot (Jordan's paid haunting)`

---

### Task 2: Family & police interference (Police Station content)

**Files:** Modify `godot/scenes/locations/police_station.tscn` (add 3 `SearchPoint` nodes, same
pattern as `detective_room.tscn`'s `Bed`); modify `godot/scripts/interrogation/search_data.gd`.

`SearchData.POINTS` += `"case_board"`, `"evidence_log"`, `"detective_memo"` (room
`police_station`, flavor-only): the chief's note that the family is "pushing... above my pay
grade"; the family's lawyer signing out copies of everything you find; a hostile detective's memo
next to an ally's rebuttal in the margin.

Commit: `feat: family + police interference content in the Police Station`

---

### Task 3: The hint-giver (Casey) + regression + playtest + merge

**Files:** Modify `godot/scripts/interrogation/interrogation_data.gd` (Casey's `topics`).

Add a `trust_min: 0.5` topic to Casey — `reveal_clue: ""` — whose response nudges the player
toward Jordan's trunk and the police station's board, in character ("I see a lot... somebody's
been playing ghost near the courtyard after midnight. And the department's not as united as they
want the family to think.").

Run the full `godot/tests/*.gd` suite (all green expected). Human playtest:
`"C:/Users/aditya/Desktop/Godot_v4.7-stable_win64.exe" --path godot` — catch Jordan's ghost moment
around 1am, search the trunk in bedroom_2, confirm both flavor clues + Jordan's interrogation
reactions; visit the Police Station and search all three new points; raise trust with Casey and
confirm the new hint topic appears and reads sensibly.

Commit, then finish the branch (merge to `main`, delete branch, verify full suite on `main`).
