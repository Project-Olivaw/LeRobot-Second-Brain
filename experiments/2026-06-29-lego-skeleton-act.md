# 2026-06-29 — Lego skeleton into a bin — ACT

**Status:** evaluated — pipeline validated; policy quality inconclusive (only 13 demos, 1 eval episode)
**Machine:** desktop · **lerobot version:** 0.5.2 (uv) / 0.5.1 (conda, used interactively)

Reconstructed from `~/.claude/history.jsonl` (the session transcript was purged), the guide
[[SO100_PICK_AND_PLACE_GUIDE]], dataset metadata and the checkpoint's `train_config.json`.

## Goal
Pick a Lego skeleton figure from the table and drop it in a bin, from one overhead camera.
The first end-to-end run of record → train → eval with the leader/follower pair.

## Setup
| Item | Value |
|---|---|
| Robot / ids | `so100_follower` `/dev/ttyACM1` `my_awesome_follower_arm` · `so100_leader` `/dev/ttyACM0` `my_awesome_leader_arm` |
| Cameras | `top` only — WENKIA overhead, index 0, 640x480@30 MJPG |
| Calibration | 2026-06-28 (recalibrated the day before after an offset was seen in teleop) |
| Scene | table, bin, Lego skeleton; object start position varied |
| Task string | `Put the Lego skeleton in the bin` |

## Dataset
| repo_id | episodes | frames | fps | size | where |
|---|---|---|---|---|---|
| `local/so100_lego_skeleton` | 13 | 18,195 | 30 | 375 MB | desktop `~/.cache/huggingface/lerobot/local/` |
| `local/eval_so100_lego_skeleton` | 1 | 1,789 | 30 | 40 MB | same |

Recording notes: target was 50 episodes; **the leader arm broke in half at episode 14** (printed
part, later reprinted). Average episode ≈ 47 s (18,195 / 13 / 30) — long for a single pick; the
60 s cap was rarely pressed early. Trained anyway "for testing purposes".

## Training
"Fast" profile: `--policy.type=act --batch_size=8 --num_workers=8 --steps=20000 --save_freq=5000
--policy.device=cuda`, defaults otherwise (`chunk_size=100`, `n_action_steps=100`, resnet18, lr 1e-5).
Wall-clock **~26 min** (21:42 → 22:08 local) → ~0.08 s/step. Config: `assets/train_configs/act_so100_lego_skeleton.train_config.json`.
Checkpoints 5k/10k/15k/20k in `outputs/train/act_so100_lego_skeleton/`.

## Evaluation
`lerobot-record --policy.path=.../checkpoints/last/pretrained_model` into `local/eval_so100_lego_skeleton`.
The first attempt "started moving" and was cancelled to fix the setup; the re-run hit
`FileExistsError` (folder already created) → [[file-exists-error-on-record]]. One eval episode was
eventually saved (1,789 frames ≈ 60 s = ran to the cap, i.e. **not a clean success**). No success
count was recorded.

## What we learned
- The whole pipeline works on this hardware; the guide's commands are correct → became [[06-record]], [[08-train-act]], [[10-evaluate]].
- `fourcc: MJPG` is required for the WENKIA at 30 fps → [[mjpg-required-for-30fps]].
- `hf auth whoami` output format changed → [[hf-whoami-format]].
- Episode boundaries are driven by the arrow keys, not timers → [[12-recording-keys]], [[episode-time-is-a-cap]].
- 13 long demos are not a dataset; the run's value was validating the tooling, not the policy.
- Sizing training by measured `updt_s` → [[updt-s-is-your-timer]].

## Next
Superseded by [[2026-07-13-fools-mate-act]] (which over-reached) and now by [[2026-09-medicaments-vla]].
If revisiting this task: 50+ episodes, press → at the drop, and evaluate 10 episodes with counts.

## Resumen (ES)
Primer ciclo completo grabar → entrenar → evaluar con una cámara. Solo 13 episodios porque el leader
se partió; entrenamiento de 20k pasos en ~26 min. Sirvió para validar la tubería y descubrir MJPG,
el formato de `hf auth whoami` y el manejo de episodios con flechas. Calidad de la política sin medir.
