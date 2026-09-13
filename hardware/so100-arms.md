# SO-100 arms (leader + follower)

Two SO-ARM100 arms (The Robot Studio design), each with 6 Feetech STS3215 bus servos, daisy-chained.
The **follower** is the one the policy drives; the **leader** is the one you move by hand to teleoperate.

## Identity used everywhere

| Arm | `type` | `id` (calibration key) | Desktop port |
|---|---|---|---|
| Follower | `so100_follower` | `my_awesome_follower_arm` | `/dev/ttyACM1` |
| Leader | `so100_leader` | `my_awesome_leader_arm` | `/dev/ttyACM0` |

The `id` is what locates the calibration JSON (`~/.cache/huggingface/lerobot/calibration/robots/so_follower/<id>.json`).
Keep it identical across calibrate / teleoperate / record / eval, and across machines. See [[calibration]].

Ports are **machine- and plug-order-dependent** — they swap after a reboot or replug. Always confirm
with [[02-find-ports]]. On macOS they look like `/dev/tty.usbmodem*` ([[macbook-m3]]).

## SO-100, not SO-101

The user owns SO-100 arms. In LeRobot the robot class is shared (`SO100Follower` is an alias of
`SOFollower`; the difference is in the config class and gear/motor assumptions for the leader).
In May 2026 the follower was once calibrated as `so101_follower` (single-arm era, see
[[feetech-firmware]]); since June 2026 everything uses `so100_*`. Calibration folders on disk are
`so_follower` / `so_leader` for both variants, which is why the old calibration still worked.
The talk repo uses "SO-101" as a metaphor in its title — do not let that leak into commands.

## Motor order and ids

| id | joint | notes |
|---|---|---|
| 1 | `shoulder_pan` | base rotation |
| 2 | `shoulder_lift` | |
| 3 | `elbow_flex` | |
| 4 | `wrist_flex` | |
| 5 | `wrist_roll` | full 0..4095 range in calibration (continuous) |
| 6 | `gripper` | reported 0..100 (open %) in the API |

API keys are `{joint}.pos` (degrees, gripper 0-100). `leader.get_action()` returns the 6 keys;
`follower.get_observation()` returns the same 6 plus one `(H, W, 3)` array per camera.
`follower.send_action(a)` returns the action *actually sent* (clipped by `max_relative_target`).
Config also exposes servo PID: `position_p_coefficient=16`, `position_i_coefficient=0`, `position_d_coefficient=32`.

## Power and wiring facts learned the hard way

- One servo **burned** in May 2026 (before any teleop work) — see [[hardware-history]]. Confirm the PSU
  voltage matches the motor variant (5 V/7.4 V vs 12 V builds are not interchangeable). Measured bus
  voltage during the firmware flash was 12.3 V.
- The **leader arm broke in half** (3D-printed part) during recording on 2026-06-30 and was reprinted.
- `ConnectionError ... Incorrect status packet` on the follower is a bus/power glitch, not a config
  error: [[incorrect-status-packet]]. Red LEDs on every motor = wiring OK; a dark motor = reseat the 3-pin cable; blinking = overload or wrong voltage.
- Three cameras + two arms on one USB controller causes brown-outs and dropped frames: [[usb-bandwidth-three-cams]].

## Firmware

All six follower motors are on Feetech firmware **3.10** (flashed 2026-05-30). LeRobot refuses to
connect if motors on a bus report different firmware versions. Procedure: [[feetech-firmware]].
The leader's firmware was never audited; if `lerobot-calibrate` on the leader ever fails with a
firmware mismatch, use the same procedure.

## Resumen (ES)

Dos brazos SO-100 (no SO-101): follower en `so100_follower` id `my_awesome_follower_arm`, leader en
`so100_leader` id `my_awesome_leader_arm`. Los puertos cambian por máquina y por orden de conexión;
los ids no. Motores 1-6: pan, lift, elbow, wrist_flex, wrist_roll, gripper. Un servo se quemó en mayo,
el leader se partió en junio, y los errores de "status packet" son de cable/alimentación.
