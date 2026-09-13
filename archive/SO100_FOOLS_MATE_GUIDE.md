# SO100 Fool's Mate Guide (three cameras)

End-to-end recipe to teach an SO100 arm to play the **black side of Fool's mate** by imitation
learning, using a leader arm for teleoperation and **three** cameras (overhead + wrist + base).

This is a companion to `SO100_PICK_AND_PLACE_GUIDE.md` (the single-camera Lego-skeleton task).
Keep that one as-is; this document is the three-camera chess task.

Everything here is **local only** by default — nothing is uploaded. Hub variants are noted where
useful.

---

## The task: Fool's mate

Fool's mate is the fastest checkmate in chess. White blunders, Black punishes:

```
1. f3   e5
2. g4   Qh4#      (checkmate — the black queen attacks the white king, no escape)
```

**The robot plays Black** (the winning side). You (the human) play White by hand and also
teleoperate the robot's Black moves. One episode is one full Fool's mate:

| # | Who        | Move                     | How                                  |
|---|------------|--------------------------|--------------------------------------|
| 1 | You (hand) | White pawn **f2-f3**     | Move the piece with your hand        |
| 2 | Robot      | Black pawn **e7-e5**     | You teleoperate the follower arm     |
| 3 | You (hand) | White pawn **g2-g4** (2 squares) | Move the piece with your hand |
| 4 | Robot      | Black queen **d8-h4#**   | You teleoperate the follower arm     |

The policy learns the **Black moves** (steps 2 and 4) from the camera views and arm state. During
recording you perform all four — moving White by hand and driving Black with the leader arm.
During evaluation the policy drives Black; you still play White by hand and reset the board.

> Reality check: this is an ambitious multi-step task. The policy must locate pieces from vision,
> grasp them, place them on the right squares, and time its two moves around your White moves.
> Expect to need a solid dataset (50+ episodes, varied board framing) and to iterate. The Lego
> guide is the gentler warm-up; this one is the stretch goal.

---

## Your hardware

| Thing            | Value                                            |
|------------------|--------------------------------------------------|
| Follower arm     | `so100_follower` on `/dev/ttyACM1`               |
| Follower id      | `my_awesome_follower_arm`                        |
| Leader arm       | `so100_leader` on `/dev/ttyACM0`                 |
| Camera `top`     | overhead USB cam, index `0` (`/dev/video0`, needs MJPG) |
| Camera `wrist`   | new cam on the wrist, index `2` (`/dev/video2`)  |
| Camera `base`    | new cam on the rotation/pitch base, index `4` (`/dev/video4`) |
| GPU              | NVIDIA RTX 5060 Ti (`--policy.device=cuda`)      |

The camera **keys** (`top`, `wrist`, `base`) are baked into the dataset and must be identical at
record and eval time, each mapped to the same physical camera. Ports and `/dev/videoN` numbers
can change on reboot/replug — re-verify with the discovery steps below if a connection fails.

Run everything from your activated env: `conda activate lerobot`. (These commands assume that env;
the Lego guide shows `uv run` for portability — same commands, drop the prefix in conda.)

---

## 0. One-time prerequisites (only for the optional Hub variants)

```bash
hf auth login --token ${HUGGINGFACE_TOKEN} --add-to-git-credential
HF_USER=$(hf auth whoami 2>/dev/null | sed -n 's/^user=//p')
echo "$HF_USER"
```

Local-only training needs none of this.

---

## 1. Identify the arm ports (`lerobot-find-port`)

You already know these (`ttyACM1` follower, `ttyACM0` leader), but if they ever shift, this is how
to re-identify them. The tool lists ports, you unplug one arm, and it reports which port vanished.

```bash
lerobot-find-port
```

Flow: it prints the ports, then asks *"Remove the USB cable from your MotorsBus and press Enter"*.
Unplug **one** arm's USB, press Enter, and it prints that arm's port (e.g. `/dev/ttyACM0`). Reconnect,
then repeat for the other arm. Use the results as `--robot.port` (follower) and `--teleop.port`
(leader).

---

## 2. Identify the three cameras (`lerobot-find-cameras`)

```bash
lerobot-find-cameras opencv
```

This lists each camera and saves a sample frame to `outputs/captured_images/`. On this machine the
capture nodes are `/dev/video0`, `/dev/video2`, `/dev/video4`, which map to camera **indices**
`0`, `2`, `4`:

- index `0` (`/dev/video0`) — the overhead USB cam (`top`). Defaults to 1920x1080 @ 5fps.
- index `2` (`/dev/video2`) — a new camera.
- index `4` (`/dev/video4`) — a new camera.

(Each USB camera also exposes an odd-numbered metadata node like `/dev/video1`; ignore those. Use
the even capture nodes, i.e. even indices.)

