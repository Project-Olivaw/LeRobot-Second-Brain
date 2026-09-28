#!/usr/bin/env python
"""Upload a local LeRobotDataset to the Hub under a different repo id.

`LeRobotDataset.push_to_hub()` has no `repo_id` parameter — it uploads to `self.repo_id`. A dataset
recorded as `local/<name>` therefore tries to create a repo in the namespace "local" and fails with
403. Re-pointing both the dataset and its metadata first is what makes the upload land in your
namespace, with a proper dataset card and version tag.

Usage: uv run python tools/push_dataset.py <local/name> <user/name> [private=true]
"""

import sys

from lerobot.datasets.lerobot_dataset import LeRobotDataset


def main() -> None:
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    local_id, remote_id = sys.argv[1], sys.argv[2]
    private = (sys.argv[3].lower() if len(sys.argv) > 3 else "true") in ("1", "true", "yes")

    dataset = LeRobotDataset(local_id)
    print(f"{local_id}: {dataset.meta.total_episodes} episodes, {dataset.meta.total_frames} frames", flush=True)

    dataset.repo_id = remote_id
    dataset.meta.repo_id = remote_id
    # upload_large_folder resumes on failure — robot datasets are mostly large video files.
    dataset.push_to_hub(private=private, tags=["so100", "lerobot"], upload_large_folder=True)
    print(f"pushed -> https://huggingface.co/datasets/{remote_id}")


if __name__ == "__main__":
    main()
