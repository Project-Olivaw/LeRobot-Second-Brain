# sourced by the wrappers
[ -n "$MACHINE" ] || { echo "run: source tools/env.sh desktop|macbook" >&2; exit 1; }
DRY=${DRY:-0}
run() { echo "+ $*"; [ "$DRY" = 1 ] || eval "$*"; }
q() { printf '%q' "$1"; }
