# Use the integer camera index, not the /dev/videoN string (Linux)

With the default `CAP_ANY` backend, OpenCV opens a **string path** (`/dev/video0`) through the
read-only **FFMPEG** backend, which cannot set MJPG / width / height / fps. Symptom:
`failed to set capture_width=640 (actual_width=1920)` or `failed to set fourcc=MJPG`.

An **integer** index opens through **V4L2**, which can set them. Index `N` maps to `/dev/videoN`.
Only even nodes are capture devices; odd ones are metadata.

The Lego guide originally recommended the `/dev/video0` path "for stability" — that advice was
wrong once resolution/fps had to be set, and cost the first three-camera teleop attempt (2026-07-13).

On macOS there are no `/dev/video*` nodes; indices are the only option.

Related: [[cameras]], [[04-find-cameras]].

## Resumen (ES)

En Linux usar índice entero (`0`, `2`, `4`), no `/dev/videoN`: la ruta abre por FFMPEG y no permite fijar MJPG/resolución/fps.
