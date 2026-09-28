#!/usr/bin/env bash
# The stage demo: run ONE instruction through a policy, record nothing, stop cleanly.
# This is the command from the slide `demo-live` (VLA-introduction-slides), wired to this machine.
# Usage: tools/demo.sh "<instruction>" [seconds=60] [policy=$DEMO_POLICY]
# Env: RTC=0 to disable real-time chunking (on by default here — a VLA stalls on every chunk
#      recompute, see lessons/policy-inference-is-bursty.md and tools/bench_policy.py).
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
need_cameras
TASK=${1:?instruction, e.g. "agarra el Complejo B"}; SECS=${2:-60}; POLICY=${3:-${DEMO_POLICY:-}}
[ -n "$POLICY" ] || { echo "no policy: pass one, or set DEMO_POLICY in machines/$MACHINE.env" >&2; exit 1; }
[ -e "$POLICY" ] && [ ! -f "$POLICY/config.json" ] && { echo "$POLICY has no config.json — point at .../pretrained_model" >&2; exit 1; }
RM=""
if [ -f "$POLICY/train_config.json" ]; then
  MAP=$(python3 -c "import json,sys; m=json.load(open(sys.argv[1])).get('rename_map') or {}; print(json.dumps(m) if m else '')" "$POLICY/train_config.json")
  [ -n "$MAP" ] && RM="--rename_map=$(q "$MAP")"
elif [ -n "${RENAME_MAP:-}" ]; then RM="--rename_map=$(q "$RENAME_MAP")"; fi
INF="--inference.type=rtc"; [ "${RTC:-1}" = 0 ] && INF=""
run "$RUN lerobot-rollout \
  --strategy.type=base $INF \
  --policy.path=$(q "$POLICY") --device=$DEVICE $RM \
  --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
  --robot.cameras=$(q "$CAMERAS") \
  --task=$(q "$TASK") \
  --duration=$SECS \
  --display_data=true"
