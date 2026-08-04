# Crestwood Hall — Dorm Layout & NPC Bible

## Floor Plan

Crestwood Hall is a single-floor dormitory with 10 navigable zones:

| Room ID | Description | Marker Position |
|---------|-------------|-----------------|
| `kitchen` | Shared kitchen with tables | (140, 140) |
| `common_room` | Main social/study space | (580, 320) |
| `hallway` | Central corridor | (450, 120) |
| `bathroom` | Shared bathroom | (950, 140) |
| `bedroom_1` | Alex's room (RA) | (120, 580) |
| `bedroom_2` | Jordan's room | (280, 580) |
| `bedroom_3` | Sam's room | (440, 580) |
| `bedroom_4` | Riley's room | (600, 580) |
| `bedroom_5` | Morgan's room | (760, 580) |
| `bedroom_6` | Casey's room | (920, 580) |

All rooms connect via the navigation mesh covering the floor plan. NPCs pathfind using `NavigationAgent2D` to `Marker2D` nodes under `RoomMarkers`.

## Daily Schedule Template

Each NPC follows the same time-block structure with their bedroom substituted:

| Hours | Location | Activity |
|-------|----------|----------|
| 07:00–08:00 | Own bedroom | Wake up |
| 08:00–08:30 | Bathroom | Morning routine |
| 08:30–09:00 | Kitchen | Breakfast |
| 09:00–12:00 | Common room | Study / socialize |
| 12:00–13:00 | Kitchen | Lunch |
| 13:00–17:00 | Own bedroom | Personal time |
| 17:00–19:00 | Common room | Hang out |
| 19:00–20:00 | Kitchen | Dinner |
| 20:00–22:00 | Common room | Evening activities |
| 22:00–24:00 | Own bedroom | Sleep prep |
| 00:00–07:00 | Own bedroom | Sleep |

## The Six Residents

### Alex (bedroom_1) — The RA
- **Personality:** Ambitious, organized, slightly controlling
- **Secrets:** Failed last semester quietly; crush on Jordan
- **Relationships:** Close with Jordan (+0.6), tension with Morgan (-0.2)

### Jordan (bedroom_2) — The Actor
- **Personality:** Dramatic theater kid, rehearses in hallways
- **Secrets:** Audition anxiety; writes poetry about Riley
- **Relationships:** Close with Alex (+0.6) and Riley (+0.7)

### Sam (bedroom_3) — The Hacker
- **Personality:** Night owl programmer, instant noodle diet
- **Secrets:** Building a secret app; owes Alex a favor
- **Relationships:** Friendly with Morgan (+0.5)

### Riley (bedroom_4) — Pre-Med
- **Personality:** Stressed but kind, always studying
- **Secrets:** Considering dropping pre-med; hides care packages from Casey
- **Relationships:** Close with Jordan (+0.7), friendly with Casey (+0.4)

### Morgan (bedroom_5) — The Athlete
- **Personality:** Early riser, competitive, loyal
- **Secrets:** Hidden injury; leadership rivalry with Alex
- **Relationships:** Best friends with Casey (+0.8), tension with Alex (-0.2)

### Casey (bedroom_6) — The Artist
- **Personality:** Quiet observer, paints at odd hours
- **Secrets:** Secret portrait series of dorm mates; knows everyone's secrets
- **Relationships:** Close with Morgan (+0.8)

## Observer Interaction

- Click any NPC to inspect personality, current activity, and AI memories
- Inject events via the observer panel (e.g., "Fire drill in hallway")
- Speed control: 0.5x to 8x simulation speed
- Day/night tint driven by in-game hour via `CanvasModulate`
