# LeRobot Second Brain

A portable knowledge vault for working with an **SO-ARM100 leader/follower pair** using
[LeRobot](https://github.com/huggingface/lerobot). It captures hardware facts, calibration files,
copy-paste workflows, experiment post-mortems, and one-lesson-per-note troubleshooting, so the work
can move between machines:

| Machine | Role |
|---|---|
| Ubuntu desktop (RTX 5060 Ti 16 GB) | record + train locally (ACT runs of June/July 2026 live here) |
| MacBook Pro M3 | record datasets anywhere (talks, demos), push to the Hub |
| Hugging Face Jobs GPU | train VLAs (SmolVLA, pi0) when the desktop is not available |

It is an [Obsidian](https://obsidian.md) vault (open the folder as a vault for wiki-links and the graph)
and also a plain Markdown repo readable on GitHub. `CLAUDE.md` is the entry point for AI coding agents.

## Start here

- [00-Start-Here](00-Start-Here.md) — map of content
- [timeline](timeline.md) — what happened, when (May → Sep 2026)
- [troubleshooting](troubleshooting.md) — symptom → fix

## Layout

```
CLAUDE.md          agent entry point: hard facts, read order, conventions
hardware/          arms, calibration, cameras, Feetech firmware, breakage history
machines/          per-machine profiles + .env files (ports, cameras, device, runner)
workflows/         01..12: environment → ports → calibrate → cameras → teleop → record → train → eval → hub sync
experiments/       dated post-mortems (Lego skeleton ACT, Fool's mate ACT) + next experiment (medicaments VLA)
lessons/           one insight per note
tools/             env.sh + thin shell wrappers over lerobot-* commands, bench.py
assets/            calibration JSONs, camera probe images, exact train configs
archive/           original guides (verbatim), VLA roadmap, reading list
presentation/      demo plan for the "From Token to Torque" VLA talk
```

## Quick use

```bash
git clone <this repo> LeRobot-Second-Brain
cd LeRobot-Second-Brain
source tools/env.sh desktop      # or: macbook
tools/find.sh                    # lerobot-find-port + lerobot-find-cameras
tools/teleop.sh                  # sanity check
tools/record.sh my_task "Pick the medicament box and place it in the tray" 50
```

Nothing in this repo uploads anything. Hub pushes are opt-in flags documented in
[workflows/11-hub-sync](workflows/11-hub-sync.md).

## Resumen (ES)

Bóveda de conocimiento del brazo SO-100 con LeRobot: hardware, calibración, comandos listos para
copiar, experimentos (qué funcionó y qué no) y lecciones. Sirve para trabajar igual en el escritorio
con GPU, en la MacBook, o entrenando en GPUs de Hugging Face. Abrir como vault de Obsidian.
