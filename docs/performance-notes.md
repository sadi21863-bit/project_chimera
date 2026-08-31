# Performance Notes (Phase 5)

## Target
Stable 60 FPS with 6 NPCs at 4x simulation speed.

## Optimizations Implemented

### HTTP Batching
- `AIClient.request_decision_batch()` POSTs to `/npc/decide/batch` when multiple NPCs need decisions simultaneously
- Request queue capped at 2 concurrent HTTP requests to prevent server stampede

### AI Decision Staggering
- `AwaitingAI` behavior leaf enforces 5-minute (in-game) cooldown between AI decisions per NPC
- Schedule-driven movement runs without AI calls

### Navigation
- Single shared `NavigationRegion2D` for the dorm (not per-NPC)
- `NavigationAgent2D.path_desired_distance = 4.0` reduces path recalculation

### Memory
- ChromaDB per-NPC collections prevent cross-contamination and keep queries scoped
- Relationship cache in-memory with ChromaDB persistence for dialogue events

### Rendering
- `AnimatedSprite2D` with PIPOYA 32x32 sprite sheets (3 frames × 4 directions per NPC)
- SpriteFrames stored as `.tres` resources, loaded once per NPC type
- `CanvasModulate` for day/night (single full-screen tint, no per-light calculations)
- Furniture rendered as static `Sprite2D` nodes (pixelinterior pack, no animation overhead)

## Profiling Checklist

Run in Godot 4.7 with Debug → Monitor:
- [ ] FPS ≥ 60 at 1x speed, 6 NPCs
- [ ] FPS ≥ 55 at 4x speed, 6 NPCs
- [ ] Draw calls < 50
- [ ] Physics frame < 8ms

## Known Bottlenecks

1. **LLM inference** — Ollama calls take 1-5s; mitigated by queue + fallback
2. **ChromaDB embedding** — first query per NPC is slower; subsequent queries cached by Chroma
3. **HTTP latency** — localhost calls ~5-20ms each; batch endpoint reduces round trips

## Sound Stubs

- Ambient loop placeholder on `CrestwoodHall` (`AudioStreamPlayer`)
- Footstep variants: assign per-room streams in editor (kitchen tile = ceramic, hallway = linoleum)
- Files expected at `godot/assets/audio/ambient_dorm.ogg`, `footstep_*.ogg`
