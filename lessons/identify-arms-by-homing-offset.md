# Which port is the leader? Read the homing offsets — do not guess and teleoperate

`lerobot-find-port` says *a* port exists; it never says *which arm* is on it. Getting it backwards is
not harmless: `lerobot-teleoperate` **enables** torque on whatever it connects as the follower and
**disables** it on the leader, so a swapped pair leaves the real follower limp — it drops under its
own weight, with the gripper and whatever it is holding — while the leader is driven to match it.

`lerobot-calibrate` writes each joint's `Homing_Offset` into the motor EEPROM, and the two arms'
values are different (follower `shoulder_pan` -1036 vs leader -2000, and so on for all six). So the
arms can identify themselves. `tools/identify_arms.py` opens each port read-only — `bus.connect()`
only opens the serial port and pings, it touches no torque register — reads the six offsets and
matches them against `assets/calibration/`:

```bash
source tools/env.sh macbook
uv run python tools/identify_arms.py
# ROBOT_PORT   /dev/tty.usbmodem58FA0929601  ->  FOLLOWER  (follower=6/6  leader=0/6)
# TELEOP_PORT  /dev/tty.usbmodem58FA0929691  ->  LEADER    (follower=0/6  leader=6/6)
```

6/6 on one role and 0/6 on the other is unambiguous. A low score on both means the arm was
recalibrated after `assets/calibration/` was last updated (re-run [[03-calibrate]] and commit the
JSONs) or it is a different physical arm.

Free side effect: a 6/6 match also proves the calibration on the machine is the one in this repo.

Related: [[02-find-ports]], [[calibration]], [[so100-arms]].

## Resumen (ES)

No adivines qué puerto es el leader: teleoperar al revés deja el follower sin torque y se cae.
`tools/identify_arms.py` lee los `Homing_Offset` guardados en los motores (solo lectura) y los
compara con `assets/calibration/`. 6/6 en un rol y 0/6 en el otro identifica el brazo sin moverlo.
