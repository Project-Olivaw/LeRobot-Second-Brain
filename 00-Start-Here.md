# 00 — Start Here

Map of content for the SO-100 + LeRobot vault. Agents: read [[CLAUDE]] first.

## State of the project (2026-09-13)

- Two ACT policies were trained on the desktop: [[2026-06-29-lego-skeleton-act]] (worked as a
  pipeline test, 13 episodes) and [[2026-07-13-fools-mate-act]] (50 episodes, 3 cameras, **failed at eval**).
- Hardware: SO-100 leader + follower, 3 USB cameras. See [[so100-arms]], [[cameras]].
- [[2026-09-medicaments-vla]] — "Complejo B" box → ESP32 car. **WORKS: 80-90% success with SmolVLA**
  (the early failures were camera order, not data — [[camera-order-matters]]). Dataset + both policies
  are on the Hub under `Youngermaster/`.
- **Next up:** [[14-two-instruction-demo]] — record the zinc bottle (50 eps), merge, retrain.
  That completes the talk's `demo-live` slide. Interaction is `tools/demo_live.sh` → `/subtask <frase>`.
- [[2026-09-cubes-stacking-vla]] — planned: red/blue cubes, 4 instructions × 50 episodes, 3 cameras,
  the real version of the deck's animated "ahora el rojo, encima".
- [[13-cross-machine-loop]] — record anywhere → Hub → train on the desktop → demo on the Mac.
- MacBook: venv ready (0.6.2-dev), calibration copied; ports/camera indices still `TODO` ([[macbook-m3]]).

## Hardware
- [[so100-arms]] — motors, ids, SO-100 vs SO-101
- [[calibration]] — files, why they travel with the repo, consistency rules
- [[cameras]] — top / wrist / base, indices, MJPG, USB bandwidth
- [[scene-kit]] — the green mat, what travels with the arm, fixed vs varied
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
13. [[14-two-instruction-demo]] — the demo, end to end (the *why*)
14. **[[15-runbook-copy-paste]] — every command, every phase, ready to paste (the *how*)**
15. **[[16-verify-the-rig]] — the 2-minute check after plugging in, on either machine**
13. [[13-cross-machine-loop]]
14. [[14-two-instruction-demo]]

## Experiments
- [[_template]]
- [[2026-06-29-lego-skeleton-act]]
- [[2026-07-13-fools-mate-act]]
- [[2026-09-medicaments-vla]]
- [[2026-09-cubes-stacking-vla]]

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
- [[act-has-no-language-input]] — ACT never sees the instruction; it cannot be the language fallback
- [[identify-arms-by-homing-offset]] — which port is the leader, read-only, before any torque
- [[iphone-continuity-camera-breaks-runs]] — the phone steals an index and hangs the run
- [[conda-env-is-not-the-checkout]] — `git pull` does not touch the pip conda env; `uv sync` after every checkout
- [[policy-inference-is-bursty]] — measure the chunk recompute, not the average (SmolVLA 152 ms on the 5060 Ti)
- [[smolvla-camera-slots]] — camera1/2/3 and the `--rename_map`; the third slot is free
- [[lock-exposure-and-white-balance]] — `tools/lock_cameras.sh`; impossible on macOS
- [[balance-the-instructions]] — multi-task datasets need equal, lexically distinct instructions
- [[camera-order-matters]] — a swapped camera looks exactly like a badly trained policy (caught again 2026-09-29)
- [[resume-needs-dataset-root]] — `--resume=true` also needs `--dataset.root`
- [[resume-counts-this-run]] — num_episodes counts this run; Esc mid-episode saves the stub
- [[macos-builtin-camera-steals-a-slot]] — a missing USB camera on macOS is replaced, not reported
- [[identical-cameras-need-by-path]] — same model + same serial = one by-id name; pin the USB port
- [[stale-exports-survive-a-resource]] — a new terminal is the only guaranteed clean slate
- [[camera-indices-shift-on-replug]] — resolve by `/dev/v4l/by-id`, never a bare index

## Reference
- [[troubleshooting]] — symptom table
- [[timeline]] — chronological log
- `tools/` — `env.sh`, `find.sh`, `teleop.sh`, `record.sh`, `train_act.sh`, `train_smolvla.sh`, `eval.sh`, `push_hub.sh`, `drop_camera.sh`, `rename_map.py`, `bench.py`, `eta.sh`;
  project runners `record_medicament_box.sh`, `record_medicamentos.sh` (two-instruction halves, `--plan`), `overnight_medicament_box.sh`;
  cross-machine `pull.sh`, `push_dataset.py`, `merge_tasks.sh`, `tasks.sh`, `lock_cameras.sh`, `bench_policy.py`;
  demo `demo_live.sh` (interactive `/subtask`), `demo.sh` (one-shot);
  setup `find_ports.sh` (both arms), `identify_arms.py` (which port is which, read-only),
  `mac_cameras.sh` (macOS diagnosis), `check_cameras.py` (pre-flight before a long session),
  `verify_cameras.py` (live feeds vs the recorded dataset — run after every replug)
- `archive/` — [[SO100_PICK_AND_PLACE_GUIDE]], [[SO100_FOOLS_MATE_GUIDE]], [[vla-roadmap-2026-08]], [[reading-list]]
- [[vla-demo-plan]] — presentation

## Resumen (ES)

Índice del vault. Estado: SmolVLA de la caja de medicamento **entrenado pero sin evaluar**; falta el
frasco de zinc para el demo de dos instrucciones de la charla. Planeado: cubos rojo/azul con
apilado (4 instrucciones × 50 episodios, 3 cámaras). El bucle entre máquinas (grabar → Hub →
entrenar → demo en la Mac) está en [[13-cross-machine-loop]].
