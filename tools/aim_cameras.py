#!/usr/bin/env python
"""Re-aim the fixed cameras until they match the views the dataset was recorded with.

Use this whenever the rig has been moved — a new room, a bumped tripod, the venue on talk day.
A policy is a function of pixels: if `top` and `base` do not frame the scene the way they framed it
during recording, the arm reaches vaguely and bobs up and down without ever closing on the object
([[policy-does-not-survive-a-new-table]], [[camera-order-matters]]). Eyeballing it is not enough —
this prints a live score so you can nudge a camera and watch the number move.

    source tools/env.sh macbook
    uv run python tools/aim_cameras.py              # live scores, Ctrl-C to stop
    uv run python tools/aim_cameras.py top          # one camera, bigger and faster

Reading the score (correlation against assets/camera-reference/<key>.png):

    > 0.80   as good as the same scene gets — stop adjusting
    0.60-0.80  usable; this is where the working desktop rig sat (top 0.70, base 0.65)
    0.30-0.60  the framing is off; the policy will be unreliable
    < 0.30   a different view entirely — wrong aim, wrong camera, or the scene is rearranged

The wrist camera is deliberately not scored: it is mounted on the gripper, so its view follows the
arm pose and a fixed reference means nothing for it (see assets/camera-reference/README.md).

Brightness is scored too, because it drifts independently of aim and macOS cannot lock exposure
([[lock-exposure-and-white-balance]]). `ratio` is live mean / reference mean; aim for 0.85-1.15.
"""

from __future__ import annotations

import os
import re
import sys
import time
from pathlib import Path

import cv2
import numpy as np

BLOCK = re.compile(r"(\w+)\s*:\s*\{([^}]*)\}")
FIELD = re.compile(r"(\w+)\s*:\s*([^,}]+)")
REFERENCE_DIR = Path(__file__).resolve().parent.parent / "assets" / "camera-reference"


def parse(spec: str) -> list[dict]:
    cams = []
    for key, body in BLOCK.findall(spec):
        f = {k: v.strip() for k, v in FIELD.findall(body)}
        cams.append(
            {
                "key": key,
                "index": f.get("index_or_path", ""),
                "width": int(f.get("width", 640)),
                "height": int(f.get("height", 480)),
            }
        )
    return cams


def thumbnail(img: np.ndarray) -> np.ndarray:
    """Downscale hard and contrast-normalise: geometry dominates, objects and light do not."""
    small = cv2.resize(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), (48, 36)).astype(np.float32)
    small -= small.mean()
    norm = np.linalg.norm(small)
    return small / norm if norm else small


def verdict(score: float) -> str:
    if score >= 0.80:
        return "EXCELLENT - stop here"
    if score >= 0.60:
        return "good (the working desktop rig was 0.65-0.70)"
    if score >= 0.30:
        return "OFF - keep adjusting"
    return "WRONG VIEW - different aim or rearranged scene"


def bar(score: float, width: int = 24) -> str:
    filled = int(max(0.0, min(1.0, score)) * width)
    return "#" * filled + "." * (width - filled)


def main() -> int:
    spec = os.environ.get("CAMERAS", "")
    if not spec:
        sys.exit("CAMERAS is empty — run: source tools/env.sh <machine>")
    wanted = sys.argv[1] if len(sys.argv) > 1 else None

    cams = [c for c in parse(spec) if (REFERENCE_DIR / f"{c['key']}.png").exists()]
    if wanted:
        cams = [c for c in cams if c["key"] == wanted]
    if not cams:
        sys.exit(
            f"no camera with a reference in {REFERENCE_DIR}.\n"
            "Generate them from the dataset: uv run python tools/verify_cameras.py <dataset>, then\n"
            "cp outputs/verify_cameras/recorded_<key>.png assets/camera-reference/<key>.png"
        )

    refs, caps = {}, {}
    for c in cams:
        refs[c["key"]] = cv2.imread(str(REFERENCE_DIR / f"{c['key']}.png"))
        cap = cv2.VideoCapture(int(c["index"]) if c["index"].isdigit() else c["index"])
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, c["width"])
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, c["height"])
        caps[c["key"]] = cap

    print(f"reference: {REFERENCE_DIR}")
    print("Nudge a camera and watch the score. Ctrl-C when every line says good or better.\n")
    try:
        while True:
            lines = []
            for c in cams:
                key = c["key"]
                frame = None
                for _ in range(4):
                    ok, f = caps[key].read()
                    if ok and f is not None:
                        frame = f
                if frame is None:
                    lines.append(f"  {key:>6}  no frame")
                    continue
                ref = refs[key]
                score = float(np.sum(thumbnail(frame) * thumbnail(ref)))
                ratio = float(np.mean(frame)) / max(float(np.mean(ref)), 1.0)
                light = "ok" if 0.85 <= ratio <= 1.15 else ("TOO DARK" if ratio < 0.85 else "TOO BRIGHT")
                lines.append(
                    f"  {key:>6}  [{bar(score)}] {score:+.2f}  {verdict(score):<42}"
                    f"  light x{ratio:.2f} {light}"
                )
            sys.stdout.write("\033[2J\033[H")  # clear, so the numbers sit still while you adjust
            print(f"reference: {REFERENCE_DIR}   (Ctrl-C to stop)\n")
            print("\n".join(lines), flush=True)  # flush: stays live when piped or logged
            time.sleep(0.4)
    except KeyboardInterrupt:
        print("\nstopped.")
    finally:
        for cap in caps.values():
            cap.release()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
