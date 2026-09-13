#!/usr/bin/env bash
# Usage: tools/train_smolvla.sh <dataset_name> [steps=20000] [suffix]
#        tools/train_smolvla.sh --jobs <dataset_name> [steps] [flavor=a10g-large]   # launch on HF Jobs
# Fine-tunes lerobot/smolvla_base. DRY=1 to print only.
set -e; source "$(dirname "$0")/_common.sh"
if [ "${1:-}" = "--jobs" ]; then
  NAME=${2:?dataset name}; STEPS=${3:-20000}; FLAVOR=${4:-a10g-large}
  [ -n "$HF_USER" ] || { echo "HF_USER is empty — see lessons/hf-whoami-format.md" >&2; exit 1; }
  run "hf jobs run --flavor $FLAVOR --timeout 6h --secrets HF_TOKEN huggingface/lerobot-gpu:latest -- \
  python -m lerobot.scripts.lerobot_train \
    --policy.path=lerobot/smolvla_base \
    --dataset.repo_id=${HF_USER}/${NAME} \
    --batch_size=32 --steps=$STEPS --policy.scheduler_decay_steps=$STEPS \
    --policy.device=cuda \
    --policy.repo_id=${HF_USER}/smolvla_${NAME} --policy.push_to_hub=true \
    --save_freq=5000 --log_freq=100"
  exit 0
fi
NAME=${1:?dataset name}; STEPS=${2:-20000}; SUF=${3:-}
JOB=smolvla_${NAME}${SUF}
run "$RUN lerobot-train \
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
  --output_dir=outputs/train/${JOB} --job_name=${JOB} \
  --policy.device=$DEVICE \
  --batch_size=$BATCH_SIZE --num_workers=$NUM_WORKERS \
  --steps=$STEPS --policy.scheduler_decay_steps=$STEPS --save_freq=5000 \
  --wandb.enable=false --policy.push_to_hub=false"
