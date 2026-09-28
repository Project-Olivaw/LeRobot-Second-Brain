#!/usr/bin/env bash
# Diagnose USB cameras on macOS, where `lerobot-find-cameras` gives no clue why a camera is missing.
# It answers, in order: does macOS see the camera at all? does this terminal have permission?
# which OpenCV index is which? Usage: tools/mac_cameras.sh
set -uo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
[ "$(uname)" = "Darwin" ] || { echo "macOS only — on Linux use tools/find.sh and /dev/v4l/by-id (hardware/cameras.md)" >&2; exit 1; }

printf '\n\033[1m1. Cameras macOS itself can see (ground truth, independent of OpenCV)\033[0m\n'
system_profiler SPCameraDataType 2>/dev/null | sed -n 's/^ *\([^:]*\):$/  - \1/p' | grep -v '^  - Camera$' || true
printf '\n\033[1m   USB devices that look like cameras\033[0m\n'
system_profiler SPUSBDataType 2>/dev/null | grep -iB1 -A4 "camera\|uvc\|webcam" | grep -iE "^ +[A-Za-z].*:$|Product ID|Speed|Current Available|Current Required" | sed 's/^/  /' || echo "  (none found)"

printf '\n\033[1m2. Does THIS terminal have camera permission?\033[0m\n'
echo "  If a camera opens but every frame is black, permission is the cause — macOS hands out"
echo "  black frames instead of an error. Fix: System Settings > Privacy & Security > Camera,"
echo "  enable your terminal app (Ghostty/iTerm/Terminal), then FULLY QUIT and reopen it."
echo "  A permission prompt only appears the first time a process asks; if you dismissed it, the"
echo "  app stays denied until you toggle it there."

printf '\n\033[1m3. What OpenCV can open, index by index\033[0m\n'
$RUN python - <<'PY'
import cv2, numpy as np
found = []
for i in range(8):
    cap = cv2.VideoCapture(i)          # AVFoundation on macOS
    if not cap.isOpened():
        cap.release(); continue
    for _ in range(8): ok, frame = cap.read()   # warm up; first frames are often empty
    w, h = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    if ok and frame is not None:
        mean = float(np.mean(frame)); std = float(np.std(frame))
        verdict = "BLACK (permission? lens cap? unpowered hub?)" if mean < 3 and std < 3 else "live image"
        print(f"  index {i}: {w}x{h}  mean={mean:5.1f} std={std:5.1f}  -> {verdict}")
        found.append(i)
    else:
        print(f"  index {i}: opens but returns no frame")
    cap.release()
print(f"\n  usable indices: {found}" if found else "\n  no cameras opened at all")
PY

printf '\n\033[1m4. Save one frame per index so you can tell top / wrist / base apart\033[0m\n'
echo "  $RUN lerobot-find-cameras opencv   # writes outputs/captured_images/"
cat <<'NOTE'

If a USB camera is missing from step 1 as well, it is a USB problem, not a software one:
  - Bus-powered hub: three UVC cameras plus two arms exceed what a MacBook port supplies.
    Use a POWERED hub, or split the cameras across both sides of the machine.
  - Some UVC cameras reserve full uncompressed bandwidth on connect; plugging them in ONE AT A TIME
    (waiting for each to appear in step 1) often gets all three enumerated where plugging all three
    at once gets one.
  - The built-in FaceTime camera and Continuity Camera (iPhone) also occupy indices. Turn off
    Continuity Camera: iPhone > Settings > General > AirPlay & Continuity > Continuity Camera.
  - Try a different cable: many thin USB cables are charge-only or too long for 480 Mbit/s.
NOTE
