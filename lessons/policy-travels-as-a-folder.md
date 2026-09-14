# The trained policy is a folder; the Hub or a USB stick moves it, the version must match

Question (2026-09-13): "train on the desktop, run on the MacBook at the talk — do I copy it on a USB?"

A checkpoint is `outputs/train/<job>/checkpoints/last/pretrained_model/` — `config.json`,
`model.safetensors`, `train_config.json` (+ tokenizer/processor files for SmolVLA). Sizes: ACT ≈ 200 MB,
SmolVLA ≈ 1.8 GB. Two ways to move it ([[11-hub-sync]] has the commands):

- **Hub (preferred):** train with `--policy.push_to_hub=true --policy.repo_id=${HF_USER}/<name>`
  (0.6.x also has `--save_checkpoint_to_hub=true`, one tag per step). On the Mac use
  `--policy.path=${HF_USER}/<name>`; pre-download with `uv run hf download ${HF_USER}/<name>` before
  leaving Wi-Fi. Versioned, and HF Jobs can produce it directly.
- **USB:** copy `pretrained_model/` and pass `--policy.path=/absolute/path/pretrained_model`. Works;
  no history.

What must travel *with* it or inference fails or is off:

| Thing | Where it lives |
|---|---|
| Same **lerobot version** on both machines (checkpoint `config.json` fields drift between releases) | pin both checkouts to one commit — the experiment note records it |
| **Camera keys** `top` / `wrist` identical to training | `machines/*.env` — [[camera-keys-are-baked-in]] |
| **Calibration** JSONs | `assets/calibration/` in this repo — [[calibration]] |
| Mac **ports / camera indices** | `machines/macbook.env` (differ from the desktop) |
| **Scene kit** (mat, tray, mounts, light) | [[policy-does-not-survive-a-new-table]] |
| **Dataset** pulled, for the `lerobot-replay` fallback | `--dataset.repo_id` downloads on first use |

Then: `source tools/env.sh macbook && tools/eval.sh <dataset> ${HF_USER}/<policy> 3`.
**Dry-run on the Mac days before, not the night before**: SmolVLA on `mps` is unmeasured and may
stutter; ACT on `mps` is known fine and is the stage fallback ([[vla-demo-plan]]).

## Resumen (ES)

La política es una carpeta `pretrained_model/`. Se mueve por el Hub (`--policy.path=usuario/nombre`,
descargar antes de perder Wi-Fi) o por USB. Debe viajar con la misma versión de lerobot, las mismas
claves de cámara, la calibración, los puertos de la Mac y la escena. Ensayar en la Mac días antes.
