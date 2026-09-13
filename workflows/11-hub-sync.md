# 11 — Hub sync (moving datasets and policies between machines)

The Hugging Face Hub is the exchange layer: record anywhere → push → train anywhere → push →
run anywhere. Nothing in this repo pushes by default; every push below is explicit.

## Decision (2026-09-13)

The June/July datasets and ACT checkpoints **stay local on the desktop**. The next datasets
(medicaments, recorded on the MacBook) will be pushed from day one so HF Jobs can train them.

## Push a dataset already on disk

```bash
$RUN python - <<'EOF'
from lerobot.datasets.lerobot_dataset import LeRobotDataset
ds = LeRobotDataset("local/so100_medicament_box")          # reads ~/.cache/huggingface/lerobot/local/...
ds.push_to_hub(repo_id="HF_USER/so100_medicament_box", private=True)
EOF
```

Or record with `--dataset.repo_id=${HF_USER}/<name> --dataset.push_to_hub=true` and skip this step.
A `local/…` dataset can be re-pointed by copying its folder to
`~/.cache/huggingface/lerobot/${HF_USER}/<name>` and pushing from there; the repo_id inside
`meta/info.json` is not used for upload.

## Push a policy checkpoint

```bash
$RUN hf upload ${HF_USER}/act_so100_medicament_box \
    outputs/train/act_so100_medicament_box/checkpoints/last/pretrained_model
# intermediate: hf upload ${HF_USER}/act_so100_medicament_box_010000 outputs/train/.../checkpoints/010000/pretrained_model
```

Or train with `--policy.push_to_hub=true --policy.repo_id=${HF_USER}/<name>`. Wrapper: `tools/push_hub.sh`.

## Pull on another machine

- Dataset: nothing to do — `--dataset.repo_id=${HF_USER}/<name>` downloads to the cache on first use
  (do it **before** going offline: `$RUN python -c "from lerobot.datasets.lerobot_dataset import LeRobotDataset as D; D('${HF_USER}/<name>')"`).
- Policy: `--policy.path=${HF_USER}/<name>` downloads on first use; pre-download with
  `$RUN hf download ${HF_USER}/<name>`.
- Calibration: from this repo, not the Hub ([[calibration]]).

## Private vs public

Use `private=True` / `--dataset.private=true` while iterating; flip to public for the talk if you
want the audience to open the dataset viewer (`https://huggingface.co/spaces/lerobot/visualize_dataset`).

## Resumen (ES)

El Hub es el puente entre máquinas. Los datasets viejos se quedan locales; los nuevos se suben desde
la Mac (`--dataset.push_to_hub=true`). Un checkpoint se sube con `hf upload`. En otra máquina basta
usar `${HF_USER}/<nombre>` como repo_id o policy.path; descargar antes de quedarse sin internet.
