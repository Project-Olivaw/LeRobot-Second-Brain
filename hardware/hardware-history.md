# Hardware history

Things that broke, and what was learned. Chronological; see [[timeline]] for the full project log.

| Date | Event | Consequence / lesson |
|---|---|---|
| 2026-05 (early) | One SO-100 follower servo **burned** during the first vision-guided-grasping attempt (single arm, no leader, RPLidar + WENKIA cam). | Real-arm work blocked; project pivoted to MuJoCo RL, which never converged. Check PSU voltage vs motor variant before powering. |
| 2026-05-30 | Follower motors on mixed firmware (3.9 / 3.10); `lerobot-calibrate` refused. | Flashed all to 3.10 via Windows VM — [[feetech-firmware]]. |
| 2026-05-30 | Calibrated follower as `so101_follower`; `wrist_flex` range came out small (~747 counts). | Sweep every joint fully at the range step — [[calibrate-same-pose]]. |
| 2026-05-31 → 06-05 | Xbox gamepad teleop, MuJoCo SAC reach policy deployed sim-to-real (3.7 cm), MediaPipe hand-following. Scripts in `~/personalProjects/lerobot_arm_calibration/`. | Servo works under software control; `max_relative_target` + floor guard are the safety pattern. |
| 2026-06 (mid) | Leader arm acquired; pair now complete. | Teleop-based imitation learning becomes possible. |
| 2026-06-28 | Both arms recalibrated as `so100_*` after the first teleop showed the follower offset "to the right, wrist up". | Current calibration JSONs — [[calibration]]. |
| 2026-06-30 | **Leader arm broke in half** (printed part) at episode 14 of the Lego dataset. | Reprinted. Dataset kept at 13 episodes and trained anyway as a pipeline test — [[2026-06-29-lego-skeleton-act]]. |
| 2026-07-13 | Two 32x32 mm board cameras added (wrist, base). Teleop failed until integer indices + MJPG were used; first record hit `Incorrect status packet` on motor id 5. | [[integer-index-not-dev-path]], [[usb-bandwidth-three-cams]], [[incorrect-status-packet]]. |
| 2026-07-14 | Fool's mate eval: two eval datasets created but aborted at 0 episodes; policy bobbed up/down, never grasped. | [[2026-07-13-fools-mate-act]] post-mortem. |
| 2026-09-10 | Ran `~/reset-feetech.sh` (Win11 VM password reset). | VM still maintained for future flashing. |

## Spares and tools on hand

- Waveshare Bus Servo Adapter (`1a86:55d3`) — flashing and direct bus access.
- FE-URT-1 (misplaced).
- Windows 11 VM `win11` with Feetech FD 1.9.8.3.
- 3D printer access (leader was reprinted).

## Resumen (ES)

Historial de roturas: un servo quemado (mayo), firmware mezclado (mayo, resuelto con VM), el leader
partido en el episodio 14 (junio, reimpreso), y errores de bus al conectar tres cámaras (julio).
Cada fila enlaza a la lección correspondiente.
