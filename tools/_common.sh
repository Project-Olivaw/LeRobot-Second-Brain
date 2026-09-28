# sourced by the wrappers
[ -n "$MACHINE" ] || { echo "run: source tools/env.sh desktop|macbook" >&2; exit 1; }
DRY=${DRY:-0}
run() { echo "+ $*"; [ "$DRY" = 1 ] || eval "$*"; }
q() { printf '%q' "$1"; }

# tools/cameras.sh unsets CAMERAS when a camera is missing, so any script that needs video says so
# clearly instead of emitting an empty --robot.cameras= (lessons/camera-indices-shift-on-replug.md).
need_cameras() {
  [ -n "${CAMERAS:-}" ] && return 0
  echo "no cameras resolved for profile '$MACHINE' — plug them in, then: ls -l /dev/v4l/by-id/" >&2
  echo "(re-run 'source tools/env.sh $MACHINE' afterwards; see hardware/cameras.md)" >&2
  exit 1
}
