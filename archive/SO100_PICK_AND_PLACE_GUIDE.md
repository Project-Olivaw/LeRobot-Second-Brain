# SO100 Pick-and-Place Guide (with overhead camera)

End-to-end recipe to teach an SO100 arm to **pick a Lego skeleton and place it in a bin**,
using a leader arm for teleoperation and one overhead ("cenital") USB camera for vision.
(The steps are generic pick-and-place — swap the task string and dataset name for any object.)

Every command is shown in **two variants**:

- **Local only** — nothing is uploaded; dataset and model stay on this machine.
- **With Hugging Face Hub** — dataset and model are also pushed to your HF account.

No step here uploads anything unless you explicitly use the Hub variant.

---

## Your hardware (used throughout this guide)

| Thing            | Value                                  |
|------------------|----------------------------------------|
| Follower arm     | `so100_follower` on `/dev/ttyACM1`     |
| Follower id      | `my_awesome_follower_arm`              |
| Leader arm       | `so100_leader` on `/dev/ttyACM0`       |
| Leader id        | `my_awesome_leader_arm`               |
| Overhead camera  | USB webcam (OpenCV) — index found below|
| Camera key       | `top` (the name stored in the dataset) |

The `id` must stay identical across calibrate / teleoperate / record / eval — it is how the
calibration file is located. You already calibrated both arms, so that part is done.

> Ports can change across reboots/replugs. If a command says it cannot open `/dev/ttyACM1`,
> re-check with `lerobot-find-port` and swap the port in the command.

---

## 0. One-time prerequisites

Run commands with `uv run` so they use the project's virtual environment.

### Hugging Face login (only needed for the Hub variants)

```bash
hf auth login --token ${HUGGINGFACE_TOKEN} --add-to-git-credential
```

Get your username into a variable. NOTE: newer `hf` CLI (v1.19+) prints `user=<name>`,
so the parser below differs from the official docs (which assume the old format):

```bash
HF_USER=$(uv run hf auth whoami 2>/dev/null | sed -n 's/^user=//p')
echo "$HF_USER"     # should print your username, e.g. Youngermaster
```

The git-credential warning during login is harmless — your token is saved to
`~/.cache/huggingface/token`, which is what the API and LeRobot actually use.

### (Optional) Weights & Biases for training charts

```bash
uv run wandb login        # only if you set --wandb.enable=true later
```

---

## 1. Find the overhead camera index

The USB camera is referenced by an index (0, 1, 2, ...). List what's connected:

```bash
uv run lerobot-find-cameras opencv
```

This prints each detected camera with its `index_or_path`, default resolution and FPS,
and saves a sample image to `outputs/captured_images/` so you can confirm which one is the
overhead view.

**Confirmed on this machine:** the overhead camera is `/dev/video0` (index `0`), so every
command below already uses `index_or_path: 0` and is copy-paste ready. `0` and `/dev/video0`
are equivalent; if you ever plug in more cameras and the numbering shifts, prefer the explicit
`/dev/video0` path since it is more stable than the bare index.

> Note: `lerobot-find-cameras` probed this camera at its default mode (1920x1080 @ 5fps). The
> commands below request **640x480 @ 30fps**, which is the right mode for recording — webcams
> expose a different (higher) FPS at lower resolution. The `ioctl(VIDIOC_QBUF): Bad file
> descriptor` lines in the probe output are harmless.

> **Important — `fourcc: MJPG` is required on this camera.** LeRobot demands the camera deliver
> the exact FPS requested. In its default uncompressed (YUYV) format this webcam only reaches
> 20 fps at 640x480, so asking for 30 fps fails with:
> `RuntimeError: OpenCVCamera(0) failed to set fps=30 (actual_fps=20.0)`.
> MJPG is a compressed format, so the same USB bandwidth carries 30 fps. That is why every
> camera block in this guide includes `fourcc: MJPG`. The camera format is applied before FPS
> precisely because it determines which frame rates are available.

> **Fallback if MJPG still can't hit 30 fps:** set `fps: 20` instead, but then you must use
> `20` *everywhere* — the camera block, recording, and training all share one FPS, so your
> dataset and the policy's control rate would become 20 Hz. Try MJPG @ 30 first; it almost
> always works at 640x480.

> Unrelated: the `rerun`/Vulkan/EGL warnings (`No config found`, `EGL says it can present...`)
> printed when `--display_data=true` is set are harmless. If teleop crashes, read past them —
> the real error (like the FPS one above) is in the Python traceback.

