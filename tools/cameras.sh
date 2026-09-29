#!/usr/bin/env bash
# Sourced by tools/env.sh on Linux. Turns stable camera identities into today's /dev/videoN indices.
#
# Resolution order per key (first hit wins):
#   1. CAM_<KEY>_PATH  — /dev/v4l/by-path name = the physical USB port. Works even when two cameras
#      are the same model with the same serial (our two Innomaker U20CAM both report SN0001, so
#      /dev/v4l/by-id only ever creates ONE link for the pair and the other looks "absent").
#      Trade-off: it identifies the PORT, so plug each camera into the port written in the profile.
#   2. CAM_<KEY>_ID    — /dev/v4l/by-id name. Follows the camera to any port, but needs a unique serial.
#   3. CAM_<KEY>_INDEX — a bare integer. Last resort; changes on replug (lessons/camera-indices-shift-on-replug.md).
#
# Exports: CAM_TOP / CAM_WRIST / CAM_BASE (+ any CAM_EXTRA*_ID/_PATH you add), CAM_KEYS,
#          CAMERAS (every camera found), CAMERAS_TWO (top+wrist), CAMERAS_THREE, CAMERAS_TOP_ONLY.
# CAMERAS is unset when a required key is missing, so need_cameras() in _common.sh fails loudly.
# Required keys default to "top wrist base"; override with CAM_REQUIRED="top wrist" for a 2-camera rig.
# Add a camera to any session without touching the profile:
#   CAM_EXTRA1_PATH=...; CAM_EXTRA1_KEY=side; source tools/env.sh desktop

_cam_resolve() {   # $1 = KEY (upper case) -> prints the video index, or nothing
  local key="$1" link idx
  eval "link=\${CAM_${key}_PATH:-}"
  [ -n "$link" ] && [ -e "/dev/v4l/by-path/$link-video-index0" ] && {
    readlink -f "/dev/v4l/by-path/$link-video-index0" | sed -n 's|.*/video\([0-9]*\)$|\1|p'; return; }
  eval "link=\${CAM_${key}_ID:-}"
  [ -n "$link" ] && [ -e "/dev/v4l/by-id/$link" ] && {
    readlink -f "/dev/v4l/by-id/$link" | sed -n 's|.*/video\([0-9]*\)$|\1|p'; return; }
  eval "idx=\${CAM_${key}_INDEX:-}"
  [ -n "$idx" ] && [ -e "/dev/video$idx" ] && echo "$idx"
}
_cam_block() {     # $1 = key, $2 = index
  printf '%s: {type: opencv, index_or_path: %s, width: %s, height: %s, fps: %s, fourcc: MJPG}' \
    "$1" "$2" "${CAM_WIDTH:-640}" "${CAM_HEIGHT:-480}" "${CAM_FPS:-30}"
}
_cam_join() { local out="" b; for b in "$@"; do out="${out:+$out, }$b"; done; echo "$out"; }

_cam_all=(); _cam_keys=""; _cam_msg=""; _cam_idxs=""
# Keys to look for: the three fixed mounts, plus any CAM_EXTRA<N>_{PATH,ID,INDEX} in the environment.
# Fed through a here-doc and `read`: zsh does not word-split an unquoted $var the way bash does, and
# a pipe would run the loop in a subshell where the exports would be lost.
_cam_candidates=$(printf 'TOP\nWRIST\nBASE\n'
                  set | sed -n 's/^CAM_\(EXTRA[0-9A-Za-z_]*\)_\(PATH\|ID\|INDEX\)=.*/\1/p' | sort -u)
while IFS= read -r _K; do
  [ -n "$_K" ] || continue
  # no bashisms here either: ${x^^} is a syntax error in zsh
  _k=$(echo "$_K" | tr 'A-Z' 'a-z'); eval "_alias=\${CAM_${_K}_KEY:-}"; [ -n "${_alias:-}" ] && _k="$_alias"
  _i=$(_cam_resolve "$_K")
  if [ -n "$_i" ]; then
    _b=$(_cam_block "$_k" "$_i"); eval "export CAM_${_K}=\"\$_b\""
    _cam_all+=("$_b"); _cam_keys="${_cam_keys:+$_cam_keys }$_k"; _cam_msg="$_cam_msg $_k=$_i"
    _cam_idxs="${_cam_idxs:+$_cam_idxs }$_i"
  else
    unset "CAM_${_K}"; _cam_msg="$_cam_msg $_k=MISSING"
  fi
done <<CAM_CANDIDATES
$_cam_candidates
CAM_CANDIDATES

export CAM_KEYS="$_cam_keys"
[ -n "${CAM_TOP:-}" ] && [ -n "${CAM_WRIST:-}" ] && export CAMERAS_TWO="{ $CAM_TOP, $CAM_WRIST }"
[ -n "${CAM_TOP:-}" ] && [ -n "${CAM_WRIST:-}" ] && [ -n "${CAM_BASE:-}" ] && \
  export CAMERAS_THREE="{ $(_cam_join "$CAM_TOP" "$CAM_WRIST" "$CAM_BASE") }"
[ -n "${CAM_TOP:-}" ] && export CAMERAS_TOP_ONLY="{ $CAM_TOP }"

# CAMERAS = everything that answered, so an extra camera is picked up without editing a script.
if [ ${#_cam_all[@]} -gt 0 ]; then export CAMERAS="{ $(_cam_join "${_cam_all[@]}") }"; else unset CAMERAS; fi

# Two keys resolving to the SAME /dev/videoN is always a configuration error: the first camera
# connects and the second fails with OpenCV's opaque "Failed to open OpenCVCamera(N)". Catch it here.
_cam_dupes=$(printf '%s\n' $_cam_idxs | sort | uniq -d | tr '\n' ' ')
if [ -n "${_cam_dupes// /}" ]; then
  unset CAMERAS
  echo "cameras: TWO KEYS ON THE SAME DEVICE (index ${_cam_dupes% }) — found:${_cam_msg:-none}" >&2
  echo "  a CAM_*_PATH/_ID in machines/$MACHINE.env points at a device another key already claims," >&2
  echo "  or a stale CAM_* export from an earlier source survived. Fix: open a new terminal, or" >&2
  echo "  unset the stale variable, then re-source. See lessons/stale-exports-survive-a-resource.md" >&2
  _cam_bad=1
fi

# Required keys must all be present, or CAMERAS is withdrawn (need_cameras() then refuses to run).
_cam_lack=""
while IFS= read -r _r; do
  [ -n "$_r" ] || continue
  case " $_cam_keys " in *" $_r "*) ;; *) _cam_lack="${_cam_lack:+$_cam_lack }$_r";; esac
done <<CAM_REQ
$(printf '%s\n' ${CAM_REQUIRED:-top wrist base} | tr ' ' '\n')
CAM_REQ
if [ -n "$_cam_lack" ]; then
  unset CAMERAS
  echo "cameras: MISSING REQUIRED [$_cam_lack] — found:${_cam_msg:-none}" >&2
  echo "  plug them in, then re-source. Identify ports with: ls -l /dev/v4l/by-path/" >&2
  echo "  recording with fewer on purpose? CAM_REQUIRED=\"top wrist\" source tools/env.sh $MACHINE" >&2
elif [ -z "${_cam_bad:-}" ]; then
  echo "cameras:$_cam_msg  (keys: $CAM_KEYS)"
fi
unset _cam_all _cam_keys _cam_missing _cam_msg _cam_candidates _cam_lack _cam_idxs _cam_dupes _cam_bad _K _k _i _b _alias _r
