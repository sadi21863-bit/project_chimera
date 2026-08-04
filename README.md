# Project Chimera / Echo

Godot 4.4+ isometric dorm simulation with 6 autonomous NPCs. AI runs through a **hybrid provider
router**: fully offline in-engine (NobodyWho + GGUF), or against a richer Python backend when present.

## Architecture

- **Godot client** (`godot/`) — simulation, observer UI, Beehave behavior trees, AI router
- **Python AI server** (`ai-server/`, optional) — ChromaDB RAG memory, Game Master validation, Ollama

`AIClient` (`godot/autoload/ai_client.gd`) routes every NPC decision/memory call through the best
available backend, with an identical public API regardless of which is active:

| Mode | Inference | Memory | Requires |
|------|-----------|--------|----------|
| `SERVER` | HTTP → FastAPI → Ollama | ChromaDB (semantic) | `ai-server/` running |
| `LOCAL` | NobodyWho (embedded llama.cpp, GGUF) | `LocalMemory` (JSON, in-engine) | NobodyWho addon + a `.gguf` |
| `RULE_BASED` | deterministic fallback | `LocalMemory` | nothing |
| `AUTO` (default) | SERVER → LOCAL → RULE_BASED by availability | — | — |

The LOCAL path is guarded by `ClassDB.class_exists("NobodyWhoChat")`, so the project runs today even
without the addon (it simply falls back). See [docs/echo-hybrid-architecture.md](docs/echo-hybrid-architecture.md).

```
SERVER path: Godot HTTPRequest → POST http://localhost:8000/npc/decide
Python endpoints: /health, /npc/decide, /memory/record, /memory/recall, /events/inject, /relationships
LOCAL path: NobodyWhoChat.ask(prompt) → response_finished → parsed JSON action (no network)
```

For fully-offline LOCAL mode, install the NobodyWho addon and drop a GGUF model in
`godot/models/` — see [godot/models/README.md](godot/models/README.md).

## Prerequisites

- [Godot 4.4+](https://godotengine.org/download)
- [Python 3.11+](https://www.python.org/downloads/)
- [uv](https://docs.astral.sh/uv/) (recommended) or pip
- [Ollama](https://ollama.com/) (optional — server falls back to rule-based decisions)

### Ollama setup (optional)

```bash
ollama pull phi3:mini
```

Override defaults via env vars if needed: `CHIMERA_OLLAMA_URL`, `CHIMERA_OLLAMA_MODEL`, `CHIMERA_OLLAMA_TIMEOUT`, `CHIMERA_OLLAMA_HEALTH_TIMEOUT`.

## Quick Start

### 1. AI Server

```bash
cd ai-server
uv sync
uv run python main.py
```

Server runs at `http://localhost:8000`. Check health: `curl http://localhost:8000/health`

### 2. Godot Client

1. Open Godot 4.4+
2. Import project from `godot/project.godot`
3. Run `main.tscn`
4. Press Play in the observer panel to start simulation

## Crestwood Hall

6-bedroom dormitory with common room, kitchen, bathroom, and hallway. See `docs/crestwood-hall.md`.

## NPCs

Alex, Jordan, Sam, Riley, Morgan, Casey — see `godot/resources/npc_profiles/` and `docs/crestwood-hall.md`.

## Repository Layout

```
project-chimera/
├── godot/          # Godot 4.4+ simulation client
├── ai-server/      # FastAPI + ChromaDB + Ollama
├── docs/           # Design docs and resource audit
├── .cursorrules
└── README.md
```