---

## 2. Teleoperate with the camera (sanity check)

Confirm both arms move together and the camera feed looks right before recording.
`--display_data=true` opens a `rerun` window with the camera feed and joint positions.

```bash
uv run lerobot-teleoperate \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --teleop.type=so100_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true
```

When the follower mirrors the leader and the overhead feed is correct, stop with `Ctrl+C`.

---

## 3. Record the dataset (50 episodes)

You teleoperate the task; LeRobot records joint actions/states **and** the overhead camera
into a dataset. Each episode = one full demonstration of putting the Lego skeleton in the bin.
Every episode is **auto-saved** to `~/.cache/huggingface/lerobot/<repo_id>` as you go.

### How an episode actually works (you drive it with the arrow keys)

Recording is a loop. For each episode there are two phases, and **you** decide when each
ends — you do not have to wait out the timers.

| Key            | What it does                                                            |
|----------------|-------------------------------------------------------------------------|
| **Right arrow →** | End the current phase **immediately** and move on                    |
| **Left arrow ←**  | **Discard** the current episode and **re-record** it                 |
| **Escape**        | **Stop** the whole session (everything saved so far is kept)         |

The flow of one episode:

1. **Record phase** — teleoperate the pick-and-place. It ends when `episode_time_s` (60s) is
   reached **OR**, more usually, the instant you press **Right arrow** after dropping the
   skeleton in the bin.
2. **Reset phase** — `reset_time_s` (10s) to reposition the skeleton for the next take. Also
   skippable with **Right arrow**.
3. The episode is auto-saved, the counter advances, and the next one begins. Repeat to 50.

Answering the common questions:

- **"How do I finish an episode / move to the next one?"** Press **Right arrow** the moment the
  skeleton lands in the bin. There is no confirm step — Right arrow ends it and advances.
- **"What if I finish in 15s instead of 60?"** `episode_time_s=60` is only a safety **cap**, not
  a target. Finish early, press **Right arrow**. You will end most episodes this way; the 60s
  only matters if you forget to press it.
- **"What if I botch a grasp?"** Press **Left arrow** to throw out that take and redo it — keep
  bad demos out of the dataset.
- **"Done before 50?"** Press **Escape**; all saved episodes are kept.

> Keyboard note: on **X11** (your setup) the arrow keys are captured globally, so they work even
> with the rerun window focused. If a press seems ignored, click the **terminal** to focus it.
> On Wayland/headless, LeRobot falls back to a terminal listener that requires the terminal to
> be focused.

### Timing flags

- `--dataset.episode_time_s` — max seconds per episode before it auto-advances (safety cap).
- `--dataset.reset_time_s` — pause between episodes to reposition the skeleton.

Tip for a good dataset: vary the skeleton's starting position (and lighting) across the 50
episodes so the policy generalizes instead of memorizing one spot.

### 3a. Local only (no upload)

The dataset is written to `~/.cache/huggingface/lerobot/<repo_id>`. The `repo_id` still needs
a `user/name` shape, but with `push_to_hub=false` nothing leaves your machine. Use any prefix
(here `local`):

```bash
uv run lerobot-record \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --teleop.type=so100_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true \
    --dataset.repo_id=local/so100_lego_skeleton \
    --dataset.num_episodes=50 \
    --dataset.single_task="Put the Lego skeleton in the bin" \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=10 \
    --dataset.push_to_hub=false
```

### 3b. With Hugging Face Hub (also uploads)

```bash
uv run lerobot-record \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --teleop.type=so100_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true \
    --dataset.repo_id=${HF_USER}/so100_lego_skeleton \
    --dataset.num_episodes=50 \
    --dataset.single_task="Put the Lego skeleton in the bin" \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=10 \
    --dataset.push_to_hub=true
```

Add `--dataset.private=true` if you want the uploaded dataset to be private.

> Resume an interrupted recording by re-running the same command with
> `--resume=true` (it appends episodes to the existing dataset until it reaches 50).

---

## 4. (Optional) Inspect / replay the dataset

Visualize what you recorded:

```bash
uv run lerobot-dataset-viz --repo-id=local/so100_lego_skeleton      # local
# or: --repo-id=${HF_USER}/so100_lego_skeleton                       # hub
```

Replay one recorded episode on the follower (no leader needed) to verify the data:

```bash
uv run lerobot-replay \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --dataset.repo_id=local/so100_lego_skeleton \
    --dataset.episode=0
```

