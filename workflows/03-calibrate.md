# 03 — Calibrate (or, more often, install the existing calibration)

**Default: do not recalibrate.** Both arms are calibrated (2026-06-28) and the JSONs are in
`assets/calibration/`. On a new machine, copy them into place ([[calibration]] has the `cp` block)
and verify with [[05-teleoperate]]. Recalibrate only if:

- teleop shows a constant offset between leader and follower,
- a motor was replaced or re-flashed,
- you start a **new** dataset and want a fresh baseline (never mid-dataset).

## Recalibrate both arms (same session, same pose)

Put **both arms in the same physical middle pose** before pressing Enter at the homing step, then
move **every joint through its full range** at the range step ([[calibrate-same-pose]]).

```bash
$RUN lerobot-calibrate \
    --robot.type=$ROBOT_TYPE \
    --robot.port=$ROBOT_PORT \
    --robot.id=$ROBOT_ID
# → ~/.cache/huggingface/lerobot/calibration/robots/so_follower/$ROBOT_ID.json

$RUN lerobot-calibrate \
    --teleop.type=$TELEOP_TYPE \
    --teleop.port=$TELEOP_PORT \
    --teleop.id=$TELEOP_ID
# → ~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader/$TELEOP_ID.json
```

Afterwards copy the new JSONs back into `assets/calibration/` (same filenames), add a dated line in
[[calibration]], and commit — otherwise the other machine keeps the old numbers.

## One-time, only for a brand-new or replaced motor

`lerobot-setup-motors` writes ids and baudrate to the servo EEPROM. Never needed for the current
arms unless a servo is swapped. If it complains about firmware, see [[feetech-firmware]].

## Resumen (ES)

Por defecto NO recalibrar: copiar los JSON de `assets/calibration/` y verificar con teleop.
Si hay que recalibrar, hacerlo con los dos brazos en la misma pose media, barrer cada articulación
completa, y volver a copiar los JSON al repo.
