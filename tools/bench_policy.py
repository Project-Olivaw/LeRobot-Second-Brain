#!/usr/bin/env python
"""Measure how fast a trained policy can actually drive the arm, on THIS machine.

Why this matters: a chunked policy (ACT, SmolVLA, pi0) is not uniformly slow — it is *bursty*.
It recomputes a whole chunk of `n_action_steps` actions, then replays them from a queue for
free. So the number that decides whether the arm stutters on stage is not the average, it is
the **recompute cost** versus the control period (33 ms at 30 Hz).

Run it before trusting a machine with a live demo. No robot and no cameras needed — frames are
synthetic; only the compute path is measured.

Usage:
  uv run python tools/bench_policy.py <policy_path_or_hub_id> [device]     # device: cuda|mps|cpu

Reading the result:
  recompute << 33 ms          -> smooth, nothing to do
  recompute up to ~1/3 chunk  -> visible but fine; add --inference.type=rtc (RTC=1 in tools/*.sh)
  recompute > chunk duration  -> the arm will freeze between chunks; use a smaller policy (ACT)
"""

import json
import sys
import time
from pathlib import Path

import numpy as np
import torch

from lerobot.configs.policies import PreTrainedConfig
from lerobot.policies.factory import get_policy_class, make_pre_post_processors

CONTROL_HZ = 30
ITERS = 160


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    device = sys.argv[2] if len(sys.argv) > 2 else ("cuda" if torch.cuda.is_available() else "cpu")

    cfg = PreTrainedConfig.from_pretrained(path)
    cfg.device = device
    policy = get_policy_class(cfg.type).from_pretrained(path, config=cfg).to(device).eval()
    preprocessor, _ = make_pre_post_processors(cfg, pretrained_path=path)

    # Hub ids are cached locally by from_pretrained; read the same config.json for the feature list.
    meta_path = Path(path) / "config.json"
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    image_keys = [k for k in meta.get("input_features", {}) if "image" in k]
    if not image_keys:  # fall back to the loaded config
        image_keys = [k for k in cfg.input_features if "image" in k]
    n_action_steps = meta.get("n_action_steps") or getattr(cfg, "n_action_steps", 1)

    obs = {k: torch.rand(1, 3, 480, 640, device=device) for k in image_keys}
    obs["observation.state"] = torch.zeros(1, 6, device=device)
    obs["task"] = "benchmark instruction"

    latencies_ms = []
    with torch.no_grad():
        for _ in range(ITERS):
            start = time.perf_counter()
            policy.select_action(preprocessor(dict(obs)))
            if device == "cuda":
                torch.cuda.synchronize()
            latencies_ms.append((time.perf_counter() - start) * 1000)

    # A recompute happens on call 0, n_action_steps, 2*n_action_steps, ... — split by position, not by
    # magnitude, so the classification holds on a fast GPU where a recompute is only a few ms.
    # The first call also pays lazy-init/compile costs, so it is reported separately.
    budget_ms = 1000 / CONTROL_HZ
    recomputes = [ms for i, ms in enumerate(latencies_ms) if i > 0 and i % n_action_steps == 0]
    cached = [ms for i, ms in enumerate(latencies_ms) if i > 0 and i % n_action_steps != 0]

    print(f"policy={cfg.type}  device={device}  cameras={len(image_keys)}  n_action_steps={n_action_steps}")
    print(f"  warmup (first call)   {latencies_ms[0]:7.0f} ms")
    if recomputes:
        print(f"  chunk recompute       {np.median(recomputes):7.0f} ms median   {max(recomputes):.0f} ms max   (n={len(recomputes)})")
    else:
        print("  chunk recompute          (none seen — every call was cheap)")
    if cached:
        print(f"  cached step           {np.median(cached):7.1f} ms median")
    chunk_seconds = n_action_steps / CONTROL_HZ
    print(f"  control budget        {budget_ms:7.1f} ms/step at {CONTROL_HZ} Hz; a recompute happens every {chunk_seconds:.1f} s")
    if recomputes:
        stalled_steps = max(recomputes) / budget_ms
        print(f"  -> each recompute stalls ~{stalled_steps:.0f} control steps ({max(recomputes) / 1000:.2f} s)")
        if max(recomputes) > chunk_seconds * 1000:
            print("  -> VERDICT: too slow — the arm freezes between chunks on this machine. Use ACT here.")
        elif stalled_steps > 3:
            print("  -> VERDICT: usable, but add --inference.type=rtc (RTC=1 in tools/eval.sh, tools/demo.sh).")
        else:
            print("  -> VERDICT: smooth.")


if __name__ == "__main__":
    main()
