# 15 — The runbook (copy-paste, every phase)

Every command for the two-instruction medicament demo, in order, with nothing to think about at the
prompt. The *why* behind each choice lives in [[14-two-instruction-demo]]; this page is for doing.

Three cameras end to end: recording includes `base`, training maps `base` → `camera3`, and
eval/demo of a 3-camera policy passes all three. Both machine profiles expect three
([[identical-cameras-need-by-path]]).

Every phase starts the same way:

```bash
cd ~/GitHub/AnotherOnes/LeRobot-Second-Brain && source tools/env.sh desktop   # or: macbook
```

`DRY=1` in front of any `tools/…` command prints what it would run and changes nothing.

---

## Phase 0 — Before touching the arm (5 min, every session)

```bash
tools/lock_cameras.sh                    # fix exposure/white balance (Linux only)
uv run python tools/check_cameras.py     # one PNG per key + compares each view to its reference
tools/teleop.sh                          # three live feeds, leader drives follower, no offset
```

`check_cameras.py` is the gate, not a formality. It catches the failure a black-frame test cannot:
a camera that opens fine but is **the wrong one** — the wrist and base cameras are the same model with
the same serial, and on macOS a USB camera that fails to enumerate is silently replaced by the
built-in one ([[macos-builtin-camera-steals-a-slot]]).

Once per machine, with the scene built the way you recorded it:

```bash
uv run python tools/check_cameras.py --save-reference    # writes assets/camera-reference/*.png
```

Every later run scores each feed against those references: **≥0.65 pass, <0.65 warn, <0.35 fail**
(measured: same camera 0.99, swapped cameras ≤0.25, a different scene 0.01). Views swapped on Linux?
Exchange the two `CAM_*_PATH` lines in `machines/desktop.env`. On macOS, re-run `tools/mac_cameras.sh`
and fix the indices.

## Phase 1 — Record (2 halves × 100 episodes)

```bash
tools/record_medicamentos.sh frasco --plan    # print the schedule, touch nothing
tools/record_medicamentos.sh frasco 100       # block 1 (first run creates the dataset)
RESUME=1 tools/record_medicamentos.sh frasco 100    # blocks 2-10, once per block
tools/record_medicamentos.sh caja 100         # then the same ten blocks for the box
RESUME=1 tools/record_medicamentos.sh caja 100
```

### What `--plan` does

Nothing to the robot — it prints the recording schedule and exits. It exists because "record 100
episodes" is not a plan; **where the object goes** in those 100 is what decides whether the policy
generalises.

```
  #   spawn spot   target is on the   episodes
  1   front-left   LEFT               10
  2   front-right  LEFT               10
  3   centre       LEFT               10
  4   back-left    LEFT               10
  5   back-right   LEFT               10
  6   front-left   RIGHT              10
  ...
  10  back-right   RIGHT              10
```

A **block** = one row = 10 episodes with the target object at one spawn spot, on one side of the mat.
10 blocks × 10 = 100 per half. Two things vary across blocks: the object's position (5 marked spots)
and **which side the two objects sit on** — that swap is what stops the policy learning "always go
left" instead of reading the sentence. Within a block you vary only the object's yaw.

You are not meant to do 100 in one sitting. Record a block (10 episodes), press **Esc**, move the
objects to the next spot/side, and continue the same dataset with `RESUME=1`. That is the only reason
`RESUME=1` exists in the sequence — **not a retry, a continuation**. The number you pass is always the
**target for the whole dataset**; the script records only what is missing ([[resume-counts-this-run]]).

Keys: **→** end the episode now · **←** discard and redo · **Esc** stop the session.
Pausing mid-episode: press → (or ←) **first**, then Esc — Esc alone saves the truncated episode.

## Phase 2 — Merge and check the balance

```bash
tools/merge_tasks.sh so100_medicamentos so100_medicamento_caja so100_medicamento_frasco
tools/tasks.sh so100_medicamentos        # gate: two instructions, ≈50/50
```

Expected (2026-09-28): `200 episodes, 125517 frames, 2 task(s), 30 fps`, cameras `top/wrist/base`,
100 / 100. If it is not roughly 50/50, fix the data before training ([[balance-the-instructions]]).

## Phase 3 — Train (desktop, ~3 h 20)

```bash
tools/train_smolvla.sh so100_medicamentos 40000
```

The `--rename_map` (top/wrist/base → camera1/2/3) is derived from the dataset and saved into the
checkpoint, so nothing downstream has to remember it ([[smolvla-camera-slots]]).

In another terminal, two minutes in:

```bash
source tools/env.sh desktop
tools/eta.sh outputs/train/logs/smolvla_so100_medicamentos_*.log 40000
```

Budget: three cameras cost ~+50% per step over two. ~9-10 GB on disk for 200 episodes; the merged
dataset is 4.2 GB. Trust `updt_s`, not the estimate ([[updt-s-is-your-timer]]).

## Phase 4 — Evaluate on the desktop

```bash
POLICY=outputs/train/smolvla_so100_medicamentos/checkpoints/last/pretrained_model

tools/eval.sh so100_medicamentos $POLICY 0        # quick look, records nothing, 30 s
tools/eval.sh so100_medicamentos $POLICY 10       # 10 scored episodes, saved as local/rollout_…
```

The number that matters is **"asked for the bottle, went to the bottle"** — score each instruction
separately, 10 episodes each, objects swapped left/right half the time. Write the counts into
[[2026-09-medicaments-vla]] as you go; a remembered score is not a result:

