# 2026-09 — Red/blue cubes, language-conditioned pick and stack — SmolVLA, 3 cameras (planned)

**Status:** planned (designed 2026-09-27)
**Machine:** record + train on **desktop**, demo on **macbook**
**lerobot version:** 0.6.2 @ `8c894413c` (both machines)

## First, a correction about the deck

In `VLA-introduction-slides`, **"agarra el rojo, encima" is not the live demo** — it is dialogue in
the *animated* `act-vs-vla` scene (`locales/scenes/actVsVla.yml`, `scenes/actVsVla.ts`), used to
tell the story of an ACT policy that grabbed the red cube when asked for the blue one.

The **live** demo (slide `demo-live`, `monologue/es.md` §demo-live) is two medicine instructions:

- `agarra el Complejo B`
- `agarra el frasco de zinc`

…with the punchline *"No hay un if en ninguna parte."* That is what
[[2026-09-medicaments-vla]] is building, and it is the lower-risk path to the same point.

So there are two options, and they are not exclusive:

| | What it proves on stage | Cost | Risk |
|---|---|---|---|
| **A. Medicines (as written)** | Same weights, only the sentence changes | 1 more dataset (zinc bottle, 50 eps) | Low — half of it is already trained |
| **B. Cubes + stacking (this note)** | The same, *plus* a composed two-object action | 200 episodes, ~6 h training | Medium-high — stacking is a precision task |

**Recommendation: do A first** (it is the deck's actual promise and the bottle dataset is 50
episodes away), then B as the upgrade if there is time. B's Phase 1 alone (cubes, no stacking)
already replaces A if you prefer cubes on stage — cubes are visually clearer from the back of a room
than a pill box.

## Goal (option B)

One policy, four instructions, 3 cameras:

| # | Instruction (ES) | Instruction (EN) | Start state | Success |
|---|---|---|---|---|
| 1 | `agarra el cubo rojo y ponlo en el tablero` | `pick up the red cube and put it on the board` | both cubes on the mat | red cube on the board, blue untouched |
| 2 | `agarra el cubo azul y ponlo en el tablero` | `pick up the blue cube and put it on the board` | both cubes on the mat | blue on the board, red untouched |
| 3 | `pon el cubo rojo encima del azul` | `put the red cube on top of the blue one` | blue already on the board, red on the mat | red resting on blue, stack standing |
| 4 | `pon el cubo azul encima del rojo` | `put the blue cube on top of the red one` | red already on the board, blue on the mat | blue resting on red, stack standing |

Stage sequence: run 2 ("el azul" → it goes to the blue one), then 3 ("ahora el rojo, encima").
That is the animated scene, made real.

## Why this design (each choice buys something)

- **A distractor cube is always in frame for 1 and 2.** If only the named cube were present, the
  policy could ignore the sentence entirely and the demo would prove nothing. This is the single
  most important design decision here — it is exactly the failure the deck's anecdote describes.
  [[balance-the-instructions]]
- **Both stack directions (3 and 4).** With only "red on blue", the policy learns *stack = move the
  red one* instead of reading the sentence. Symmetry forces it to parse the instruction.
- **The chessboard as the place target.** A good call: high-frequency black/white texture is a
  strong, unambiguous visual anchor, far better than a plain square. Treat it as a **fixture** —
  taped down, never moved within a dataset ([[dont-move-the-scene]]).
- **Instructions differ early and by content words** (`agarra el cubo rojo` vs `pon el cubo rojo
  encima del azul`), not by a suffix. [[balance-the-instructions]]
- **Three cameras** — `top` (which cube is where), `wrist` (grasp alignment), `base` (the side view
  that shows *height*, which is what stacking actually needs). SmolVLA already has a `camera3` slot,
  so this costs nothing architecturally: extend the rename map with
  `"observation.images.base": "observation.images.camera3"` ([[smolvla-camera-slots]]).
  The `base` camera was dark and arm-occluded in the Fool's mate run — **reposition and light it
  before recording**, and check the probe image ([[cameras]]).
- **Cubes ≥ 5 cm, matte.** Stacking tolerance is roughly ±1 cm on a 5 cm cube; smaller cubes make
  this a precision task the arm's repeatability cannot support. [[act-limits-small-objects]]

## Episode plan — 200 episodes, four datasets

`lerobot-record` writes one instruction per run, so record one dataset per instruction and merge
them with `tools/merge_tasks.sh` ([[06-record]]).

| Dataset | Instruction | Episodes | Layout |
|---|---|---|---|
| `so100_cubes_red` | 1 | 50 | 5 red spots × 10; blue distractor moved every episode |
| `so100_cubes_blue` | 2 | 50 | 5 blue spots × 10; red distractor moved every episode |
| `so100_cubes_stack_red_on_blue` | 3 | 50 | blue pre-placed on the board (2 board positions), red on 5 spots × 10 |
| `so100_cubes_stack_blue_on_red` | 4 | 50 | mirror of the above |
| **merged** `so100_cubes` | all four | **200** | 25% each — verify with `tools/tasks.sh so100_cubes` |

