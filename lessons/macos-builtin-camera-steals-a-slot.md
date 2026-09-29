# On macOS a missing USB camera is silently replaced by the built-in one

2026-09-28, MacBook with two hubs: teleop came up with **three** feeds, so everything looked right —
but they were the **built-in FaceTime camera, wrist and base**. The USB overhead camera had not
enumerated, and because AVFoundation indices are *positional*, everything below it shifted up one and
the laptop-lid view landed in the `top` slot.

Why this is worse than a camera that fails outright: nothing errors. `lerobot-record` and
`lerobot-rollout` both start happily, the rerun window shows three live images, and the policy is fed
a viewpoint it has never seen. At recording time that poisons the dataset; at demo time the policy
just behaves badly on stage with no message to explain it ([[camera-keys-are-baked-in]]).

Linux is immune to the *substitution* (there is no built-in camera and `/dev/v4l/by-path` pins each
socket — [[identical-cameras-need-by-path]]), but not to the general class: any key can end up on the
wrong camera.

## The check that catches it

`tools/check_cameras.py` now compares every feed against a stored reference view:

```bash
uv run python tools/check_cameras.py --save-reference   # once, on the scene you recorded
uv run python tools/check_cameras.py                    # every session from then on
```

It scores a 64x48 contrast-normalised grayscale thumbnail by normalised cross-correlation — framing,
not lighting or where the objects happen to sit. Measured on our own frames (2026-09-28):

| Comparison | Score | Verdict |
|---|---|---|
| Same camera, captured minutes later | **+0.99** | pass |
| `top` vs `base` (cameras swapped) | +0.25 | **fails** (< 0.35) |
| `top` vs `wrist` (cameras swapped) | -0.19 | **fails** |
| `top` vs an unrelated scene (the built-in-camera case) | +0.01 | **fails** |

So: `< 0.35` fails the pre-flight, `< 0.65` warns that something moved. The references live in
`assets/camera-reference/*.png` and travel with the repo, like the calibration files — they are part
of the scene kit ([[scene-kit]]).

## macOS habits that avoid it in the first place

- Turn **Continuity Camera** off (iPhone → Settings → General → AirPlay & Continuity).
- Plug the cameras in **one at a time**, waiting for each to appear, then run `tools/mac_cameras.sh`
  and re-read the indices. Some UVC cameras claim full bandwidth on connect and the last one loses.
- Cameras and arms on **separate powered hubs**; the arms need their own supply
  ([[usb-bandwidth-three-cams]]).
- Re-run `tools/mac_cameras.sh` and then `check_cameras.py` after **every** replug, and again at the
  venue. Count the feeds *and* look at them — three feeds is not the same as the right three.

Related: [[camera-indices-shift-on-replug]], [[macbook-m3]], [[15-runbook-copy-paste]].

## Resumen (ES)

En la Mac, si una cámara USB no enumera, los índices se corren y la cámara integrada ocupa su lugar
sin dar ningún error: se graba o se demuestra con una vista que la política nunca vio. `check_cameras.py`
ahora compara cada feed con una referencia guardada (`--save-reference`): misma cámara ≈ 0.99, cámaras
intercambiadas ≤ 0.25, escena distinta ≈ 0.01; por debajo de 0.35 falla. Además: desactivar Continuity
Camera, conectar las cámaras de una en una, hubs con alimentación y volver a verificar tras cada
reconexión y en el sitio del evento.
