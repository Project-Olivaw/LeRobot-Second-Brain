# Calibration

Calibration maps raw encoder counts (0..4095) to joint degrees via a `homing_offset` and a
`range_min`/`range_max` per motor. It is a property of **the physical arm**, not of the computer —
so the JSON files travel with this repo and are reused on every machine.

## The files (copies in `assets/calibration/`)

| Arm | Source path on the desktop | Copy in repo |
|---|---|---|
| Follower | `~/.cache/huggingface/lerobot/calibration/robots/so_follower/my_awesome_follower_arm.json` | `assets/calibration/robots__so_follower__my_awesome_follower_arm.json` |
| Leader | `~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader/my_awesome_leader_arm.json` | `assets/calibration/teleoperators__so_leader__my_awesome_leader_arm.json` |

Both were recorded on **2026-06-28** (the second, corrected calibration — the first one left the
follower "slightly to the right, wrist a little up" during teleop).

Current follower values (counts):

| joint | id | homing_offset | range_min | range_max |
|---|---|---|---|---|
| shoulder_pan | 1 | -1036 | 1088 | 3053 |
| shoulder_lift | 2 | 970 | 923 | 3104 |
| elbow_flex | 3 | -1988 | 948 | 3088 |
| wrist_flex | 4 | 903 | 1129 | 2902 |
| wrist_roll | 5 | -122 | 0 | 4095 |
| gripper | 6 | -1719 | 2021 | 3222 |

Leader: pan -2000 [1200,3276]; lift -790 [849,3038]; elbow 987 [1111,3172]; wrist_flex -1762 [1070,2467];
wrist_roll -1946 [0,4095]; gripper 1544 [1979,3023].

## Installing the calibration on a new machine (MacBook)

```bash
mkdir -p ~/.cache/huggingface/lerobot/calibration/robots/so_follower \
         ~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader
cp assets/calibration/robots__so_follower__my_awesome_follower_arm.json \
   ~/.cache/huggingface/lerobot/calibration/robots/so_follower/my_awesome_follower_arm.json
cp assets/calibration/teleoperators__so_leader__my_awesome_leader_arm.json \
   ~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader/my_awesome_leader_arm.json
```

Then run [[05-teleoperate]] as the check: the follower must mirror the leader with no offset.
If the follower is offset, recalibrate **both** arms together ([[03-calibrate]]) and commit the new
JSONs to this repo with a dated note here.

## Rules

1. **Same id everywhere.** The id is the filename; a typo silently creates a new uncalibrated arm.
2. **Never recalibrate the follower between recording sessions of the same dataset** — old and new
   episodes would live in different coordinate spaces. Recalibrate → start a new dataset.
3. **Calibrate leader and follower in the same physical middle pose**, and sweep every joint through
   its full range at the range step. Under-sweeping a joint gives it a tiny range (this happened to
   `wrist_flex` in May: ~747 counts vs ~2200 for others). See [[calibrate-same-pose]].
4. A policy trained on a dataset assumes the calibration that recorded it. If you recalibrate after
   training, expect the policy to be offset. Keep the JSONs versioned here for that reason.
5. Datasets store `robot_type: so_follower` (not `so100_follower`) — normal for lerobot 0.5.x.

## Resumen (ES)

La calibración es del brazo, no del computador: los JSON están en `assets/calibration/` y se copian
a `~/.cache/huggingface/lerobot/calibration/...` en cualquier máquina. Mismo `id` siempre. No
recalibrar el follower a mitad de un dataset. Calibrar ambos brazos en la misma pose media y barrer
cada articulación completa.
