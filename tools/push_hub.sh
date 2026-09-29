#!/usr/bin/env bash
# Usage: tools/push_hub.sh dataset <local_name> [private=true]
#        tools/push_hub.sh policy  <job_name> [checkpoint=last] [private=true]
# Both default to PRIVATE. A policy repo can be flipped public later from the Hub UI (or with
# `hf repo settings <user>/<name> --public`); an accidental public release cannot be taken back.
# Explicit uploads only. Requires HF_USER. DRY=1 to print only.
set -e; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"   # `uv run` resolves the project from the cwd
[ -n "$HF_USER" ] || { echo "HF_USER is empty — see lessons/hf-whoami-format.md" >&2; exit 1; }
case "${1:-}" in
  dataset)
    NAME=${2:?local dataset name}; PRIV=${3:-true}
    # LeRobotDataset.push_to_hub() takes NO repo_id — it uploads to self.repo_id, so a local/
    # dataset must be re-pointed first or the push tries to create the namespace "local" (403).
    run "$RUN python $(q "$VAULT_DIR/tools/push_dataset.py") $(q "${DATASET_PREFIX}/${NAME}") $(q "${HF_USER}/${NAME}") $(q "$PRIV")" ;;
  policy)
    JOB=${2:?job name}; CK=${3:-last}; PRIV=${4:-true}
    SRC="outputs/train/${JOB}/checkpoints/${CK}/pretrained_model"
    [ -f "$SRC/config.json" ] || { echo "no policy at $SRC — check the job name and checkpoint" >&2; exit 1; }
    FLAG="--private"; [ "$PRIV" = false ] && FLAG="--no-private"
    run "$RUN hf upload ${HF_USER}/${JOB} $(q "$SRC") $FLAG" ;;
  *) echo "usage: $0 dataset <name> | policy <job> [ckpt]" >&2; exit 1 ;;
esac
