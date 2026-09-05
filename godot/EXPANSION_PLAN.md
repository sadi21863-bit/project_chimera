# Project Chimera — Expansion Plan

## Current State (v0.7)

### Locations (12)
| ID | Name | Travel Time | Connected To |
|----|------|-------------|--------------|
| dorm | Crestwood Hall | — | All bedrooms, campus |
| detective_room | Your Room | 1h | dorm |
| police_station | Police Station | 1h | dorm |
| university | University | 1h | dorm |
| campus | The Campus | 0h | dorm |
| bedroom_1-6 | Resident Rooms | 0h | dorm |
| daniel_room | Daniel's Room | 0h | dorm |

### NPCs (7)
- Alex (RA) — controls keys, logbook
- Jordan (Actor) — witnessed Daniel, ghost costume
- Sam (Hacker) — disabled camera, wiring
- Riley (Pre-med) — gave sleep aid, pharmacology notes
- Morgan (Athlete) — found body, moved evidence
- Casey (Artist) — saw everything, portraits
- Dean Whitfield — cover-up, family pressure

### Clues (15)
2 per suspect + ghost costume/note/sighting

### Systems
- Scheduler (day/night cycle, 1 real sec = 1 game min)
- Standing (trust with NPCs, -1 to 1)
- Consequences (strikes, deadline, death window)
- Investigation (clue discovery)
- CaseFile (evidence gating for accusations)
- Enhanced Interrogation (styles, pressure, follow-ups)
- Tutorial (10 hints)
- Notebook, Evidence Board, Observer Panel

---

## Expansion Plan

### Phase 1: Map & Location Overhaul

**Goal:** Replace the flat button list with a visual map showing connected locations, travel costs, and discovery status.

#### 1.1 Visual Travel Map
- Node-based map (like a subway diagram)
- Each location is a node with connections drawn as lines
- Travel time shown on connections
- Unvisited locations shown as "?" until discovered
- Current location highlighted
- NPCs shown as dots on their current location

#### 1.2 New Locations (8 new)
| ID | Name | Travel Time | Purpose |
|----|------|-------------|---------|
| courtyard | Courtyard | 0h | Central outdoor area, Casey's sketch spot |
| server_room | Server Room | 0h | Sam's wiring, camera feeds |
| library | Library | 1h | Research, dean's paper trail |
| hospital | Hospital | 2h | Riley's clinical rotation, medical records |
| bar | The Rusty Anchor | 1h | Off-campus, witnesses, tabloid contact |
| jordan_office | Theater Department | 1h | Jordan's rehearsal space, scripts |
| morgan_gym | Athletic Center | 1h | Morgan's injury, rivalries |
| crestwood_family | Crestwood Estate | 3h | Family secrets, cover-up origin |

#### 1.3 Location Connections (Graph)
```
                    ┌─────────────┐
                    │   Campus    │
                    └──────┬──────┘
                           │ 0h
                    ┌──────┴──────┐
         ┌─────────┤ Crestwood   ├─────────┐
         │ 0h      │   Hall      │ 0h      │ 0h
    ┌────┴────┐    └──────┬──────┘    ┌────┴────┐
    │Bedrooms │           │           │ Courtyard│
    └─────────┘           │ 0h        └─────────┘
                    ┌─────┴─────┐
                    │  Server   │
                    │   Room    │
                    └───────────┘
                           │ 1h
              ┌────────────┼────────────┐
              │            │            │
        ┌─────┴─────┐ ┌───┴───┐ ┌─────┴─────┐
        │  Police   │ │Library│ │ University│
        │  Station  │ │  1h   │ │           │
        └───────────┘ └───┬───┘ └─────┬─────┘
                          │           │ 1h
                    ┌─────┴─────┐ ┌───┴────────┐
                    │  Hospital │ │  Theater   │
                    └───────────┘ │ Department │
                                  └────────────┘
                    ┌─────────────┐
                    │    Bar      │
                    │(Rusty Anchor│
                    └─────────────┘
```

