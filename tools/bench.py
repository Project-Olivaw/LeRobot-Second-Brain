#!/usr/bin/env python
"""Phase 0 diagnostic: measure the teleoperation loop before trusting any dataset.

Everything downstream — every episode you record, every policy you train — inherits the
quality of this loop. Run it before recording, and again any time you move a camera or
swap a cable.

Reports over a fixed run:
  * achieved loop rate vs target (are you really at 30 Hz?)
  * per-joint tracking error: leader command vs follower measured position
  * per-stage latency: leader read / action write / observation read
  * per-camera read time AND duplicate-frame rate

The duplicate-frame check is the important one. A saturated USB bus does not error out:
the driver hands back the previous buffer again. The recording looks fine and the dataset
is quietly full of repeated frames, which teaches a policy that nothing ever moves.

Usage:
  python hardware/bench.py \
      --leader-port /dev/ttyACM0 --leader-id my_leader \
      --follower-port /dev/ttyACM1 --follower-id my_follower \
      --cameras "wrist=0,base=2,top=4" \
      --seconds 60
"""

from __future__ import annotations

import argparse
import time
from collections import defaultdict

import numpy as np

from lerobot.cameras.opencv import OpenCVCameraConfig
from lerobot.robots.so_follower import SO100Follower, SO100FollowerConfig
from lerobot.teleoperators.so_leader import SO100Leader, SO100LeaderConfig


def parse_cameras(spec: str, fps: int, width: int, height: int, fourcc: str):
    """Turn "wrist=0,base=/dev/video2" into a dict of camera configs."""
    cams = {}
    for item in filter(None, (s.strip() for s in spec.split(","))):
        name, _, idx = item.partition("=")
        cams[name] = OpenCVCameraConfig(
            index_or_path=int(idx) if idx.isdigit() else idx,
            fps=fps,
            width=width,
            height=height,
            fourcc=fourcc,
        )
    return cams


def frame_signature(frame) -> int:
    """Cheap fingerprint of a frame, for spotting repeated buffers."""
    return hash(np.ascontiguousarray(frame[::16, ::16]).tobytes())


def pct(values, p):
    return float(np.percentile(values, p)) if len(values) else float("nan")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--leader-port", required=True)
    ap.add_argument("--follower-port", required=True)
    ap.add_argument("--leader-id", default="so100_leader")
    ap.add_argument("--follower-id", default="so100_follower")
    ap.add_argument("--cameras", default="", help='e.g. "wrist=0,base=2,top=4"')
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--width", type=int, default=640)
    ap.add_argument("--height", type=int, default=480)
    ap.add_argument("--fourcc", default="MJPG", help="MJPG keeps USB bandwidth down; YUYV is raw")
    ap.add_argument("--seconds", type=float, default=60.0)
    args = ap.parse_args()

    cameras = parse_cameras(args.cameras, args.fps, args.width, args.height, args.fourcc)

    follower = SO100Follower(
        SO100FollowerConfig(port=args.follower_port, id=args.follower_id, cameras=cameras)
    )
    leader = SO100Leader(SO100LeaderConfig(port=args.leader_port, id=args.leader_id))

    print(f"connecting… follower={args.follower_port} leader={args.leader_port} cameras={list(cameras)}")
    follower.connect()
    leader.connect()

    period = 1.0 / args.fps
    deadline = time.perf_counter() + args.seconds

    loop_dt, t_lead, t_send, t_obs = [], [], [], []
    joint_err = defaultdict(list)
    cam_dt = defaultdict(list)
    cam_dup = defaultdict(int)
    cam_n = defaultdict(int)
    last_sig = {}
    overruns = 0

    print(f"running {args.seconds:.0f}s at {args.fps} Hz — move the leader arm through its full range\n")
    prev = time.perf_counter()
    try:
        while time.perf_counter() < deadline:
            t0 = time.perf_counter()

            a = time.perf_counter()
            action = leader.get_action()
            t_lead.append(time.perf_counter() - a)

            a = time.perf_counter()
            sent = follower.send_action(action)
            t_send.append(time.perf_counter() - a)

            a = time.perf_counter()
            obs = follower.get_observation()
            t_obs.append(time.perf_counter() - a)

            # Tracking error: what we asked for vs where the arm actually is.
            for k, commanded in sent.items():
                if k.endswith(".pos") and k in obs:
                    joint_err[k.removesuffix(".pos")].append(abs(commanded - obs[k]))

            for name in cameras:
                frame = obs.get(name)
                if frame is None:
                    continue
                cam_n[name] += 1
                sig = frame_signature(frame)
                if last_sig.get(name) == sig:
                    cam_dup[name] += 1
                last_sig[name] = sig

            now = time.perf_counter()
            loop_dt.append(now - prev)
            prev = now

            sleep = period - (now - t0)
            if sleep > 0:
                time.sleep(sleep)
            else:
                overruns += 1
    except KeyboardInterrupt:
        print("\ninterrupted — reporting on what we have")
    finally:
        follower.disconnect()
        leader.disconnect()

    # ---------------- report ----------------
    dt = np.array(loop_dt[1:])  # drop first, it includes startup
    print("\n" + "=" * 62)
    print("LOOP TIMING")
    print("=" * 62)
    print(f"  target            {args.fps} Hz  ({period*1e3:.1f} ms)")
    print(f"  achieved (median) {1/np.median(dt):.1f} Hz  ({np.median(dt)*1e3:.1f} ms)")
    print(f"  p95 period        {pct(dt,95)*1e3:.1f} ms")
    print(f"  worst period      {dt.max()*1e3:.1f} ms")
    print(f"  overruns          {overruns}/{len(dt)}  ({100*overruns/max(len(dt),1):.1f}%)")

    print("\nSTAGE LATENCY (median / p95, ms)")
    for label, arr in (("leader read", t_lead), ("send action", t_send), ("read obs ", t_obs)):
        a = np.array(arr)
        print(f"  {label}   {np.median(a)*1e3:6.1f} / {pct(a,95)*1e3:6.1f}")

    print("\nTRACKING ERROR — leader command vs follower position (degrees)")
    for joint, errs in joint_err.items():
        e = np.array(errs)
        flag = "  <-- HIGH" if np.median(e) > 5 else ""
        print(f"  {joint:<16} median {np.median(e):5.2f}   p95 {pct(e,95):5.2f}   max {e.max():5.2f}{flag}")

    if cameras:
        print("\nCAMERAS")
        for name in cameras:
            n, dup = cam_n[name], cam_dup[name]
            rate = 100 * dup / max(n, 1)
            flag = "  <-- STALLING" if rate > 5 else ""
            print(f"  {name:<10} frames {n:5d}   duplicates {dup:5d} ({rate:4.1f}%){flag}")

    print("\n" + "=" * 62)
    print("GATE: proceed only if achieved rate is within 10% of target,")
    print("      every joint's median error is < 5 deg, and no camera")
    print("      shows a duplicate rate above ~5%.")
    print("=" * 62)


if __name__ == "__main__":
    main()
