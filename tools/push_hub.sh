#!/usr/bin/env bash
# Usage: tools/push_hub.sh dataset <local_name> [private=true]
#        tools/push_hub.sh policy  <job_name> [checkpoint=last]
# Explicit uploads only. Requires HF_USER. DRY=1 to print only.
set -e; source "$(dirname "$0")/_common.sh"
[ -n "$HF_USER" ] || { echo "HF_USER is empty — see lessons/hf-whoami-format.md" >&2; exit 1; }
case "${1:-}" in
  dataset)
    NAME=${2:?local dataset name}; PRIV=${3:-true}
    # LeRobotDataset.push_to_hub() takes NO repo_id — it uploads to self.repo_id, so a local/
    # dataset must be re-pointed first or the push tries to create the namespace "local" (403).
    run "$RUN python $(q "$VAULT_DIR/tools/push_dataset.py") $(q "${DATASET_PREFIX}/${NAME}") $(q "${HF_USER}/${NAME}") $(q "$PRIV")" ;;
  policy)
    JOB=${2:?job name}; CK=${3:-last}
    run "$RUN hf upload ${HF_USER}/${JOB} outputs/train/${JOB}/checkpoints/${CK}/pretrained_model" ;;
  *) echo "usage: $0 dataset <name> | policy <job> [ckpt]" >&2; exit 1 ;;
esac
