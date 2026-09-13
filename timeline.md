# Timeline (SO-ARM100 work, 2025-12 → 2026-09)

Times are local (Colombia, UTC-5) unless noted. Sources: surviving Claude Code memory files,
`~/.claude/history.jsonl` prompt log, file mtimes, dataset/checkpoint metadata. The June-July
session transcripts themselves were purged on 2026-09-13; everything below is what could be recovered.

| Date | What | Where / artifact |
|---|---|---|
| 2025-12 | Isaac Lab sim-to-real experiments with an SO-100 follower (lerobot 0.4.3). | `~/SO-arm/lerobot`, repo `jayounghoyos/SO-100-arm-test` |
| 2026-05-24 → 26 | Vision-guided grasping plan (follower + RPLidar C1 + WENKIA cam). **One servo burns.** Pivot to MuJoCo PPO grasping (4 reward iterations, never converged), then to the "carrito" ROS2 project. | memory `-personalProjects-SO-Arm-100` |
| 2026-05-30 | Firmware mismatch 3.9/3.10 blocks `lerobot-calibrate`; Win11 VM + Feetech FD flashes all to 3.10; follower calibrated (as `so101_follower`, port ACM0). | [[feetech-firmware]] |
| 2026-05-31 → 06-05 | `move_demo.py`, Xbox gamepad teleop, MuJoCo SAC reach → real arm (3.7 cm), MediaPipe hand-following, cube-grasp RL started. | `~/personalProjects/lerobot_arm_calibration/` |
| 2026-06 (mid) | Leader arm acquired. lerobot 0.5.2 cloned to `~/GitHub/AnotherOnes/lerobot`. | |
| 2026-06-28 20:23 | Both arms (re)calibrated as `so100_*` after a teleop offset. **Current calibration.** | `assets/calibration/` |
| 2026-06-28 21:56 → 22:32 | HF login troubles (`whoami` format); pick-and-place guide written; overhead camera found at index 0. | [[SO100_PICK_AND_PLACE_GUIDE]] |
| 2026-06-29 20:23 → 21:33 | Teleop with camera fails (fps 20 → MJPG); episode-key questions; three training profiles; recording Lego skeleton. **Leader breaks at episode 14.** | [[2026-06-29-lego-skeleton-act]] |
| 2026-06-29 21:42 → 22:08 | ACT "fast" training, 20k steps, ~26 min. Eval attempted; `FileExistsError`. | `outputs/train/act_so100_lego_skeleton` |
| 2026-07-13 11:11 → 12:25 | Two 32x32 board cameras added (wrist, base). Fool's mate guide written. Teleop error (string path → integer index). First record error (`Incorrect status packet`, id 5). | [[SO100_FOOLS_MATE_GUIDE]] |
| 2026-07-13 11:24 → 15:30 | 50 Fool's mate episodes recorded (148k frames); ACT "medium" 60k steps, ~4 h. | `local/so100_fools_mate` |
| 2026-07-13 19:13 → 22:27 | Eval attempts: two eval datasets aborted at 0 episodes; policy bobs, never grasps. Post-mortem discussion; user considers simpler task and a mobile robot (ESP32 + Jetson). | [[2026-07-13-fools-mate-act]] |
| 2026-08-23 → 24 | VLA learning roadmap planned (phases 0-6, reading list). | [[vla-roadmap-2026-08]], [[reading-list]] |
| 2026-08-30 | `vlaLerobot` project scaffolded: lerobot 0.6.2 vendored, torch 2.11 cu128 verified on Blackwell, `hardware/bench.py`, `notes/00-hardware.md`. Hardware not connected. | `~/personalProjects/vlaLerobot/`, `tools/bench.py` |
| 2026-09-10 | `reset-feetech.sh` run (Win11 VM password reset). | |
| 2026-09-13 | Transcripts found purged; this vault created. Decision: next project = medicaments with SmolVLA on MacBook + HF Jobs; old data stays local. Talk "From Token to Torque" (AI Medellín) in preparation. | this repo, [[vla-demo-plan]] |

## Resumen (ES)

Cronología: servo quemado y firmware (mayo), calibración y primer ACT con Lego (junio, leader roto en
el episodio 14), Fool's mate con tres cámaras y 60k pasos que falló en evaluación (julio), roadmap
VLA (agosto), y creación de este vault con el plan de medicamentos + SmolVLA (septiembre).