> **Use the integer index (`0`, `2`, `4`), not the `/dev/videoN` string path.** With the default
> `CAP_ANY` backend, OpenCV opens a **string path** through the read-only **FFMPEG** backend, which
> **cannot set MJPG / width / height / fps** — it fails with
> `failed to set capture_width=640 (actual_width=1920)`. An **integer** index opens through the
> **V4L2** backend, which *can* set them. The index `N` maps to `/dev/videoN`.

**You must confirm which of index `2` / `4` is the wrist vs the base.** Open the saved images in
`outputs/captured_images/` and look:

- The **wrist** view moves with the gripper (close-up of whatever the gripper points at).
- The **base** view is a wider, fixed side/low angle of the board.

If they're swapped versus the table above, just swap the `2` and `4` index values in the camera
blocks below.

> Harmless: the `ioctl(VIDIOC_QBUF): Bad file descriptor` lines during the probe are normal V4L2
> chatter.

---

## 3. Calibrate both arms

Only needed if not already calibrated (or after you reprint/replace the leader). Put **both arms in
the same physical middle pose** before pressing ENTER at the homing step, and move **every joint
through its full range** at the range step — this keeps leader and follower consistent (see the
"calibration consistency" discussion in the Lego guide).

```bash
lerobot-calibrate \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm
# Saved to ~/.cache/huggingface/lerobot/calibration/robots/so_follower/my_awesome_follower_arm.json
```

```bash
lerobot-calibrate \
    --teleop.type=so100_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm
# Saved to ~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader/my_awesome_leader_arm.json
```

---

## 4. Teleoperate with all three cameras (practice as a human)

Do this first: get comfortable performing Fool's mate by teleoperation, and confirm all three feeds
look right, before recording anything. `--display_data=true` opens a rerun window with the three
camera feeds and joint positions. Teleoperation stores **nothing** — it's pure practice.

```bash
lerobot-teleoperate \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}, wrist: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30, fourcc: MJPG}, base: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --teleop.type=so100_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true
```

Practice the choreography end to end: your White f3 by hand → teleoperate Black e5 → your White g4
by hand → teleoperate Black Qh4#. Practice until you can do it smoothly and repeatably; consistent
demonstrations make a far better dataset.

> Why `fourcc: MJPG` on all three: three simultaneous 640x480@30 **raw** streams can exceed USB
> bandwidth and make one camera fail to open or drop frames. MJPG is compressed (~10x smaller), so
> all three fit. See Troubleshooting if a camera still fails.

---

## 5. Record the dataset (50 episodes, or more)

Same three-camera config, now recording. Each episode is one complete Fool's mate. Episodes are
**auto-saved** to `~/.cache/huggingface/lerobot/local/so100_fools_mate` as you go.

### How you drive each episode (arrow keys)

| Key            | What it does                                                       |
|----------------|-------------------------------------------------------------------|
| **Right arrow →** | End the current phase **immediately** and move on              |
| **Left arrow ←**  | **Discard** the current episode and **re-record** it           |
| **Escape**        | **Stop** the whole session (episodes already saved are kept)   |

Per-episode flow:

1. **Record phase** — perform the full Fool's mate (both your hand moves and the two teleoperated
   Black moves). Press **Right arrow** the instant Qh4# is placed. It also auto-ends at
   `episode_time_s` (a safety cap).
2. **Reset phase** — `reset_time_s` to put every piece back to the starting position for the next
   take. Skippable with **Right arrow**.
3. Auto-saved, counter advances, next episode. Repeat to 50 (or more).
4. Botched a move? **Left arrow** to redo that episode. Keep bad demos out.

On X11 (your setup) the arrow keys are captured globally; if a press is ignored, click the terminal
to focus it.

### Recording tips for this task (important)

- **Board framing must stay fixed.** Keep the board, cameras, and lighting stable within a session;
  the policy keys off what it sees.
- **Vary what generalizes, keep constant what shouldn't.** The four moves are always the same squares,
  so keep them exact. Vary small things: slight lighting changes, tiny board shifts — only if you want
  robustness. For a first working policy, keep everything as consistent as possible.
- **Bump `episode_time_s`** — a full four-move sequence with hand moves takes a while. 120s is safer
  than 60s here.
- **Aim for 50+ episodes.** Multi-step manipulation from vision needs more data than a single pick.

### 5a. Record (local only)

```bash
lerobot-record \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}, wrist: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30, fourcc: MJPG}, base: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --teleop.type=so100_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true \
    --dataset.repo_id=local/so100_fools_mate \
    --dataset.num_episodes=50 \
    --dataset.single_task="Play black Fools mate move pawn e7e5 then queen d8h4 for checkmate" \
    --dataset.episode_time_s=120 \
    --dataset.reset_time_s=20 \
    --dataset.push_to_hub=false
```

