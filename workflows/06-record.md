# 06 — Record a dataset

You teleoperate; LeRobot stores joint state, action, and every camera at `fps` into
`~/.cache/huggingface/lerobot/<repo_id>` (episodes auto-saved as you go). With
`--dataset.push_to_hub=true` it also uploads at the end.

```bash
NAME=so100_medicament_box
TASK="Pick the medicament box and place it in the tray"     # no colons, no apostrophes

$RUN lerobot-record \
    --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
    --robot.cameras="$CAMERAS" \
    --teleop.type=$TELEOP_TYPE --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID \
    --display_data=true \
    --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
    --dataset.single_task="$TASK" \
    --dataset.num_episodes=50 \
    --dataset.episode_time_s=30 \
    --dataset.reset_time_s=10 \
    --dataset.push_to_hub=$PUSH_TO_HUB
```

Wrapper: `tools/record.sh <name> "<task>" [episodes] [episode_time_s] [reset_time_s]`.

Driving each episode: **→** end phase now, **←** discard and redo, **Esc** stop the session.
Details and per-OS caveats in [[12-recording-keys]]. `episode_time_s` is a safety cap, not a
target ([[episode-time-is-a-cap]]).

## Flags that matter

| Flag | Notes |
|---|---|
| `--dataset.repo_id` | Must look like `user/name`. `local/...` = never uploaded. `${HF_USER}/...` when pushing. |
| `--dataset.single_task` | Natural-language sentence; VLAs condition on it. **No `:` or `'`** — draccus parses `key: value` as a dict ([[single-task-no-colons]]). |
| `--dataset.num_episodes` | 50 minimum for a first policy; 100-300 to make it robust. |
| `--dataset.episode_time_s` | Cap; 30 s is fine for a single pick-and-place, 120 s for multi-step. |
| `--dataset.reset_time_s` | Pause to reset the scene; skippable with →. |
| `--dataset.push_to_hub` | `false` on the desktop today; `true` on the Mac (so HF Jobs can train). Add `--dataset.private=true` for a private repo. |
| `--resume=true` | Re-run the **same** command to append episodes up to `num_episodes`. Do not recalibrate in between. |

## Errors you will meet

- `FileExistsError`: the dataset folder already exists (often an empty scaffold from a crashed start).
  `rm -rf ~/.cache/huggingface/lerobot/<repo_id>` or use a new name ([[file-exists-error-on-record]]).
- `Incorrect status packet` right after the cameras connect: bus/power glitch ([[incorrect-status-packet]]).
- Camera fails to set fps/width: [[mjpg-required-for-30fps]], [[integer-index-not-dev-path]].

## What makes the data good

Read [[good-dataset-rules]] before recording 50 episodes you cannot reuse. Short version: fixed
scene and cameras, vary only the object pose, consistent smooth demonstrations, discard bad takes
with ←, keep the task single-step.

## Resumen (ES)

`lerobot-record` graba estado, acciones y cámaras en `~/.cache/huggingface/lerobot/<repo_id>`.
Flechas: → termina la fase, ← descarta el episodio, Esc termina. La tarea en lenguaje natural, sin
`:` ni `'`. En el escritorio `local/` (no sube); en la Mac `push_to_hub=true` para entrenar en HF.
