#!/usr/bin/env python
"""Pre-flight the cameras in $CAMERAS before a long recording session.

Camera indices are baked into the dataset ([[camera-keys-are-baked-in]]) and on macOS they shift
whenever a camera, a hub or the Continuity Camera comes and goes ([[camera-indices-shift-on-replug]]).
This opens every camera in the profile's $CAMERAS block, checks it returns a *live* frame at the
recording resolution, and writes one PNG per key so you can confirm the views before spending hours.

Usage:
    source tools/env.sh macbook
    uv run python tools/check_cameras.py                 # checks $CAMERAS
    uv run python tools/check_cameras.py "$CAMERAS_THREE"
    CAM_SHOTS=/tmp/shots uv run python tools/check_cameras.py

Exit code 0 = every camera opened and returned a live image.
"""

import os
import re
import sys
from pathlib import Path

import cv2
import numpy as np

BLOCK = re.compile(r"(\w+)\s*:\s*\{([^}]*)\}")
FIELD = re.compile(r"(\w+)\s*:\s*([^,}]+)")


def parse(spec: str) -> list[dict]:
    """Parse the `{ top: {type: opencv, index_or_path: 0, ...}, wrist: {...} }` env block."""
    cams = []
    for key, body in BLOCK.findall(spec):
        fields = {k: v.strip() for k, v in FIELD.findall(body)}
        cams.append(
            {
                "key": key,
                "index": fields.get("index_or_path", ""),
                "width": int(fields.get("width", 640)),
                "height": int(fields.get("height", 480)),
                "fps": int(fields.get("fps", 30)),
            }
        )
    return cams


def check(cam: dict, shots: Path) -> tuple[bool, str]:
    index = cam["index"]
    source = int(index) if index.isdigit() else index
    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        cap.release()
        return False, "cannot open — wrong index, unplugged, or claimed by another process"
    try:
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, cam["width"])
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, cam["height"])
        cap.set(cv2.CAP_PROP_FPS, cam["fps"])
        frame = None
        for _ in range(15):  # first frames are often empty
            ok, f = cap.read()
            if ok and f is not None:
                frame = f
        if frame is None:
            return False, "opens but returns no frame"
        got = (int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)))
        mean, std = float(np.mean(frame)), float(np.std(frame))
        cv2.imwrite(str(shots / f"{cam['key']}.png"), frame)
        if mean < 3 and std < 3:
            return False, f"BLACK frame ({got[0]}x{got[1]}) — lens cap, no light, camera permission, or unpowered hub"
        note = ""
        if (got[0], got[1]) != (cam["width"], cam["height"]):
            note = f"  WARNING: got {got[0]}x{got[1]}, asked {cam['width']}x{cam['height']}"
        if mean < 25:
            note += "  WARNING: very dark — add light before recording"
        return True, f"live {got[0]}x{got[1]} mean={mean:5.1f} std={std:5.1f}{note}"
    finally:
        cap.release()


def main() -> int:
    spec = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("CAMERAS", "")
    if not spec:
        sys.exit("CAMERAS is empty — run: source tools/env.sh <machine>")
    cams = parse(spec)
    if not cams:
        sys.exit(f"could not parse any camera out of: {spec}")

    shots = Path(os.environ.get("CAM_SHOTS", Path.home() / ".cache/lerobot-vault/camera-check"))
    shots.mkdir(parents=True, exist_ok=True)

    failures = []
    for cam in cams:
        ok, message = check(cam, shots)
        print(f"  {cam['key']:>6} (index {cam['index']}): {'OK  ' if ok else 'FAIL'} {message}")
        if not ok:
            failures.append(cam["key"])

    print(f"\n  frames written to {shots}   (open {shots})")
    if failures:
        print(
            f"\n  {len(failures)} camera(s) not usable: {', '.join(failures)}\n"
            "  Fix before recording — the keys and indices are baked into the dataset.\n"
            "  macOS: tools/mac_cameras.sh   Linux: tools/find.sh"
        )
        return 1
    print("  all cameras live — confirm the views in the PNGs, then record.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
