# 00 — Start Here

Map of content for the SO-100 + LeRobot vault. Agents: read [[CLAUDE]] first.

## State of the project (2026-09-13)

- Two ACT policies were trained on the desktop: [[2026-06-29-lego-skeleton-act]] (worked as a
  pipeline test, 13 episodes) and [[2026-07-13-fools-mate-act]] (50 episodes, 3 cameras, **failed at eval**).
- Hardware: SO-100 leader + follower, 3 USB cameras. See [[so100-arms]], [[cameras]].
- Next: [[2026-09-medicaments-vla]] — medicament box, **go on 2026-09-13**: 50 episodes (5 spots × 10)
  recorded on the desktop, ACT → SmolVLA overnight on the 5060 Ti, demo from the MacBook via the Hub.
  Feeds the talk in [[vla-demo-plan]].
- MacBook: venv ready (0.6.2-dev), calibration copied; ports/camera indices still `TODO` ([[macbook-m3]]).

## Hardware
- [[so100-arms]] — motors, ids, SO-100 vs SO-101
- [[calibration]] — files, why they travel with the repo, consistency rules
- [[cameras]] — top / wrist / base, indices, MJPG, USB bandwidth
- [[feetech-firmware]] — the 3.9 vs 3.10 mismatch and the Windows VM fix
- [[hardware-history]] — burned servo, broken leader, aborted evals

## Machines
- [[desktop-ubuntu]] — RTX 5060 Ti, ports, envs, where data lives
- [[macbook-m3]] — what changes on macOS (ports, cameras, `mps`)
- [[hf-cloud-gpu]] — training on HF Jobs

## Workflows (in order)
1. [[01-environment]]
2. [[02-find-ports]]
3. [[03-calibrate]]
4. [[04-find-cameras]]
5. [[05-teleoperate]]
6. [[06-record]]
7. [[07-inspect-replay]]
8. [[08-train-act]]
9. [[09-train-vla]]
10. [[10-evaluate]]
11. [[11-hub-sync]]
12. [[12-recording-keys]]

## Experiments
- [[_template]]
- [[2026-06-29-lego-skeleton-act]]
- [[2026-07-13-fools-mate-act]]
- [[2026-09-medicaments-vla]]

## Lessons (one idea each)
- [[mjpg-required-for-30fps]]
- [[integer-index-not-dev-path]]
- [[usb-bandwidth-three-cams]]
- [[single-task-no-colons]]
- [[file-exists-error-on-record]]
- [[incorrect-status-packet]]
- [[calibrate-same-pose]]
- [[hf-whoami-format]]
- [[act-limits-small-objects]]
- [[dont-move-the-scene]]
- [[camera-keys-are-baked-in]]
- [[episode-time-is-a-cap]]
- [[train-refuses-to-overwrite]]
- [[updt-s-is-your-timer]]
- [[rerun-warnings-are-harmless]]
- [[good-dataset-rules]]
- [[no-same-evening-vla]] — why 10 episodes + 2 hours cannot produce a VLA
- [[policy-does-not-survive-a-new-table]] — bring the scene, not a new model
- [[policy-travels-as-a-folder]] — desktop → Mac: Hub or USB, same version, same keys
- [[lerobot-06-extras]] — 0.6.x needs `--extra core_scripts`

## Reference
- [[troubleshooting]] — symptom table
- [[timeline]] — chronological log
- `tools/` — `env.sh`, `find.sh`, `teleop.sh`, `record.sh`, `train_act.sh`, `train_smolvla.sh`, `eval.sh`, `push_hub.sh`, `bench.py`
- `archive/` — [[SO100_PICK_AND_PLACE_GUIDE]], [[SO100_FOOLS_MATE_GUIDE]], [[vla-roadmap-2026-08]], [[reading-list]]
- [[vla-demo-plan]] — presentation

## Resumen (ES)

Índice del vault. Estado: dos políticas ACT entrenadas (Lego OK como prueba, Fool's mate falló),
hardware SO-100 con 3 cámaras, siguiente proyecto medicamentos con SmolVLA. Sigue los workflows
en orden numérico y consulta lecciones cuando algo falle.
