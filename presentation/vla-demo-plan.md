# VLA talk — live demo plan ("From Token to Torque", AI Medellín)

Slides repo: https://github.com/Youngermaster/VLA-introduction-slides (Slidev, ES/EN, `/practice` mode,
offline). The deck's title metaphor says "SO-101"; **the hardware on stage is an SO-100 pair** —
say "SO-ARM100 / SO-100" when pointing at the arm, or fix the wording in the deck.

## What the demo should show

1. **Teleoperation** (10 s): leader moves, follower mirrors — "this is how the data is collected".
2. **Policy rollout**: the arm picks the medicament box and places it in the tray on an instruction.
   With SmolVLA, say the instruction out loud as you type it: `Pick up the medicament box and place it in the tray`.
3. **Language conditioning** (if the bottle dataset is done): same scene, change the noun → different object.
4. **Fallback**: `lerobot-replay` of a recorded episode ([[07-inspect-replay]]) — identical motion, no
   inference. Keep it ready in a second terminal; the audience still sees the arm move.

## Machine on stage: MacBook Pro M3 ([[macbook-m3]])

How the policy gets here: trained on the desktop, pushed to the Hub, pulled on the Mac — the folder,
the version rule and what else must travel are in [[policy-travels-as-a-folder]]. The scene kit is not
optional: a new table breaks the policy ([[policy-does-not-survive-a-new-table]]).

Pre-flight (**a week before** for the `mps` dry run; the rest the day before, on Wi-Fi):
- [ ] Desktop and Mac on the same lerobot commit (experiment note records it).
- [ ] `machines/macbook.env` filled and committed (ports, camera indices).
- [ ] Calibration JSONs copied; `tools/teleop.sh` shows no offset.
- [ ] Policy pulled: `uv run hf download ${HF_USER}/<policy>`; dataset for replay pulled.
- [ ] Inference dry run with `tools/eval.sh` at the venue lighting if possible; measure loop rate.
- [ ] Terminal has Accessibility permission (arrow keys).
- [ ] rerun window arranged on the projector (camera feeds are a good visual).
- [ ] Scene kit: mat with spawn area, tray, box, bottle, wrist light, tape to fix everything.
- [ ] Power strip; the arms' PSU; USB-C hub with cameras and arms on separate ports.

Command cheat-sheet (after `source tools/env.sh macbook`):

```bash
tools/teleop.sh                                   # 1. teleop
tools/eval.sh so100_medicament_box ${HF_USER}/smolvla_so100_medicament_box 3   # 2. policy (records eval_*)
$RUN lerobot-replay --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
     --dataset.repo_id=${HF_USER}/so100_medicament_box --dataset.episode=0             # 4. fallback
```

## Story beats that come from this vault

- Data collection is the product: [[good-dataset-rules]] in one slide (fixed scene, vary the object, → promptly).
- Why the chess demo failed ([[2026-07-13-fools-mate-act]]) is a better teaching moment than a success:
  action chunking, averaging over inconsistent demos, small objects.
- ACT vs SmolVLA: same dataset, ACT = single-task baseline; VLA = pretrained VLM + language.
- Compute reality: 20k ACT steps ≈ 26 min on a 5060 Ti; SmolVLA fine-tune on an A10G via HF Jobs ([[hf-cloud-gpu]]).

## Risks

| Risk | Mitigation |
|---|---|
| Venue lighting differs from training | record 10 episodes at the venue in the morning and fine-tune? unrealistic — instead record the training set with 2-3 lighting levels, and bring the wrist light |
| Venue table / background differs | bring the mat + tray + camera mounts as one kit — [[policy-does-not-survive-a-new-table]] |
| USB / power glitch on stage | [[incorrect-status-packet]] checklist; spare cables; replay fallback |
| `mps` inference too slow | run ACT baseline instead of SmolVLA, or lower fps; test beforehand |
| Camera index shift on the Mac | probe at the venue; `.env` is a one-line fix |

## Resumen (ES)

Demo en la charla con la MacBook: teleoperación, luego la política recogiendo la caja de medicamento
con instrucción en lenguaje, y `lerobot-replay` como plan B. El hardware es SO-100 aunque el título
diga SO-101. Preparar todo el día anterior con Wi-Fi (modelo y dataset descargados, permisos, luz).
