# 13 — The cross-machine loop (record → train → demo, on whichever machine is available)

The Hub is the transport. Nothing needs a USB stick: a policy is ~0.9 GB and a 200-episode dataset
is ~6 GB, against **100 GB of free private storage** on a free Hugging Face account (public repos
are "best-effort" — keep robot data private and it is simply free). `HF_USER=Youngermaster`.

```
  MacBook  ──record──►  Hub (dataset, private)  ──►  Desktop ──train──►  Hub (policy, private)
     ▲                                                                          │
     └──────────────────────────── pull & run the demo ◄────────────────────────┘
```

## The rule that makes it work

Three things must match on both machines, or the policy misbehaves in ways that look like a bad model:

1. **Same lerobot version** — 0.6.2 @ `8c894413c` on both today. 0.6 writes dataset format v3.0 that
   0.5 cannot read ([[conda-env-is-not-the-checkout]]).
2. **Same camera keys and views** — `top` / `wrist` / `base`. The *indices* differ per machine and
   are resolved locally; the keys travel inside the dataset ([[camera-keys-are-baked-in]]).
3. **Same scene** — mat, board, lighting. The policy does not survive a new table
   ([[policy-does-not-survive-a-new-table]]).

## A. Record on the MacBook, push

```bash
source tools/env.sh macbook          # PUSH_TO_HUB=true, DATASET_PREFIX=Youngermaster
uv run hf auth login                 # once
tools/find.sh                        # fill ports + camera indices in machines/macbook.env, commit
tools/teleop.sh                      # no offset, feeds live
tools/record.sh so100_cubes_red "agarra el cubo rojo y ponlo en el tablero" 50 40 15
```

Recording with `PUSH_TO_HUB=true` uploads at the end of the session. To push a dataset that already
exists locally: `tools/push_hub.sh dataset <name>`.

**Caveat:** macOS cannot lock camera exposure/white balance ([[lock-exposure-and-white-balance]]),
so datasets recorded on the Mac are less consistent than desktop ones. Prefer the desktop for
recording when it is available; use the Mac when it is not, and keep the light steady.

## B. Train on the desktop

```bash
source tools/env.sh desktop
tools/pull.sh dataset so100_cubes_red             # downloads into the HF cache
DATASET_PREFIX=$HF_USER tools/train_smolvla.sh so100_cubes 60000
tools/push_hub.sh policy smolvla_so100_cubes      # 869 MB, private
```

`DATASET_PREFIX=$HF_USER` points the trainer at the Hub copy instead of `local/`. Or train from
`local/` if the dataset was recorded on the desktop — same thing, no upload needed.

If the desktop is unavailable, the same command runs on [[hf-cloud-gpu]] (`hf jobs run`, paid).

## C. Pull and demo on the MacBook

```bash
source tools/env.sh macbook
tools/pull.sh policy smolvla_so100_cubes          # do this BEFORE leaving wifi
uv run python tools/bench_policy.py "$DEMO_POLICY" mps   # will it keep up? lessons/policy-inference-is-bursty.md
tools/demo.sh "agarra el cubo azul y ponlo en el tablero" 60
tools/demo.sh "pon el cubo rojo encima del azul" 60
```

`tools/demo.sh` records nothing and enables `--inference.type=rtc` by default. To evaluate properly
and keep video evidence, use `tools/eval.sh` instead ([[10-evaluate]]).

## What does *not* travel over the Hub

- **Calibration** — it travels in this repo (`assets/calibration/`), see [[calibration]].
- **Ports and camera indices** — per machine, in `machines/*.env`.
- **The scene** — bring the mat, the board and the cubes.

## Storage housekeeping

A full SmolVLA run directory is ~15 GB on disk, but only `checkpoints/<step>/pretrained_model`
(869 MB) is the policy; `training_state/` (394 MB per checkpoint) is only needed to resume. Push and
keep the `pretrained_model` folder; delete old runs once a policy is on the Hub.

## Resumen (ES)

El Hub es el transporte: 100 GB privados gratis, política ~0.9 GB, dataset 200 episodios ~6 GB — no
hace falta USB. Grabar (Mac o escritorio) → `push_hub.sh dataset` → entrenar en el escritorio →
`push_hub.sh policy` → `pull.sh policy` en la Mac antes de quedarse sin wifi → `tools/demo.sh`.
Deben coincidir versión de lerobot, claves de cámara y escena. La calibración viaja en este repo.
