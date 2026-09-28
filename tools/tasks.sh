#!/usr/bin/env bash
# Show the instructions stored in a dataset and how many episodes carry each one.
# A multi-task VLA dataset must be BALANCED — see lessons/balance-the-instructions.md.
# Usage: tools/tasks.sh <dataset_name>
set -euo pipefail; source "$(dirname "$0")/_common.sh"; cd "$LEROBOT_DIR"   # $RUN=uv run needs the project dir
NAME=${1:?dataset name}
ROOT="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}/${DATASET_PREFIX}/${NAME}"
[ -d "$ROOT" ] || { echo "not found: $ROOT" >&2; exit 1; }
$RUN python - "$ROOT" <<'PY'
import json, sys
from pathlib import Path
import pandas as pd
root = Path(sys.argv[1])
info = json.loads((root / "meta" / "info.json").read_text())
print(f"{root.name}: {info['total_episodes']} episodes, {info['total_frames']} frames, "
      f"{info['total_tasks']} task(s), {info['fps']} fps")
print("cameras:", [k.split('.')[-1] for k in info["features"] if "image" in k])
eps = pd.concat([pd.read_parquet(p) for p in sorted((root / "meta" / "episodes").rglob("*.parquet"))])
col = "tasks" if "tasks" in eps.columns else ("task" if "task" in eps.columns else None)
if col is None:
    print("(no per-episode task column in this dataset version)"); raise SystemExit
counts = eps[col].explode().value_counts()
width = max(len(str(t)) for t in counts.index)
for task, n in counts.items():
    print(f"  {str(task):<{width}}  {n:>4} episodes  {n / info['total_episodes'] * 100:5.1f}%")
PY
