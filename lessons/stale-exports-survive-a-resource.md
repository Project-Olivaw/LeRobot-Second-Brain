# Re-sourcing a profile cannot unset what the old one exported

`source tools/env.sh desktop` loads `machines/desktop.env` into the **current shell**. Exported
variables persist there. So if a profile edit *removes* a line, re-sourcing in the same terminal
leaves the old value in place — the shell has no way to know the variable is no longer wanted.

**How it bit us (2026-09-29).** `CAM_TOP_PATH` was deleted from `machines/desktop.env` so that `top`
would resolve by the WENKIA's unique serial instead of a USB port ([[camera-order-matters]]). In a
terminal that had already sourced the old profile, the stale `CAM_TOP_PATH` still pointed at port 7
— the wrist camera's port. Both keys then resolved to the same device:

```
cameras: top=2 wrist=2 base=0
```

`lerobot-teleoperate` connected the first camera and failed on the second, with an error that says
nothing about any of this:

```
INFO  OpenCVCamera(2) connected.
[WARN] VIDEOIO(V4L2:/dev/video2): can't open camera by index
ConnectionError: Failed to open OpenCVCamera(2).
```

A camera device can only be opened once — the second key was fighting the first for `/dev/video2`.

## Fixed in the tooling

1. **`tools/env.sh` clears profile-owned variables before sourcing** (every `CAM_*`, `CAMERAS*`,
   `DEMO_*`), so deleting a line from a profile now takes effect on a re-source.
2. **`tools/cameras.sh` refuses duplicates**: two keys on one `/dev/videoN` withdraws `$CAMERAS` and
   prints what to do, instead of letting OpenCV produce the opaque error above.

## When you still meet it

Any other variable a profile stops setting, and anything exported by hand during a debugging
session. The reliable escape is a **new terminal** — that is not superstition, it is the only way to
guarantee no leftovers. Otherwise `unset <VAR>` and re-source.

Symptom to remember: **"it works for the agent but not for me"**, or a setting that will not change
no matter how you edit the file. Check `set | grep CAM_` in the shell that is failing.

Related: [[16-verify-the-rig]], [[camera-indices-shift-on-replug]], [[troubleshooting]].

## Resumen (ES)

Volver a hacer `source` de un perfil no puede borrar lo que el perfil anterior exportó. Al quitar
`CAM_TOP_PATH` del `.env`, una terminal que ya lo había cargado se quedó con el valor viejo y `top` y
`wrist` apuntaron al mismo `/dev/video2`: la primera cámara conecta y la segunda falla con
"Failed to open OpenCVCamera(2)". Ya está corregido (`env.sh` limpia las variables antes de cargar y
`cameras.sh` rechaza índices duplicados). Ante un ajuste que "no cambia por más que edites el
archivo": abre una terminal nueva.