Why 50 each and not fewer: HF's own SmolVLA recipe for an SO-100 pick-and-place is **50 episodes =
5 positions × 10 repeats**, and states that 25 was not enough (`docs/source/smolvla.mdx`). Four
instructions → 4 × 50. Your instinct of ~200 is right.

**Phase it**, so you always have something that works:

1. **Phase 1 (100 eps, ~2.5 h recording):** datasets 1 and 2 only. Train, evaluate. This alone is a
   complete demo — "same weights, only the sentence changes".
2. **Phase 2 (+100 eps):** add 3 and 4, merge all four, retrain. Stacking is the stretch.

Do not skip Phase 1's evaluation. If the policy cannot tell red from blue with 100 episodes, adding
stacking data will not fix it — the problem would be the scene, the light, or the demos.

Episode timing: `episode_time_s=40` (cap), `reset_time_s=15` (repositioning two cubes takes longer
than one box). Expected real episode length 15-25 s. Press → the moment the cube settles
([[episode-time-is-a-cap]]).

## Recording commands (desktop, after `source tools/env.sh desktop`)

```bash
tools/lock_cameras.sh                     # lock exposure/WB first — lessons/lock-exposure-and-white-balance.md
CAMERAS="$CAMERAS_THREE"                  # top + wrist + base for this project

tools/record.sh so100_cubes_red  "agarra el cubo rojo y ponlo en el tablero"   50 40 15
tools/record.sh so100_cubes_blue "agarra el cubo azul y ponlo en el tablero"   50 40 15
tools/record.sh so100_cubes_stack_red_on_blue "pon el cubo rojo encima del azul" 50 40 15
tools/record.sh so100_cubes_stack_blue_on_red "pon el cubo azul encima del rojo" 50 40 15

tools/merge_tasks.sh so100_cubes so100_cubes_red so100_cubes_blue \
                     so100_cubes_stack_red_on_blue so100_cubes_stack_blue_on_red
tools/tasks.sh so100_cubes                # must show ~25% per instruction
```

Spanish or English? Pick one and keep it — the instruction is a model input, and SmolVLA's
pretraining is English-heavy, so English generalises slightly better while Spanish matches the talk.
Safest: **record in Spanish** (what you will say on stage) and accept that the model only knows
those exact four sentences. Do not mix languages inside one dataset.

## Training (desktop, overnight)

```bash
RENAME_MAP='{"observation.images.top": "observation.images.camera1",
             "observation.images.wrist": "observation.images.camera2",
             "observation.images.base": "observation.images.camera3"}' \
tools/overnight_medicament_box.sh 60000 15000    # reads NAME from the script — copy it for cubes
```

Budget, extrapolated from the measured medicament run (2 cameras, 0.21 s/step at batch 8):

| Run | steps | est. s/step | est. wall-clock |
|---|---|---|---|
| ACT baseline (3 cams) | 15 000 | ~0.25 | ~1 h |
| SmolVLA (3 cams, 4 tasks) | 60 000 | ~0.30 | **~5 h** |

More instructions need more steps than the 30k the single-task medicament policy used. Checkpoints
every 2 500 are the safety net. Confirm with `tools/eta.sh` after 200 steps ([[updt-s-is-your-timer]]).

## Disk

| Item | Estimate | Basis |
|---|---|---|
| 200 episodes × 3 cameras | **~6 GB** | measured 24 MB/ep at 2 cams / 26 s |
| ACT run (all checkpoints) | ~5 GB | measured 4.7 GB for the medicament ACT |
| SmolVLA run (all checkpoints) | ~15-20 GB | measured 15 GB for 13 checkpoints; each is 869 MB model + 394 MB optimizer state |
| **Total** | **~30 GB** | 165 GB free today |

Free 3.3 GB first by deleting the two 0-episode Fool's mate eval folders
(`~/.cache/huggingface/lerobot/local/eval_so100_fools_mate*`), and consider `--save_freq=5000` to
halve the checkpoint count.

## Evaluation protocol

10 episodes per instruction (40 total) with `tools/eval.sh`, at 5 trained spots + 5 unseen ones.
Record: grasped the *named* cube (the language test), completed the placement, stack stayed standing.
The number that matters for the talk is **"asked for blue, went to blue"** — that is the claim.

## Resumen (ES)

"Agarra el rojo, encima" es una escena *animada* del deck, no el demo en vivo (el demo son los dos
medicamentos). Si se quiere hacer real con cubos: 4 instrucciones × 50 episodios = 200, en cuatro
datasets que luego se fusionan; siempre con el cubo distractor en cámara (si no, el modelo ignora la
frase) y con las dos direcciones de apilado (si no, aprende "apilar = mover el rojo"). Tablero como
objetivo fijo, cubos ≥ 5 cm, 3 cámaras (`base` da la altura, clave para apilar). Fase 1: solo rojo y
azul (100 episodios) — eso ya demuestra el punto de la charla. Fase 2: apilado. ~6 GB de datos,
~5 h de entrenamiento, ~30 GB de disco.
