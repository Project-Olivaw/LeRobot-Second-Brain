#!/usr/bin/env bash
# Usage: tools/train_act.sh <dataset_name> [steps=30000] [save_freq=5000] [suffix]
# Trains ACT locally on $DEVICE. Output: $LEROBOT_DIR/outputs/train/act_<name><suffix>. DRY=1 to print only.
set -e; source "$(dirname "$0")/_common.sh"
NAME=${1:?dataset name}; STEPS=${2:-30000}; SF=${3:-5000}; SUF=${4:-}
JOB=act_${NAME}${SUF}
run "$RUN lerobot-train \
  --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
  --policy.type=act \
  --output_dir=outputs/train/${JOB} --job_name=${JOB} \
  --policy.device=$DEVICE \
  --batch_size=$BATCH_SIZE --num_workers=$NUM_WORKERS \
  --steps=$STEPS --save_freq=$SF \
  --wandb.enable=false --policy.push_to_hub=false"
