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
- **macOS has no `by-id` equivalent.** Indices there are AVFoundation integers; the only defence is
  to look at the probe images every session ([[macbook-m3]], `tools/mac_cameras.sh`).

Related: [[cameras]], [[04-find-cameras]], [[camera-keys-are-baked-in]].

## Resumen (ES)

Los números `/dev/videoN` cambian al reconectar o reiniciar (fueron 0/2/4 en julio y 4/2/- en
septiembre) y nada avisa: se graba la muñeca bajo la clave `top`. Por eso el escritorio guarda los
nombres estables de `/dev/v4l/by-id/` en el `.env` y `tools/cameras.sh` los traduce al índice del
día. En macOS no existe ese mecanismo: hay que mirar las imágenes de prueba cada sesión.
