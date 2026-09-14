#!/usr/bin/env bash
# Usage: tools/eta.sh <train.log> [total_steps]   — ETA from the last `updt_s` line (lessons/updt-s-is-your-timer.md)
# Reads the log written by tools/overnight_medicament_box.sh (or any lerobot-train output piped through tee).
set -euo pipefail
LOG=${1:?log file}; TOTAL=${2:-}
python3 - "$LOG" "$TOTAL" <<'PY'
import re, sys, datetime as dt
log, total = sys.argv[1], sys.argv[2]
line = None
for l in open(log, errors="ignore"):
    if "updt_s:" in l and "step:" in l:
        line = l
if not line:
    sys.exit("no `step: ... updt_s:` line yet — the first one appears after log_freq steps")
def num(s):  # "1K" -> 1000, "500" -> 500, "1.2M" -> 1200000
    m = re.fullmatch(r"([\d.]+)([KMB]?)", s); return float(m[1]) * {"": 1, "K": 1e3, "M": 1e6, "B": 1e9}[m[2]]
step  = int(num(re.search(r"step:(\S+)", line)[1]))
updt  = float(re.search(r"updt_s:([\d.]+)", line)[1])
data  = float((re.search(r"data_s:([\d.]+)", line) or [0, "0"])[1])
loss  = re.search(r"loss:(\S+)", line); loss = loss[1] if loss else "?"
print(f"step {step}  loss {loss}  updt_s {updt:.3f}  data_s {data:.3f}  ({3600/updt:.0f} steps/h)")
if total:
    left = (int(total) - step) * updt
    print(f"remaining {left/3600:.1f} h  -> ETA {(dt.datetime.now() + dt.timedelta(seconds=left)).strftime('%a %H:%M')}")
if data > 0.2 * updt:
    print("dataloader-bound (data_s is large): raise num_workers or check the disk")
PY
