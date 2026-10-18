# Model Download Flow — Runtime Local-AI Bootstrap for the Windows Release

Status: DESIGN (read-only research pass, HEAD `4fad7eb`, parent `33ecce2`)
Deliverable of: "runtime local AI model download flow" for the packaged Windows release
Target machine class: 2 cores (AMD A9-9420), 7.5 GB RAM, weak GPU (Radeon R5 M330 ~1.7 GB VRAM), constrained disk

---

## 1. Executive summary

1. LOCAL mode is real and wired (`AIClient` → `NobodyWhoProvider` → NobodyWho GDExtension embedded llama.cpp), but the Windows export excludes `addons/nobodywho/*` **and** `models/*` (`godot/export_presets.cfg:11`), so a shipped exe can never reach LOCAL by downloading a GGUF alone.
2. **Key architecture finding: the download flow must be paired with bundling the NobodyWho GDExtension DLL (~78.6 MB).** Without the extension, `ClassDB.class_exists("NobodyWhoModel")` is false → `is_available()` false → `is_ready()` false → `resolve_mode()` never returns LOCAL (`godot/scripts/ai/nobodywho_provider.gd:73-78`, `godot/autoload/ai_client.gd:67-69`). Runtime loading of GDExtensions from `user://` is nominally possible (`GDExtensionManager.load_extension`, only `reload_extension` is editor-only) but is unsupported/undocumented for user-dir-hosted addons and carries Windows AV/unsigned-DLL risk — rejected in favor of bundling.
3. NobodyWho itself supports `hf://`/URL model paths with built-in download+cache (verified against upstream docs), but offers no progress/pause/verify control exposed to the game — the game-owned fallback downloader (chunked HTTPRequest + Range resume + SHA-256 verify + atomic rename to `user://models/`) is the design.
4. Godot 4.7 (our pinned engine) does **not** have `HTTPRequest.keep_partial_download` / `append_to_download_file` (they exist only in `latest`/future docs, PR #118226); so resume is implemented by the game with chunked Range requests (8 MiB windows), appending each chunk with `FileAccess` `READ_WRITE`+`seek_end()`.
5. Default model = **`Llama-3.2-1B-Instruct` Q4_K_M (807,694,464 bytes ≈ 771 MiB)** — the only model empirically verified in-repo to produce parseable JSON decisions, already named in the project setting (`godot/project.godot:64`), and upstream verified byte-exact against `bartowski/Llama-3.2-1B-Instruct-GGUF` (local file SHA-256 == HF LFS oid, measured).
6. `gemma-2-2b-it-Q8_0` (2.78 GB) and `Qwen3.5-0.8B-Instruct-Q4_K_M` (527 MB) are documented unusable for this game's JSON decision contract on this hardware (`godot/models/README.md:28-29`); Qwen additionally has **no verified upstream** (open question).
7. Target dir: `user://models/` (writable, guaranteed; Windows path `%APPDATA%\Godot\app_userdata\Project Chimera`), dev fallback to `res://models/` unchanged.
8. Provider "ready" re-evaluation: new `NobodyWhoProvider.reload_model()` + `AIClient.local_ready_changed(bool)` signal → `resolve_mode()` flips RULE_BASED → LOCAL without process restart.
9. Test plan: five exit-code headless tests under `godot/tests/` (path resolution, download-core resume/verify, UI transitions, provider re-eval, disk gating) using an injected/fake transport and stub provider — no real network in tests.
10. Honest caveat carried through the design: on the 2-core target, measured Llama-1B local decisions take 90+ s (`docs/superpowers/plans/2026-07-13-plan-local-ai-cpu-fix.md:14-24`); the flow ships the download but does not promise realtime NPC thinking on minimum spec.

---

## 2. Current LOCAL path analysis (verified, HEAD 4fad7eb / 33ecce2)

### 2.1 Router — `godot/autoload/ai_client.gd`

| Concern | Location | Behavior |
|---|---|---|
| Provider class | `ai_client.gd:30` | `const NobodyWhoProvider := preload("res://scripts/ai/nobodywho_provider.gd")` |
| Instantiation | `ai_client.gd:44-47` | `_ready()` builds `_local_provider` (`NobodyWhoProvider.new()`), child of the autoload — built **always**, even when the addon is missing. |
| Mode enum | `ai_client.gd:16` | `{ AUTO, SERVER, LOCAL, RULE_BASED }` |
| AUTO resolution | `ai_client.gd:62-69` | SERVER if `server_online` → LOCAL if `_local_provider.is_ready()` → RULE_BASED. |
| Decide (LOCAL) | `ai_client.gd:168-181` | `_local_decide()` recalls from `LocalMemory`, builds via `_build_local_prompt()` (`:184-209`), calls `_provider.decide(npc_id, persona, prompt, cb)`, parses with tolerant `_extract_json()` (`:385-395`); unparsable/`false` → rule-based fallback. |
| Free-text interrogation | `godot/scenes/main.gd:499-511` | Calls `AIClient._local_decide()` directly when `use_ai` and mode ≠ RULE_BASED — LOCAL mode is load-bearing beyond NPC decisions. |
| Health reprobe | `ai_client.gd:49-58`, `96-122` | 15 s timer; `server_status_changed` emitted only on changes. No equivalent "local readiness" signal exists today. |

### 2.2 Provider — `godot/scripts/ai/nobodywho_provider.gd`

| Concern | Location | Behavior |
|---|---|---|
| Addon-availability guard | `:73-74` | `is_available()` = `ClassDB.class_exists("NobodyWhoModel") and ClassDB.class_exists("NobodyWhoChat")`. Class checks only — the script parses/runs without the addon. |
| Readiness | `:77-78` | `is_ready()` = `is_available() and _chat != null`. |
| Model path resolution | `:110-126` | `_resolve_model_path()`: (1) setting `echo/nobodywho_model_path`; (2) const default `res://models/model.gguf` (`:16`); (3) auto-discover first `.gguf` in `res://models/`. **`res://`-only today.** |
| Missing-model behavior | `:31-38` | `_ready()` bail-out: `push_warning("NobodyWho: model file not found at %s — LOCAL mode inert until provided.")` and return. No re-check ever happens — model is resolved exactly once at boot. |
| Inference backend | `:39-62` | `ClassDB.instantiate("NobodyWhoModel")` → property `model_path`, `use_gpu_if_available=false` (forced CPU-only, `:44`); `NobodyWhoChat` (`context_length=512`, `:18`) + `start_worker()`; response via `response_finished`, `stop_generation()` on `_exit_tree` (`:67-69`). One shared chat serializes decisions (busy flag, `:84-90`). |
| Sampler | `:55-61` | Deliberately **no** JSON-grammar sampler: default sampler + example-driven prompt + tolerant parse (Qwen "runs away", Llama "stalls after `{"` with grammar samplers — measured). |
| CPU slowness evidence | `docs/superpowers/plans/2026-07-13-plan-local-ai-cpu-fix.md:14-24` | Real prompt + Llama-3.2-1B on this A9-9420 box: no decision completed in 90 s of generation, twice. Conclusion recorded there: LOCAL "don't recommend enabling it for actual play yet" on this hardware class. |

### 2.3 Model files — `godot/models/` (verified on disk)

| File | Bytes | Comments |
|---|---|---|
| `gemma-2-2b-it-Q8_0.gguf` | 2,784,495,456 | README:28: does not load on the target GPU (compute buffer + weights). 5.3× the Llama download. |
| `Qwen3.5-0.8B-Instruct-Q4_K_M.gguf` | 527,503,680 | README:29: loads but "runs away under JSON grammar and emits non-JSON otherwise — unusable for structured decisions". |
| `disabled/Llama-3.2-1B-Instruct-Q4_K_M.gguf` | 807,694,464 | Kept out of the active path (README point + per-NPC-era plan); the file **project.godot:64 settings** key references by name. |
| `README.md` | — | Setup/picker docs; repeatedly updated hardware measurements; **no download URLs recorded for any file.** |

Notable current-state quirk: `echo/nobodywho_model_path="res://models/Llama-3.2-1B-Instruct-Q4_K_M.gguf"` (`project.godot:64`) points at a filename that currently lives in `disabled/`, so on a stock dev checkout `_resolve_model_path()` returns the setting, `FileAccess.file_exists` fails, and LOCAL is inert (negative-file check at `nobodywho_provider.gd:36`). The flow design resolves this class of drift automatically (see §6.1).

### 2.4 Export state — what a shipped player gets

- `godot/export_presets.cfg:11`: `exclude_filter="tools/*, tests/*, qa/*, addons/nobodywho/*, models/*"` under preset `Windows Desktop` (`:3`), `export_filter="all_resources"` (`:9`), output `../build/windows/ProjectChimera.exe` (`:12`).
- Addon dir today contains: `nobodywho.gdextension` (1,620 B, tracked) referencing `res://addons/nobodywho/libnobodywho-godot-x86_64-pc-windows-msvc-release.dll` (`godot/addons/nobodywho/nobodywho.gdextension:11-12`), and the on-disk working tree carries only the GDExtension hot-reload temp copy `~libnobodywho-godot-x86_64-pc-windows-msvc-release.dll` (78,617,600 bytes — gitignored via root `.gitignore` "Large Godot native extension binary removed from GitHub uploads"). The real (non-`~`) DLL is **not on disk and not in git**.
- The `.godot/extension_list.cfg` (dev editor state) points to the extension; in an exported PCK the equivalent list is embedded, and each entry is loaded at startup: the exported build will log the "gdextension missing" family errors seen in issue godotengine/godot#87761 ("Can't open dynamic library... GDExtension dynamic library not found") for a resource that was excluded — i.e. the current benign warning's source is the engine, not our code (nothing in our scripts logs it; grep confirmed).
- With the addon excluded, a shipped exe runs permanently in SERVER/RULE_BASED; the model-download flow **cannot** fix that by itself.

---

## 3. Architecture decision

### 3.1 The GDExtension question (answered with evidence)

**Question:** Can the flow download the model only, or must the release also bundle (or download) the GDExtension?

**Answer: bundle the extension in the export (un-exclude `addons/nobodywho/*`); do NOT download it.** Evidence:

1. **Excluded extension ⇒ LOCAL permanently inert.** `nobodywho_provider.gd:73-74` gates on `ClassDB.class_exists(...)`. Classes are registered only by the GDExtension library loaded at startup (or runtime). Export a game without `addons/nobodywho/*` and no model file on earth changes `is_ready()`.
2. **Export mechanics put libraries beside the exe, not in the PCK.** Godot's GDExtension export plugin walks the `.gdextension` `[libraries]` table and registers each matching shared library into the export via `add_shared_object(path, tags)` (godotengine/godot `editor/plugins/gdextension_export_plugin.h`; see issue godotengine/godot#53958 and #63230: shared objects "can't be loaded from inside of the .pck file and thus need to exist besides the executable"). So bundling costs the DLL as a loose file next to `ProjectChimera.exe` in `addons/nobodywho/`, loaded by the PCK-embedded extension list at startup. Cost today: ~78.6 MB DLL (compresses substantially in a zip/installer).
3. **Runtime loading exists but is the wrong tool.** `GDExtensionManager.load_extension(path)` is API-available in release builds (only `reload_extension()` is editor-only — docs "GDExtensionManager"). A spring-2026 forum thread (godotengine.org #137586) confirms a runtime `load_extension()` returns `LOAD_STATUS_OK`, classes land in `ClassDB`, and `ClassDB.instantiate()` works — with the caveat that references ste-type-checked at parse (`extends NobodyWhoChat`) crash; `nobodywho_provider.gd` already avoids that (it uses `ClassDB.instantiate`, `:39,47`). BUT there is no documented path for a `user://`-hosted `.gdextension` whose `[libraries]` entry must resolve to a downloaded absolute DLL path; ad-hoc rewriting of generated config files at runtime is undocumented territory, and downloading an unsigned ~78 MB native DLL on first run triggers Windows AV/SmartScreen decisions we cannot sign against (no code signing in the project). Rejected for v1; revisit only if the user must keep a "tiny installer" (then: download DLL+model together with the same verifier, load with `load_extension()`, and force a restart on failure).
4. **Options compared** (decision matrix):

| Option | Local-AI works in shipped exe? | Cost | Risk | Verdict |
|---|---|---|---|---|
| Status quo (exclude addon) | never | 0 | LOCAL unreachable | rejected |
| **Bundle addon+DLL, download model on demand** | yes, after ~771 MB download | +78.6 MB install | low; DLL unchanged upstream | **chosen** |
| Download DLL at runtime + `load_extension()` | maybe | +0 MB install, +78.6 MB download | undocumented `user://` config resolution; AV; unsigned DLL; total failure mode = LOCAL unreachable at runtime | rejected for v1 |
| Raise the whole exe + pck to include a bundled GGUF | yes without download | +2.78 GB / +0.5-0.8 GB distribution | defeats disk-constrained installs | rejected |

5. **NobodyWho does model downloads natively** (upstream README, verified live 2026-10-18: "Model downloading — load models directly from Hugging Face or any URL"; docs.nobodywho.ooo/godot/downloading-models documents `hf://owner/repo`, `owner/repo:QUANT`, `user://`/absolute paths, `%LOCALAPPDATA%\nobodywho\models` cache, `HF_TOKEN` for gated models). This is a credible *long-term* simplification, but the game can't drive it: no documented progress callbacks, no pause/cancel contract, no disk precheck, no checksum verification, and the cache lands outside `user://` where our cleanup/setting story can't manage it. The bundled version predates this API surface anyway (our provider still uses the Node-style legacy API: `model.set("model_path", ...)`, `start_worker()`, `ask()` — `nobodywho_provider.gd:39-62` — while current docs use `await NobodyWhoChat.create(...)`). Chosen: game-owned downloader, NobodyWho gets a local file path only.

### 3.2 Consequences of bundling

- `export_presets.cfg:11` becomes `exclude_filter="tools/*, tests/*, qa/*, models/*"`.
- The `.gdextension` (resource) enters the PCK; the DLL auto-copies beside the exe. Verify with `tools/verify_nobodywho.gd` after an export run.
- The missing-gdextension warning disappears — there is no longer a stale reference to chase.
- `godot/models/README.md` "Install NobodyWho from AssetLib" step becomes release-build-only guidance; the shipped build is self-contained except models.
- The DLL is currently absent from git (root `.gitignore` explicitly ignores `godot/addons/nobodywho/libnobodywho-...dll`); a restore/commit process is needed anyway (open question §9.1), so committing it (or pinning it via a release URL in build tooling) is part of the change.

---

## 4. Default model decision

**Choose `Llama-3.2-1B-Instruct-Q4_K_M.gguf` (807,694,464 bytes ≈ 771 MiB), upstream `https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF` (file `Llama-3.2-1B-Instruct-Q4_K_M.gguf`).**

Justification, ranked:

1. **It is the only candidate verified in-repo to satisfy the game's actual need** — one bounded JSON action object per decision window (`awaiting_ai.gd:15` `DECISION_INTERVAL = 5.0`; output contract documented at `ai_client.gd:200-208`). `nobodywho_provider.gd:55-61` records that clean, parseable `source=local` decisions were verified with Llama-3.2-1B. The JSON-grammar route is dead by measurement, so model *instruction adherence* is the bottleneck — Llama-3.2-1B is the strongest documented adherence at this size in `models/README.md:34-37`.
2. **Byte-exact upstream provenance (verified, not guessed):** local `godot/models/disabled/Llama-3.2-1B-Instruct-Q4_K_M.gguf` SHA-256 = `6f85a640a97cf2bf5b8e764087b1e83da0fdb51d7c9fab7d0fece9385611df83` (measured with `certutil`), matching the HF LFS `oid` (the file content hash) reported by the HF API for `bartowski/Llama-3.2-1B-Instruct-GGUF/tree/main` with the same size 807,694,464. The exact download is therefore predicable: `https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf` (`resolve/main/<filename>` is the canonical HF download URL for the file we verified). Same verification method gives `gemma-2-2b-it-Q8_0.gguf` → `bartowski/gemma-2-2b-it-GGUF` (size 2,784,495,456 matches exactly; LFS oid `2d448a9aab894b8e8e18168cf3f490cb9f65632222f29f93514ac9ecc754debe`).
3. **It is already the project's named model**: `project.godot:64` points at exactly this filename; the file exists locally (in `disabled/`) for development and verification.
4. **Hardware math:** NobodyWho guidance ≈1.5× model file in free RAM (`docs.nobodywho.ooo` + upstream README) → ~1.2 GB RAM burden incl. compute buffers at `CONTEXT_LENGTH=512`; fine on 7.5 GB. Qwen3.5-0.8B is 35 % smaller but *unusable* (README:29 — non-JSON output; the game's tolerant parser then falls back to rule-based every time, i.e. the download buys literally nothing). `gemma-2-2b` Q8 won't load on the target GPU (README:28) and at 2 B params on 2 cores would be ~4-5× slower than the already-too-slow 1 B (measured 90 s + per decision; the cpu-fix plan rejects even 1 B as realtime-viable on this box, :22-24).
5. **Why not bundle the model instead of downloading:** size (0.77-2.78 GB per install), the export explicitly excludes `models/*`, and target-class machines are disk-constrained by assumption. Unchanged goal.

**Explicit non-goals:** shipping SERVER mode artifacts (Python/Ollama) — unchanged; Qwen/gemma as downloadable catalog entries — deferred (§9).

---

## 5. Flow specification

### 5.1 Catalog

New file `godot/scripts/ai/model_catalog.gd` (static-only; no autoload):

```gdscript
const TARGET_DIR := "user://models"
const PART_SUFFIX := ".part"
const REQUIREMENTS := {
    "Llama-3.2-1B-Instruct-Q4_K_M": {
        "url": "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
        "size_bytes": 807694464,                       # from HF API tree (== local file size, verified)
        "sha256": "6f85a640a97cf2bf5b8e764087b1e83da0fdb51d7c9fab7d0fece9385611df83",  # HF LFS oid
        "source": "bartowski/Llama-3.2-1B-Instruct-GGUF (community quant of meta-llama/Llama-3.2-1B-Instruct, license: llama3.2)",
    },
}
```

(iOS-style `json` per entry also records a `license_note` for the credits screen — open question §9.6.)

### 5.2 Downloader — `godot/autoload/model_download.gd` (autoload, name `ModelDownload`)

Separate from `AIClient` (keeps routing clean, matches repo autoload granularity). Signals (repo style, mirrors `server_status_changed`):

```gdscript
signal state_changed(state: int, detail: String)   # State enum below
signal progress_changed(recv: int, total: int)     # bytes
signal finished(ok: bool, detail: String)
```

State machine constants:

```gdscript
enum State {
    IDLE,          # no download configured / never started
    CHECKING,      # existing file/part/meta inspection (sync, cheap)
    PROBING,       # HEAD request: size + Accept-Ranges + ETag
    DOWNLOADING,   # chunked GET loop in flight
    PAUSED,        # user pause, network failure budget exhausted, or disk-low
    VERIFYING,     # size + SHA-256 of .part
    PROMOTING,     # .part -> final rename
    DONE,          # verified file at user://models/<name>.gguf
    FAILED,        # terminal for this run; detail carries the reason code
}
```

Why **chaptered HTTPRequest**, not low-level `HTTPClient`: 4.7 `HTTPRequest` already gives TLS, redirects (`max_redirects=8`), gzip handling and a single completion signal per chunk, and its completion contract is already the codebase's HTTP idiom (every `AIClient` call site). Per-chunk body lives in a `PackedByteArray` (8 MiB max in RAM). 4.7 does **not** have `HTTPRequest.keep_partial_download` / `append_to_download_file` (verified against `docs.godotengine.org/en/4.7/classes/class_httprequest.html`; both appear in `latest` docs only, PR godotengine/godot#118226), and without those flags a one-shot `download_file` write would truncate on resume. When the engine is bumped past 4.7, `download_file` + Range + `append_to_download_file` can replace the loop (noted in code comment for the future).

Chunk loop (verbatim mechanics):

```
CHUNK_BYTES        := 8388608        # 8 MiB — RAM bound per chunk body
CHUNK_TIMEOUT_S    := 30.0           # per-chunk (redirects+headers+data); timeout=0 only for single-shot
MAX_STREAM_RETRIES := 10             # consecutive failed chunks before PAUSED
REQUIRED_FREE_INT  := model_size * 2 # .part + rename headroom + meta
```

1. `_probe()`: `HTTPRequest` `HEAD` on the catalog URL → parse `headers` for `Content-Length`, `Accept-Ranges: bytes`, `ETag`, `Last-Modified`. Non-200/Content-Length=0 → `FAILED(url_unreachable)` (retain resumable part; next Resume re-probes).
2. `_meta_load()`/`_meta_save()`: `user://models/<name>.gguf.json` — `{url, etag, last_modified, size}` via `FileAccess` → `store_var`/`get_var` (JSON-free dictionary, no third-party schema drift).
3. Resume math: existing `.part` bytes `n = FileAccess.get_size(part_path)`; if `n >= size` → straight to `VERIFYING`. Elif `n > 0`: meta `etag` matches HEAD `etag` ⇒ request with `Range: bytes=n-` and **`If-Range: <etag>`** so a changed upstream answers plain 200; we then delete the stale part and restart from 0 (server may not honor 206: verifier `response_code == 206` expected; `200` while resuming ⇒ same restart path). Meta missing while `.part` exists (quit-before-meta-save): truncate decision — treat as restart from 0 only if `n > CHUNK_BYTES` (else delete), avoiding garbage growth.
4. Chunk loop: `req.request(url, PackedStringArray(["Range: bytes=A-B", "If-Range: <etag>", "Accept-Encoding: identity"]), ...)`. Header pins `req.accept_gzip = false` first so Godot does not auto-append `Accept-Encoding: gzip, deflate` (4.7 docs note); `req.timeout = CHUNK_TIMEOUT_S` (per-chunk — safe because we issue windows, unlike a monolithic 0-timeout GET); `body_size_limit` left at -1 (window is our limit).
5. Append: `var f := FileAccess.open(part_path, FileAccess.READ_WRITE)` once per chunk, `f.seek_end()` not needed beyond `f.get_length()`; instead `f.seek(f.get_length())` + `f.store_buffer(body)` + `f.close()`; on write error → `FAILED(write_error)` (keeps part). Cursor math prevents double-appends ( exquisite detail: `store_buffer` advances cursor; subsequent `submit` for the next window must `seek()` to the fresh `get_length()` after re-`open`).
6. Progress: `progress_changed.emit(n, size)` after each chunk; UI also self-renders locally if the manager is paused (no per-frame signal spam).
7. Overflow guard: a chunk may cross `size` (server sends beyond window) — after write, clamp `f.seek(0)`-based size checks; if `get_size(part) > expected_size` after any chunk ⇒ curl-like server error ⇒ truncate to `expected` only if SHA later verifies, else FAILED at VERIFYING (never trust truncation to fix data).
8. `VERIFYING`: `FileAccess.get_size(part) == size` **and** `FileAccess.get_sha256(part) == sha256` (exact HF-pinned constant). Mismatch ⇒ `DirAccess.remove(part)` + delete stale meta ⇒ `FAILED(checksum_mismatch)`. (Of course we could fall back to full redownload once — but the part is then likely fine and re-download wastes hours on 771 MiB; auto-retry once ONLY if the mismatched part was under 95% of size — recorded decision.)
9. `PROMOTING`: `DirAccess.rename(part_path, final_path)` — atomic same-volume move, overwrites an existing destination (4.7 docs: rename overwrites "if not access-protected"). Before rename: `DirAccess.make_dir_recursive(TARGET_DIR)` if needed.
10. `DONE`: `finished(true)` + `state DONE`; then prompts `AIClient.refresh_local_provider()` (§6.3) and emits `local_model_downloaded`.

Pause / resume / cancel:
- `pause()` — set flag; the in-flight chunk completes, then loop halts at `PAUSED` (part is intact; meta already saved).
- `resume()` — restart at `CHECKING` (re-probe reapplies Range).
- `cancel()` — issue `req.cancel_request()` if in flight, then `DirAccess.remove(part)`+`remove(meta)` → `IDLE` (explicit user intent: free the space).
- Quit mid-download (window close, crash): nothing to do — part+meta survive; next launch's background `CHECKING` (autoload `_ready()`: if a `.part` + matching meta exist, auto-continue at `PROBING`; Do NOT auto-download a brand-new model without user intent) resumes.
- Auto-retry budget: `MAX_STREAM_RETRIES` consecutive failures ⇒ `PAUSED` with detail `network_dropout` — the UI label becomes "Paused — tap to resume".

Disk check happens at `CHECKING`, before any byte is written:
```gdscript
var dir := DirAccess.open(TARGET_DIR)          # create first: make_dir_recursive
var free := dir.get_space_left()               # bytes; 0 = platform call failed
if free > 0 and free < REQUIRED_FREE_INT:      # treat 0 as unknown-but-continue
    → PAUSED with detail "disk_low" (needs ~1.5 GB for the 771 MiB model)
```
(4.7 doc caveat: `DirAccess.get_space_left()` "Returns 0 if the platform-specific method to query the available space fails" — on Windows this is NTFS accurate; treat 0 as "cannot know", not as "full".)

### 5.3 UI — Settings screen section

`godot/scenes/ui/settings_screen.gd` builds everything in code (`:17-56`), so the section follows the same pattern:

```
[ Local AI ]
  Download local AI model (~0.75 GB)      [Button]   <- hidden if done
  [ProgressBar] 312/771 MiB   resume/pause  cancel
  Status: "LOCAL AI: downloading / verified / failed (reason)"
  After DONE: "Installed. LOCAL mode active next decision." (+ "Delete model (free 0.75 GB)" second-press confirm)
```

- Bind: `ModelDownload.progress_changed` → `ProgressBar.max_value = size_bytes`, value = recv.
- Buttons: Download → `ModelDownload.start(TARGET_KEY)`; Pause/Resume → `ModelDownload.pause()/resume()`; Cancel → `ModelDownload.cancel()` (with a second-press confirm, repo pattern (`settings_screen.gd` presets are second-press-free but destructive actions confirm).
- Entry point placement: the settings screen is `Main/UI/SettingsScreen` (`main.gd:16`), wired open via `_story.settings_requested` (`main.gd:56`). It is NOT reachable during INVESTIGATION today — add one "Settings" button to the observer top bar (`godot/scenes/ui/observer_panel.gd`, `_update_status` line region) so this flow is usable mid-game. (Small companion change; listed in implementation order.)
- The label copies refer by humanized size from the catalog (`"%0.2f GB/MB" % (size_bytes / 1024.0 / MB)`), never hard-coded — the "…(~0.5 GB)" placeholder in the product brief becomes "(~0.75 GB)" for the chosen model.

### 5.4 Gate on extension availability

Before offering Download, `settings_screen` asks `AIClient._local_provider.is_available()`:
- true → normal flow.
- false → hide Download, show "Local AI runtime is not included in this build." (This state is impossible in the shipped exe after §3.2's export change, but keeps dev builds and regressions honest — a bundle-exclusion typo in `export_presets.cfg` fails here visibly rather than silently.)
- Availability is distinct from model presence: `is_available()` (ClassDB) vs `is_ready()` (ClassDB + chat built).

---

## 6. Integration points (exact)

### 6.1 `nobodywho_provider.gd` — path resolution + reload

Replace `_resolve_model_path()` (`:110-126`) with a downloaded-first order; add reload:

```gdscript
const TARGET_DIR := "user://models"

func _resolve_model_path() -> String:
    # 1) downloaded (user://) wins — catalog order = priority order
    for name in ModelCatalog.REQUIREMENTS:
        var p := TARGET_DIR.path_join(str(name) + ".gguf")
        if FileAccess.file_exists(p):
            return ProjectSettings.globalize_path(p)   # absolute OS path: NobodyWho never sees res/user relativity
    # 2) explicit project setting (dev overrides; existing behavior, nobodywho_provider.gd:111-114)
    # 3) res:// default + auto-discover first .gguf in res://models/ (existing behavior, :115-125)
    ...
```

- `ProjectSettings.globalize_path()` is required because NobodyWho reads the raw OS path; leaving `user://models/...` in would depend on the bundled NobodyWho release documenting/normalizing `user://` (current upstream docs do, but our pinned old-HTML 12.x-out release is not verified to — avoids the risk entirely; dev-mode `res://` still passes through unchanged historically; keep that behavior by globalizing only the user:// branch).
- `FileAccess.file_exists("user://...")` works for any absolute user:// form (4.7 docs: static `FileAccess.file_exists(path)`).

New `reload_model()` on the provider:

```gdscript
func reload_model() -> void:
    if not is_available(): return          # ClassDB gate (same as _ready())
    if _busy and _chat != null: _chat.call("stop_generation")   # mirror _exit_tree (:67-69)
    _teardown()                            # free _chat/_model children, null them
    _model_path = _resolve_model_path()
    if not FileAccess.file_exists(_model_path):
        _model_path = ""; return           # stays inert; next resolve attempts on next call
    _build_model_and_chat()               # extracted from _ready() body (:39-62)
```

Readiness re-evaluation becomes observable:

```gdscript
signal ready_changed(ready: bool)          # new; emit after _ready() build and after reload_model()
```

### 6.2 `ai_client.gd` — re-resolve + signal

```gdscript
signal local_ready_changed(ready: bool)    # new, next to server_status_changed (:12)

func refresh_local_provider() -> void:
    _local_provider.reload_model()
    local_ready_changed.emit(_local_provider.is_ready())
    EventLog.log_action("LOCAL AI model %s" % ("ready" if _local_provider.is_ready() else "missing"), "system")
```

No changes to `resolve_mode()` (it already consults `is_ready()` live, `:67`) — after `reload_model()` the next `request_decision` resolves LOCAL. Decision ordering stays untouched.

### 6.3 `ModelDownload` → `AIClient` handoff

On `DONE`, `AIClient.refresh_local_provider()` runs (autoload cross-call, no timer). `ModelDownload` never reaches into provider internals.

### 6.4 Observer panel repaint

`observer_panel.gd:71-79` `_update_status()` currently repaints only on server-status/pause ticks. Connect `AIClient.local_ready_changed` → `_update_status()` so the `AI: RULE` → `AI: LOCAL` flip is immediate post-download. (Also fixes the same staleness for post-init states.)

### 6.5 Export change

```diff
- exclude_filter="tools/*, tests/*, qa/*, addons/nobodywho/*, models/*"
+ exclude_filter="tools/*, tests/*, qa/*, models/*"
```

Unchanged: `models/*` still excluded (download flow owns them). Addon DLL restore process: open question §9.1.

### 6.6 `models/README.md`

Post-implementation note the game now manages the model path and the "auto-discovers" hint in dev mode gains the user:// mention; the "Install NobodyWho via AssetLib" step becomes release-irrelevant. One paragraph, no links removed.

---

## 7. Test plan (headless, exit-code style per repo runner)

Constraints from the harness: each file is a separate Godot process (`tests/test_all.gd:72-76` uses `OS.execute` + exit code), discovery picks up `test_*.gd` except `test_all.gd` (`:112-113`), and each test enforces its own deadline (`test_tutorial.gd:95-99` pattern) because nothing else will (`test_all.gd:20`). No network, no addon assumptions (a repo checkout may lack the DLL), no real downloads.

| # | File | Injects/mocks | Asserts |
|---|---|---|---|
| T1 | `tests/test_model_path_resolution.gd` | None (pure `FileAccess`/`DirAccess` in `user://`) | (a) resolution order: user:// catalog file wins over the project setting (`ProjectSettings.set_setting("echo/nobodywho_model_path", "res://models/X.gguf")` override inside the test process); (b) setting wins only when user:// is absent; (c) missing-everything → warning path keeps `_model_path` empty and `is_ready()` stays `false`; (d) user:// path becomes an absolute path via `globalize_path()` (contains no `user://` prefix); (e) cleanup: test files removed after. |
| T2 | `tests/test_model_download_core.gd` | `ModelDownload._start_head_probe`/`_start_chunk_request` replaced with fake response queues: `(code, headers, body)` sequences scripted per test; a real `user://models/` test dir (suffix `_test_<pid>`, cleaned up). | (a) happy path tiny fixture (e.g. 3×256 B windows): state CHECKING→PROBING→DOWNLOADING→VERIFYING→PROMOTING→DONE and final file bytes == expected; (b) **interrupted resume**: 2 chunks written, process "restarts" (re-`start()`), server replays Range from the exact offset (`fake sentinel checks the requested Range start == part size`), completes; part never reset; (c) **checksum mismatch**: last byte flipped → `VERIFYING` → FAILED(checksum) and `.part` **deleted**; (d) meta/etag mismatch (HEAD etag ≠ meta etag) + part present → restart from 0 (sentinel bytes not preserved); (e) size-short part then Range continues; (f) `get_space_left` injectable: `disk_low` → PAUSED before any request; (g) deadline + `quit(failures)`. |
| T3 | `tests/test_model_download_ui.gd` | Instantiate `res://scenes/ui/settings_screen.tscn`; inject a fake `ModelDownloadManager` script (extends RefCounted, mirrors signals) via a `bind_manager()` test setter. | Idle → Download press → state label "downloading…", progress label updates on `progress_changed`; Pause → "paused"; Resume → "downloading"; failure signal → label shows reason; `finished(true)` → "Installed…" and Download hidden; Delete → confirm → press clears state. Deadline enforcement as in T2. |
| T4 | `tests/test_provider_ready_reeval.gd` | Stub provider: a small script `tests/stub_local_provider.gd` with `is_available()→true`, `is_ready()` bool, `decide()`; swap into `AIClient._local_provider` in the test process. | (a) `resolve_mode()` flips AUTO: RULE_BASED→LOCAL when stub `is_ready()` true (no server_online); (b) `refresh_local_provider()` emits `local_ready_changed(true)`, and a subsequent `request_decision` returns `source=local`; (c) flip-ready-to-false → next decision falls back to rule-based (existing contract, `ai_client.gd:135-138` unchanged); (d) `reload_model()` on a ClassDB-absent provider (real one, no stub) is a safe no-op returning without crash. |
| T5 | `tests/test_model_disk_gate.gd` | Fake probe error injection (catalog entry pointing at `http://127.0.0.1:1/` reserved port). | (a) unreachable URL → PROBING→FAILED(url_unreachable) fast (< deadline) and no `.part` created; (b) existing (correct) full-size part bumps straight to VERIFYING→DONE with zero network (fake probe asserts no call); (c) stale 0-byte part + valid meta → fresh download from 0. |

Runner integration is automatic: `tests/test_all.gd` discovers by prefix; nothing to register. CI note: none of these tests requires the NobodyWho nodes or network — T4 explicitly uses a stub, keeping the suite green on machines without the DLL (so a bundle regression cannot break the suite, it fails the settings screen check instead, T3).

### Deliberate non-tests

- *Real* HF download as a test (a green "downloaded 5 MB of a 771 MB file" tells us nothing about correctness; costs bandwidth; fails offline). Real-download verification is a manual on-device step after implementation (`tools/`), asserted by re-running `tools/verify_nobodywho.gd` with the downloaded model — reuse, new file, no harness change.

---

## 8. Edge cases

| Case | Handling |
|---|---|
| App quit mid-download | `.part` + meta persist (writes use closed per-chunk handles; meta saved after every chunk). Next launch: `ModelDownload._ready()` sees `.part`+meta ⇒ auto-`PROBING` only if a `.part` exists of a **already-started** entry; brand-new downloads always need explicit user intent. |
| Interrupted while VERIFYING only (e.g. power chip during SHA read) | verification reads are non-mutating; no `.part` truncation; next run re-verifies. |
| Insufficient disk | Precheck at `CHECKING` (`REQUIRED_FREE_INT = 2× size`, ~1.5 GB): PAUSED(disk_low) before any write. Also catches the later "user fills the disk during the download" case at every chunk (`dir.get_space_left()` is re-checked every 256 MiB written, not every chunk — cost). |
| Network drop mid-stream | Per-chunk `timeout` (30 s) + result code → retry the same window up to `MAX_STREAM_RETRIES`, each retry recomputes Range from current part size (never trusts previous attempt's write). Exhausted ⇒ PAUSED(network_dropout) — UI's Resume re-arms. |
| Server ignores Range (200 instead of 206 on resume) | Restart from 0 — we detect `code==200` mid-download and delete the part (can't trust any bytes). If-Range minimizes this window; HF is Range-capable (its own download cache design relies on it — the HF-backed asset server returns 206 for byte ranges; if an intermediary strips it, restart-from-0 is still correct, just slow). |
| Checksum mismatch | FAILED(checksum_mismatch), part deleted. Only auto-retry when part was < 95 % complete (mid-transfer corruption more likely than post-verification bitflip; full-redownload cost on 771 MiB on a constrained connection is defensible). |
| Model present but extension missing (shipped-exe regression, or a user who deleted `addons/nobodywho/` from an installed dir) | `settings_screen` checks `is_available()`: hides download, shows "Local AI runtime missing". If already downloaded: provider `_build()` never runs; everything degrades to today's fallback behavior; **the model file is preserved** (not treated as invalid). |
| RAM pressure while LOCAL is active | Model load itself is eager and synchronous at `_ready()`/reload. With 7.5 GB total (target ~0.7-1.0 GB free after OS+game), a 771 MB CPU-only model fits (NobodyWho guidance 1.5×, CPU-only, `context_length=512`). The provider already serializes decisions and awaits `stop_generation()` before reload — a user downloading **while playing** would flip `RULE_BASED→LOCAL` mid-session, so `refresh_local_provider()` is called only when the screen is exited (or immediately: it's < 1 s on a 771 MB file) and the observer repaints. Both choices enumerated for the implementer; default: immediate. |
| Benign "missing .gdextension" warning | Root cause today: the exported PCK's embedded extension list still references `res://addons/nobodywho/nobodywho.gdextension` which the export filter removed — the engine then logs "GDExtension dynamic library not found"-family noise at startup (godotengine/godot#87761 mechanics). Bundling (§3.2) removes the reference and the warning together. Do not add code to suppress it (there is no clean engine-level mute; and the warning would reappear in a broken bundle, which is exactly when we want it). |
| Concurrent LOCAL decide vs reload | `reload_model()` runs `_chat.stop_generation()` when busy (`§6.1`) — a pending `decide()` callback will be served from the redone chat or miss (time out → error path `nobodywho_provider.gd:101-107`). Torn decisions are impossible because one shared busy flag serializes; callbacks are never lost silently (empty-string push → rule-based). |

---

## 9. Open questions (need owner input)

1. **NobodyWho DLL restoration & version pin.** The working tree lacks the real `libnobodywho-godot-x86_64-pc-windows-msvc-release.dll` (78.6 MB; only the `~` hot-reload temp remains; gitroot ignores it deliberately). Which release do we bundle — current `12.x` (requires Godot 4.6+; ✓ our 4.7) or the legacy 4.5-API the provider matches? Current docs' Godot API is `await NobodyWhoChat.create(...)` — different from our provider. Pin + adapt `nobodywho_provider.gd` (small, contained) **or** pin a legacy 4.5-compat release + keep the provider. Either way: verify with `tools/verify_nobodywho.gd`.
2. **Qwen3.5-0.8B upstream.** No authoritative repo offers a file matching our local byte size (527,503,680). Closest community hits: `ertghiu256/Qwen3.5-0.8b-instruct-v2-gguf` (`Qwen3.5-0.8B.Q4_K_M.gguf = 541,903,584`) — different file, different run. Model is rejected on merit anyway (README:29) → **question: drop it from the catalog entirely, or keep as "tiny" alternative despite reported quality?** Default: drop.
3. **Offer gemma q8/q4 in the catalog?** `bartowski/gemma-2-2b-it-GGUF` is verified (byte-exact Q8, and Q4_K_M 1,708,582,752 exists there too). On minimum spec it's unusable; on players with 8+ cores it's the quality jump. delaying it to P2 keeps the catalog point; whether to ship a size-graded multi-entry chooser is a product call.
4. **LOCAL decision timeout.** Measured 90 s+ per decision at 1 B on this CPU class (`docs/superpowers/plans/2026-07-13-plan-local-ai-cpu-fix.md:14-24`), and the `request_ai_decision` leaf holds `WAITING` with no deadline (`scripts/behavior/request_ai_decision.gd:58-60`). AI mode with a downloaded model on minimum spec will read as "slow thinkers" — acceptable per product, but do we add a per-decision wall-clock cap (e.g. 120 s → rule-based) in the same increment so NPC behavior stays observable? Recommend yes (P1); needs design sign-off because it changes freeze semantics for SERVER responses too if done at the router level.
5. **Distribution channel for the bundle.** Bundled DLL (~78.6 MB, compresses in installer) rides the same installer zip as the exe — any store/Itch/Steam upload limit needs a look if it encodes ~30 MB extra; alternate case is a "separate LOCAL-AI pack" installer which defeats the point.
6. **Licensing/attribution lines.** Llama-3.2 redistribution is under Meta's Llama Community License (attribution + acceptable-use notice in credits); NobodyWho itself is EUPL-1.2 ("proprietary distribution fine; modifications to code of this repo must be shared") — verify the two attribution paragraphs go in the credits screen when we bundle.
7. **Auto-download on first run?** Default chosen: explicit user action only. If the product wants "seamless first-run upgrade", it belongs after the flow proves out.

---

## 10. Recommended implementation order

1. **P0-a — restore & pin the NobodyWho DLL** (open question §9.1): commit or re-vendor the DLL; verify `tools/verify_nobodywho.gd` passes in the current tree again. No release-flow change yet.
2. **P0-b — export change**: `export_presets.cfg:11` un-exclude addon; run an export; confirm `addons/nobodywho/libnobodywho...dll` sits next to `build/windows/ProjectChimera.exe` and the extended-classes warning is gone; re-run `tools/verify_nobodywho.gd` against the exported dir.
3. **P0-c — catalog + path resolution** (`model_catalog.gd`, `nobodywho_provider.gd` §6.1: `_resolve_model_path()` order, `reload_model()`, `ready_changed`) + `ai_client.gd` §6.2 (`local_ready_changed`, `refresh_local_provider()`). Ship T1 + T4.
4. **P0-d — downloader core** (`model_download.gd` autoload): state machine, probe, chunked Range resume, meta, verify, promote, disk gate; plus T2 + T5. No UI yet — drivable via a debug console line.
5. **P0-e — settings screen section + observer entry point** (§5.3, §6.4): progress UI wired to signals; T3. Observer *"Settings"* button is the only non-AI-file touch.
6. **P1 — polish + honest UX**: mode label repaint (already in 5); local-decide timeout (open question §9.4) if signed off; `models/README.md` §6.6 note; credits-screen attribution (§9.6); size graded second catalog entry (§9.3).
7. **P2 — deferred**: runtime-GDExtension-download alternative (only if a "small installer" product constraint appears); nobodywho-native downloader reroute once a release with progress callbacks is pinned; "delete model" UI affordance polished.
