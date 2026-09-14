# 2026-09 — Medicament boxes / bottles — SmolVLA (recording)

**Status:** **recording 2026-09-13 night** ("Complejo B" box → ESP32 car), ACT → SmolVLA overnight on the desktop, evaluate 2026-09-14
**Machine:** record on **desktop** (already set up), train on **desktop** overnight (HF Jobs as backup), demo on **macbook**
**lerobot version:** **0.6.2 @ `8c894413c`** on both machines (desktop `uv run`, verified 2026-09-13 22:15; Mac venv) — see "Version alignment" below

## Goal
Language-conditioned pick-and-place of medicament packaging: "pick up the medicament box and place
it on the ESP32 car" (and later "…the bottle…"). Success = object rests on the car's top plate, ≥ 7/10 evaluation
episodes with the object at unseen poses inside the training area. Demo for [[vla-demo-plan]].

## Task design (applies the Fool's mate lessons)

| Choice | Decision | Why |
|---|---|---|
| Objects | one **box** (≥ 5 cm side, matte, high-contrast label) first; bottle second dataset | large, graspable, distinct from background — [[act-limits-small-objects]] |
| Sub-tasks | single reach-grasp-place, ~10-20 s | no waiting segments — [[2026-07-13-fools-mate-act]] |
| Scene | fixed place target (the ESP32 car, parked; originally a tray), fixed mat with a marked "spawn area", fixed camera mounts, constant light | vary the object, never the fixtures — [[dont-move-the-scene]] |
| Variation | object position (grid over the spawn area) and yaw; 2-3 lighting levels only after the first policy works | generalisation without inconsistency — [[good-dataset-rules]] |
| Cameras | `top` + `wrist` (drop `base`), 640x480@30 MJPG; add a small light on the wrist | [[cameras]] |
| Episodes | 50 box → train → if OK, 50 bottle → merge → multi-task | VLA multi-task value |
| Task strings | `Pick up the Complejo B medicament box and place it on the ESP32 car` (box, 2026-09-13) / `Pick up the medicament bottle and place it on the ESP32 car` (later) | natural instruction, distinct nouns, no `:`/`'` |
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

### Version alignment — **done 2026-09-13 22:15 on the desktop**

```bash
# desktop
cd ~/GitHub/AnotherOnes/lerobot && git fetch && git checkout 8c894413c
uv sync --locked --extra core_scripts --extra feetech --extra smolvla --extra training
uv run lerobot-record --help | head -3          # sanity
```
Result: `uv run python -c "import lerobot"` → **0.6.2**, torch 2.11.0+cu128, bf16 matmul on the 5060 Ti
OK, every flag used by `tools/*.sh` present in `--help`, `lerobot/smolvla_base` pre-downloaded to the HF
cache, and a real connect to both arms + `top`/`wrist` cameras with the existing calibration files
succeeded. **Use `uv run` (`RUN="uv run"`, the default in `machines/desktop.env`) for record, train and
eval of this project.** The conda `lerobot` env the user typed `conda activate lerobot` into is a *pip*
install of 0.5.1 that `git pull` does not touch ([[conda-env-is-not-the-checkout]]) — fine for teleop
practice, wrong version for this dataset (0.6 writes dataset format v3.0, which 0.5 cannot read).

### 2026-09-13 22:00 — target changed: ESP32 car instead of tray

The box is **"Complejo B"** (red/white blister box) and the place target is the user's **ESP32 car**
(yellow-wheeled chassis, flat black top plate) parked at a fixed spot on the left of the `top` view.
Same task shape (single reach-grasp-place onto a flat surface), so every design decision above holds.

- Task string: `Pick up the Complejo B medicament box and place it on the ESP32 car`
- Dataset: `local/so100_medicament_box`, `top` + `wrist` at 640x480@30 MJPG (drop `base`).
- The car is a **fixture** for this dataset: same parking spot, same heading, wheels chocked or
  power off so it cannot roll when the box lands ([[dont-move-the-scene]]).