- Need more than 50? Raise `--dataset.num_episodes`, or record more later by re-running the **same**
  command with `--resume=true` (it appends until it hits the new target). Do **not** recalibrate the
  follower between sessions or old/new episodes end up in different coordinate spaces.
- Hub variant: set `--dataset.repo_id=${HF_USER}/so100_fools_mate` and `--dataset.push_to_hub=true`.

### 5b. (Optional) Inspect / replay

```bash
lerobot-dataset-viz --repo-id=local/so100_fools_mate
```

Replay one episode on the follower (no leader, no cameras needed):

```bash
lerobot-replay \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --dataset.repo_id=local/so100_fools_mate \
    --dataset.episode=0
```

---

## 6. Train the policy (ACT) — Basic / Medium / Best

ACT auto-adapts to your motors and to all **three** cameras stored in the dataset. Training runs in
**fp32** (no mixed precision); the only speed levers are `--steps`, `--batch_size`, `--num_workers`.

**Three cameras roughly triple the vision compute** versus the single-camera Lego task, so each step
is slower and the times below are longer. Treat the estimates as ballpark. The trainer prints
`updt_s` (seconds/step) every log line — after ~1 minute, compute the exact fit:
`steps = budget_seconds / updt_s`.

| Profile | steps | batch | workers | Est. time (3 cams, 5060 Ti) | When to use |
|---------|-------|-------|---------|------------------------------|-------------|
| **Basic** | 15000 | 8 | 8 | ~1-1.5 h | Quick usable / pipeline test |
| **Medium** | 60000 | 8 | 8 | ~5-7 h | Solid daytime/overnight run |
| **Best** | 120000 | 8 | 8 | ~10-13 h | Highest quality, overnight |

Notes:

- All three keep the validated `batch=8`. For ACT, **more gradient steps** buys more quality than a
  bigger batch — so the tiers scale `--steps`, not batch size.
- `num_workers=8` keeps three camera streams decoding fast enough to feed the GPU. If the desktop
  gets sluggish, drop to 6; if GPU utilization (`nvidia-smi -l 1`) sits under ~80%, the dataloader is
  the bottleneck — this is more likely with three video streams, so keep workers high.
- **Want to use more GPU / go faster wall-clock on the 16GB card?** Add `--batch_size=16`. With three
  640x480 cameras this uses noticeably more VRAM — if you hit a CUDA out-of-memory error, go back to
  `--batch_size=8` (or `12`). Do not raise batch on the 8GB card.
- Checkpoints are written every `save_freq` steps to
  `outputs/train/act_so100_fools_mate/checkpoints/`, so you can stop early and evaluate `last`.

### 6a. Basic (~1-1.5 h)

```bash
lerobot-train \
    --dataset.repo_id=local/so100_fools_mate \
    --policy.type=act \
    --output_dir=outputs/train/act_so100_fools_mate \
    --job_name=act_so100_fools_mate \
    --policy.device=cuda \
    --batch_size=8 --num_workers=8 \
    --steps=15000 --save_freq=5000 \
    --wandb.enable=false --policy.push_to_hub=false
```

### 6b. Medium (~5-7 h)

```bash
lerobot-train \
    --dataset.repo_id=local/so100_fools_mate \
    --policy.type=act \
    --output_dir=outputs/train/act_so100_fools_mate \
    --job_name=act_so100_fools_mate \
    --policy.device=cuda \
    --batch_size=8 --num_workers=8 \
    --steps=60000 --save_freq=10000 \
    --wandb.enable=false --policy.push_to_hub=false
```

### 6c. Best (~10-13 h, overnight)

```bash
lerobot-train \
    --dataset.repo_id=local/so100_fools_mate \
    --policy.type=act \
    --output_dir=outputs/train/act_so100_fools_mate \
    --job_name=act_so100_fools_mate \
    --policy.device=cuda \
    --batch_size=8 --num_workers=8 \
    --steps=120000 --save_freq=20000 \
    --wandb.enable=false --policy.push_to_hub=false
```

> All three profiles write to the **same** `output_dir`, and training refuses to overwrite an
> existing run (`FileExistsError`). Between runs, either delete
> `outputs/train/act_so100_fools_mate`, or give each profile its own `--output_dir`/`--job_name`
> (e.g. `..._basic`, `..._medium`, `..._best`).

Resume an interrupted run from its last checkpoint:

```bash
lerobot-train \
    --config_path=outputs/train/act_so100_fools_mate/checkpoints/last/pretrained_model/train_config.json \
    --resume=true
```

---

## 7. Evaluate the trained policy

The policy drives the follower to play Black; **you still play White by hand and reset the board**.
The camera config must match recording exactly (same three keys, same cameras). No leader arm is used.

Name the eval dataset with an `eval_` prefix.

