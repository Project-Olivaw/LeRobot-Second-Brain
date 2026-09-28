#!/usr/bin/env python
"""Tell which serial port is the leader and which is the follower — without moving anything.

Why this exists: `lerobot-find-port` tells you that *a* port exists, not *which arm* is on it, and
the first teleop with the two swapped disables torque on the follower (it flops under gravity) while
commanding the leader. This reads each arm's stored `Homing_Offset` — written into the motors by
`lerobot-calibrate` and different for the two arms — and matches it against the calibration JSONs in
`assets/calibration/`. Opening the bus only pings the motors; no torque register is touched.

Usage:
    source tools/env.sh macbook           # or desktop
    uv run python tools/identify_arms.py                       # checks $ROBOT_PORT and $TELEOP_PORT
    uv run python tools/identify_arms.py /dev/tty.usbmodemA /dev/tty.usbmodemB

Exit code 0 = the profile's ROBOT_PORT/TELEOP_PORT match the hardware; 1 = swapped or undecidable.
"""

import json
import os
import sys
from pathlib import Path

from lerobot.motors import Motor, MotorNormMode
from lerobot.motors.feetech import FeetechMotorsBus

VAULT = Path(__file__).resolve().parent.parent
CALIB = {
    "follower": VAULT / "assets/calibration/robots__so_follower__my_awesome_follower_arm.json",
    "leader": VAULT / "assets/calibration/teleoperators__so_leader__my_awesome_leader_arm.json",
}
MOTORS = {
    "shoulder_pan": Motor(1, "sts3215", MotorNormMode.RANGE_M100_100),
    "shoulder_lift": Motor(2, "sts3215", MotorNormMode.RANGE_M100_100),
    "elbow_flex": Motor(3, "sts3215", MotorNormMode.RANGE_M100_100),
    "wrist_flex": Motor(4, "sts3215", MotorNormMode.RANGE_M100_100),
    "wrist_roll": Motor(5, "sts3215", MotorNormMode.RANGE_M100_100),
    "gripper": Motor(6, "sts3215", MotorNormMode.RANGE_0_100),
}


def expected_offsets() -> dict[str, dict[str, int]]:
    out = {}
    for role, path in CALIB.items():
        if not path.exists():
            sys.exit(f"missing calibration file: {path}")
        out[role] = {k: v["homing_offset"] for k, v in json.loads(path.read_text()).items()}
    return out


def read_offsets(port: str) -> dict[str, int]:
    """Open the bus read-only and return the homing offset stored in each motor."""
    bus = FeetechMotorsBus(port=port, motors=MOTORS)
    bus.connect(handshake=True)  # opens the port and pings; does not write torque
    try:
        return bus.sync_read("Homing_Offset", normalize=False)
    finally:
        bus.disconnect()


def score(actual: dict[str, int], expected: dict[str, int]) -> int:
    return sum(1 for name, value in actual.items() if expected.get(name) == value)


def classify(port: str, expected: dict[str, dict[str, int]]) -> tuple[str, dict[str, int]]:
    actual = read_offsets(port)
    scores = {role: score(actual, exp) for role, exp in expected.items()}
    best = max(scores, key=scores.get)
    others = [s for role, s in scores.items() if role != best]
    verdict = best if scores[best] >= 4 and scores[best] > max(others) else "unknown"
    return verdict, scores


def main() -> int:
    args = sys.argv[1:]
    if args:
        ports = {"(arg 1)": args[0], "(arg 2)": args[1]} if len(args) == 2 else {"(arg 1)": args[0]}
    else:
        ports = {"ROBOT_PORT": os.environ.get("ROBOT_PORT"), "TELEOP_PORT": os.environ.get("TELEOP_PORT")}
        if not all(ports.values()):
            sys.exit("ROBOT_PORT / TELEOP_PORT not set — run: source tools/env.sh <machine>")

    expected = expected_offsets()
    results = {}
    for label, port in ports.items():
        try:
            verdict, scores = classify(port, expected)
        except Exception as exc:  # noqa: BLE001 - surface the cable/port problem verbatim
            print(f"{label:12} {port}\n             ERROR: {exc}")
            return 1
        results[label] = verdict
        detail = "  ".join(f"{role}={s}/6" for role, s in scores.items())
        print(f"{label:12} {port}  ->  {verdict.upper():9} (matching offsets: {detail})")

    if "unknown" in results.values():
        print(
            "\nCould not identify an arm from its stored homing offsets. Either it was calibrated\n"
            "after assets/calibration/ was last updated, or it is a different physical arm.\n"
            "Re-run workflows/03-calibrate.md, or identify by unplugging: tools/find_ports.sh"
        )
        return 1

    if len(results) == 2:
        want = {"ROBOT_PORT": "follower", "TELEOP_PORT": "leader"}
        if all(k in want for k in results):
            if all(results[k] == want[k] for k in results):
                print("\nOK — the profile matches the hardware. Safe to run tools/teleop.sh")
                return 0
            print(
                "\nSWAPPED — ROBOT_PORT must be the follower and TELEOP_PORT the leader.\n"
                "Exchange the two port values in machines/$MACHINE.env before teleoperating:\n"
                "running it swapped disables torque on the follower and it will drop."
            )
            return 1
        roles = set(results.values())
        if len(roles) == 1:
            print("\nBoth ports report the same arm — check you passed two different ports.")
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
