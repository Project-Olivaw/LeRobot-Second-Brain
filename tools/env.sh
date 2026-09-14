#!/usr/bin/env bash
# Usage: source tools/env.sh desktop|macbook
# Loads machines/<name>.env and cds into $LEROBOT_DIR so `uv run lerobot-*` resolves.
_name="${1:-desktop}"
# No `cd` inside $(...): zsh chpwd hooks (auto-ls) would leak their output into the path.
_here="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
_env="$_here/../machines/$_name.env"
if [ ! -f "$_env" ]; then echo "no profile: $_env" >&2; return 1 2>/dev/null || exit 1; fi
export VAULT_DIR="$(readlink -f "$_here/..")"
# shellcheck disable=SC1090
source "$_env"
if [ -d "$LEROBOT_DIR" ]; then cd "$LEROBOT_DIR" || true; else echo "warning: LEROBOT_DIR=$LEROBOT_DIR not found" >&2; fi
case "$ROBOT_PORT" in *TODO*) echo "warning: fill ports/cameras in machines/$_name.env" >&2;; esac
echo "[$MACHINE] robot=$ROBOT_PORT teleop=$TELEOP_PORT device=$DEVICE run='$RUN' lerobot=$LEROBOT_DIR"
