# 2026-09 — Medicament boxes / bottles — SmolVLA (planned)

**Status:** planned → **go (2026-09-13 evening)**: record on the desktop, train overnight, evaluate 2026-09-14
**Machine:** record on **desktop** (already set up), train on **desktop** overnight (HF Jobs as backup), demo on **macbook**
**lerobot version:** pin **both** checkouts to the Mac's commit `8c894413c` (0.6.2-dev, 2026-09-13) — see "Version alignment" below

## Goal
Language-conditioned pick-and-place of medicament packaging: "pick up the medicament box and place
it in the tray" (and later "…the bottle…"). Success = object ends inside the tray, ≥ 7/10 evaluation
episodes with the object at unseen poses inside the training area. Demo for [[vla-demo-plan]].

## Task design (applies the Fool's mate lessons)

| Choice | Decision | Why |
|---|---|---|
| Objects | one **box** (≥ 5 cm side, matte, high-contrast label) first; bottle second dataset | large, graspable, distinct from background — [[act-limits-small-objects]] |
| Sub-tasks | single reach-grasp-place, ~10-20 s | no waiting segments — [[2026-07-13-fools-mate-act]] |
| Scene | fixed tray, fixed mat with a marked "spawn area", fixed camera mounts, constant light | vary the object, never the fixtures — [[dont-move-the-scene]] |
| Variation | object position (grid over the spawn area) and yaw; 2-3 lighting levels only after the first policy works | generalisation without inconsistency — [[good-dataset-rules]] |
| Cameras | `top` + `wrist` (drop `base`), 640x480@30 MJPG; add a small light on the wrist | [[cameras]] |
| Episodes | 50 box → train → if OK, 50 bottle → merge → multi-task | VLA multi-task value |
| Task strings | `Pick up the medicament box and place it in the tray` / `Pick up the medicament bottle and place it in the tray` | natural instruction, distinct nouns, no `:`/`'` |
| Episode cap | `episode_time_s=30`, `reset_time_s=10` | press → at placement |

## 2026-09-13 20:15 — go/no-go analysis (Sunday evening, MacBook)

Question: "10 episodes, SmolVLA working by 22:30, on the MacBook?" **No** — see [[no-same-evening-vla]]
for the numbers. What was found and decided:

- The Mac had never been set up (no venv, no `hf`, empty calibration cache, `TODO` ports). Fixed the
  same evening: venv installed (0.6.2-dev, torch 2.11, `mps` on, `hf` 1.30 inside), calibration copied,
  vault paths/install lines corrected ([[lerobot-06-extras]]). Ports and camera indices still `TODO`.
- HF's own recipe for this exact task: **50 episodes = 5 object positions × 10 repeats**, 25 not enough,
  20k steps ≈ 4 h on an A100 (`docs/source/smolvla.mdx`).
- ZeroGPU minutes ≠ HF Jobs; Jobs need prepaid credit (`a10g-small` $1/h).
- **Decision:** record the 50 episodes on the **desktop** (everything already works there), chain
  **ACT 10k steps (~30 min) → SmolVLA overnight** on the 5060 Ti, evaluate on 2026-09-14 morning; the
  daytime window is for evaluation and a second iteration, not for the first training run.
- Table/background change breaks the policy → the scene kit travels ([[policy-does-not-survive-a-new-table]]).
- Desktop → Mac transfer = Hub or USB folder + same lerobot commit + Mac env + scene ([[policy-travels-as-a-folder]]).

### Version alignment (do before recording)

```bash
# desktop
cd ~/GitHub/AnotherOnes/lerobot && git fetch && git checkout 8c894413c
uv sync --locked --extra core_scripts --extra feetech --extra smolvla --extra training
uv run lerobot-record --help | head -3          # sanity
```
0.6.2 + torch 2.11 cu128 is already proven on this GPU in `~/personalProjects/vlaLerobot`. If the sync
fails, do **not** fight it at night: record/train on 0.5.2 and pin the Mac to `v0.5.2` instead — what
matters is that both machines run the same commit when the checkpoint is loaded.

