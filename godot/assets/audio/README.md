# Audio Assets

All files below are CC0 (public domain) — no attribution required, but credited here for traceability.

## Footsteps

Source: [Kenney RPG Audio pack](https://kenney.nl/assets/rpg-audio) (CC0, see `LICENSE_kenney_rpg_audio.txt`).
Mapped per room surface (see `npc.gd` `ROOM_FOOTSTEP_SOUNDS`):

- `footstep_ceramic_00/01/02.ogg` — kitchen, bathroom
- `footstep_linoleum_00/01/02.ogg` — hallway, common_room
- `footstep_carpet_00/01/02.ogg` — bedrooms (default)

`npc.gd` picks a random variant per step and applies slight pitch randomization to avoid repetition.

## Ambient

Source: `noise_01.ogg` from [30 CC0 SFX loops](https://opengameart.org/content/30-cc0-sfx-loops) (OpenGameArt, CC0), renamed to `ambient_dorm.ogg`.
Looped at low volume (-20dB) by `crestwood_hall.gd`. If this file is ever removed, `crestwood_hall.gd` falls back to a procedurally generated low hum via `AudioStreamGenerator` rather than playing silence.
