#!/usr/bin/env bash
# Merge several single-instruction datasets into one multi-task dataset for a VLA.
# lerobot-record writes ONE --dataset.single_task per run, so a multi-task dataset is built by
# recording one dataset per instruction and merging them here. Task strings are preserved per episode.
# Usage: tools/merge_tasks.sh <output_name> <name1> <name2> [name3 ...]
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
OUT=${1:?output name}; shift; [ $# -ge 2 ] || { echo "give at least two input datasets" >&2; exit 1; }
IN=""; for n in "$@"; do IN="${IN:+$IN,}${DATASET_PREFIX}/${n}"; done
run "$RUN lerobot-edit-dataset \
  --operation.type=merge \
  --operation.repo_ids=$(q "[$IN]") \
  --new_repo_id=${DATASET_PREFIX}/${OUT} \
  --push_to_hub=false"
echo "merged -> ${DATASET_PREFIX}/${OUT}"
echo "check the task list with: tools/tasks.sh ${OUT}"
