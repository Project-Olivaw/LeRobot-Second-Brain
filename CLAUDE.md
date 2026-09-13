# LeRobot Second Brain — agent instructions

This repository is a knowledge vault, not a code project. It exists so that any Claude Code agent
(on the Ubuntu desktop, on the MacBook Pro M3, or driving a Hugging Face cloud GPU) can pick up the
SO-ARM100 work without re-learning what has already been learned. Read this file first, then follow
the read order below. Do not guess hardware facts — they are all written down here.

## Hard facts (do not override without asking the user)

- **Hardware is an SO-100 leader + SO-100 follower** (The Robot Studio SO-ARM100, 6x Feetech STS3215).
  It is **NOT an SO-101**. Use `--robot.type=so100_follower` and `--teleop.type=so100_leader`.
  The presentation repo (VLA-introduction-slides) says "SO-101" in its title metaphor — that is wording, not hardware.
- Robot ids: follower `my_awesome_follower_arm`, leader `my_awesome_leader_arm`. Calibration is keyed
  by these ids and the JSONs are in `assets/calibration/` — copy them, never recalibrate casually
  (see [[calibration]]).
- Cameras are keyed `top` (overhead), `wrist`, `base`. Keys are baked into datasets and must match at eval.
- Existing datasets and checkpoints are **local-only on the desktop** and are not on the Hub
  (see [[desktop-ubuntu]] for paths). Do not push them unless the user asks.
- Preferred runner on the desktop: `uv run` inside `~/GitHub/AnotherOnes/lerobot` (lerobot 0.5.2,
  torch 2.11 cu128). A conda env `lerobot` (0.5.1) also exists; the user sometimes uses it.
- Next project (Sep 2026): **medicament boxes/bottles pick-and-place, trained as a VLA (SmolVLA first),
  recorded on the MacBook, trained on HF Jobs.** See [[2026-09-medicaments-vla]].

## Read order for a new agent

1. `00-Start-Here.md` — map of content.
2. `hardware/so100-arms.md`, `hardware/cameras.md`, `hardware/calibration.md`.
3. The machine profile you are on: `machines/desktop-ubuntu.md`, `machines/macbook-m3.md`, or `machines/hf-cloud-gpu.md`.
4. `workflows/` in numeric order for the stage you need.
5. `experiments/` — what was tried and why Fool's mate failed, before proposing a new task.
6. `troubleshooting.md` → `lessons/` when something breaks.

## Conventions

- Every note ends with a `## Resumen (ES)` — keep it when editing.
- Commands in `workflows/` use variables from `machines/*.env`; load them with
  `source tools/env.sh desktop` or `source tools/env.sh macbook`. Never hard-code a port in a workflow note.
- New experiment = copy `experiments/_template.md`, name it `YYYY-MM-DD-<slug>.md`, fill it as you go, link it from `timeline.md`.
- New insight = one file in `lessons/`, one idea per file, linked from `troubleshooting.md`.
- Never commit datasets, checkpoints, videos, `.safetensors`, or HF tokens. `.gitignore` enforces the file types; you enforce the tokens.
- Verify CLI flags against the LeRobot version on the machine (`uv run lerobot-train --help`) — flags drift between releases.
- Prefer current docs over memory: `docs/source/*.mdx` in the lerobot checkout, or https://huggingface.co/docs/lerobot.

## Where things live on the desktop

| Thing | Path |
|---|---|
| lerobot checkout | `~/GitHub/AnotherOnes/lerobot` |
| datasets | `~/.cache/huggingface/lerobot/local/<name>` |
| checkpoints | `~/GitHub/AnotherOnes/lerobot/outputs/train/<job>/checkpoints/` |
| calibration | `~/.cache/huggingface/lerobot/calibration/{robots/so_follower,teleoperators/so_leader}/` |
| this vault | `~/GitHub/AnotherOnes/LeRobot-Second-Brain` |
| VLA study project | `~/personalProjects/vlaLerobot` (lerobot 0.6.2 vendored, `hardware/bench.py`) |

## Resumen (ES)

Este repo es la memoria compartida del brazo SO-100 (leader + follower, no SO-101). Lee primero
`00-Start-Here.md`, luego hardware, luego el perfil de la máquina donde estás. Los comandos usan
variables de `machines/*.env`. Los datasets y checkpoints viejos son locales al escritorio.
El siguiente proyecto es medicamentos con SmolVLA, grabado en la MacBook y entrenado en HF Jobs.
