# 08 — Train ACT (baseline)

ACT is the fast, low-memory baseline and still the best ROI for a **single-task grasp-and-place**.
Train it first even if the target is a VLA: it validates the dataset in under an hour.
The two existing runs are documented in [[2026-06-29-lego-skeleton-act]] and [[2026-07-13-fools-mate-act]].

```bash
NAME=so100_medicament_box
JOB=act_${NAME}

$RUN lerobot-train \
    --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
    --policy.type=act \
    --output_dir=outputs/train/${JOB} \
    --job_name=${JOB} \
    --policy.device=$DEVICE \
    --batch_size=$BATCH_SIZE --num_workers=$NUM_WORKERS \
    --steps=30000 --save_freq=5000 \
    --wandb.enable=false --policy.push_to_hub=false
```

Wrapper: `tools/train_act.sh <name> [steps] [save_freq]`.

## Profiles measured on the desktop (RTX 5060 Ti, fp32, 640x480)

| Cameras | steps | batch | workers | wall-clock | used for |
|---|---|---|---|---|---|
| 1 | 20 000 | 8 | 8 | ~26 min | Lego skeleton (pipeline test) |
| 3 | 60 000 | 8 | 8 | ~4 h 06 | Fool's mate (failed at eval — not a training problem) |
| 2 (planned) | 30 000 | 8-16 | 8 | ~1.5-2.5 h (est.) | medicaments baseline |

The trainer logs `updt_s`; after a minute compute `steps = budget_s / updt_s` ([[updt-s-is-your-timer]]).
More gradient steps buys more than a bigger batch for ACT; raise `--batch_size=16` only to use spare
VRAM, drop back on CUDA OOM. Add `--num_workers` if `nvidia-smi` shows < 80 % utilisation.

## Defaults that were used (from `assets/train_configs/*.train_config.json`)

`chunk_size=100`, `n_action_steps=100`, `vision_backbone=resnet18`, `dim_model=512`,
`n_encoder_layers=4`, `n_decoder_layers=1`, `use_vae=true`, `kl_weight=10`, `lr=1e-5`
(backbone too), `weight_decay=1e-4`, `dropout=0.1`, `temporal_ensemble_coeff=None`, `seed=1000`.
Inputs: `observation.state` + one `observation.images.<key>` per camera; output `action` (6).

`n_action_steps=100` at 30 fps = the policy commits to **3.3 s** of motion per inference and does not
look at the cameras in between. For reactive tasks set `--policy.n_action_steps=25` or enable
temporal ensembling (`--policy.temporal_ensemble_coeff=0.01` with `n_action_steps=1`).

## Housekeeping

- Training refuses to overwrite an existing `output_dir` (`FileExistsError`) — new name per run or delete ([[train-refuses-to-overwrite]]).
- Resume: `$RUN lerobot-train --config_path=outputs/train/${JOB}/checkpoints/last/pretrained_model/train_config.json --resume=true`.
- Checkpoints: `outputs/train/${JOB}/checkpoints/<step>/pretrained_model/` (+ `last` symlink). Evaluate any of them ([[10-evaluate]]).
- Cloud: same flags via [[hf-cloud-gpu]]. Mac: `DEVICE=mps` works but is slow; prefer the cloud.

## Resumen (ES)

ACT es la línea base rápida: `lerobot-train --policy.type=act` con batch 8 y 8 workers. En el
escritorio: ~26 min por 20k pasos con 1 cámara, ~4 h por 60k con 3. Usar `updt_s` para dimensionar.
`n_action_steps=100` significa 3.3 s de movimiento a ciegas; bajar a 25 para tareas reactivas.
