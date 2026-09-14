# 09 — Train a VLA (SmolVLA first)

Target for the medicament project: a language-conditioned policy, fine-tuned from
`lerobot/smolvla_base` (SmolVLM2-500M backbone + flow-matching action expert, ~450M params).
It fits a 16 GB GPU at batch 4-8 with the vision encoder frozen, and an A10G/A100 on
[[hf-cloud-gpu]] for bigger batches. pi0 / pi0.5 need ≥ 24 GB and come later.

Flag names below were checked against `src/lerobot/policies/smolvla/configuration_smolvla.py`
in lerobot 0.5.2 (defaults: `chunk_size=50`, `n_action_steps=50`, `optimizer_lr=1e-4`,
`scheduler_warmup_steps=1000`, `scheduler_decay_steps=30000`, `freeze_vision_encoder=True`,
`train_expert_only=True`, images resized with padding to 512x512).

## Dataset requirements that differ from ACT

- The **task string is an input**. Write it as an instruction a person would give:
  `"Pick up the medicament box and place it in the tray"`. Vary phrasing only if you record
  several tasks; for one task keep it fixed. No colons/apostrophes ([[single-task-no-colons]]).
- Multi-task is where VLAs shine: record boxes and bottles as **separate datasets with distinct
  task strings**, then merge (`lerobot-edit-dataset`) or pass a list to `--dataset.repo_id` if the
  installed version supports it — check `--help`.
- 2 cameras (top + wrist) at 640x480 is fine; SmolVLA resizes internally. Camera keys still must match at eval.
- Install extras: `uv sync --locked --extra feetech --extra smolvla` (desktop, 0.5.2) — on 0.6.x also `--extra core_scripts --extra training` / `pip install 'lerobot[smolvla]'`.

## Fine-tune on the desktop (16 GB)

```bash
NAME=so100_medicament_box
JOB=smolvla_${NAME}

$RUN lerobot-train \
    --policy.path=lerobot/smolvla_base \
    --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
    --output_dir=outputs/train/${JOB} \
    --job_name=${JOB} \
    --policy.device=$DEVICE \
    --batch_size=8 --num_workers=$NUM_WORKERS \
    --steps=20000 \
    --policy.scheduler_decay_steps=20000 \
    --save_freq=5000 \
    --wandb.enable=false --policy.push_to_hub=false
```

Wrapper: `tools/train_smolvla.sh <name> [steps]` (add `--jobs` to print the HF Jobs form).

Notes:
- `--policy.path` (pretrained) instead of `--policy.type=smolvla` (from scratch). Do not fine-tune from scratch.
- Scale `--policy.scheduler_decay_steps` to `--steps`; the default 30k keeps the LR at peak on short runs.
- For a real quality jump on a specialised task, unfreeze the vision encoder — more VRAM, slower:
  `--policy.freeze_vision_encoder=false --policy.train_expert_only=false` (batch 4 on 16 GB).
- Train loss plateau → stop. 20k steps on 50 episodes is a reasonable first run; expect ~1-2 s/step on the 5060 Ti with the encoder frozen (measure `updt_s`).
- **HF's own numbers** (`docs/source/smolvla.mdx`, 0.6.2): 20k steps ≈ **4 h on one A100** at batch 64 (~0.7 s/step);
  their SO-100 pick-place dataset is **50 episodes = 5 object positions × 10 repeats**, and "25 episodes was
  not enough, leading to bad performance". Budget accordingly: a same-evening SmolVLA is not realistic —
  launch it on [[hf-cloud-gpu]] with `--save_checkpoint_to_hub=true` and evaluate the next day.

## Fine-tune on HF Jobs

The same command wrapped in `hf jobs run --flavor a10g-large … python -m lerobot.scripts.lerobot_train …`
with the dataset on the Hub and `--policy.repo_id=${HF_USER}/${JOB} --policy.push_to_hub=true`.
Full form in [[hf-cloud-gpu]].

## Inference

Same as [[10-evaluate]] with `--policy.path=outputs/train/${JOB}/checkpoints/last/pretrained_model`
(or the Hub id). SmolVLA is slower than ACT per inference; on the desktop it keeps up at 30 fps
with `n_action_steps=50`. On the Mac (`mps`) expect stutter — use RTC if the installed version has
`--inference.type=rtc` on `lerobot-rollout`, or reduce control fps.

## After SmolVLA

- pi0 / pi0.5 (`--policy.path=lerobot/pi0_base` etc.) on an A100 via HF Jobs, LoRA/PEFT flags if the
  version exposes them; see [[vla-roadmap-2026-08]] Phase 5.
- The reading list for the underlying math (flow matching, action chunking) is [[reading-list]].

## Resumen (ES)

Afinar `lerobot/smolvla_base` con `--policy.path`, batch 8 en el escritorio o A10G en HF Jobs,
`--steps=20000` y `--policy.scheduler_decay_steps=20000`. La frase de la tarea es una entrada del
modelo: escribirla como instrucción. Para más calidad, descongelar el encoder de visión.
