#!/usr/bin/env python3
"""Deterministic visual-QA pipeline orchestrator.

Claude-of-Duty harness mapping:
  - baseline.mjs "isolated page per shot"  -> one fresh Godot process per shot
  - fixed frame budget                     -> --fixed-fps + exact frame staging
  - imagediff.mjs non-zero gate            -> visual_diff.gd exit code

Usage:
  uv run tools/run_visual_shots.py --init     # first run: create baselines
  uv run tools/run_visual_shots.py            # capture + diff (exit != 0 on drift)

Requires the WINDOWED Godot build for captures (headless renders nothing);
the diff step runs headless. A brief game window appears per shot.
"""

import argparse
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
GODOT_WINDOWED = Path(r"C:\Users\aditya\Desktop\Godot472\Godot_v4.7.2-stable_win64.exe")
GODOT_CONSOLE = Path(r"C:\Users\aditya\Desktop\Godot472\Godot_v4.7.2-stable_win64_console.exe")
GODOT_PROJECT = PROJECT / "godot"
CAPTURES = GODOT_PROJECT / "qa" / "captures"

SHOTS = [
    "cinematic",
    "story_choice",
    "dorm",
    "bedroom",
    "case_panel",
    "interrogation",
    "dialogue",
    "accusation",
    "travel_map",
    "settings",
]

FIXED_FPS = 30
SETTLE_FRAMES = 45
SEED = 1337


def run_capture(shot: str) -> bool:
    out = CAPTURES / f"{shot}.png"
    if out.exists():
        out.unlink()  # fail loudly if this shot's capture doesn't regenerate
    cmd = [
        str(GODOT_WINDOWED),
        "--path", str(GODOT_PROJECT),
        "--fixed-fps", str(FIXED_FPS),
        "-s", "res://tools/visual_capture.gd",
        "--",
        f"shot={shot}",
        f"settle={SETTLE_FRAMES}",
        f"seed={SEED}",
    ]
    print(f"[capture] {shot} ...", flush=True)
    proc = subprocess.run(cmd, cwd=PROJECT, capture_output=True, text=True, timeout=180)
    ok = out.exists()
    status = "ok" if ok else "MISSING PNG"
    print(f"[capture] {shot}: {status}", flush=True)
    if not ok:
        tail = "\n".join((proc.stdout or "").splitlines()[-8:])
        err_tail = "\n".join((proc.stderr or "").splitlines()[-8:])
        print(tail)
        print(err_tail, file=sys.stderr)
    return ok


def run_diff(init: bool) -> int:
    cmd = [str(GODOT_CONSOLE), "--headless", "--path", str(GODOT_PROJECT),
           "-s", "res://tools/visual_diff.gd"]
    if init:
        cmd += ["--", "--init"]
    proc = subprocess.run(cmd, cwd=PROJECT, capture_output=True, text=True, timeout=300)
    print(proc.stdout or "")
    if proc.returncode != 0:
        print(f"[diff] FAILED shots: {proc.returncode}", file=sys.stderr)
    else:
        print("[diff] all shots within tolerance")
    return proc.returncode


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--init", action="store_true",
                    help="REFRESH all baselines from this run's captures")
    ap.add_argument("--only", default=None,
                    help="capture a single named shot instead of all")
    args = ap.parse_args()

    if not GODOT_WINDOWED.exists():
        print(f"windowed Godot not found: {GODOT_WINDOWED}", file=sys.stderr)
        return 2

    shots = [args.only] if args.only else SHOTS
    missing = 0
    for shot in shots:
        if not run_capture(shot):
            missing += 1
    if missing:
        print(f"{missing} capture(s) failed", file=sys.stderr)
        return 2

    if args.init:
        baseline_dir = GODOT_PROJECT / "qa" / "baseline"
        baseline_dir.mkdir(parents=True, exist_ok=True)
        import shutil
        # Only overwrite baselines for the shots just captured — never wipe
        # siblings (a full --init still refreshes every shot in SHOTS).
        for shot in shots:
            shutil.copyfile(CAPTURES / f"{shot}.png", baseline_dir / f"{shot}.png")
            print(f"[init] baseline refreshed: {shot}")
        # Baselines now mirror these exact captures; verify pipeline is green.
        return run_diff(False)

    return run_diff(False)


if __name__ == "__main__":
    sys.exit(main())
