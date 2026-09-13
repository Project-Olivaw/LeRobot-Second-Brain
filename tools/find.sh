#!/usr/bin/env bash
# Identify arm ports and camera indices. Then update machines/$MACHINE.env.
set -e; source "$(dirname "$0")/_common.sh"
run "$RUN lerobot-find-port"
run "$RUN lerobot-find-cameras opencv"
echo "Camera frames saved to outputs/captured_images/ — map them to top/wrist/base in machines/$MACHINE.env"
