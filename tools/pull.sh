#!/usr/bin/env bash
# Bring a policy and/or a dataset from the Hub onto THIS machine (desktop <-> MacBook exchange).
# Usage: tools/pull.sh policy  <repo_id_or_name>     # e.g. smolvla_so100_medicament_box
#        tools/pull.sh dataset <repo_id_or_name>
# A bare name is prefixed with $HF_USER. Downloads into the HF cache, so later
# --policy.path=<repo_id> / --dataset.repo_id=<repo_id> run offline. Do this BEFORE leaving wifi.
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
KIND=${1:?policy|dataset}; NAME=${2:?repo id or name}
case "$NAME" in */*) REPO="$NAME";; *) [ -n "${HF_USER:-}" ] || { echo "HF_USER empty — run: hf auth login (lessons/hf-whoami-format.md)" >&2; exit 1; }; REPO="$HF_USER/$NAME";; esac
case "$KIND" in
  policy)  run "$RUN hf download $(q "$REPO")"; echo "use it with: --policy.path=$REPO" ;;
  dataset) run "$RUN hf download --repo-type=dataset $(q "$REPO")"; echo "use it with: --dataset.repo_id=$REPO" ;;
  *) echo "usage: $0 policy|dataset <repo>" >&2; exit 1 ;;
esac
