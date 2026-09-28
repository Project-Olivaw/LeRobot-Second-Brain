#!/usr/bin/env bash
# Record ONE half of the two-instruction demo dataset (workflows/14-two-instruction-demo.md).
#
#   tools/record_medicamentos.sh frasco [episodes=100]   -> "agarra el frasco de magnesio"
#   tools/record_medicamentos.sh caja   [episodes=100]   -> "agarra la caja de Complejo B"
#   tools/record_medicamentos.sh <which> --plan          -> print the spot/side schedule and exit
#
# Env: RESUME=1 append to an existing dataset (how you record 100 episodes across several sittings)
#      CAMS="$CAMERAS_THREE" record three cameras   |   DRY=1 print the command only
#      SKIP_CAM_CHECK=1 skip the camera pre-flight (don't)
# Keys while recording: -> end episode now, <- discard & redo, Esc stop (workflows/12-recording-keys.md).
#
# THE RULE THAT MAKES THIS WORK: both objects are in frame in EVERY episode of BOTH datasets, and
# they swap sides halfway. If a dataset only ever contains its own object, the policy never has to
# read the sentence — see lessons/balance-the-instructions.md.
set -euo pipefail; source "$(dirname "$0")/_common.sh"
TOOLS="$(cd "$(dirname "$0")" && pwd)"; VAULT="$(dirname "$TOOLS")"

WHICH=${1:?which half: frasco | caja}; shift || true
case "$WHICH" in
  frasco) NAME=so100_medicamento_frasco; TASK="agarra el frasco de magnesio";  TARGET="frasco de magnesio (bottle)";;
  caja)   NAME=so100_medicamento_caja;   TASK="agarra la caja de Complejo B"; TARGET="caja de Complejo B (box)";;
  *) echo "unknown half '$WHICH' — use: frasco | caja" >&2; exit 1;;
esac
case "$TASK" in *:*|*\'*) echo "task string must not contain ':' or \"'\"" >&2; exit 1;; esac

PLAN=0; EPS=100
for arg in "$@"; do case "$arg" in --plan) PLAN=1;; ''|*[!0-9]*) ;; *) EPS=$arg;; esac; done
EPISODE_TIME_S=${EPISODE_TIME_S:-30}; RESET_TIME_S=${RESET_TIME_S:-10}

# --- the recording schedule: 5 spawn spots x 2 sides x N repeats -------------------------------
# "side" = which side of the mat the TARGET object sits on. Swapping it is what stops the policy
# from learning "always go left" instead of reading the instruction.
SPOTS=(front-left front-right centre back-left back-right)
plan() {
  local per_block=$((EPS / 10)) n=0
  printf '\n  %-3s %-12s %-16s %s\n' "#" "spawn spot" "target is on the" "episodes"
  printf '  %s\n' "-------------------------------------------------------------"
  for side in LEFT RIGHT; do
    for spot in "${SPOTS[@]}"; do
      n=$((n + 1))
      printf '  %-3s %-12s %-16s %s\n' "$n" "$spot" "$side" "$per_block"
    done
  done
  cat <<PLANNOTE

  $EPS episodes = 10 blocks x $per_block. Record a block, stop with Esc, move the objects, then
  continue with:  RESUME=1 tools/record_medicamentos.sh $WHICH $EPS
  Within a block vary the object's yaw every episode; keep the same approach path.
PLANNOTE
}
[ "$PLAN" = 1 ] && { plan; exit 0; }

cd "$LEROBOT_DIR"   # `uv run` resolves the project from the cwd

# --- pre-flight ---------------------------------------------------------------------------------
VER=$($RUN python -c "import lerobot; print(lerobot.__version__)")
echo "lerobot $VER via '$RUN' in $LEROBOT_DIR ($(git -C "$LEROBOT_DIR" rev-parse --short HEAD))"
case "$VER" in 0.6*) ;; *) echo "expected lerobot 0.6.x — the policy must be trained and run on the same version" >&2; exit 1;; esac

for dev in "$ROBOT_PORT" "$TELEOP_PORT"; do
  [ -e "$dev" ] || { echo "missing $dev — run tools/find_ports.sh (macOS ports are stable; Linux ACM numbers swap)" >&2; exit 1; }
done
$RUN python "$TOOLS/identify_arms.py" || { echo "arm identification failed — fix before teleoperating" >&2; exit 1; }

export CAMERAS="${CAMS:-$CAMERAS}"
if [ "${SKIP_CAM_CHECK:-0}" != 1 ]; then
  CAMERAS="$CAMERAS" $RUN python "$TOOLS/check_cameras.py" || exit 1
fi

DS="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}/${DATASET_PREFIX}/${NAME}"
if [ -d "$DS" ] && [ "${RESUME:-0}" != 1 ]; then
  echo "dataset folder exists: $DS" >&2
  echo "  append:  RESUME=1 $0 $WHICH $EPS      |  start over:  rm -rf $DS" >&2
  exit 1
fi
if [ "${PUSH_TO_HUB:-false}" = true ]; then
  $RUN hf auth whoami >/dev/null 2>&1 || { echo "PUSH_TO_HUB=true but not logged in — run: $RUN hf auth login" >&2; exit 1; }
fi

cat <<EOF

  dataset : ${DATASET_PREFIX}/${NAME}   (${EPS} episodes, cap ${EPISODE_TIME_S}s, reset ${RESET_TIME_S}s)
  task    : "$TASK"
  target  : $TARGET
  cameras : $CAMERAS

  IN EVERY EPISODE: both objects on the mat, in frame. You move only the $TARGET.
  The other object sits there untouched as the distractor — that is what teaches the sentence.
  Same mat, same destination, same light for BOTH halves of the dataset (lessons/scene-kit.md).
EOF
plan

exec "$TOOLS/record.sh" "$NAME" "$TASK" "$EPS" "$EPISODE_TIME_S" "$RESET_TIME_S"
