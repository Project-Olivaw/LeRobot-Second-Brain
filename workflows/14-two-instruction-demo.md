# 14 — The two-instruction demo, end to end

The recipe for the talk's `demo-live` slide: **one policy, two objects, two sentences.** This is the
whole build, from empty table to stage.

Why this and not the cubes: it is the deck's actual promise, the box half is already recorded and
trained, and a language demo needs *two distinguishable objects* — not a hard manipulation task.
Stacking would add a precision problem on top of the language problem, and only the language problem
is what the talk is about. [[2026-09-cubes-stacking-vla]] stays as the stretch goal.

## The answer to "how do I interact with the language?"

**Not two scripts.** `lerobot-rollout --interactive=true` keeps the arm connected and the policy
warm and reads commands from stdin, so you change the instruction *by typing one line*:

```bash
source tools/env.sh macbook      # or desktop
tools/demo_live.sh               # uses $DEMO_POLICY and $DEMO_TASK1 from the profile
```

```
/start                                   # the robot does nothing until you type this
   … it picks the Complejo B and puts it on the board …
/subtask agarra el frasco de magnesio    # say it out loud while you type it
   … same weights, same process — it goes to the other object …
/reset                                   # back to the initial pose, hold
/stop
```

Also available: `/help`, `/vqa <question>` (ask the policy what it sees), `/autosteer`.

That single prompt *is* the demo. Reloading a 869 MB policy between instructions would put ~15 dead
seconds on stage and break the "same weights" claim visually. If you prefer a one-shot run per
instruction (e.g. for recording video), `tools/demo.sh "<instruction>" 60` does that instead.

## Step 1 — record the second dataset (the bottle)

The box dataset exists (`local/so100_medicament_box`, 50 episodes). You need its twin.

```bash
source tools/env.sh desktop
tools/lock_cameras.sh                     # exposure/WB — lessons/lock-exposure-and-white-balance.md
tools/record.sh so100_medicament_bottle "agarra el frasco de magnesio" 50 30 10
```

Rules that make the demo *work* rather than merely run:

- **Both objects are in frame in every episode, in both datasets.** In the bottle episodes the
  Complejo B box sits there untouched, and vice versa. If each dataset only ever contains its own
  object, the policy never has to read the sentence — and on stage, with both objects on the table,
  it will do whatever it likes. This is the single most important rule here.
  [[balance-the-instructions]]
- **Swap their positions between episodes** so "the left one" is not a shortcut for either.
- **Same scene as the box dataset**: same mat, same target, same cameras, same light
  ([[scene-kit]]). The two datasets get merged — any difference between them becomes a cue the
  policy can use instead of the language.
- **Same target for both** — put both objects on the chessboard/car. The instruction should select
  the *object*, not the destination.
- 5 spawn spots × 10 episodes, press → the moment it lands ([[good-dataset-rules]]).

### About the existing box dataset

Its task string is English (`Pick up the Complejo B medicament box and place it on the ESP32 car`)
and the target is the ESP32 car. Decide now and make both datasets match:

```bash
# Option A (recommended): relabel the box dataset to the Spanish sentence you will say on stage.
# Verified flags on 0.6.2: --operation.task_replacements (old->new), --operation.new_task (set all),
# --operation.episode_tasks (per episode).
uv run lerobot-edit-dataset --operation.type=modify_tasks \
  --repo_id=local/so100_medicament_box --new_repo_id=local/so100_medicament_box_es \
  --operation.task_replacements='{"Pick up the Complejo B medicament box and place it on the ESP32 car": "agarra el Complejo B"}'
```

Option B is re-recording the 50 box episodes in Spanish with the bottle present as a distractor.
It costs an hour and removes every doubt — if the box episodes have no bottle in frame, **do B**,
because relabelling cannot add the distractor the policy needs to see.

## Step 2 — merge and check the balance

```bash
tools/merge_tasks.sh so100_medicamentos so100_medicament_box_es so100_medicament_bottle
tools/tasks.sh so100_medicamentos        # must show ~50/50, two distinct instructions
```

## Step 3 — train

```bash
RENAME_MAP='{"observation.images.top": "observation.images.camera1",
             "observation.images.wrist": "observation.images.camera2"}' \
tools/train_smolvla.sh so100_medicamentos 30000
```

Measured reference from the single-task box run: **30k steps = 1 h 41 at 0.21 s/step, batch 8, 3 GB
VRAM**. Two instructions and twice the data: keep 30k as the floor, 40k if the evaluation is shaky.
Train ACT too (`tools/train_act.sh so100_medicamentos 20000`, ~1 h) — it is the fallback if SmolVLA
is too slow on the Mac ([[policy-inference-is-bursty]]).

## Step 4 — evaluate on the desktop, then publish

```bash
tools/eval.sh so100_medicamentos outputs/train/smolvla_so100_medicamentos/checkpoints/last/pretrained_model 10
```

The number that matters is not "did it grasp" — it is **"asked for the bottle, went to the bottle"**.
Score both instructions separately, 10 episodes each, with the objects swapped left/right half the
time. Then:

```bash
tools/push_hub.sh dataset so100_medicamentos
tools/push_hub.sh policy  smolvla_so100_medicamentos
```

## Step 5 — the Mac

```bash
source tools/env.sh macbook
tools/pull.sh policy smolvla_so100_medicamentos       # before leaving wifi
uv run python tools/bench_policy.py "$DEMO_POLICY" mps
tools/demo_live.sh
```

Set the stage instructions once in `machines/macbook.env` (`DEMO_TASK1`, `DEMO_TASK2`) so there is
nothing to remember under lights. Full checklist: [[vla-demo-plan]].

## How many episodes, really

| Plan | Episodes | Recording | Verdict |
|---|---|---|---|
| 50 + 50 | 100 | ~2 h | **Do this.** Matches HF's own SmolVLA recipe (5 positions × 10) and the deck's "~50 episodios" slide. |
| 100 + 100 | 200 | ~4 h | Only if 50/50 evaluates badly *and* the failure is "grabs the wrong object sometimes" rather than "never grasps". |

200 is the right number for the **four-instruction cube task**, where each instruction needs its own
50. For two instructions, 50/50 is the recipe — more episodes of the same thing mostly buys
robustness to object position, which is not what this demo is testing. Spend the extra hour on
making the two datasets *identical except for the object and the sentence* instead.

## Resumen (ES)

El demo de la charla: una política, dos objetos, dos frases. Se interactúa con
`tools/demo_live.sh` — un solo proceso, `/start` y luego `/subtask agarra el frasco de magnesio`
para cambiar la instrucción en vivo sin recargar nada. Falta grabar 50 episodios del frasco
(`agarra el frasco de magnesio`) **con la caja presente en cuadro**, y la caja debe tener el frasco
presente también: si cada dataset solo contiene su objeto, el modelo nunca aprende a leer la frase.
Fusionar, verificar 50/50 con `tools/tasks.sh`, entrenar 30k pasos (~1 h 41), evaluar contando
"pedí el frasco, fue al frasco", subir al Hub y bajar en la Mac. 50/50 es suficiente; 200 es para
la versión de cuatro instrucciones con cubos.
