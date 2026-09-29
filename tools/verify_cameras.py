#!/usr/bin/env python
"""Prove that each camera key still shows what it showed when the dataset was recorded.

The failure this catches is silent and expensive: a camera key (`top`, `wrist`, `base`) that points
at a different physical lens than it did during recording. Nothing errors — the policy just behaves
like a badly trained one, which is indistinguishable from "we need more data".
See lessons/camera-order-matters.md; it cost this project a full evaluation session.

What it does: pulls one reference frame per key out of the recorded dataset, grabs one live frame
per key from the cameras the current profile resolves, and scores every live frame against every
reference frame. The best match per reference should be the key with the same name.

Usage (after `source tools/env.sh desktop|macbook`):
    uv run python tools/verify_cameras.py <dataset_name> [out_dir]

Works on Linux and macOS: it reads the indices out of $CAMERAS, so whatever the profile resolved
(by-id, by-path, or a bare index on macOS) is what gets tested.

Reading the output:
    every key OK                -> safe to record, evaluate or demo
    keys swapped                -> fix the profile or the cables, then re-run. On Linux swap the
                                   CAM_*_PATH/_ID values in machines/<machine>.env; on macOS swap
                                   the index_or_path numbers.
    a key scores low everywhere -> the scene changed (that is fine, look at the PNGs and judge), or
                                   that camera moved / is dark / is covered.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

import cv2
import numpy as np

REFERENCE_FRAME = 30  # a bit into the episode, past any startup flicker
# A correct camera scored 0.50-0.69 against its own recorded view with the objects moved, so the
# floor sits well below that: a genuine swap is caught by the best-match test, not by this number.
MIN_SCORE = 0.35
WARMUP_READS = 12  # UVC cameras hand out stale/empty buffers for the first few reads


def parse_cameras(spec: str) -> dict[str, int]:
    """Pull {key: index} out of the $CAMERAS draccus blob the profile exports."""
    return {k: int(v) for k, v in re.findall(r"(\w+)\s*:\s*\{[^}]*index_or_path:\s*(\d+)", spec)}


def dataset_root(name: str) -> Path:
    home = os.environ.get("HF_LEROBOT_HOME") or (Path.home() / ".cache/huggingface/lerobot")
    prefix = os.environ.get("DATASET_PREFIX", "local")
    root = Path(home) / (name if "/" in name else f"{prefix}/{name}")
    if not root.exists():
        sys.exit(f"dataset not found: {root}")
    return root


def reference_frames(root: Path, out: Path) -> dict[str, np.ndarray]:
    """One frame per camera key, decoded from the dataset's own videos."""
    frames = {}
    for video_dir in sorted((root / "videos").glob("observation.images.*")):
        key = video_dir.name.rsplit(".", 1)[-1]
        mp4 = next(iter(sorted(video_dir.rglob("*.mp4"))), None)
        if mp4 is None:
            continue
        path = out / f"recorded_{key}.png"
        subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-y", "-i", str(mp4),
             "-vf", f"select=eq(n\\,{REFERENCE_FRAME})", "-vframes", "1", str(path)],
            check=True,
        )
        frames[key] = cv2.imread(str(path))
    return frames


def live_frames(cameras: dict[str, int], out: Path) -> dict[str, np.ndarray]:
    frames = {}
    for key, index in cameras.items():
        # CAP_V4L2 can set MJPG/size on Linux; on macOS the default AVFoundation backend is correct.
        backend = cv2.CAP_V4L2 if sys.platform.startswith("linux") else cv2.CAP_ANY
        cap = cv2.VideoCapture(index, backend)
        cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        ok, frame = False, None
        for _ in range(WARMUP_READS):
            ok, frame = cap.read()
        cap.release()
        if not ok or frame is None:
            print(f"  {key}: index {index} returned no frame — see hardware/cameras.md")
            continue
        cv2.imwrite(str(out / f"live_{key}.png"), frame)
        frames[key] = frame
    return frames


def similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Correlation of heavily downscaled, contrast-normalised greyscale.

    Small enough that moved objects and lighting barely matter, but the overall geometry of a view
    (overhead table vs gripper close-up vs low side angle) dominates — which is exactly the thing
    that must not change.
    """
    def prep(img: np.ndarray) -> np.ndarray:
        small = cv2.resize(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), (48, 36)).astype(np.float32)
        small -= small.mean()
        norm = np.linalg.norm(small)
        return small / norm if norm else small

    return float((prep(a) * prep(b)).sum())


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    name = sys.argv[1]
    out = Path(sys.argv[2] if len(sys.argv) > 2 else "outputs/verify_cameras")
    out.mkdir(parents=True, exist_ok=True)

    spec = os.environ.get("CAMERAS")
    if not spec:
        sys.exit("CAMERAS is not set — run: source tools/env.sh desktop|macbook")
    cameras = parse_cameras(spec)
    print(f"profile resolves: {cameras}")

    root = dataset_root(name)
    print(f"reference: {root}")
    recorded = reference_frames(root, out)
    live = live_frames(cameras, out)
    if not recorded or not live:
        sys.exit("nothing to compare")

    missing = set(recorded) - set(live)
    if missing:
        print(f"\n  WARNING: the dataset has {sorted(missing)} but the profile does not — "
              "the policy expects those views (lessons/smolvla-camera-slots.md)")

    print(f"\n{'recorded key':<14}{'best live match':<18}{'score':>7}   verdict")
    ok = True
    for key, ref in sorted(recorded.items()):
        scores = {live_key: similarity(ref, frame) for live_key, frame in live.items()}
        best = max(scores, key=scores.get)
        if best == key and scores[best] >= MIN_SCORE:
            verdict = "OK"
        elif best != key:
            verdict = f"SWAPPED — '{key}' is now on the camera you call '{best}'"
            ok = False
        else:
            verdict = "same key, but the view changed a lot — look at the PNGs"
            ok = False
        print(f"{key:<14}{best:<18}{scores[best]:>7.2f}   {verdict}")

    print(f"\nimages: {out}/recorded_*.png vs {out}/live_*.png")
    if not ok:
        print("\nFix before recording or evaluating — a swapped camera silently ruins inference.")
        print("  Linux: swap CAM_*_PATH / CAM_*_ID in machines/<machine>.env, re-source, re-run.")
        print("  macOS: swap the index_or_path values in machines/macbook.env, re-source, re-run.")
        sys.exit(1)
    print("\nAll keys match what was recorded.")


if __name__ == "__main__":
    main()
