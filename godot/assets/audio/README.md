# Audio Assets Directory

## Directory Structure
```
audio/
├── music/               # Background music tracks
├── sfx/                 # Sound effects (footsteps, doors, UI)
└── ambience/            # Ambient sounds (rain, wind, room tone)
```

## Import Guidelines

### Supported Formats
- **WAV** (preferred for SFX): Uncompressed, lowest latency
- **OGG** (preferred for music): Compressed, streaming support
- **MP3**: Compressed, good compatibility

### Import Settings
1. **SFX (WAV)**:
   - Compress mode: Disabled (fastest loading)
   - Loop: OFF
   - Mono: ON for 2D, OFF for 3D
   - Max polyphony: 8-16

2. **Music (OGG)**:
   - Compress mode: RAM (fast playback)
   - Loop: ON
   - Mono: OFF (stereo)
   - Max polyphony: 1-2

3. **Ambience (OGG/WAV)**:
   - Compress mode: RAM
   - Loop: ON
   - Mono: ON for 2D, OFF for 3D
   - Max polyphony: 2-4

### Naming Convention
```
[category]_[name]_[variant].[format]
Examples:
- sfx_footstep_concrete_01.wav
- sfx_door_creak_01.wav
- music_dormitory_night_01.ogg
- ambience_rain_light_01.ogg
```

### Audio Bus Setup
Create audio buses in Godot:
```
Master
├── Music
├── SFX
├── Ambience
└── Voice
```

### Placement in Godot
1. Use `AudioStreamPlayer` for 2D non-positional audio
2. Use `AudioStreamPlayer2D` for 2D positional audio
3. Use `AudioStreamPlayer3D` for 3D positional audio
4. Use `AudioBus` for volume control and effects

### Music System Integration
- Use `MusicManager` autoload for crossfading
- Set mood-based tracks (exploration, investigation, tension)
- Implement volume sliders in settings

## Sources
- Kenney: https://kenney.nl (CC0)
- Freesound: https://freesound.org (CC0/CC-BY)
- OpenGameArt: https://opengameart.org
- Mixkit: https://mixkit.co (free)
