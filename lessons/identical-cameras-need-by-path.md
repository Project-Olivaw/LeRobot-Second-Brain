# Two cameras of the same model share one `/dev/v4l/by-id` name — pin them by PORT instead

2026-09-28, desktop. `tools/env.sh desktop` reported `base=absent` and teleop showed two feeds, while
all three cameras were plugged in and working (`/dev/video0`, `video2`, `video4` all returned frames).

The cause is in udev, not in lerobot. `/dev/v4l/by-id` names a device by *vendor + model + serial*:

```
usb-Innomaker_Innomaker-U20CAM-1080p-S1_SN0001-video-index0 -> ../../video4
```

Both the wrist and the base camera are Innomaker U20CAMs and **both report `SN0001`** — the same
string. Two devices, one name: udev creates the link for whichever enumerated first and silently
skips the other, so the by-id lookup can never see more than one of the pair.

The fix is `/dev/v4l/by-path`, which names the **physical USB port**:

```
pci-0000:0d:00.0-usb-0:7:1.0-video-index0 -> ../../video0    # WENKIA  = top
pci-0000:0d:00.0-usb-0:1:1.0-video-index0 -> ../../video4    # Innomaker = wrist
pci-0000:0d:00.0-usb-0:8:1.0-video-index0 -> ../../video2    # Innomaker = base
```

`tools/cameras.sh` now tries `CAM_<KEY>_PATH` (by-path) first, `CAM_<KEY>_ID` (by-id) second, and a
bare `CAM_<KEY>_INDEX` last. The trade-off is explicit: **by-path identifies the socket, so each
camera must go back into the port named in `machines/<machine>.env`.** That is the right discipline
anyway — the *view* is what is baked into the dataset ([[camera-keys-are-baked-in]]), and a camera
that moved port has usually also moved in space.

Consequences worth keeping:

- A missing **required** camera now withdraws `$CAMERAS` entirely, so `need_cameras()` stops the run
  instead of silently recording with fewer views than the dataset expects. `CAM_REQUIRED="top wrist"`
  is the deliberate opt-out.
- Identical cameras are worth labelling physically (tape on the cable: TOP / WRIST / BASE), because
  nothing in software can tell them apart once they are in the wrong sockets.
- Verify before every long session: `uv run python tools/check_cameras.py` writes one PNG per key.
  Wrist and base swapped? Exchange the two `CAM_*_PATH` values — they are the same camera model.

Related: [[camera-indices-shift-on-replug]], [[camera-keys-are-baked-in]], [[usb-bandwidth-three-cams]], [[cameras]].

## Resumen (ES)

Dos cámaras del mismo modelo comparten el mismo nombre en `/dev/v4l/by-id` (ambas dicen `SN0001`),
así que udev solo crea un enlace y la tercera parecía "ausente" aunque funcionaba. La solución es
`/dev/v4l/by-path`, que identifica el **puerto USB físico**: `tools/cameras.sh` usa `CAM_*_PATH`
primero. A cambio, cada cámara debe volver siempre al mismo puerto (y conviene etiquetar los cables).
Si falta una cámara requerida, `$CAMERAS` se anula y el script se detiene en vez de grabar de menos.
