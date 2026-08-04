# Project Chimera — Resource Audit (Phase 0)

Audit date: 2026-06-22  
Environment: Windows 10, Godot 4.4+ target, Python 3.11+

## Summary

| Resource | Status | Notes |
|----------|--------|-------|
| ProtoCRPG | **MANUAL** | Run `scripts/setup.ps1` to clone `prototype` branch. Chimera ships a functional standalone Godot project with equivalent isometric nav + action log patterns. |
| Beehave | **PASS (stub)** | Minimal Beehave-compatible BT included in `godot/addons/beehave/`. Run setup script for full upstream addon. |
| Event Bus | **PASS** | Minimal pub/sub in `godot/addons/event_bus/event_bus.gd` |
| Dialog System | **PASS** | Speech bubble overlay in `godot/addons/dialog_system/` |
| Locker | **PASS (stub)** | JSON save/load in `godot/addons/locker/save_manager.gd` |
| FastAPI | **PASS** | `ai-server/main.py` serves all endpoints |
| ChromaDB | **PASS** | Per-NPC collections in `chimera/memory.py` |
| Ollama | **PASS (optional)** | Structured JSON via `/api/generate`; rule-based fallback when unavailable |
| Godot HTTPRequest | **PASS** | `ai_client.gd` queue with 2 concurrent, retry, batch endpoint |

## Spike Test Results

### ChromaDB store/retrieve
- **PASS:** `MemoryStore.record()` + `recall()` with persistent client at `ai-server/data/chroma/`
- Verified via `/memory/record` and `/memory/recall` endpoints

### Ollama structured JSON
- **CONDITIONAL:** Requires `ollama pull phi3:mini` and running Ollama daemon
- **Fallback PASS:** `rule_based_action()` returns valid `NpcAction` when Ollama offline

### FastAPI health + decide
- **PASS:** `GET /health` returns status + chroma path
- **PASS:** `POST /npc/decide` validates actions via Game Master whitelist

### Godot behavior tree
- **PASS:** Schedule-driven movement via Selector → Sequence → MoveToMarker → IdleAtLocation
- **PASS:** AI branch: AwaitingAI → RequestAIDecision → ExecuteAction

### Navigation
- **PASS:** 6 NPCs pathfind to room markers on schedule changes
- NavigationRegion2D covers full dorm floor plan

## Manual Steps Required

1. **Clone upstream addons (recommended):**
   ```powershell
   cd C:\Users\aditya\project-chimera
   .\scripts\setup.ps1
   ```
2. **Install Ollama (optional):**
   ```bash
   ollama pull phi3:mini
   ```
3. **Open in Godot 4.4+:** Import `godot/project.godot`
4. **Start AI server:**
   ```bash
   cd ai-server && uv sync && uv run python main.py
   ```

## ProtoCRPG 4.3 → 4.4 Migration Notes

If cloning ProtoCRPG via setup script:
- Update `config/features` to include `"4.4"`
- Replace deprecated `NavigationAgent2D` bake patterns if import warnings appear
- Strip turn-based combat scenes; retain TileMapLayer + Y-sort + camera patterns
- Chimera's standalone implementation already uses Godot 4.4 APIs