---

## 5. Train the policy (ACT)

ACT is the standard imitation-learning policy for this task. It auto-adapts to your motor
count and to the `top` camera stored in the dataset. Checkpoints land in
`outputs/train/<job_name>/checkpoints/`. Training typically takes a few hours on GPU.

You have an NVIDIA GPU (RTX 5060 Ti), so use `--policy.device=cuda` (use `cpu` only as a slow
fallback).

### Training time and the three speed profiles (this machine)

What controls speed (there is **no mixed-precision / AMP** in the trainer — it runs in fp32):

- `--steps` — number of gradient updates. **Wall-clock is roughly linear in this.**
- `--batch_size` — bigger = more GPU and VRAM used per step (fuller GPU), but each step is
  slower. Default `8` is the validated value for ACT.
- `--num_workers` — dataloader processes. More keeps the GPU fed so it never stalls on data.

The trainer prints `updt_s` (seconds per step) and `smp/s` (samples per second) each log line.
**This is your real timer.** After ~1 minute, read `updt_s` and compute how many steps fit a
time budget: `steps = budget_seconds / updt_s` (e.g. 1 hour = `3600 / updt_s`). Use it to
fine-tune `--steps` to your actual measured speed.

| Profile | steps | batch | workers | Est. time | When to use |
|---------|-------|-------|---------|-----------|-------------|
| **Fast** | 20000 | 8 | 8 | ~50-75 min | Tonight's run; a usable first policy |
| **Default** | 100000 | 8 | 4 | ~4-6 h | The validated baseline |
| **Max quality** | 80000 | 16 | 8 | ~5-6 h | Best result, fullest GPU use |

Notes on the trade-offs:

- **Fast** keeps the validated `batch=8` and just trims steps, because for ACT *more gradient
  steps* matters more for quality than a bigger batch. `workers=8` keeps the GPU fed so those
  20k steps run as fast as possible. This is the one that fits your ~1-1:15h night budget.
- **Max quality** raises `batch=16`. Each step sees 2x the data, so 80k steps here = **1.28M
  samples** seen vs the default's 0.8M — more total learning, and it uses more of the GPU
  (your "use the full setup" ask). 16 GB VRAM leaves comfortable headroom for VS Code + the
  desktop (your 5-10% offset), since fp32 ACT at batch 16 only needs a few GB. Want even more
  quality and don't mind ~8h? Push `--steps=100000`.
- **Using the full GPU** = batch size + keeping workers ahead. You can watch it live with
  `nvidia-smi -l 1` in another terminal. If GPU utilization sits below ~80%, the dataloader is
  the bottleneck — raise `--num_workers`. If it's pinned near 100% and the desktop feels
  sluggish, lower `--num_workers` to 6 (compute headroom), not the batch.
- If you ever hit a CUDA out-of-memory error, lower `--batch_size` (16 → 12 → 8).

All three profiles below are **local only**: no Hub upload, no W&B. Checkpoints are written to
`outputs/train/act_so100_lego_skeleton/checkpoints/` every `save_freq` steps, so you can stop
early and evaluate an intermediate checkpoint.

#### Fast (~1 hour)

```bash
uv run lerobot-train \
    --dataset.repo_id=local/so100_lego_skeleton \
    --policy.type=act \
    --output_dir=outputs/train/act_so100_lego_skeleton \
    --job_name=act_so100_lego_skeleton \
    --policy.device=cuda \
    --batch_size=8 \
    --num_workers=8 \
    --steps=20000 \
    --save_freq=5000 \
    --wandb.enable=false \
    --policy.push_to_hub=false
```

#### Max quality (~5-6 hours)

```bash
uv run lerobot-train \
    --dataset.repo_id=local/so100_lego_skeleton \
    --policy.type=act \
    --output_dir=outputs/train/act_so100_lego_skeleton \
    --job_name=act_so100_lego_skeleton \
    --policy.device=cuda \
    --batch_size=16 \
    --num_workers=8 \
    --steps=80000 \
    --save_freq=10000 \
    --wandb.enable=false \
    --policy.push_to_hub=false
```

> Heads up: all three write to the **same** `output_dir`. Training refuses to overwrite an
> existing run, so either delete `outputs/train/act_so100_lego_skeleton` between runs, or give
> each profile its own `--output_dir`/`--job_name` (e.g. `..._fast`, `..._max`).

### 5a. Local only (no upload, no W&B)