#### 1.4 Travel Costs
- Walking (same building): 0h
- Short trip (nearby): 1h
- Long trip (across town): 2-3h
- Travel at night (+1h, risk of encounters)

---

### Phase 2: Building Interior Expansion

**Goal:** Make each location feel lived-in with interactive objects, ambient NPCs, and environmental storytelling.

#### 2.1 Common Room Overhaul
- Vending machine (clue: wiring note)
- Noticeboard (clue: camera maintenance log)
- Couch with cushions (clue: logbook page)
- TV playing news about Daniel's death
- Radio with ambient music

#### 2.2 Hallway Enhancements
- Fire safety poster (clue: alarm disconnection)
- Door locks (visual feedback for Alex's key)
- Ghost sighting marker (Jordan's costume spot)
- Stairs (Daniel's fall location)

#### 2.3 Daniel's Room (Crime Scene)
- Sealed with police tape (can break = strike)
- Desk with second student ID
- Nightstand with stimulants
- Headboard with ledger
- Window overlooking courtyard

#### 2.4 New Location Interiors
- **Server Room**: Racks of equipment, Sam's workstation, camera feeds
- **Library**: Research terminals, dean's published papers, old newspapers
- **Hospital**: Riley's locker, medical records, pharmacy
- **Bar**: Tabloid contact's booth, ambient NPCs, rumors
- **Theater**: Jordan's rehearsal space, script collection, costume rack
- **Gym**: Morgan's locker, injury records, rivalries board
- **Crestwood Estate**: Family portraits, cover-up documents, lawyer's office

---

### Phase 3: Story Expansion

**Goal:** Deepen the narrative with more plot threads, red herrings, and moral complexity.

#### 3.1 New Plot Threads
1. **The Tabloid Connection** — Jordan's ghost gigs were arranged by a tabloid stringer who was investigating Daniel's double life
2. **The Family Cover-Up** — The Crestwoods knew about Daniel's identity change and actively suppressed it
3. **The Medical Mystery** — Riley's sleep aid interacted with Daniel's stimulants in an unexpected way
4. **The Rivalry** — Morgan and Alex had a leadership dispute that escalated after Daniel's death
5. **The Artistic Witness** — Casey's portraits contain hidden details that only emerge under scrutiny

#### 3.2 Red Herrings (Expanded)
1. **The Ghost** — Jordan's costume gigs look like stalking, but are just tabloid work
2. **The Pills** — Riley's sleep aid looks like poison, but was harmless alone
3. **The Wiring** — Sam's camera work looks like evidence tampering, but was for an app
4. **The Key** — Alex's master key looks like murder access, but was for noise complaints
5. **The Sketch** — Casey's courtyard sketch looks like surveillance, but was art
6. **The Bottle** — Morgan's moved bottle looks like evidence destruction, but was panic

#### 3.3 New Evidence Types
1. **Documentary** — Letters, records, logs (physical evidence)
2. **Testimonial** — NPC statements, overheard conversations (social evidence)
3. **Circumstantial** — Timelines, locations, motives (inferential evidence)
4. **Forensic** — Medical reports, technical analysis (scientific evidence)

#### 3.4 Branching Interrogation Paths
- **Cooperative Path**: Build trust → NPCs voluntarily share information
- **Confrontational Path**: Press hard → NPCs crack under pressure but may lie
- **Investigative Path**: Present evidence → NPCs explain or deny
- **Sympathetic Path**: Show empathy → NPCs confess guilt they're hiding

#### 3.5 New Endings (6 new)
| Ending | Trigger | Description |
|--------|---------|-------------|
| ending_truth | Correct accusation + full evidence | The real truth emerges |
| ending_partial | Correct accusation + partial evidence | Right person, wrong reason |
| ending_coverup | Discover family involvement | The cover-up succeeds |
| ending_tabloid | Give story to tabloid | Public scandal, justice unclear |
| ending_walk_away | Refuse to accuse | The case goes cold |
| ending_sacrifice | Take blame for NPC | Protect someone you care about |

---

### Phase 4: System Enhancements

#### 4.1 NPC Relationship Graph
- Track relationships between NPCs (not just detective-NPC)
- NPCs can warn each other about the detective
- Relationships affect what they say in interrogation
- Visual relationship graph in notebook

#### 4.2 Evidence Quality System
- Evidence has quality levels (weak, moderate, strong, definitive)
- Chain of custody matters (found vs. given vs. stolen)
- Evidence can be challenged in accusation
- Quality affects ending outcome

#### 4.3 Time Pressure Mechanics
- Scheduled events that happen at specific times
- NPCs move and interact on their own
- Missing events means missing evidence
- Time-sensitive choices (help NPC vs. investigate)

#### 4.4 Environmental Storytelling
- Ambient dialogue between NPCs
- Environmental clues (posters, notes, objects)
- Day/night visual changes
- Weather effects on NPC behavior

---

### Phase 5: Visual & Audio Polish

#### 5.1 Screen Effects
- Screen shake on discoveries
- Flash on clue found
- Fade transitions between locations
- Vignette during interrogation

#### 5.2 Particle Effects
- Dust motes in sunbeams
- Rain on windows
- Steam from coffee
- Flickering lights in hallway

#### 5.3 Sound Design
- Location-specific ambient sounds
- NPC footsteps
- Door opens/closes
- Paper rustling
- Heartbeat during danger

#### 5.4 Music System Enhancement
- Location-specific music tracks
- Tension layers that build during investigation
- Resolution themes for endings
- Dynamic mixing based on game state

---

## Implementation Priority

### Immediate (Next Session)
1. ✅ Enhanced Interrogation (done)
2. ✅ Tutorial System (done)
3. ✅ Free Assets Imported (done)
4. Visual Travel Map (replace button list)
5. 4 new locations (courtyard, server_room, library, hospital)

### Short Term (1-2 Sessions)
6. Location interiors with interactive objects
7. New search points in new locations
8. NPC relationship tracking
9. Evidence quality system

### Medium Term (3-5 Sessions)
10. New plot threads and red herrings
11. Branching interrogation paths
12. 6 new endings
13. Screen effects and particles

### Long Term (5+ Sessions)
14. Sound design
15. Music system enhancement
16. Environmental storytelling
17. Polish and playtesting

---

## Technical Notes

### Map System Architecture
```
travel_map_v2.gd (replaces travel_map.gd)
├── MapNode (Control) — each location is a node
├── MapConnection (Line2D) — connections between nodes
├── MapNPC (TextureRect) — NPC indicators
└── MapLegend (VBoxContainer) — travel time info
```

### Location Graph Data Structure
```gdscript
const LOCATION_GRAPH := {
    "dorm": {"connections": ["campus", "bedroom_1", ...], "position": Vector2(400, 300)},
    "campus": {"connections": ["dorm"], "position": Vector2(400, 100)},
    # ...
}
```

### Evidence Quality System
```gdscript
enum EvidenceQuality { WEAK, MODERATE, STRONG, DEFINITIVE }
enum EvidenceSource { FOUND, GIVEN, STOLEN, TESTIMONIAL }

const EVIDENCE_DATA := {
    "clue_keys": {"quality": EvidenceQuality.MODERATE, "source": EvidenceSource.FOUND},
    # ...
}
```

---

## Success Metrics

### Playability
- [x] All 12+ locations accessible and visually distinct
- [x] Travel map shows connections and costs
- [x] NPCs move autonomously on schedules
- [x] Evidence quality affects accusations
- [x] 14+ endings with meaningful differences

### Narrative
- [x] 6+ red herrings that feel fair
- [x] 4+ interrogation paths with different outcomes (Direct/Empathetic/Confrontational)
- [x] NPCs have visible relationships
- [x] Time pressure creates urgency (10 scheduled events)
- [x] Environmental storytelling adds depth

### Technical
- [x] All tests pass
- [x] Save/load preserves all new systems
- [x] No parse errors
- [x] Performance stable with new content
