# Cameras

Three USB cameras, all opened through LeRobot's `opencv` camera type at **640x480 @ 30 fps, MJPG**.

| key | what | physical | desktop node / index | sample image |
|---|---|---|---|---|
| `top` | overhead ("cenital") view, fixed on a printed stick attached to the arm base | WENKIA 1080p webcam (default 1920x1080 @ 5 fps) | `/dev/video0` → index `0` | `assets/captured_images/opencv__dev_video0.png` |
| `wrist` | mounted on the gripper, looks at what the jaws point at | small 32x32 mm board camera | `/dev/video2` → index `2` | `assets/captured_images/opencv__dev_video2.png` |
| `base` | mounted low on the rotation/pitch base, side view | small 32x32 mm board camera | `/dev/video4` → index `4` | `assets/captured_images/opencv__dev_video4.png` |

The `key` (`top`, `wrist`, `base`) is stored in the dataset as `observation.images.<key>` and is
what the policy expects at eval. Keys must match; which physical device sits behind a key can
change per machine ([[camera-keys-are-baked-in]]).

Canonical camera block (desktop):

```
{ top:   {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG},
  wrist: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30, fourcc: MJPG},
  base:  {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 30, fourcc: MJPG}}
```

It is defined once per machine in `machines/<machine>.env` as `$CAMERAS` (and `$CAMERA_TOP_ONLY`).

## Rules that cost us hours

- **`fourcc: MJPG` is mandatory.** In raw YUYV the WENKIA only reaches 20 fps at 640x480 and LeRobot
  errors with `failed to set fps=30 (actual_fps=20.0)`. [[mjpg-required-for-30fps]]
- **Use the integer index, not the `/dev/videoN` string** on Linux. A string path opens through the
  read-only FFMPEG backend and cannot set MJPG / width / height / fps
  (`failed to set capture_width=640 (actual_width=1920)`). Index `N` = `/dev/videoN`. [[integer-index-not-dev-path]]
- **Odd `/dev/video*` nodes are metadata**, not capture. Only even nodes (0, 2, 4) are cameras.
- **Three raw streams exceed one USB 2.0 bus**; MJPG (~10x smaller) fits. If a camera still fails to
  open with all three attached, spread them over different physical USB controllers. [[usb-bandwidth-three-cams]]
- Indices shift after replug/reboot: re-run [[04-find-cameras]] and look at the saved PNGs to re-identify.
- `ioctl(VIDIOC_QBUF): Bad file descriptor` during the probe is harmless V4L2 chatter.
- `lerobot-find-cameras` reports the **default** mode (1920x1080 @ 5 fps for the WENKIA); the
  requested mode (640x480 @ 30) is a different, valid mode.

## Quality observations (from the July probe images)

- `wrist` (video2): usable but dark; the gripper jaw occupies the top-left of the frame.
- `base` (video4): very dark, and the arm itself occludes roughly the left third of the frame. This
  view added compute without adding much information in the Fool's mate run — see [[2026-07-13-fools-mate-act]].
- For the medicament task, prefer **top + wrist** (two cameras, as the LeRobot guide recommends) and
  add light. Two cameras also halves the USB pressure and speeds training.

## macOS differences

On the MacBook the backend is AVFoundation; indices are integers `0, 1, 2 ...` with no `/dev/video`
nodes and no odd metadata nodes. The built-in FaceTime camera is usually index 0, so the USB cameras
will be 1, 2, 3 — confirm with the probe. See [[macbook-m3]].

## Resumen (ES)

Tres cámaras USB a 640x480@30 MJPG con claves `top` (cenital WENKIA, índice 0), `wrist` (índice 2) y
`base` (índice 4). Usar índice entero, no `/dev/videoN`; MJPG obligatorio; tres cámaras crudas no
caben en un bus USB. La cámara `base` estaba oscura y tapada por el brazo. Para medicamentos usar
top + wrist con buena luz.
