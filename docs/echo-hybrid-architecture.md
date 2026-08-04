# Hybrid AI Architecture (Project Echo pivot)

Project Echo keeps Chimera's working Godot simulation and **adds a fully-local in-engine AI path**, so the
game can run either as a self-contained desktop binary (no Python, no Ollama) or against the richer
Python backend when it's available. The two paths share one public interface.

## Provider router

`AIClient` (`godot/autoload/ai_client.gd`) is a router with a mode enum:

```
enum AiMode { AUTO, SERVER, LOCAL, RULE_BASED }
```

| Mode | Inference | Memory | Needs |
|------|-----------|--------|-------|
| `SERVER` | HTTP → FastAPI → Ollama | ChromaDB (semantic) | `ai-server/` running + Ollama |
| `LOCAL` | NobodyWho (embedded llama.cpp, GGUF) | `LocalMemory` (JSON, keyword+recency) | NobodyWho addon + a `.gguf` |
| `RULE_BASED` | Deterministic fallback | `LocalMemory` | nothing |
| `AUTO` | best available at runtime | follows chosen path | — |

`AUTO` resolution order each decision: **SERVER if `/health` is up → LOCAL if NobodyWho is ready → RULE_BASED**.
The mode is a plain variable, so the observer panel can expose a switch later.

## Why hybrid (not replace)

- **Distributable**: LOCAL needs no external processes — one Godot export + a bundled GGUF.
- **No regression**: the LOCAL provider is guarded by `ClassDB.class_exists("NobodyWhoChat")`. If the
  addon isn't installed, LOCAL is inert and `AUTO` falls back to the existing SERVER/RULE_BASED paths,
  so the project that runs today keeps working unchanged.
- **Dev power**: SERVER keeps ChromaDB semantic recall and the Game Master validation for richer behavior.

## NobodyWho facts (vs. the Echo plan's assumptions)

- NobodyWho **does not connect to Ollama**. It embeds llama.cpp and loads a `.gguf` directly
  (`NobodyWhoModel.model_path`). Ollama is only used by the SERVER path.
- API used: `NobodyWhoModel` (`model_path`), `NobodyWhoChat` (`system_prompt`, `model_node`,
  `start_worker()`, `ask(prompt)`, signal `response_finished(text)`).
- **Godot has no built-in SQLite.** In-engine memory therefore uses a JSON store (`LocalMemory`),
  consistent with the project's existing Locker / `relationships.json` persistence. Embedding-based
  recall via `NobodyWhoEncoder` is a documented future upgrade.

## Public interface (unchanged — call sites untouched)

`request_decision(npc_id, context, callback)`, `request_decision_batch`, `record_memory`,
`recall_memory`, `inject_event`, `fetch_relationships`; signals `server_status_changed`,
`decision_received`; properties `server_online`, `use_ai`. Behavior-tree leaves and the observer
panel call these exactly as before.

## Per-NPC LOCAL chat

One shared `NobodyWhoModel`; one lazily-created `NobodyWhoChat` per NPC keyed by `npc_id`, each seeded
with that NPC's persona as `system_prompt`. The model worker serializes requests, which is fine given
the existing 5-minute per-NPC decision cooldown.

## Build sequence

1. **AI hybrid layer** (this increment): router + `LocalMemory` + NobodyWho provider + setup docs.
2. **Player + observer toggle**: add a `CharacterBody2D` player, "press E to talk" dialogue box reusing
   `DialogSystem`, and a mode switch between observer and play. (Next increment.)
3. **Polish**: response caching for greetings/idle, desktop export presets.
