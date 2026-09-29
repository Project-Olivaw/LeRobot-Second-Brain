# The camera ORDER must match training, or the policy sees a swapped world

The medicament SmolVLA policy failed its first evaluations and looked like a data problem. It was
not: after **changing the order of the cameras** it reached **80-90% success**. Worth understanding,
because it is silent and it will happen again.

A policy consumes tensors in a fixed order — `camera1`, `camera2`, `camera3` for SmolVLA
([[smolvla-camera-slots]]). Which physical lens ends up in slot 1 is decided by a chain:

```
physical camera -> /dev/videoN (or macOS index) -> key in --robot.cameras (top/wrist/base)
                -> --rename_map -> cameraN -> the slot the network learned
```

Break any link and the model gets the wrist view where it expects the overhead view. Nothing errors.
The arm just behaves like a badly trained policy: hesitant, reaching to the wrong place, sometimes
almost right. Indistinguishable from "we need more data" — which is exactly the wrong conclusion.

**The link that breaks in practice is the first one:** `/dev/videoN` numbers are assigned in plug
order and change after a reboot or replug ([[camera-indices-shift-on-replug]]). The dataset stores
the *keys*, not the devices ([[camera-keys-are-baked-in]]), so a swap is invisible to every tool.

**It happened again on 2026-09-29**, and this time it was caught before it cost anything. After
reconnecting the desk, `machines/desktop.env` pinned `top` to USB port 7 and `wrist` to port 1, but
port 7 held an Innomaker (the gripper camera) and port 1 held the WENKIA (the overhead camera) — the
two keys were swapped. Proof: a frame decoded from the recorded dataset's `top` video is the
overhead view, and the live camera the profile called `top` showed the gripper jaws.

That comparison is now a tool: **`tools/verify_cameras.py <dataset>`** ([[16-verify-the-rig]]).
Run it after every replug, on either machine, before recording or evaluating.

Defences, in order:

1. **Resolve by stable id, never by bare index.** `machines/desktop.env` names cameras by their
   `/dev/v4l/by-id/` string and `tools/cameras.sh` turns those into today's index at `source` time.
   This is the real fix and it is already in place on the desktop. macOS has no `by-id` equivalent —
   check the probe images every session there ([[macbook-m3]]).
2. **Look at the pictures before recording or evaluating.** `lerobot-find-cameras` writes one frame
   per camera to `outputs/captured_images/`; 10 seconds of looking beats an hour of doubting the data.
3. **Compare against the dataset, not against memory** — `tools/verify_cameras.py` scores live
   frames against the recorded ones and exits non-zero on a swap.
4. **When a policy underperforms, rule the cameras out first** — it is cheaper than recording more
   episodes, and this time it was the whole problem.

Related: [[cameras]], [[10-evaluate]], [[2026-09-medicaments-vla]].

## Resumen (ES)

La política de la caja de medicamento falló al principio y parecía falta de datos; al **cambiar el
orden de las cámaras** subió a 80-90% de acierto. El modelo consume las cámaras en un orden fijo
(camera1/2/3) y los índices `/dev/videoN` cambian al reconectar, sin dar ningún error: el brazo
simplemente parece mal entrenado. Por eso el escritorio resuelve las cámaras por `by-id`
(`tools/cameras.sh`). Ante una política que rinde mal, descartar primero las cámaras.
