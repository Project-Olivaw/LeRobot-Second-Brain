#!/usr/bin/env python3
"""Print the --rename_map that maps a dataset's camera keys onto smolvla_base's camera1/2/3.

`lerobot/smolvla_base` was pretrained with its cameras named `observation.images.camera1..3`, and
lerobot >= 0.6 refuses to start when the dataset's visual keys differ (lessons/smolvla-rename-map.md).
Order: top -> camera1, wrist -> camera2, base -> camera3; any other key follows alphabetically.

Usage: python3 tools/rename_map.py <path to dataset meta/info.json>
"""

import json
import sys

ORDER = {"top": 0, "wrist": 1, "base": 2}


def main() -> int:
    info = json.load(open(sys.argv[1]))
    keys = [k for k in info["features"] if ".images." in k]
    if not keys:
        return 0  # state-only dataset: no map needed
    keys.sort(key=lambda k: (ORDER.get(k.rsplit(".", 1)[-1], 99), k))
    if len(keys) > 3:
        sys.exit(
            f"smolvla_base has 3 camera slots but the dataset has {len(keys)}: {keys}\n"
            "Drop one (tools/drop_camera.sh <src> <new> <key>) or set RENAME_MAP yourself."
        )
    print(json.dumps({k: f"observation.images.camera{i + 1}" for i, k in enumerate(keys)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
