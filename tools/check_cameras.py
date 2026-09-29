#!/usr/bin/env python
"""Pre-flight the cameras in $CAMERAS before a long recording session.

Camera indices are baked into the dataset ([[camera-keys-are-baked-in]]) and on macOS they shift
whenever a camera, a hub or the Continuity Camera comes and goes ([[camera-indices-shift-on-replug]]).
This opens every camera in the profile's $CAMERAS block, checks it returns a *live* frame at the
recording resolution, and writes one PNG per key so you can confirm the views before spending hours.

It also compares each feed against a stored reference view, which is what catches the failure a
black-frame test cannot: a camera that opens fine but is the WRONG ONE. On macOS the indices are
positional, so when a USB camera fails to enumerate the built-in FaceTime camera quietly slides into
its slot and the policy is fed a view it has never seen ([[camera-indices-shift-on-replug]]).

Usage:
    source tools/env.sh macbook
    uv run python tools/check_cameras.py                 # checks $CAMERAS
    uv run python tools/check_cameras.py "$CAMERAS_THREE"
    CAM_SHOTS=/tmp/shots uv run python tools/check_cameras.py
    uv run python tools/check_cameras.py --save-reference # record today's views as the reference

Run --save-reference once, on the machine and scene you recorded the dataset with. Afterwards every
check scores each feed against it: a gross mismatch (different camera, camera pointing elsewhere)
fails, a moderate one warns. It is a heuristic on a 64x48 grayscale thumbnail — it catches "wrong
camera", not a two-centimetre shift in the mount.

Exit code 0 = every camera opened, returned a live image, and matched its reference.
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


REFERENCE_DIR = Path(__file__).resolve().parent.parent / "assets" / "camera-reference"
FAIL_BELOW = 0.35   # below this the feed is a different scene altogether
WARN_BELOW = 0.65   # below this something moved; look at the PNG before recording


def thumbnail(frame: np.ndarray) -> np.ndarray:
    """64x48 grayscale, contrast-normalised: compares framing, not lighting or object placement."""
    small = cv2.resize(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY), (64, 48)).astype(np.float32)
    small -= small.mean()
    norm = np.linalg.norm(small)
    return small / norm if norm > 1e-6 else small


def similarity(frame: np.ndarray, reference: np.ndarray) -> float:
    """Normalised cross-correlation in [-1, 1]; ~1 = same view, ~0 = unrelated."""
    return float(np.sum(thumbnail(frame) * thumbnail(reference)))


def compare_to_reference(key: str, frame: np.ndarray) -> tuple[bool, str]:
    path = REFERENCE_DIR / f"{key}.png"
    if not path.is_file():
        return True, "  (no reference yet — run --save-reference on the recording scene)"
    reference = cv2.imread(str(path))
    if reference is None:
        return True, f"  WARNING: unreadable reference {path}"
    score = similarity(frame, reference)
    if score < FAIL_BELOW:
        return False, (
            f"  WRONG VIEW: matches its reference only {score:.2f} — this is probably a different "
            f"camera (macOS: the built-in one taking a missing USB camera's index). Compare against {path}"
        )
    if score < WARN_BELOW:
        return True, f"  WARNING: view moved (match {score:.2f}) — compare against {path} before recording"
    return True, f"  view matches reference ({score:.2f})"


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
        ok_view, view_note = compare_to_reference(cam["key"], frame)
        return ok_view, f"live {got[0]}x{got[1]} mean={mean:5.1f} std={std:5.1f}{note}\n{view_note}"
    finally:
        cap.release()


def save_references(cams: list[dict]) -> int:
    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
    for cam in cams:
        source = int(cam["index"]) if cam["index"].isdigit() else cam["index"]
        cap = cv2.VideoCapture(source)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, cam["width"])
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, cam["height"])
        frame = None
        for _ in range(15):
            ok, f = cap.read()
            if ok and f is not None:
                frame = f
        cap.release()
        if frame is None:
            print(f"  {cam['key']:>6}: no frame — not saved")
            continue
        path = REFERENCE_DIR / f"{cam['key']}.png"
        cv2.imwrite(str(path), frame)
        print(f"  {cam['key']:>6} (index {cam['index']}): saved {path}")
    print("\n  Look at these PNGs now: they define what 'correct' means from here on.")
    print("  They are small and belong in git — they travel with the scene kit.")
    return 0


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--save-reference"]
    saving = "--save-reference" in sys.argv
    spec = args[0] if args else os.environ.get("CAMERAS", "")
    if not spec:
        sys.exit("CAMERAS is empty — run: source tools/env.sh <machine>")
    cams = parse(spec)
    if not cams:
        sys.exit(f"could not parse any camera out of: {spec}")
    if saving:
        return save_references(cams)

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