### Recording layout (copies HF's recipe)

Mark **5 spawn spots** on the mat (4 corners + centre of the spawn area). **10 episodes per spot**,
random yaw each time, always the same approach path, press → the moment the box is in the tray.
Fixed tray, fixed mat, fixed cameras, constant light ([[good-dataset-rules]]).

### Overnight command (desktop, after `source tools/env.sh desktop`)

```bash
NAME=so100_medicament_box
tools/train_act.sh $NAME 10000 2000 \
  && $RUN lerobot-train \
       --policy.path=lerobot/smolvla_base \
       --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
       --output_dir=outputs/train/smolvla_${NAME} --job_name=smolvla_${NAME} \
       --policy.device=cuda --batch_size=8 --num_workers=$NUM_WORKERS \
       --steps=30000 --policy.scheduler_decay_steps=30000 --save_freq=5000 \
       --wandb.enable=false --policy.push_to_hub=false
```
Watch `updt_s` for the first 2 minutes and resize `--steps` to the hours available
([[updt-s-is-your-timer]]); intermediate checkpoints every 5k are the safety net.
Push the chosen checkpoint to the Hub afterwards ([[11-hub-sync]]) so the Mac can pull it.

## Plan
1. ~~Mac setup~~ → **desktop** for recording and training this round; Mac setup continues in parallel
   ([[macbook-m3]]: fill `machines/macbook.env`, Accessibility permission).
2. Version alignment (above). `tools/teleop.sh` — no offset, both feeds live; practice 10 runs.
3. `tools/record.sh so100_medicament_box "Pick up the medicament box and place it in the tray" 50 30 10`
   — 5 spots × 10 (layout above). Push to the Hub afterwards (or set `PUSH_TO_HUB=true`).
4. **ACT baseline first** (10k steps, ~30 min) — [[08-train-act]]. If ACT cannot do it, the data is the
   problem; fix data before spending hours on SmolVLA.
5. SmolVLA fine-tune overnight on the desktop (command above); HF Jobs `a10g-large` as backup — [[09-train-vla]].
6. Evaluate on the desktop first (`tools/eval.sh`, 10 episodes: the 5 trained spots + 5 unseen); write counts
   here. Then pull on the Mac and repeat 3 episodes on `mps` to measure the loop rate.
7. Repeat for the bottle; merge; evaluate with both instructions to show language conditioning.

## Dataset
| repo_id | episodes | frames | fps | size | where |
|---|---|---|---|---|---|
| `${HF_USER}/so100_medicament_box` | — | — | 30 | — | Hub (private) |
| `${HF_USER}/so100_medicament_bottle` | — | — | 30 | — | Hub (private) |

## Training
(fill: job id, flavor, steps, wall-clock, loss)

## Evaluation
(fill: grid results per checkpoint, ACT vs SmolVLA)

## Open questions
- HF username to use (Youngermaster vs jayounghoyos) — set `HF_USER` in `machines/macbook.env`.
- Whether the installed lerobot accepts a list in `--dataset.repo_id` for multi-dataset training, or
  whether `lerobot-edit-dataset` merge is needed.
- SmolVLA inference rate on `mps`; if < 10 Hz, run the demo from the ACT baseline or use RTC.

## Resumen (ES)
Caja de medicamento (grande, contrastada) en una bandeja, escena fija, solo varía la posición del
objeto, 2 cámaras. Decisión del 2026-09-13: grabar 50 episodios (5 puntos × 10) en el **escritorio**,
encadenar ACT (10k) → SmolVLA de noche en la 5060 Ti, evaluar el 14 por la mañana; ambas máquinas en
el mismo commit de lerobot; la política viaja a la Mac por el Hub junto con la escena. Después botella.
