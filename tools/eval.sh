#!/usr/bin/env bash
# Run a trained policy on the follower (lerobot >= 0.6: `lerobot-rollout`; `lerobot-record` now rejects eval_ names).
# Usage: tools/eval.sh <dataset_name> <policy_path_or_hub_id> [episodes=10] ["task sentence"] [episode_time_s=30]
#   episodes=0  -> quick look, nothing recorded (strategy base, runs for episode_time_s seconds)
#   episodes>0  -> strategy episodic: records <prefix>/rollout_<name>_<timestamp>, -> ends episode, <- discards, Esc stops;
#                  the leader drives the arm during reset phases (bring it back to start, then ->).
# The --rename_map used at training time is read from <policy>/train_config.json automatically (SmolVLA from
# smolvla_base: top->camera1, wrist->camera2; ACT: none). RENAME_MAP=... is used only for policies without that file (Hub ids).
# Env: RTC=1 to use real-time chunking (smoother for VLAs). DRY=1 to print only.
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
NAME=${1:?dataset name}; POLICY=${2:?policy path}; EPS=${3:-10}; TASK=${4:-}; ET=${5:-30}
if [ -z "$TASK" ]; then
  META="$HOME/.cache/huggingface/lerobot/${DATASET_PREFIX}/${NAME}/meta/tasks.parquet"
  [ -f "$META" ] && TASK=$($RUN python -c "import pandas as pd,sys; print(pd.read_parquet(sys.argv[1]).index[0])" "$META" 2>/dev/null || true)
  [ -n "$TASK" ] || { echo "no task found in $META — pass it as 4th argument" >&2; exit 1; }
fi
[ -e "$POLICY" ] && [ ! -f "$POLICY/config.json" ] && { echo "$POLICY has no config.json — point at .../checkpoints/<step>/pretrained_model" >&2; exit 1; }
PDIR=$(policy_dir "$POLICY")                 # a Hub id resolves to its cached snapshot directory
if [ -n "$PDIR" ] && [ -f "$PDIR/train_config.json" ]; then   # the policy knows its own map; ignore any RENAME_MAP left in the shell
  RENAME_MAP=$(python3 -c "import json,sys; m=json.load(open(sys.argv[1])).get('rename_map') or {}; print(json.dumps(m) if m else '')" "$PDIR/train_config.json")
fi
RM=""; [ -n "${RENAME_MAP:-}" ] && RM="--rename_map=$(q "$RENAME_MAP")"
need_cameras
POLICY_CAMERAS=$(cameras_for_policy "${PDIR:-$POLICY}") || exit 1   # only the cameras this policy was trained on
INF=""; [ "${RTC:-0}" = 1 ] && INF="--inference.type=rtc"
COMMON="$RUN lerobot-rollout \
  --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
  --robot.cameras=$(q "$POLICY_CAMERAS") \
  --policy.path=$POLICY --policy.device=$DEVICE $RM $INF \
  --display_data=true"
if [ "$EPS" = 0 ]; then
  run "$COMMON --strategy.type=base --task=$(q "$TASK") --duration=$ET"
else
  run "$COMMON --strategy.type=episodic \
  --teleop.type=$TELEOP_TYPE --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID \
  --dataset.repo_id=${DATASET_PREFIX}/rollout_${NAME} \
  --dataset.single_task=$(q "$TASK") \
  --dataset.num_episodes=$EPS --dataset.episode_time_s=$ET --dataset.reset_time_s=15 \
  --dataset.push_to_hub=false"
fi