```bash
lerobot-record \
    --robot.type=so100_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: MJPG}, wrist: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30, fourcc: MJPG}, base: {type: opencv, index_or_path: 4, width: 640, height: 480, fps: 30, fourcc: MJPG}}" \
    --display_data=true \
    --dataset.repo_id=local/eval_so100_fools_mate \
    --dataset.single_task="Play black Fools mate move pawn e7e5 then queen d8h4 for checkmate" \
    --dataset.num_episodes=10 \
    --dataset.episode_time_s=120 \
    --dataset.reset_time_s=20 \
    --dataset.push_to_hub=false \
    --policy.path=outputs/train/act_so100_fools_mate/checkpoints/last/pretrained_model
```

- Evaluate an intermediate checkpoint instead by pointing `--policy.path` at e.g.
  `outputs/train/act_so100_fools_mate/checkpoints/060000/pretrained_model`.
- To re-run eval into the same `repo_id`, first delete the folder
  (`rm -rf ~/.cache/huggingface/lerobot/local/eval_so100_fools_mate`) or use a new name — `record`
  refuses to write into an existing dataset directory.

---

## Quick reference

| Stage  | Local-only                                   | Hub                                              |
|--------|----------------------------------------------|--------------------------------------------------|
| Record | `--dataset.push_to_hub=false`                | `--dataset.push_to_hub=true` + `${HF_USER}` repo |
| Train  | `--policy.push_to_hub=false`                 | `--policy.push_to_hub=true --policy.repo_id=...` |
| Eval   | `--policy.path=outputs/.../pretrained_model` | `--policy.path=${HF_USER}/act_so100_fools_mate`  |

- Datasets: `~/.cache/huggingface/lerobot/<repo_id>`
- Checkpoints: `outputs/train/act_so100_fools_mate/checkpoints/`

---

## Troubleshooting (three-camera specifics)

- **A camera fails to open / `failed to set fps=30` with three cameras attached:** USB bandwidth.
  Keep `fourcc: MJPG` on all three (already set here). If it persists, spread cameras across
  **different physical USB controllers** (not all on one hub), or lower every camera to `fps: 15`
  (change it in the camera block *and* keep it consistent — FPS becomes the dataset/control rate).
- **`failed to set capture_width=640 (actual_width=1920)` / `failed to set fourcc=MJPG`:** you used
  a `/dev/videoN` **string path**, which OpenCV opens via the read-only FFMPEG backend. Use the
  **integer index** (`0`, `2`, `4`) instead — it opens via V4L2 and can set MJPG/resolution/fps.
- **Wrong camera under a key (wrist/base swapped):** open `outputs/captured_images/` after
  `lerobot-find-cameras`, identify each view, and swap the `2` / `4` index values.
- **Camera indices changed after replug/reboot:** re-run `lerobot-find-cameras` and update the
  index numbers (index `N` = `/dev/videoN`).
- **`failed to set fps` on `top` only:** it's the 1080p@5 default cam — `fourcc: MJPG` (already set)
  is what lets it do 640x480@30.
- **CUDA out of memory in training:** three cameras use more VRAM — lower `--batch_size` (16 → 12 → 8).
- **Training slower than the table:** three video streams can starve the GPU; raise `--num_workers`,
  and confirm GPU use with `nvidia-smi -l 1`. Resolution is the biggest compute lever if you need to
  cut time.
- **`FileExistsError` on record/eval:** the target dataset folder already exists (often from a
  cancelled or crashed run — record creates the folder *before* connecting the arm, so a mid-startup
  crash leaves an empty scaffold). Delete it (`rm -rf ~/.cache/huggingface/lerobot/<repo_id>`) or pick
  a new `repo_id`.
- **`ConnectionError: Failed to write 'Lock' on id_=N ... Incorrect status packet!`:** the follower
  arm's serial/motor bus glitched (not a config problem — the cameras had already connected fine).
  In order: (1) **retry the command** — it is often transient; (2) reseat the follower **USB cable**
  (`/dev/ttyACM1`) and the **servo daisy-chain connectors**, especially around the motor id in the
  error (e.g. id 5 = wrist_roll); (3) check the follower's **power supply** is firmly connected —
  servo brown-outs cause this, and three cameras + two arms sharing USB power makes it worse, so put
  the arms on a powered hub or direct ports separate from the cameras; (4) confirm `/dev/ttyACM1` is
  still the follower with `lerobot-find-port` (ACM numbers can swap on replug).
- **Task label looks like a dict / mangled (e.g. `{"Play black Fools mate": ...}`):** the
  `single_task` string contained a **colon** (draccus reads `key: value` as a dict) or an apostrophe.
  Keep `single_task` free of colons and apostrophes (the commands here already do).
- **rerun / Vulkan / EGL warnings with `--display_data=true`:** harmless; the real error, if any, is
  in the Python traceback.
