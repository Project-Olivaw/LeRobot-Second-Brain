#!/usr/bin/env bash
# Usage: tools/teleop.sh [--no-cams]   (DRY=1 to print only)
set -e; source "$(dirname "$0")/_common.sh"
CAMS="--robot.cameras=$(q "$CAMERAS")"; [ "${1:-}" = "--no-cams" ] && CAMS=""
run "$RUN lerobot-teleoperate \
  --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID $CAMS \
  --teleop.type=$TELEOP_TYPE --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID \
  --display_data=true"
