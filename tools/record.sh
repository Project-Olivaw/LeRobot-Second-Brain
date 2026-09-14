#!/usr/bin/env bash
# Usage: tools/record.sh <name> "<task sentence>" [episodes=50] [episode_time_s=30] [reset_time_s=10]
# Env: RESUME=1 to append to an existing dataset. DRY=1 to print only.
# lerobot >= 0.6 appends a _YYYYmmdd_HHMMSS stamp to repo_id unless --dataset.no_stamp=true (lessons/record-stamps-repo-id.md).
set -e; source "$(dirname "$0")/_common.sh"
NAME=${1:?name}; TASK=${2:?task}; EPS=${3:-50}; ET=${4:-30}; RT=${5:-10}
case "$TASK" in *:*|*\'*) echo "task string must not contain ':' or \"'\" (lessons/single-task-no-colons.md)" >&2; exit 1;; esac
RES=""; [ "${RESUME:-0}" = 1 ] && RES="--resume=true"
run "$RUN lerobot-record \
  --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
  --robot.cameras=$(q "$CAMERAS") \
  --teleop.type=$TELEOP_TYPE --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID \
  --display_data=true \
  --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
  --dataset.single_task=$(q "$TASK") \
  --dataset.num_episodes=$EPS --dataset.episode_time_s=$ET --dataset.reset_time_s=$RT \
  --dataset.push_to_hub=$PUSH_TO_HUB --dataset.no_stamp=true $RES"
