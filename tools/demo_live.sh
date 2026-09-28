#!/usr/bin/env bash
# THE STAGE DEMO. One process, hardware and policy stay warm, and you change the instruction by
# typing — no restart, no reload, no second terminal.
#
#   tools/demo_live.sh                      # uses $DEMO_POLICY and $DEMO_TASK1
#   tools/demo_live.sh "<first instruction>" [policy]
#
# Once it starts you get a "/" prompt. The robot does NOT move until you type /start.
#   /start                  begin acting on the current instruction
#   /subtask <text>         change the instruction live  <-- this is the demo
#   /reset                  return to the initial position and hold
#   /stop                   shut down cleanly
#   /help                   full command list
#
# Stage sequence for the talk:
#   /start
#   (silence while it picks the Complejo B)
#   /subtask agarra el frasco de zinc      <- say it out loud as you type it
#   (silence; when it goes to the other object, stop talking)
#
# Env: RTC=0 to disable real-time chunking (on by default; a VLA stalls on each chunk recompute —
#      lessons/policy-inference-is-bursty.md).
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
need_cameras
TASK=${1:-${DEMO_TASK1:-}}; POLICY=${2:-${DEMO_POLICY:-}}
[ -n "$POLICY" ] || { echo "no policy: pass one, or set DEMO_POLICY in machines/$MACHINE.env" >&2; exit 1; }
[ -n "$TASK" ]   || { echo "no instruction: pass one, or set DEMO_TASK1 in machines/$MACHINE.env" >&2; exit 1; }
[ -e "$POLICY" ] && [ ! -f "$POLICY/config.json" ] && { echo "$POLICY has no config.json — point at .../pretrained_model" >&2; exit 1; }
RM=""
if [ -f "$POLICY/train_config.json" ]; then
  MAP=$(python3 -c "import json,sys; m=json.load(open(sys.argv[1])).get('rename_map') or {}; print(json.dumps(m) if m else '')" "$POLICY/train_config.json")
  [ -n "$MAP" ] && RM="--rename_map=$(q "$MAP")"
elif [ -n "${RENAME_MAP:-}" ]; then RM="--rename_map=$(q "$RENAME_MAP")"; fi
POLICY_CAMERAS=$(cameras_for_policy "$POLICY") || exit 1
INF="--inference.type=rtc"; [ "${RTC:-1}" = 0 ] && INF=""
run "$RUN lerobot-rollout \
  --strategy.type=base --interactive=true $INF \
  --policy.path=$(q "$POLICY") --device=$DEVICE $RM \
  --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
  --robot.cameras=$(q "$POLICY_CAMERAS") \
  --task=$(q "$TASK") \
  --display_data=true"
