# sourced by the wrappers
[ -n "$MACHINE" ] || { echo "run: source tools/env.sh desktop|macbook" >&2; exit 1; }
DRY=${DRY:-0}
run() { echo "+ $*"; [ "$DRY" = 1 ] || eval "$*"; }
q() { printf '%q' "$1"; }

# tools/cameras.sh unsets CAMERAS when a camera is missing, so any script that needs video says so
# clearly instead of emitting an empty --robot.cameras= (lessons/camera-indices-shift-on-replug.md).
need_cameras() {
  [ -n "${CAMERAS:-}" ] && return 0
  echo "no cameras resolved for profile '$MACHINE' — plug them in, then: ls -l /dev/v4l/by-path/" >&2
  echo "(re-run 'source tools/env.sh $MACHINE' afterwards; see hardware/cameras.md)" >&2
  exit 1
}

# policy_camera_keys <policy_dir> -> the DATASET camera keys the policy was trained on, one per line.
# A policy fine-tuned from smolvla_base stores them as the keys of its rename_map (top/wrist ->
# camera1/camera2); ACT and friends store them directly in config.json input_features.
policy_camera_keys() {
  python3 - "$1" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
keys = []
tc = p / "train_config.json"
if tc.is_file():
    keys = [k for k in (json.loads(tc.read_text()).get("rename_map") or {}) if ".images." in k]
if not keys:
    cf = p / "config.json"
    if cf.is_file():
        keys = [k for k in json.loads(cf.read_text()).get("input_features", {}) if ".images." in k]
print("\n".join(k.rsplit(".", 1)[-1] for k in keys))
PY
}

# cameras_for_policy <policy_dir> -> a --robot.cameras block holding EXACTLY the cameras that policy
# needs, taken from the resolved CAM_<KEY> blocks. A rig with more cameras than the policy uses is
# normal (we record three, the demo policy reads two); passing the extra one is an error at load time
# ([[camera-keys-are-baked-in]]), so the policy decides, not the shell.
cameras_for_policy() {
  local dir="$1" key block out="" missing=""
  [ -d "$dir" ] || { echo "${CAMERAS:-}"; return 0; }          # Hub id: fall back to the profile
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    eval "block=\${CAM_$(echo "$key" | tr 'a-z' 'A-Z'):-}"
    if [ -n "$block" ]; then out="${out:+$out, }$block"; else missing="${missing:+$missing }$key"; fi
  done <<POLICY_KEYS
$(policy_camera_keys "$dir")
POLICY_KEYS
  if [ -n "$missing" ]; then
    echo "policy $(basename "$(dirname "$dir")") needs camera(s) [$missing] that this machine did not resolve" >&2
    echo "  plug them in / fix CAM_*_PATH in machines/$MACHINE.env, then re-source tools/env.sh" >&2
    return 1
  fi
  [ -n "$out" ] || { echo "${CAMERAS:-}"; return 0; }           # state-only policy: keep the profile's set
  echo "{ $out }"
}
