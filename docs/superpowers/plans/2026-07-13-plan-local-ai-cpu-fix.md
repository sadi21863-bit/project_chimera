# Local AI Fix — Force CPU-Only Inference (partial fix; full findings below)

## What's actually fixed
A direct headless probe (loading the already-downloaded `Llama-3.2-1B-Instruct-Q4_K_M.gguf` via the
real `NobodyWhoModel`/`NobodyWhoChat` classes) confirmed: `NobodyWhoModel.use_gpu_if_available`
defaults to `true`, driving the AMD Radeon R5 M330's Vulkan backend — a very low-VRAM (1.7GB), likely
poorly-supported mobile GPU. With `use_gpu_if_available = false`, model loading and a short, simple
prompt ("Say hello in one word.", small context) completed cleanly in ~31s total with no crash — so
GPU offload was a real, fixable crash source. **Fixed**: `nobodywho_provider.gd` now forces
`use_gpu_if_available = false` unconditionally, and stops any in-flight generation on `_exit_tree()`
(a segfault was separately observed when quitting while a request was still running — `stop_generation()`
mitigates this).

## What's NOT fixed — the honest result
A second, more realistic test — instantiating the actual `main.tscn`, letting `AiMode.AUTO` route real
NPC decisions to LOCAL through the normal behavior-tree path, with the real (longer) persona+situation
prompt `_build_local_prompt()` builds — did **not** complete a single decision in 90 seconds of
generation time, twice (once at `context_length=2048`, once at `512` — context size wasn't the
bottleneck). The engine itself never hung (a heartbeat kept printing every 5s the whole time, proving
the game loop stays responsive), but any individual NPC's behavior-tree branch would sit `RUNNING`
event for 90+ real seconds waiting on that one decision — which reads as "stuck" to a player, even
though it's not a true freeze. **Root cause: this CPU (AMD A9-9420, 2 cores) is simply too weak for
real-time 1B-parameter token generation**, not a config bug — the earlier "31s, works great" result
came from an overly simple test prompt, and doesn't hold for the real game's prompt.

## Current state (all deliberate, not oversight)
- `use_gpu_if_available = false` and the `stop_generation()`-on-exit safety net are real fixes, kept.
- `CONTEXT_LENGTH` reduced 2048 → 512 (matches the file's own stated design intent — "keeps the
  compute buffer tiny" — even though it didn't move the needle on this specific bottleneck).
- The model file stays in `godot/models/disabled/` by default. Two independent reasons now, not one:
  (a) eager-loading in `_ready()` adds ~6.3s to every headless test that instantiates `main.tscn`
  (all `*.gguf` are gitignored, so this is a purely local, uncommitted convenience choice); (b) moving
  it into the active path makes `AiMode.AUTO` prefer LOCAL over RULE_BASED as soon as the model is
  "ready," and LOCAL is now confirmed to make NPCs appear stuck for 90+ seconds at a time on this
  hardware — **don't recommend enabling it for actual play yet.**

## Next steps (not done here — out of scope for this fix)
1. Try `Qwen2.5-0.5B-Instruct-GGUF` (researched separately, ~half the params of Llama-3.2-1B, so
   roughly half the per-token cost) — needs the user to download it; may or may not be fast enough.
2. If still too slow, LOCAL mode may simply not be practical on this specific machine — RULE_BASED
   (already the default when no model is present) is the realistic fallback, with LOCAL/SERVER modes
   reserved for better hardware or an externally-hosted Ollama server.

Git: branch `plan-local-ai-cpu-fix` from `main`. Commits,
`Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
