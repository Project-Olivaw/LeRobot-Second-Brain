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

## Step 1 — record BOTH halves fresh, in Spanish, with both objects in frame

Decided 2026-09-27: record both halves from scratch rather than relabel the old box dataset. The
June box episodes were recorded in English, aimed at the ESP32 car, and **without the bottle in
frame** — and relabelling cannot add a distractor that was never filmed. Recording both halves is
"Option B" below, applied to both objects, and it removes every doubt at once.

```bash
source tools/env.sh macbook              # or desktop
tools/record_medicamentos.sh frasco --plan    # read the spot/side schedule first
tools/record_medicamentos.sh frasco 100       # "agarra el frasco de magnesio"
tools/record_medicamentos.sh caja   100       # "agarra la caja de Complejo B"
```

`tools/record_medicamentos.sh` carries the task strings, refuses to start on the wrong lerobot
version, identifies both arms from their homing offsets ([[identify-arms-by-homing-offset]]),
pre-flights the cameras (`tools/check_cameras.py`), and prints the schedule:
**5 spawn spots x 2 sides x N repeats**, ten blocks. Record a block, press Esc, move the objects,
then continue the same dataset with `RESUME=1`. 100 episodes in one unbroken sitting is not a plan.

On Linux also run `tools/lock_cameras.sh` first (exposure/WB —
[[lock-exposure-and-white-balance]]); on macOS UVC exposure is not settable from the CLI, so fix the
room light instead and do not touch it between the two halves.

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

### About the existing box dataset (settled — kept, not used for this demo)

`local/so100_medicament_box` (50 episodes, English task, ESP32 car target, no bottle in frame) stays
on the desktop as the single-instruction ACT baseline and the `lerobot-replay` fallback. It is
**not** merged into the two-instruction dataset. For reference, the relabel path that was considered
and rejected:

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

### Recording on the MacBook instead of the desktop

Both are fine — the dataset is identical — but the Mac has three traps the desktop does not:

- **Camera indices are bare AVFoundation integers** with no `/dev/v4l/by-id` to pin them, and they
  shift when a camera, a hub or the **iPhone Continuity Camera** appears or disappears. Turn
  Continuity Camera off, and re-run `tools/mac_cameras.sh` after every replug
  ([[camera-indices-shift-on-replug]]). `tools/check_cameras.py` runs automatically before recording
  and fails loudly on a black or missing feed.
- **Arrow keys need Accessibility + Input Monitoring** for the terminal app, or episode control is
  silently dead ([[12-recording-keys]]).
- **`PUSH_TO_HUB=true` in `machines/macbook.env`**, so `hf auth login` must be done first — the
  recorder now checks this before the first episode instead of failing after the last one.

Arms and cameras on **separate** ports of a powered hub ([[usb-bandwidth-three-cams]]); the arms need
their own PSU.

## Step 2 — merge and check the balance

```bash
tools/merge_tasks.sh so100_medicamentos so100_medicamento_caja so100_medicamento_frasco
tools/tasks.sh so100_medicamentos        # must show ~50/50, two distinct instructions
```

`tools/tasks.sh` is the gate, not a formality: if it does not print two instructions at roughly
50/50, stop and fix the data ([[balance-the-instructions]]).

## Step 3 — train

```bash
RENAME_MAP='{"observation.images.top": "observation.images.camera1",
             "observation.images.wrist": "observation.images.camera2"}' \
tools/train_smolvla.sh so100_medicamentos 30000
```

Measured reference from the single-task box run: **30k steps = 1 h 41 at 0.21 s/step, batch 8, 3 GB
VRAM**. With 200 episodes and two instructions, budget **40k steps (~2 h 20)** and keep 30k as the
floor; scale `--policy.scheduler_decay_steps` with `--steps` either way.

**Do not train ACT on the merged dataset.** ACT has no tokenizer and never sees the instruction
(verified in 0.6.2), so with both objects in frame it averages the two target trajectories and
hovers — the Fool's mate failure, by construction ([[act-has-no-language-input]]). The stage
fallbacks are `lerobot-replay`, or an ACT trained on **one** half, which grabs the same object
whatever you say and therefore demonstrates manipulation, not language.

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
| 50 + 50 | 100 | ~2 h | The minimum that works. Matches HF's own SmolVLA recipe (5 positions × 10) and the deck's "~50 episodios" slide. |
| 100 + 100 | 200 | ~4 h | **Chosen 2026-09-27.** 10 blocks of 10 per half, recorded across sittings with `RESUME=1`. |

Recording 200 episodes costs roughly **twice the hours for a smaller gain than making the two halves
identical-except-the-object** — that framing still holds. It was chosen anyway because this dataset
has to survive a live audience, and the extra 100 buy robustness to object position and to the venue.
Two safeguards make it cheap to be wrong: after the **first 50 + 50** are on disk, merge a copy and
train 15k steps as a probe — if it already picks the right object, the remaining 100 episodes are
insurance rather than a prerequisite, and you learn that a day early.

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
Decisión del 2026-09-27: grabar **las dos mitades desde cero en español**, 100 + 100 episodios
(`tools/record_medicamentos.sh frasco|caja`), en bloques de 10 con `RESUME=1`, **siempre con los dos
objetos en cuadro** y cambiando de lado a mitad de camino. Fusionar, verificar 50/50 con
`tools/tasks.sh`, entrenar 40k pasos (~2 h 20), evaluar contando "pedí el frasco, fue al frasco",
subir al Hub y bajar en la Mac. **ACT no sirve aquí**: no lee la instrucción; el plan B es
`lerobot-replay` o un ACT de una sola mitad.
