# 04 — Find and identify cameras

```bash
$RUN lerobot-find-cameras opencv
```

Prints each camera (id, backend, default mode) and saves one frame per camera to
`outputs/captured_images/`. Open those PNGs to decide which device is `top`, `wrist`, `base`:

- `top`: overhead view of the whole workspace.
- `wrist`: moves with the gripper; the jaw is visible in the frame.
- `base`: fixed low side view.

Then update `CAM_TOP` / `CAM_WRIST` / `CAM_BASE` in `machines/<machine>.env`.

## Reading the output correctly

- Linux: ids are `/dev/videoN`; **use the integer `N`** in configs, and only even N (odd = metadata).
  The probe may show backend `FFMPEG` and a 1920x1080@5 default — that is the default mode, not a limit. [[integer-index-not-dev-path]]
- macOS: backend `AVFOUNDATION`, ids `0, 1, 2…`; index 0 is usually the built-in camera.
- `ioctl(VIDIOC_QBUF): Bad file descriptor` lines are noise.

## Test a camera block before recording

```bash
$RUN lerobot-teleoperate \
    --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
    --robot.cameras="$CAMERAS" \
    --teleop.type=$TELEOP_TYPE --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID \
    --display_data=true
```

All feeds must appear in the rerun window at a steady 30 fps. Failures here are almost always
[[mjpg-required-for-30fps]] or [[usb-bandwidth-three-cams]].

## Resumen (ES)

`lerobot-find-cameras opencv` lista cámaras y guarda una foto de cada una en
`outputs/captured_images/`; con las fotos se decide cuál es `top`, `wrist` y `base` y se actualiza el
`.env`. En Linux usar índice entero y solo pares; en macOS la 0 suele ser la integrada.