```bash
uv run lerobot-train \
    --dataset.repo_id=local/so100_lego_skeleton \
    --policy.type=act \
    --output_dir=outputs/train/act_so100_lego_skeleton \
    --job_name=act_so100_lego_skeleton \
    --policy.device=cuda \
    --wandb.enable=false \
    --policy.push_to_hub=false
```

### 5b. With Hugging Face Hub (uploads the trained policy)

```bash
uv run lerobot-train \
    --dataset.repo_id=${HF_USER}/so100_lego_skeleton \
    --policy.type=act \
    --output_dir=outputs/train/act_so100_lego_skeleton \
    --job_name=act_so100_lego_skeleton \
    --policy.device=cuda \
    --wandb.enable=true \
    --policy.push_to_hub=true \
    --policy.repo_id=${HF_USER}/act_so100_lego_skeleton
```

### Resume training from the last checkpoint

```bash
uv run lerobot-train \
    --config_path=outputs/train/act_so100_lego_skeleton/checkpoints/last/pretrained_model/train_config.json \
    --resume=true
```

### (Hub) Manually upload a checkpoint later

```bash
uv run hf upload ${HF_USER}/act_so100_lego_skeleton \
    outputs/train/act_so100_lego_skeleton/checkpoints/last/pretrained_model
```

---

## 6. Evaluate the trained policy

This is the same `lerobot-record` script, but the **policy** drives the arm instead of you.
The camera config must match recording: same overhead camera, same `top` key. Name the eval
dataset with an `eval_` prefix by convention.

`--policy.path` accepts a **local checkpoint folder** or a **Hub model id**.

### 6a. Local checkpoint, local eval dataset

```bash
uv run lerobot-record \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --display_data=true \
    --dataset.repo_id=local/eval_so100_lego_skeleton \
    --dataset.single_task="Put the Lego skeleton in the bin" \
    --dataset.num_episodes=10 \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=10 \
    --dataset.push_to_hub=false \
    --policy.path=outputs/train/act_so100_lego_skeleton/checkpoints/last/pretrained_model
```

### 6b. Hub model id, upload eval results

```bash
uv run lerobot-record \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --display_data=true \
    --dataset.repo_id=${HF_USER}/eval_so100_lego_skeleton \
    --dataset.single_task="Put the Lego skeleton in the bin" \
    --dataset.num_episodes=10 \
    --dataset.episode_time_s=60 \
    --dataset.reset_time_s=10 \
    --dataset.push_to_hub=true \
    --policy.path=${HF_USER}/act_so100_lego_skeleton
```

Note there is **no leader arm** in the eval command — the policy generates the actions.

---

## Quick reference: local vs Hub

| Stage     | Local-only flag(s)                 | Hub flag(s)                                            |
|-----------|------------------------------------|--------------------------------------------------------|
| Record    | `--dataset.push_to_hub=false`      | `--dataset.push_to_hub=true` (+ `HF_USER` repo_id)     |
| Train     | `--policy.push_to_hub=false`       | `--policy.push_to_hub=true --policy.repo_id=...`       |
| Eval      | `--policy.path=outputs/.../pretrained_model` | `--policy.path=${HF_USER}/act_so100_lego_skeleton` |

Everything is saved to disk in both modes:

- Datasets: `~/.cache/huggingface/lerobot/<repo_id>`
- Checkpoints: `outputs/train/act_so100_lego_skeleton/checkpoints/`

---

## Troubleshooting

- **Wrong / black camera:** re-run `uv run lerobot-find-cameras opencv` and fix the index.
- **`failed to set fps=30 (actual_fps=20.0)`:** the camera can't do 30 fps in its current
  format. Keep `fourcc: MJPG` in the camera block (already included here); if it still fails,
  drop every FPS in the guide to `20` (camera, recording, training must all match).
- **`rerun` / Vulkan / EGL warnings with `--display_data=true`:** harmless. The real error, if
  any, is in the Python traceback below them, not in the rerun warnings.
- **Cannot open serial port:** run `uv run lerobot-find-port`, then update `/dev/ttyACM*`.
  Ports can swap between the two arms after a reboot or replug.
- **Few-frames / jerky data:** keep `fps` consistent (30) across camera config and recording.
- **Poor success rate after training:** record more episodes and vary the object's start
  position and lighting; quality and variety of demonstrations matter more than raw count.
- **GPU not used:** ensure `--policy.device=cuda`; `cpu` works but is much slower.
