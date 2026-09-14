#!/usr/bin/env bash
# Overnight chain on the desktop GPU: ACT baseline (short) -> SmolVLA fine-tune (long).
# Usage: tools/overnight_medicament_box.sh [smolvla_steps=30000] [act_steps=20000]
#   Detached:  nohup tools/overnight_medicament_box.sh > /dev/null 2>&1 &     (or run it inside tmux)
#   Follow:    tail -f $LEROBOT_DIR/outputs/train/logs/smolvla_so100_medicament_box_*.log
#   ETA:       tools/eta.sh <that log> 30000
# Env: NAME (dataset), SKIP_ACT=1, DRY=1. Refuses to overwrite existing job dirs (lessons/train-refuses-to-overwrite.md).
set -euo pipefail; source "$(dirname "$0")/_common.sh"

NAME=${NAME:-so100_medicament_box}
VLA_STEPS=${1:-30000}; ACT_STEPS=${2:-20000}
SAVE_FREQ=2500                      # frequent checkpoints = whatever has finished by morning is usable
ACT_JOB=act_${NAME}; VLA_JOB=smolvla_${NAME}
DS="$HOME/.cache/huggingface/lerobot/${DATASET_PREFIX}/${NAME}"
LOGDIR="$LEROBOT_DIR/outputs/train/logs"; STAMP=$(date +%Y%m%d_%H%M)

# Keep the box awake for the whole chain (re-exec under systemd-inhibit once).
if [ -z "${_INHIBITED:-}" ] && [ "$DRY" != 1 ] && command -v systemd-inhibit >/dev/null; then
  _INHIBITED=1 exec systemd-inhibit --what=sleep:idle --who=lerobot --why="overnight training $NAME" "$0" "$@"
fi

# --- pre-flight ---
[ -f "$DS/meta/info.json" ] || { echo "no dataset at $DS — record first (tools/record_medicament_box.sh)" >&2; exit 1; }
EPISODES=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['total_episodes'])" "$DS/meta/info.json")
FRAMES=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['total_frames'])" "$DS/meta/info.json")
echo "dataset ${DATASET_PREFIX}/${NAME}: $EPISODES episodes, $FRAMES frames"
[ "$EPISODES" -ge 40 ] || echo "WARNING: fewer than 40 episodes — HF reports 25 was not enough (lessons/no-same-evening-vla.md)" >&2
for j in $ACT_JOB $VLA_JOB; do
  [ "$j" = "$ACT_JOB" ] && [ "${SKIP_ACT:-0}" = 1 ] && continue
  [ -e "$LEROBOT_DIR/outputs/train/$j" ] && { echo "outputs/train/$j exists — move it or pass a new NAME" >&2; exit 1; }
done
[ -d "$HOME/.cache/huggingface/hub/models--lerobot--smolvla_base" ] || $RUN hf download lerobot/smolvla_base >/dev/null
nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader
mkdir -p "$LOGDIR"; cd "$LEROBOT_DIR"

SUMMARY="$LOGDIR/overnight_${NAME}_${STAMP}.summary"
note() { echo "$(date '+%F %T')  $*" | tee -a "$SUMMARY"; }
note "start  lerobot=$($RUN python -c 'import lerobot;print(lerobot.__version__)') commit=$(git rev-parse --short HEAD) episodes=$EPISODES"

# --- 1) ACT baseline: cheap first signal. If ACT cannot learn it, the data is the problem. ---
if [ "${SKIP_ACT:-0}" != 1 ]; then
  ACT_LOG="$LOGDIR/${ACT_JOB}_${STAMP}.log"
  note "ACT    steps=$ACT_STEPS log=$ACT_LOG"
  if run "$RUN lerobot-train \
    --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
    --policy.type=act \
    --output_dir=outputs/train/${ACT_JOB} --job_name=${ACT_JOB} \
    --policy.device=$DEVICE \
    --batch_size=$BATCH_SIZE --num_workers=$NUM_WORKERS \
    --steps=$ACT_STEPS --save_freq=$SAVE_FREQ --log_freq=100 \
    --wandb.enable=false --policy.push_to_hub=false 2>&1 | tee $(q "$ACT_LOG")"; then
    note "ACT    done  -> outputs/train/${ACT_JOB}/checkpoints/last/pretrained_model"
  else
    note "ACT    FAILED (see log) — continuing to SmolVLA so the GPU is not idle all night"
  fi
fi

# --- 2) SmolVLA fine-tune from lerobot/smolvla_base (encoder frozen, expert only — fits 16 GB at batch 8) ---
VLA_LOG="$LOGDIR/${VLA_JOB}_${STAMP}.log"
note "SmolVLA steps=$VLA_STEPS log=$VLA_LOG"
if run "$RUN lerobot-train \
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
  --output_dir=outputs/train/${VLA_JOB} --job_name=${VLA_JOB} \
  --policy.device=$DEVICE \
  --batch_size=$BATCH_SIZE --num_workers=$NUM_WORKERS \
  --steps=$VLA_STEPS --policy.scheduler_decay_steps=$VLA_STEPS \
  --save_freq=$SAVE_FREQ --log_freq=100 \
  --wandb.enable=false --policy.push_to_hub=false 2>&1 | tee $(q "$VLA_LOG")"; then
  note "SmolVLA done  -> outputs/train/${VLA_JOB}/checkpoints/last/pretrained_model"
else
  note "SmolVLA FAILED (see log). Usable checkpoints, if any: ls outputs/train/${VLA_JOB}/checkpoints"
fi
note "end"
