# Local LLM models (LOCAL mode)

The hybrid AI's **LOCAL** provider (NobodyWho) loads a GGUF model from this folder. This is only
needed for fully-offline in-engine inference; SERVER mode (Python + Ollama) ignores it.

## Setup

1. Install the **NobodyWho** addon: Godot editor → AssetLib → search "NobodyWho" → install + enable.
   (Without it, LOCAL mode stays inert and AUTO falls back to SERVER / RULE_BASED — the project still runs.)
2. Place a GGUF model here named `model.gguf`, e.g. a small instruct model like Phi-3-mini or
   Llama-3.2-3B-Instruct (Q4_K_M quantization is a good size/quality balance for desktop).
3. Run the game. `AIClient` auto-selects LOCAL when no Python server is running.

## Model path override

Default path is `res://models/model.gguf`; the provider also auto-discovers the first `.gguf` in this
folder. Override explicitly via the `echo/nobodywho_model_path` project setting (already set in
`project.godot`). NobodyWho also accepts `hf://owner/repo/file.gguf` and `https://` URLs.

> GGUF files are large and are **not** committed to the repo. Keep them local.

## Runtime download (in-game)

The game can download a model itself (Settings → Local AI → Download), so no manual placement is
needed. Files land in `user://models/` (`%APPDATA%\Godot\app_userdata\Project Chimera\models\` on
Windows) and are verified against a pinned SHA-256 before use. The provider resolves in this order:
downloaded model in `user://models/` → `echo/nobodywho_model_path` setting → `res://models/model.gguf`
→ first `.gguf` auto-discovered in this folder. Partial downloads resume via HTTP Range; a failed
integrity check is deleted and retried from scratch on the next Download press.

## Hardware reality & model choice (verified on this machine)

This machine's GPU (AMD Radeon R5 M330, ~1.7 GB VRAM) only fits very small models:

| Model | Result |
|-------|--------|
| `gemma-2-2b-it` Q8 (2.78 GB) | ❌ compute buffer (1.1 GB) won't fit alongside weights → load fails |
| `Qwen3.5-0.8B-Instruct` Q4 (527 MB) | ⚠️ loads + generates, but runs away under JSON grammar and emits non-JSON otherwise — unusable for structured decisions |

NobodyWho serializes through a single shared chat (see `nobodywho_provider.gd`), so VRAM use stays flat
regardless of NPC count. The limiter is model quality at ≤1B params.

**Recommended models that fit ~1.7 GB VRAM *and* follow instructions well** (download the Q4_K_M GGUF):
- `Llama-3.2-1B-Instruct` (~0.8 GB) — best small-model instruction following
- `Qwen2.5-1.5B-Instruct` (~1.0 GB) — strong, still fits
- `Qwen2.5-0.5B-Instruct` (~0.4 GB) — tiny fallback

With a well-behaved model you can re-enable strict JSON output in `nobodywho_provider.gd`
(`set_sampler_preset_json`). If you have more VRAM or want higher quality, run `gemma-2-2b`/`Phi-4-mini`
via **SERVER mode** (Ollama) instead — the router prefers SERVER automatically when it's running.
