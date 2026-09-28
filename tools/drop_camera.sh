#!/usr/bin/env bash
# Derive a dataset with fewer cameras from one that was recorded with more.
# Record every camera you own (you cannot add a view later); train the policy on the subset the
# machine that RUNS it can actually provide (workflows/14-two-instruction-demo.md, "how many cameras").
#
#   tools/drop_camera.sh <source_name> <new_name> <key> [key ...]     # keys to REMOVE, e.g. base
#
# Example: a 3-camera recording -> the 2-camera dataset the MacBook demo can serve
#   tools/drop_camera.sh so100_medicamentos so100_medicamentos_2cam base
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
SRC=${1:?source dataset name}; OUT=${2:?new dataset name}; shift 2
[ $# -ge 1 ] || { echo "name at least one camera key to remove (top|wrist|base)" >&2; exit 1; }
ROOT="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}/${DATASET_PREFIX}"
[ -d "$ROOT/$SRC" ] || { echo "not found: $ROOT/$SRC" >&2; exit 1; }
[ -e "$ROOT/$OUT" ] && { echo "already exists: $ROOT/$OUT — pick another name or rm -rf it" >&2; exit 1; }
FEATS=""; for k in "$@"; do FEATS="${FEATS:+$FEATS,}observation.images.${k}"; done
run "$RUN lerobot-edit-dataset \
  --operation.type=remove_feature \
  --repo_id=${DATASET_PREFIX}/${SRC} \
  --new_repo_id=${DATASET_PREFIX}/${OUT} \
  --operation.feature_names=$(q "[$FEATS]") \
  --push_to_hub=false"
echo "-> ${DATASET_PREFIX}/${OUT}   (check with: tools/tasks.sh ${OUT})"
