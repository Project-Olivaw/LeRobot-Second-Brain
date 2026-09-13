# 05 — Teleoperate (sanity check and practice)

Teleoperation stores **nothing**. Use it to (a) verify calibration and cameras, (b) practice the task
until demonstrations are smooth and repeatable — dataset quality starts here ([[good-dataset-rules]]).

```bash
$RUN lerobot-teleoperate \
    --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
    --robot.cameras="$CAMERAS" \
    --teleop.type=$TELEOP_TYPE --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID \
    --display_data=true
```

Wrapper: `tools/teleop.sh` (add `--no-cams` to skip cameras when isolating an arm problem).

Checks:

1. Follower mirrors the leader with **no constant offset** in any joint. Offset → recalibrate both ([[03-calibrate]]).
2. Every camera feed is live in the rerun window and not stuttering.
3. The gripper opens/closes fully — if the leader's gripper range is off, the follower will never fully close on an object.

`Ctrl+C` to stop. rerun/Vulkan/EGL warnings are noise ([[rerun-warnings-are-harmless]]); the real
error is in the Python traceback.

## Bench (optional)

`tools/bench.py` (from the vlaLerobot project) measures teleop loop rate, latency and per-joint
jitter; the target is ≥ 27 Hz (within 10 % of 30). Run it once per machine and record the numbers in
the machine note. Usage: `$RUN python tools/bench.py --help`.

## Resumen (ES)

Teleoperar no guarda nada: sirve para verificar calibración y cámaras y para practicar la tarea hasta
hacerla fluida. Si el follower va desfasado, recalibrar los dos brazos. `tools/teleop.sh`.
