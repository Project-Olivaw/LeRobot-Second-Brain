# Calibrate leader and follower in the same pose and sweep every joint fully

The first calibration (2026-06) left the follower "slightly to the right, wrist a little up"
during teleop — the two arms had different homing poses. In May, `wrist_flex` got a tiny range
(~747 counts vs ~2200) because the joint was not swept fully.

Do: put both arms in the same physical middle pose before pressing Enter at the homing step;
at the range step, move every joint to both mechanical limits, including the gripper fully open and
closed. Calibrate both arms in the same session. Then verify with teleop before recording.

Related: [[calibration]], [[03-calibrate]].

## Resumen (ES)

Calibrar los dos brazos en la misma pose media y barrer cada articulación hasta sus límites; si no, el follower queda desfasado.
