# Camera indices shift on replug — resolve by stable id instead

`/dev/videoN` numbers are handed out in the order the kernel enumerates devices, so they change
after a reboot, a replug, or simply plugging the cameras in a different order. Observed on this
machine: `top`/`wrist`/`base` were `0`/`2`/`4` in July 2026 and `4`/`2`/`-` on 2026-09-14.

Nothing errors when they move. `lerobot-record` happily records the wrist view under the key `top`,
and a policy evaluated with swapped views behaves like a badly trained one
([[camera-order-matters]]) — which is how an afternoon gets spent doubting the dataset.

**Fix: never hard-code an index.** Every USB camera exposes a stable name under `/dev/v4l/by-id/`
that encodes vendor, model and serial:

```bash
ls -l /dev/v4l/by-id/
# usb-Sonix_Technology_Co.__Ltd._WENKIA_PC-LM7_SN0001-video-index0 -> ../../video4
```

`machines/desktop.env` stores those names in `CAM_TOP_ID` / `CAM_WRIST_ID` / `CAM_BASE_ID`, and
`tools/cameras.sh` (sourced by `tools/env.sh`) resolves them to today's index and builds the
`--robot.cameras` blocks. A missing camera is reported by name instead of silently becoming a
different one; `need_cameras` in `tools/_common.sh` stops any script that needs video.

Two caveats:

- Identical camera models with no unique serial get by-id names that differ only by a bus path —
  they are stable per *port*, so keep each camera in the same physical socket.
- **macOS has no usable `by-id` equivalent — and the obvious workaround does not work.** macOS does
  expose a stable per-port id (`system_profiler SPCameraDataType -json` -> `spcamera_unique-id`, e.g.
  `0x11300000c456366`; the same value is `AVCaptureDevice.uniqueID`). It is tempting to resolve it to
  an index the way `tools/cameras.sh` does on Linux. **It cannot be done:** OpenCV's AVFoundation
  index order is not the order AVFoundation itself reports. Measured on 2026-09-29 with five devices
  attached — AVFoundation listed `FaceTime, WENKIA, Innomaker, Innomaker, iPhone` while OpenCV's
  indices 0/1/2 were `base, wrist, top` (the three USB cameras) with the phone and FaceTime last.
  So on macOS the defence is **content**, not identity: `tools/check_cameras.py --save-reference`
  freezes today's views and every later run scores against them, and
  `tools/verify_cameras.py <dataset>` scores the live feeds against the *recorded* videos, which is
  the real ground truth ([[camera-order-matters]]). Also remove the phone from the list entirely —
  [[iphone-continuity-camera-breaks-runs]].

Related: [[cameras]], [[04-find-cameras]], [[camera-keys-are-baked-in]].

## Resumen (ES)

Los números `/dev/videoN` cambian al reconectar o reiniciar (fueron 0/2/4 en julio y 4/2/- en
septiembre) y nada avisa: se graba la muñeca bajo la clave `top`. Por eso el escritorio guarda los
nombres estables de `/dev/v4l/by-id/` en el `.env` y `tools/cameras.sh` los traduce al índice del
día. En macOS no existe ese mecanismo: hay que mirar las imágenes de prueba cada sesión.
