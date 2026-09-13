# 2026-07-13 — Fool's mate (robot plays Black) — ACT, 3 cameras

**Status:** evaluated — **failed** (0/10+ attempts; never grasped the first pawn)
**Machine:** desktop · **lerobot version:** 0.5.1 (conda `lerobot`)

Reconstructed from `~/.claude/history.jsonl`, [[SO100_FOOLS_MATE_GUIDE]], dataset metadata,
`train_config.json`, and the camera probe images in `assets/captured_images/`.

## Goal
One episode = a full Fool's mate. Human moves White by hand (f3, then g4); the robot, teleoperated
during recording, moves Black **e7-e5** and then **Qd8-h4#**. Success = the policy performs both
Black moves at the right moments while a human plays White.

## Setup
| Item | Value |
|---|---|
| Robot / ids | same as always (`so100_*`, `my_awesome_*_arm`), ports ACM1/ACM0 |
| Cameras | `top` idx 0 (WENKIA overhead), `wrist` idx 2, `base` idx 4 — two new 32x32 mm board cams; all 640x480@30 MJPG |
| Calibration | 2026-06-28 |
| Scene | chessboard with pieces; the board was **deliberately shifted a little between some episodes** so the policy "could adjust" |
| Task string | `Play black Fools mate move pawn e7e5 then queen d8h4 for checkmate` (apostrophe/colon removed after a draccus parse bug) |

## Dataset
| repo_id | episodes | frames | fps | size | where |
|---|---|---|---|---|---|
| `local/so100_fools_mate` | 50 | 148,032 | 30 | 6.5 GB | desktop `~/.cache/huggingface/lerobot/local/` |
| `local/eval_so100_fools_mate` | 0 | 0 | — | 1.5 GB (orphan videos) | same — safe to delete |
| `local/eval_so100_fools_mate_retry` | 0 | 0 | — | 1.8 GB (orphan videos) | same — safe to delete |

Average episode ≈ **99 s** (148,032 / 50 / 30) — four chess moves incl. two hand moves. Incidents:
teleop with the new cameras failed until integer indices were used ([[integer-index-not-dev-path]]);
the first record attempt died with `Incorrect status packet` on motor id 5 ([[incorrect-status-packet]]).

## Training
"Medium" profile: `--policy.type=act --batch_size=8 --num_workers=8 --steps=60000 --save_freq=10000`,
three image inputs, defaults otherwise (`chunk_size=100`, `n_action_steps=100`, resnet18, lr 1e-5).
Wall-clock **~4 h 06** (16:24 → 20:30 local) → ~0.25 s/step. Config in
`assets/train_configs/act_so100_fools_mate.train_config.json`. Checkpoints every 10k.

## Evaluation
`lerobot-record --policy.path=.../checkpoints/last/pretrained_model` on 2026-07-14, 10+ manual
attempts, none saved as episodes. Observed behaviour (user's words): sometimes goes up and hovers;
sometimes "goes up, then down, up and down continuously"; never grasps the e7 pawn; but when the
human moves the second White pawn it "moves the wrist and grabs the air" — it learned *something*
about the timing cue, not the grasp.

## Why it failed (post-mortem)

1. **Task far too long and multi-modal for 50 demos.** ~100 s episodes with two robot moves separated
   by a human move. ACT with `n_action_steps=100` emits 3.3 s of open-loop motion per inference; the
   "wait for the human" segments are long stretches where the correct action is *do nothing*, then a
   sudden reach. Waiting dominates the loss; the reach is under-represented. → [[act-limits-small-objects]]
2. **Chess pieces are small, dark, and identical-looking** at 640x480 from an overhead cam; the
   grasp tolerance is a few millimetres. The Lego guide's own warning ("gentler warm-up") applied.
3. **The scene moved.** Shifting the board between episodes without a corresponding visual anchor
   makes the demonstrations inconsistent: same visual context → different target joint positions. ACT
   averages, which produces the hover/bob. → [[dont-move-the-scene]]
4. **Camera quality.** The probe images show the `base` view dark and ~1/3 occluded by the arm, and
   the `wrist` view dark. Three feeds tripled compute (0.25 vs 0.08 s/step) for little signal.
5. **Eval hygiene.** No eval episodes were saved (two `FileExistsError`s, then aborts), so there is no
   video to analyse and no success count. → [[file-exists-error-on-record]], `tools/eval.sh` timestamps the repo id.
6. Not a training failure: loss went down and the policy reacts to visual cues. The dataset did not
   contain a learnable mapping at this size.

## What we learned
- Start with a **single reach-grasp-place on a large, high-contrast object**, fixed scene, ≤ 30 s episodes → [[good-dataset-rules]].
- Vary the **object pose**, not the fixtures/board/cameras.
- Two good cameras beat three poor ones; light the wrist cam.
- For a reactive/multi-step task lower `n_action_steps` (25) or use temporal ensembling; better, split
  the task into separately triggered sub-tasks.
- USB: arms and cameras on separate controllers → [[usb-bandwidth-three-cams]].
- Task strings: no `:` or `'` → [[single-task-no-colons]].
- Keep the dataset — it is a fine stress test for a future VLA with language ("move the pawn e7 to e5")
  if the scene is re-recorded consistently. The 3.3 GB of orphan eval videos can go.

## Next
[[2026-09-medicaments-vla]]: larger objects, one step, two cameras, SmolVLA.

## Resumen (ES)
50 episodios de ~100 s con tres cámaras, 60k pasos (~4 h). En evaluación el brazo sube y baja, nunca
agarra el peón; solo reacciona al segundo movimiento humano. Causas: tarea demasiado larga y con
esperas para ACT, piezas pequeñas, tablero movido entre episodios, cámaras oscuras/tapadas, y sin
episodios de evaluación guardados. Lección: una sola acción, objeto grande, escena fija, 2 cámaras.
