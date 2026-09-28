#!/usr/bin/env bash
# Sourced by tools/env.sh on Linux. Resolves each camera by its stable /dev/v4l/by-id name (survives
# replugging, reboots and other cameras being added/removed) to the /dev/videoN index OpenCV needs today,
# then rebuilds CAM_TOP / CAM_WRIST / CAM_BASE / CAMERAS*. Missing cameras are dropped from CAMERAS_THREE
# with a warning; CAMERAS (top+wrist) fails loudly if either is missing. See lessons/camera-indices-shift-on-replug.md.
# Ids come from machines/<name>.env (CAM_TOP_ID, CAM_WRIST_ID, CAM_BASE_ID) — list yours with: ls -l /dev/v4l/by-id/
_cam_index() {  # $1 = by-id name -> prints N from /dev/videoN, or nothing
  local link="/dev/v4l/by-id/$1"
  [ -e "$link" ] && readlink -f "$link" | sed -n 's|.*/video\([0-9]*\)$|\1|p'
}
_cam_block() {  # $1 = key, $2 = index
  printf '%s: {type: opencv, index_or_path: %s, width: 640, height: 480, fps: 30, fourcc: MJPG}' "$1" "$2"
}
_top=$(_cam_index "${CAM_TOP_ID:-}"); _wrist=$(_cam_index "${CAM_WRIST_ID:-}"); _base=$(_cam_index "${CAM_BASE_ID:-}")
_blocks=(); _msg=""
if [ -n "$_top" ];   then export CAM_TOP="$(_cam_block top "$_top")";       _blocks+=("$CAM_TOP");   _msg+=" top=$_top";     else _msg+=" top=MISSING";   fi
if [ -n "$_wrist" ]; then export CAM_WRIST="$(_cam_block wrist "$_wrist")"; _blocks+=("$CAM_WRIST"); _msg+=" wrist=$_wrist"; else _msg+=" wrist=MISSING"; fi
if [ -n "$_base" ];  then export CAM_BASE="$(_cam_block base "$_base")";    _blocks+=("$CAM_BASE");  _msg+=" base=$_base";   else _msg+=" base=absent";   fi
_join() { local out="" b; for b in "$@"; do out="${out:+$out, }$b"; done; echo "$out"; }
if [ -n "$_top" ] && [ -n "$_wrist" ]; then
  export CAMERAS="{ $CAM_TOP, $CAM_WRIST }"
else
  unset CAMERAS; echo "cameras: top or wrist not found — plug them in, then: ls -l /dev/v4l/by-id/" >&2
fi
export CAMERAS_THREE="{ $(_join "${_blocks[@]}") }"
[ -n "$_top" ] && export CAMERAS_TOP_ONLY="{ $CAM_TOP }"
echo "cameras (by-id):$_msg"
unset _top _wrist _base _blocks _msg
