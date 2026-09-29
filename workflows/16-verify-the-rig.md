# 16 — Verify the rig before you trust it (desktop or MacBook)

Run this after plugging everything in, and again before any recording, evaluation or demo. It takes
about two minutes and it catches the one failure that has already cost this project a full
evaluation session: a camera key pointing at the wrong lens ([[camera-order-matters]]).

**For an agent picking this up on a new machine:** everything below is machine-agnostic. The only
platform-specific part is *how* a camera is pinned — `/dev/v4l/by-path` or `by-id` on Linux, a bare
index on macOS — and `tools/verify_cameras.py` tests whatever the profile resolved either way.

## The five checks

```bash
cd ~/GitHub/AnotherOnes/LeRobot-Second-Brain
source tools/env.sh desktop          # or: macbook

# 1. Profile loaded, arms and cameras resolved
#    Expect: "cameras (by-*): top=N wrist=N base=N" and the [machine] line with both ports.

# 2. The CLI and the version match the dataset/policy
$RUN python -c "import lerobot, torch; print(lerobot.__version__, torch.__version__)"

# 3. The arms answer, and each port is the arm you think it is (read-only, no torque)
$RUN python tools/identify_arms.py

# 4. THE IMPORTANT ONE — every camera key still shows what it showed at recording time
$RUN python tools/verify_cameras.py so100_medicamentos

# 5. The policy loads and is fast enough on this machine
$RUN python tools/bench_policy.py "$DEMO_POLICY" "$DEVICE"
```

Then the live check: `tools/teleop.sh` (follower mirrors leader, all feeds live), and
`tools/demo_live.sh` for the policy itself.

## What check 4 actually does

It decodes one frame per camera key **out of the recorded dataset**, grabs one live frame per key
from the cameras the profile resolved, and scores every live frame against every recorded one. The
best match for `top` must be the camera you currently call `top`.

```
recorded key  best live match     score   verdict
base          base                 0.50   OK
top           top                  0.70   OK
wrist         wrist                0.52   OK
```

Scores of 0.5-0.7 are normal for a correct camera — the objects have moved since recording, and the
comparison deliberately ignores that. Only the *ranking* matters.

A failure looks like this (this is the real fault found on the desktop on 2026-09-29):

```
top           wrist                0.70   SWAPPED — 'top' is now on the camera you call 'wrist'
wrist         top                  0.52   SWAPPED — 'wrist' is now on the camera you call 'top'
```

It exits non-zero, so it can gate a script.

## How to fix a swap

**Linux** — edit `machines/desktop.env`, then `source tools/env.sh desktop` and re-run check 4:

- A camera with a **unique serial** (our WENKIA) should be pinned by `CAM_<KEY>_ID` and have **no**
  `CAM_<KEY>_PATH`, so it is found in whatever port it is plugged into.
- Cameras that are **the same model with the same serial** (our two Innomaker U20CAM, both SN0001)
  cannot be told apart by `by-id` — only `CAM_<KEY>_PATH` (the USB port) distinguishes them
  ([[identical-cameras-need-by-path]]). Swap the two `_PATH` values to swap those two keys.
- List the current names with `ls -l /dev/v4l/by-path/` and `ls -l /dev/v4l/by-id/`.

**macOS** — there is no `by-path`/`by-id`; swap the `index_or_path` numbers in
`machines/macbook.env`. Indices there can change between sessions, so run check 4 **every session**
([[macbook-m3]], `tools/mac_cameras.sh` if a camera is missing entirely).

Either way, the alternative fix is physical: move the cables so reality matches the profile.

## If a whole key is missing

The policy's input list is fixed at training time. A policy trained on `top`+`wrist`+`base` needs
all three ([[smolvla-camera-slots]]); the check warns when the dataset has a key the profile does
not. Options: plug the camera back in, or use a policy trained on the subset you actually have.

## Resumen (ES)

Verificación de dos minutos antes de grabar, evaluar o hacer el demo, en cualquiera de las dos
máquinas. Lo esencial es el paso 4: `tools/verify_cameras.py <dataset>` extrae un fotograma de cada
cámara del dataset grabado, toma uno en vivo de cada cámara del perfil y comprueba que cada clave
(`top`, `wrist`, `base`) sigue apuntando al mismo lente. Una cámara intercambiada no da ningún error
pero arruina la inferencia. En Linux se corrige con `CAM_*_PATH`/`CAM_*_ID` en el `.env` (las dos
Innomaker tienen el mismo serial, así que solo el puerto las distingue); en macOS, cambiando los
índices. Puntajes de 0.5-0.7 son normales; lo que importa es el orden.
