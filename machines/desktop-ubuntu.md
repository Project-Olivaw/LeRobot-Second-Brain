# Machine: Ubuntu desktop (GPU box)

The machine where all 2026 recordings and ACT trainings happened. Not always available — that is
why this vault exists.

## Specs (verified 2026-08-30)

| Item | Value |
|---|---|
| OS | Ubuntu 24.04.4 LTS, X11 session (arrow keys work globally during recording) |
| CPU / RAM | AMD Ryzen 7 8700F (16 threads) / 32 GB |
| GPU | NVIDIA RTX 5060 Ti **16 GB**, Blackwell sm_120, driver 595.84 |
| torch | 2.11.0+cu128 (cu128 is the LeRobot-pinned index; verified with a real bf16 matmul, not just an import) |
| Python | 3.12 |
| Shell | zsh, ghostty terminal |
| Storage of note | `~/.cache/huggingface/lerobot/` (datasets, calibration), `outputs/train/` (checkpoints) |

## LeRobot environments (there are several — pick one and stay in it)

| Env | Version | How to run | Notes |
|---|---|---|---|
| `~/GitHub/AnotherOnes/lerobot/.venv` (uv) | **0.5.2** (commit 3dd19d04) | `cd ~/GitHub/AnotherOnes/lerobot && uv run lerobot-…` | **Preferred.** Matches the guides and the checkpoints. |
| conda `lerobot` | 0.5.1 / torch 2.10 | `conda activate lerobot && lerobot-…` | What the user typed during the July sessions. Works; slightly older. |
| `~/personalProjects/vlaLerobot/vendor/lerobot` | 0.6.2 | `.venv` in that project | VLA study project; newer API (`lerobot-rollout` etc.). |
| `~/personalProjects/lerobot_arm_calibration/lerobot` | 0.5.2 | that project's `.venv` | May 2026 single-arm work, RL scripts. |
| `~/SO-arm/lerobot` | 0.4.3 | — | Dec 2025 Isaac Lab sim2real repo `jayounghoyos/SO-100-arm-test`. Old. |

`machines/desktop.env` sets `RUN="uv run"`; set `RUN=""` if you are inside conda.

## Devices

| Device | Value |
|---|---|
| Follower | `/dev/ttyACM1` |
| Leader | `/dev/ttyACM0` |
| Cameras | index `0` top, `2` wrist, `4` base (odd nodes are metadata) |
| Serial permissions | user is in `dialout`; no `sudo chmod 666` needed |
| USB topology | several independent controllers (480M buses 001/003/005/006/008, 10G buses 002/004/007/009) — put cameras on different ones |

## Local-only artifacts (not on the Hub)

| Artifact | Path | Size |
|---|---|---|
| dataset `local/so100_lego_skeleton` (13 eps, 18,195 frames, `top`) | `~/.cache/huggingface/lerobot/local/so100_lego_skeleton` | 375 MB |
| dataset `local/eval_so100_lego_skeleton` (1 ep) | same root | 40 MB |
| dataset `local/so100_fools_mate` (50 eps, 148,032 frames, `top`+`wrist`+`base`) | same root | 6.5 GB |
| `local/eval_so100_fools_mate`, `..._retry` (0 episodes — aborted evals, videos only) | same root | 1.5 + 1.8 GB — safe to delete |
| ACT `act_so100_lego_skeleton` (20k steps, ckpts 5k/10k/15k/20k) | `~/GitHub/AnotherOnes/lerobot/outputs/train/act_so100_lego_skeleton` | 2.4 GB |
| ACT `act_so100_fools_mate` (60k steps, ckpts every 10k) | `.../outputs/train/act_so100_fools_mate` | 3.5 GB |
| camera probe images | `.../outputs/captured_images/` (copied to `assets/`) | — |

Exact hyperparameters: `assets/train_configs/*.train_config.json`.

## Measured training speed (ACT, fp32, batch 8, 8 workers)

- 1 camera 640x480: 20k steps in ~26 min → **~0.08 s/step**.
- 3 cameras 640x480: 60k steps in ~4 h 6 min → **~0.25 s/step** (≈49 min per 10k).
- Use `updt_s` from the log to size runs: `steps = budget_s / updt_s` ([[updt-s-is-your-timer]]).

## Also on this machine

- Windows 11 VM `win11` (virt-manager) with Feetech FD for firmware flashing — [[feetech-firmware]].
- Xbox controller teleop and MuJoCo RL scripts in `~/personalProjects/lerobot_arm_calibration/`.
- Slides repo for the talk may be cloned here too; see [[vla-demo-plan]].

## Resumen (ES)

Escritorio Ubuntu con RTX 5060 Ti 16 GB. Usar `uv run` dentro de `~/GitHub/AnotherOnes/lerobot`
(0.5.2). Follower en ttyACM1, leader en ttyACM0, cámaras 0/2/4. Aquí viven los datasets y
checkpoints ACT (solo locales). Velocidad medida: ~0.08 s/paso con 1 cámara, ~0.25 s/paso con 3.
