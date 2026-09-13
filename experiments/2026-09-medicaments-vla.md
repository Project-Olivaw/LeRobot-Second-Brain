# 2026-09 — Medicament boxes / bottles — SmolVLA (planned)

**Status:** planned
**Machine:** record on **macbook**, train on **hf-jobs** (desktop when available), demo on macbook
**lerobot version:** whatever is current at recording time — write it here

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

## Plan
1. Mac setup per [[macbook-m3]] (fill `machines/macbook.env`, copy calibration, Accessibility permission).
2. `tools/teleop.sh` — no offset, both feeds live; practice 10 runs.
3. `tools/record.sh so100_medicament_box "Pick up the medicament box and place it in the tray" 50 30 10`
   with `PUSH_TO_HUB=true` → `${HF_USER}/so100_medicament_box`.
4. **ACT baseline first** on HF Jobs (30k steps, `t4-small`/`a10g-small`) — [[08-train-act]]. If ACT
   cannot do it, the data is the problem; fix data before spending on SmolVLA.
5. SmolVLA fine-tune on HF Jobs (`a10g-large`, batch 32, 20k steps) — [[09-train-vla]].
6. Evaluate on the Mac with `tools/eval.sh` (10 episodes, object on a 3x3 grid + 1 unseen spot); write counts here.
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
Siguiente experimento: caja de medicamento (grande, contrastada) en una bandeja, escena fija, se
varía solo la posición del objeto, 2 cámaras, 50 episodios grabados en la Mac y subidos al Hub.
Primero ACT como línea base en HF Jobs, luego SmolVLA; después botella y multi-tarea con lenguaje.
