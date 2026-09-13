# Machine: Hugging Face Jobs (cloud GPU)

Pay-per-second GPUs from Hugging Face, used when the desktop is unavailable or the model needs more
than 16 GB (pi0-class). Source of truth: the "Train using Hugging Face Jobs" section of
`docs/source/il_robots.mdx` in the lerobot checkout, and https://huggingface.co/docs/hub/jobs.
Verified against lerobot 0.5.2 docs on 2026-09-13 — re-check flags on newer releases.

## Prerequisites

- Dataset on the Hub: `<HF_USER>/<dataset>` (recorded with `--dataset.push_to_hub=true`, or pushed later — [[11-hub-sync]]).
- `hf auth login` on the machine that launches the job; a write token stored as the `HF_TOKEN` secret.
- A billing method on the HF account (Jobs are paid).

## Launch a training job

```bash
hf jobs run \
  --flavor a10g-small \
  --timeout 4h \
  --secrets HF_TOKEN \
  huggingface/lerobot-gpu:latest \
  -- \
  python -m lerobot.scripts.lerobot_train \
    --dataset.repo_id=${HF_USER}/${DATASET} \
    --policy.type=act \
    --steps=30000 \
    --batch_size=16 \
    --policy.device=cuda \
    --policy.repo_id=${HF_USER}/act_${DATASET} \
    --log_freq=100
```

SmolVLA variant (fine-tune from `lerobot/smolvla_base`) — see [[09-train-vla]] for the reasoning:

```bash
hf jobs run \
  --flavor a10g-large \
  --timeout 6h \
  --secrets HF_TOKEN \
  huggingface/lerobot-gpu:latest \
  -- \
  python -m lerobot.scripts.lerobot_train \
    --policy.path=lerobot/smolvla_base \
    --dataset.repo_id=${HF_USER}/${DATASET} \
    --batch_size=32 \
    --steps=20000 \
    --policy.scheduler_decay_steps=20000 \
    --policy.device=cuda \
    --policy.repo_id=${HF_USER}/smolvla_${DATASET} \
    --policy.push_to_hub=true \
    --save_freq=5000 \
    --log_freq=100
```

Wrapper: `tools/train_smolvla.sh --jobs <dataset>` prints/launches this.

## Choosing hardware

`hf jobs hardware` lists flavors and prices. Rules of thumb:

| Flavor | Use |
|---|---|
| `t4-small` | ACT on 1-2 cameras, cheapest; batch 8. |
| `a10g-small` / `a10g-large` (24 GB) | ACT batch 16-32, SmolVLA batch 16-32 with unfrozen vision. |
| `a100-large` (80 GB) | pi0 / pi0.5 fine-tune, or SmolVLA batch 64 fast. |

Set `--timeout` above the expected wall-clock (ACT 3 cams ≈ 0.25 s/step on a 5060 Ti; an A10G is
roughly 1.5-2x faster). The job dies at timeout without pushing the final checkpoint, so also set
`--save_freq` and `--policy.push_to_hub=true` so intermediate checkpoints land on the Hub.

## Monitor and retrieve

- https://huggingface.co/settings/jobs — logs and status. Scheduling can take a few minutes.
- The policy appears at `https://huggingface.co/<HF_USER>/<policy>`; use it anywhere with
  `--policy.path=<HF_USER>/<policy>` ([[10-evaluate]]).
- `hf jobs logs <job_id>` / `hf jobs cancel <job_id>` from the CLI.

## Alternatives if Jobs is not an option

- Google Colab / Kaggle notebooks with `pip install 'lerobot[smolvla]'` and the same `lerobot-train`
  command; mount the dataset from the Hub. Slower to set up, free tiers time out.
- A rented VM (Lambda, RunPod) using the `huggingface/lerobot-gpu` Docker image.

## Resumen (ES)

Para entrenar sin el escritorio: `hf jobs run --flavor a10g-small ... python -m lerobot.scripts.lerobot_train ...`
con el dataset ya en el Hub y `--policy.repo_id` para que el modelo quede en el Hub. Usar
`--save_freq` + `--policy.push_to_hub=true` para no perder checkpoints si el job muere por timeout.
