#!/usr/bin/env bash
# Lock exposure and white balance on the cameras of the current profile (Linux only).
# Auto-exposure/AWB change the pixels when the room light changes, and the policy keys off pixels —
# see lessons/lock-exposure-and-white-balance.md. Run this BEFORE record / rollout, after every replug.
# Usage: tools/lock_cameras.sh [exposure=250] [white_balance_kelvin=4600]
#        tools/lock_cameras.sh --show      # just print what each camera currently reports
set -uo pipefail; source "$(dirname "$0")/_common.sh"
[ "$(uname)" = "Linux" ] || { echo "macOS/Windows: UVC exposure is not settable from here — see the lesson note." >&2; exit 1; }
command -v v4l2-ctl >/dev/null || { echo "install v4l-utils: sudo apt install v4l-utils" >&2; exit 1; }
EXP=${1:-250}; WB=${2:-4600}
for id_var in CAM_TOP_ID CAM_WRIST_ID CAM_BASE_ID; do
  link="/dev/v4l/by-id/${!id_var:-}"; [ -e "$link" ] || continue
  dev=$(readlink -f "$link"); key=$(echo "${id_var#CAM_}" | tr '[:upper:]' '[:lower:]' | sed 's/_id//')
  if [ "${1:-}" = "--show" ]; then
    echo "== $key ($dev)"; v4l2-ctl -d "$dev" --list-ctrls | grep -iE "exposure|white_balance" || true; continue
  fi
  echo "== $key ($dev)"
  # Control names differ between UVC drivers; try both spellings and report what stuck.
  v4l2-ctl -d "$dev" --set-ctrl=auto_exposure=1 2>/dev/null || v4l2-ctl -d "$dev" --set-ctrl=exposure_auto=1 2>/dev/null || echo "  (no manual exposure mode)"
  v4l2-ctl -d "$dev" --set-ctrl=exposure_time_absolute="$EXP" 2>/dev/null || v4l2-ctl -d "$dev" --set-ctrl=exposure_absolute="$EXP" 2>/dev/null || true
  v4l2-ctl -d "$dev" --set-ctrl=white_balance_automatic=0 2>/dev/null || v4l2-ctl -d "$dev" --set-ctrl=white_balance_temperature_auto=0 2>/dev/null || echo "  (no manual white balance)"
  v4l2-ctl -d "$dev" --set-ctrl=white_balance_temperature="$WB" 2>/dev/null || true
  v4l2-ctl -d "$dev" --list-ctrls | grep -iE "^\s+(auto_exposure|exposure_time_absolute|white_balance)" | sed 's/^/  /'
done
echo "Note: these reset when the camera is replugged or power-cycled. Re-run after any replug."
