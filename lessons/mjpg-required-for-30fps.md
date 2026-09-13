# MJPG is required to get 30 fps at 640x480

LeRobot demands the camera deliver **exactly** the requested fps. In its default uncompressed
YUYV mode the WENKIA webcam only reaches 20 fps at 640x480, so `fps: 30` fails with
`RuntimeError: OpenCVCamera(0) failed to set fps=30 (actual_fps=20.0)`.

Fix: add `fourcc: MJPG` to every camera block. MJPG is compressed on-camera (~10x smaller), so the
same USB bandwidth carries 30 fps — and three cameras fit on one bus.

Fallback if MJPG still cannot reach 30: use `fps: 20` **everywhere** (camera block, recording,
training) — fps is the dataset/control rate and must be consistent.

Related: [[usb-bandwidth-three-cams]], [[integer-index-not-dev-path]], [[cameras]].

## Resumen (ES)

Sin `fourcc: MJPG` la cámara solo da 20 fps y LeRobot falla al pedir 30. Ponerlo en todos los bloques de cámara.