| Instruction | Objects | Went to the right object | Grasped it | Placed it on the board |
|---|---|---|---|---|
| `agarra el frasco de zinc` | bottle LEFT | /5 | /5 | /5 |
| `agarra el frasco de zinc` | bottle RIGHT | /5 | /5 | /5 |
| `agarra la caja de Complejo B` | box LEFT | /5 | /5 | /5 |
| `agarra la caja de Complejo B` | box RIGHT | /5 | /5 | /5 |

Three columns because they fail for different reasons: *wrong object* is a language problem (the data
was not balanced enough), *right object but no grasp* is a manipulation problem (more or cleaner
demonstrations), *grasped but not placed* is usually the episode cap or an occluded wrist view.

Rehearse the stage flow itself:

```bash
tools/demo_live.sh "agarra la caja de Complejo B"
#  /start
#  /subtask agarra el frasco de zinc     <- the demo: same weights, new sentence
#  /reset      /stop
```

## Phase 5 — Publish

```bash
tools/push_hub.sh dataset so100_medicamentos          # private by default
tools/push_hub.sh policy  smolvla_so100_medicamentos  # private by default
```

Done 2026-09-28, both **private**:
- dataset → `Youngermaster/so100_medicamentos` (200 episodes, 125,517 frames, 4.2 GB)
- policy  → `Youngermaster/smolvla_so100_medicamentos` (40k steps, loss 0.058, 869 MB)

The checkpoint carries `train_config.json`, so its camera map (top/wrist/base → camera1/2/3) travels
with it and the Mac needs no flags. To make either public for the talk:
`hf repo settings <user>/<name> --public` — and note that an accidental public release cannot be
taken back, which is why both default to private.

## Phase 6 — The MacBook (the rehearsal that counts)

```bash
cd ~/GitHub/AnotherOnes/LeRobot-Second-Brain && source tools/env.sh macbook
hf auth login                                   # once
tools/pull.sh policy smolvla_so100_medicamentos # BEFORE leaving wifi — it is ~900 MB
uv run python tools/check_cameras.py            # three cameras; indices shift on macOS
uv run python tools/bench_policy.py "$DEMO_POLICY" mps    # inference rate; < 10 Hz -> RTC
tools/demo_live.sh
```

**Count the feeds AND look at them.** Observed 2026-09-28 with two hubs: three cameras came up, but
they were the *built-in* camera, wrist and base — the USB overhead camera had not enumerated and the
indices shifted under it. `check_cameras.py` now fails on that
([[macos-builtin-camera-steals-a-slot]]). Plug the cameras in one at a time, then:

```bash
tools/mac_cameras.sh                     # which AVFoundation index is which, with PNGs
# fix CAM_TOP/CAM_WRIST/CAM_BASE indices in machines/macbook.env, then:
uv run python tools/check_cameras.py     # must pass all three against the references
```

Mac traps, all of them avoidable: Continuity Camera steals an AVFoundation index (turn it off),
arrow keys need Accessibility + Input Monitoring, arms and cameras belong on **separate** powered
hubs, and the policy needs all three cameras — a missing one stops the run
([[macbook-m3]], [[14-two-instruction-demo]]).

## Phase 7 — Moving the scene around the house (generalisation test)

The point of this phase is to find out what breaks *before* the venue does. Move the table, the mat
and the arm to a new room, rebuild the scene from the recording-day photo, and run:

```bash
source tools/env.sh desktop            # or macbook
uv run python tools/check_cameras.py   # compare the top PNG against the recording-day photo
tools/demo.sh "agarra el frasco de zinc" 60
tools/demo.sh "agarra la caja de Complejo B" 60
```

Change **one** thing at a time and write down the success rate in the experiment note:

| Variation | What it tests |
|---|---|
| Same room, lights off / curtains open | exposure and colour, the most common venue difference |
| Another room, same mat and same camera geometry | background beyond the mat |
| Mat rotated 90° relative to the arm | whether the policy uses the mat or the arm frame |
| Objects at positions *between* the 5 trained spots | interpolation |
| A third object on the mat as a distractor | language grounding vs "grab the nearest thing" |

Fixed in every variation: the arm's position relative to the mat, the camera mounts, and the
chessboard's place on the mat. If a run collapses, re-run `check_cameras.py` first — a camera that
moved in its mount explains more failures than the model does ([[scene-kit]],
[[policy-does-not-survive-a-new-table]]).

## If something breaks

| Symptom | Fix |
|---|---|
| `resume() requires an explicit 'root'` | already handled by `tools/record.sh` — [[resume-needs-dataset-root]] |
| A camera reads `MISSING` although it is plugged in | pin the USB port — [[identical-cameras-need-by-path]] |
| `Feature mismatch … Missing features: camera1/2/3` | the rename map — [[smolvla-camera-slots]] |
| Resume overshoots the target | pass the target, not the remainder — [[resume-counts-this-run]] |
| Anything else | [[troubleshooting]] |

## Resumen (ES)

Runbook copiable de todas las fases: preparación de cámaras (`lock_cameras.sh`, `check_cameras.py`,
`teleop.sh`), grabación en 10 bloques por mitad con `RESUME=1` (el número es el objetivo total, no lo
que falta), fusión y verificación 50/50, entrenamiento de 40k pasos (~3 h 20 con tres cámaras),
evaluación contando "pedí el frasco, fue al frasco", publicación en el Hub, ensayo en la Mac y, por
último, pruebas moviendo la escena por la casa cambiando **una sola variable** cada vez.
