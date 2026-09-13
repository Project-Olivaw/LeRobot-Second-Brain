#!/usr/bin/env bash
# Usage: tools/push_hub.sh dataset <local_name> [private=true]
#        tools/push_hub.sh policy  <job_name> [checkpoint=last]
# Explicit uploads only. Requires HF_USER. DRY=1 to print only.
set -e; source "$(dirname "$0")/_common.sh"
[ -n "$HF_USER" ] || { echo "HF_USER is empty — see lessons/hf-whoami-format.md" >&2; exit 1; }
case "${1:-}" in
  dataset)
    NAME=${2:?local dataset name}; PRIV=${3:-true}
    run "$RUN python -c \"from lerobot.datasets.lerobot_dataset import LeRobotDataset as D; D('${DATASET_PREFIX}/${NAME}').push_to_hub(repo_id='${HF_USER}/${NAME}', private=${PRIV^})\"" ;;
  policy)
    JOB=${2:?job name}; CK=${3:-last}
    run "$RUN hf upload ${HF_USER}/${JOB} outputs/train/${JOB}/checkpoints/${CK}/pretrained_model" ;;
  *) echo "usage: $0 dataset <name> | policy <job> [ckpt]" >&2; exit 1 ;;
esac
