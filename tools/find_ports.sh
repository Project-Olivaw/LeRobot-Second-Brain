#!/usr/bin/env bash
# Identify BOTH arms' ports in one sitting and print the lines to paste into machines/<machine>.env.
# `lerobot-find-port` only ever handles one bus per run (it diffs the port list across one unplug),
# so it has to be run twice — that is why a single run looks like it only configured one arm.
# Usage: tools/find_ports.sh
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"
banner() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
capture() {  # $1 = human label -> echoes the detected port
  banner "$1"
  echo "Have BOTH arms plugged in, then follow the prompt: unplug ONLY the $1 when asked."
  out=$($RUN lerobot-find-port 2>&1 | tee /dev/tty)
  echo "$out" | sed -n "s/.*port of this MotorsBus is '\([^']*\)'.*/\1/p" | tail -1
}
FOLLOWER=$(capture "FOLLOWER arm (the one that holds the gripper)")
echo; read -r -p "Plug the follower back in, then press Enter for the leader..." _
LEADER=$(capture "LEADER arm (the one you move by hand)")
banner "Result"
[ -n "$FOLLOWER" ] && [ -n "$LEADER" ] || { echo "could not parse one of the ports — scroll up and read them manually" >&2; exit 1; }
[ "$FOLLOWER" = "$LEADER" ] && { echo "both runs reported $FOLLOWER — you probably unplugged the same arm twice" >&2; exit 1; }
cat <<OUT
Paste these into machines/$MACHINE.env and commit:

export ROBOT_PORT=$FOLLOWER
export TELEOP_PORT=$LEADER

Then: source tools/env.sh $MACHINE && tools/teleop.sh
OUT
