# Lock camera exposure and white balance, or the scene changes when the light does

A policy keys off pixels. Auto-exposure and auto-white-balance make the *same* scene produce
different pixels under different light — which is exactly what happens when the arm travels to a
venue. That shift is often larger than the object-position variation you carefully recorded.

LeRobot's `OpenCVCameraConfig` exposes only `fps`, `width`, `height`, `fourcc`, `rotation`,
`warmup_s` and `backend` — **no exposure or white-balance control**. Set it outside LeRobot:

```bash
# Linux (v4l-utils), per camera, BEFORE lerobot-record / lerobot-rollout:
v4l2-ctl -d /dev/videoN --set-ctrl=auto_exposure=1            # 1 = manual mode on most UVC cams
v4l2-ctl -d /dev/videoN --set-ctrl=exposure_time_absolute=250 # tune to the room
v4l2-ctl -d /dev/videoN --set-ctrl=white_balance_automatic=0
v4l2-ctl -d /dev/videoN --set-ctrl=white_balance_temperature=4600
v4l2-ctl -d /dev/videoN --list-ctrls                          # names vary per camera — check first
```

`tools/lock_cameras.sh` does this for the cameras in the current profile.

**macOS has no equivalent** for UVC cameras — this is a concrete reason to record datasets on the
desktop and use the MacBook only for inference ([[macbook-m3]]).

Since the settings cannot be locked everywhere, also make the data robust: record under 2-3
lighting levels once the fixed-light version works, and bring your own light to the venue.

Related: [[dont-move-the-scene]], [[policy-does-not-survive-a-new-table]], [[good-dataset-rules]].

## Resumen (ES)

El auto-exposición y el balance de blancos cambian los píxeles cuando cambia la luz, y la política se guía por píxeles. LeRobot no los controla: fijarlos con `v4l2-ctl` en Linux (`tools/lock_cameras.sh`). En macOS no se puede, otra razón para grabar en el escritorio.
