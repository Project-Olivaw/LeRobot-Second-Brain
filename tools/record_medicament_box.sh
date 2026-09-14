#!/usr/bin/env bash
# Record the 2026-09 dataset: "Complejo B" box -> ESP32 car (experiments/2026-09-medicaments-vla.md).
# Usage: tools/record_medicament_box.sh [episodes=50]
# Env:   RESUME=1 to append to an existing dataset (same command, do NOT recalibrate in between).
#        CAMS="$CAMERAS_THREE" to record three cameras (default: $CAMERAS = top + wrist).
#        DRY=1 to print the final command only.
# Keys during recording: -> end phase now, <- discard & redo, Esc stop (workflows/12-recording-keys.md).
set -euo pipefail; source "$(dirname "$0")/_common.sh"
TOOLS="$(cd "$(dirname "$0")" && pwd)"; cd "$LEROBOT_DIR"      # `uv run` resolves the project from the cwd

NAME=${NAME:-so100_medicament_box}
TASK="Pick up the Complejo B medicament box and place it on the ESP32 car"   # no ':' or "'"
EPS=${1:-50}; EPISODE_TIME_S=30; RESET_TIME_S=10
export CAMERAS="${CAMS:-$CAMERAS}"

# --- pre-flight: same version on both machines, ports present, cameras present, no stale folder ---
VER=$($RUN python -c "import lerobot; print(lerobot.__version__)")
echo "lerobot $VER via '$RUN' in $LEROBOT_DIR ($(git -C "$LEROBOT_DIR" rev-parse --short HEAD))"
case "$VER" in 0.6*) ;; *) echo "expected lerobot 0.6.x (pinned to the MacBook's commit) — see the experiment note" >&2; exit 1;; esac

for dev in "$ROBOT_PORT" "$TELEOP_PORT"; do
  [ -e "$dev" ] || { echo "missing $dev — ports swap on replug, run tools/find.sh" >&2; exit 1; }
done
for idx in $(grep -o 'index_or_path: [0-9]*' <<<"$CAMERAS" | grep -o '[0-9]*$'); do
  [ -e "/dev/video$idx" ] || { echo "missing /dev/video$idx — run tools/find.sh" >&2; exit 1; }
done

DS="$HOME/.cache/huggingface/lerobot/${DATASET_PREFIX}/${NAME}"
if [ -d "$DS" ] && [ "${RESUME:-0}" != 1 ]; then
  echo "dataset folder exists: $DS" >&2
  echo "  append:  RESUME=1 $0 $EPS      |  start over:  rm -rf $DS" >&2
  exit 1
fi

cat <<EOF

  dataset : ${DATASET_PREFIX}/${NAME}  (${EPS} episodes, cap ${EPISODE_TIME_S}s, reset ${RESET_TIME_S}s)
  task    : "$TASK"
  cameras : $CAMERAS
  layout  : 5 spawn spots x 10 episodes, random yaw, same approach path, -> the moment the box rests on the car
  fixtures: car, mat, cameras and light do NOT move for the whole session (lessons/dont-move-the-scene.md)

EOF

exec "$TOOLS/record.sh" "$NAME" "$TASK" "$EPS" "$EPISODE_TIME_S" "$RESET_TIME_S"
