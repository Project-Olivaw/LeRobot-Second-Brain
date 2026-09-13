#!/usr/bin/env bash
# Usage: tools/eval.sh <dataset_name> <policy_path_or_hub_id> [episodes=10] ["task sentence"] [episode_time_s=30]
# Runs the policy on the follower and records into <prefix>/eval_<name>_<timestamp>. DRY=1 to print only.
set -e; source "$(dirname "$0")/_common.sh"
NAME=${1:?dataset name}; POLICY=${2:?policy path}; EPS=${3:-10}; TASK=${4:-}; ET=${5:-30}
EVAL=eval_${NAME}_$(date +%Y%m%d_%H%M)
if [ -z "$TASK" ]; then
  META="$HOME/.cache/huggingface/lerobot/${DATASET_PREFIX}/${NAME}/meta/tasks.jsonl"
  [ -f "$META" ] && TASK=$(python3 -c "import json,sys; print(json.loads(open(sys.argv[1]).readline())['task'])" "$META" 2>/dev/null || true)
  [ -n "$TASK" ] || TASK="Do the task"
fi
run "$RUN lerobot-record \
  --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
  --robot.cameras=$(q "$CAMERAS") \
  --display_data=true \
  --dataset.repo_id=${DATASET_PREFIX}/${EVAL} \
  --dataset.single_task=$(q "$TASK") \
  --dataset.num_episodes=$EPS --dataset.episode_time_s=$ET --dataset.reset_time_s=10 \
  --dataset.push_to_hub=false \
  --policy.path=$POLICY"