- Runner scripts (all read `machines/desktop.env`, `DRY=1` prints the command):
  - `tools/record_medicament_box.sh [episodes=50]` — pre-flight (version 0.6.x, ports, `/dev/video*`,
    no stale dataset folder), then `tools/record.sh`. `RESUME=1` appends.
  - `tools/overnight_medicament_box.sh [smolvla_steps=20000] [act_steps=10000]` — ACT 10k → SmolVLA 20k,
    checkpoints every 2500, logs in `outputs/train/logs/`, runs under `systemd-inhibit`, ACT failure
    does not stop SmolVLA. Start it detached: `nohup tools/overnight_medicament_box.sh >/dev/null 2>&1 &`.
  - `tools/eta.sh <log> 20000` — ETA from the latest `updt_s` ([[updt-s-is-your-timer]]).
- Time budget (measured 2-camera ACT ≈ 0.17 s/step → 10k ≈ 30 min; SmolVLA assumed ~1 s/step at
  batch 8 → 20k ≈ 5.5 h): recording 22:30–23:30, ACT until ~00:00, SmolVLA done by ~06:00; if
  `updt_s` is 1.5 s it ends ~08:30 — still before the evaluation window. Check `tools/eta.sh` after
  the first 200 steps and, if the ETA overshoots, let it run: the 2500-step checkpoints are the fallback.

### Recording layout (copies HF's recipe)

Mark **5 spawn spots** on the mat (4 corners + centre of the spawn area). **10 episodes per spot**,
random yaw each time, always the same approach path, press → the moment the box rests on the car.
Fixed car, fixed mat, fixed cameras, constant light ([[good-dataset-rules]]).

### Overnight command (desktop, after `source tools/env.sh desktop`)

Superseded by `tools/overnight_medicament_box.sh` (see the 22:00 entry above); the underlying commands are
`tools/train_act.sh`-style ACT (10k steps) followed by
`lerobot-train --policy.path=lerobot/smolvla_base --steps=20000 --policy.scheduler_decay_steps=20000 --save_freq=2500 …`.
Watch `updt_s` for the first 2 minutes ([[updt-s-is-your-timer]]); the 2500-step checkpoints are the safety net.
Push the chosen checkpoint to the Hub afterwards ([[11-hub-sync]]) so the Mac can pull it.

## Plan
1. ~~Mac setup~~ → **desktop** for recording and training this round; Mac setup continues in parallel
   ([[macbook-m3]]: fill `machines/macbook.env`, Accessibility permission).
2. ~~Version alignment~~ done (0.6.2 via `uv run`). `tools/teleop.sh` — no offset, both feeds live; practice 10 runs.
3. `tools/record_medicament_box.sh 50` — 5 spots × 10 (layout above), task string and cameras baked in.
   Inspect a few episodes before training ([[07-inspect-replay]]). Push to the Hub afterwards ([[11-hub-sync]]).
4. + 5. `nohup tools/overnight_medicament_box.sh >/dev/null 2>&1 &` — **ACT baseline first** (10k, ~30 min,
   [[08-train-act]]) then SmolVLA 20k ([[09-train-vla]]). If ACT cannot do it in the morning, the data is
   the problem; fix data before another SmolVLA run. HF Jobs `a10g-large` stays the backup.
6. Evaluate on the desktop first (`tools/eval.sh`, 10 episodes: the 5 trained spots + 5 unseen); write counts
   here. Then pull on the Mac and repeat 3 episodes on `mps` to measure the loop rate.
7. Repeat for the bottle; merge; evaluate with both instructions to show language conditioning.

## Dataset
| repo_id | episodes | frames | fps | size | where |
|---|---|---|---|---|---|
| `local/so100_medicament_box` (desktop) → `${HF_USER}/so100_medicament_box` | 50 planned | — | 30 | — | desktop cache, then Hub (private) |
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
Caja "Complejo B" colocada sobre el carro ESP32 (el carro es un fixture: no se mueve), escena fija, solo
varía la posición de la caja, 2 cámaras. 2026-09-13 noche: escritorio alineado a lerobot 0.6.2
(`uv run`, hardware probado), grabar 50 episodios (5 puntos × 10) con `tools/record_medicament_box.sh`,
encadenar ACT (10k) → SmolVLA (20k) con `tools/overnight_medicament_box.sh`, evaluar el 14 por la
mañana; la política viaja a la Mac por el Hub junto con la escena. Después botella.
