# 01 — Environment

Goal: a shell where `lerobot-*` commands work and the variables for this machine are loaded.

## Load the machine profile (every new terminal)

```bash
cd ~/GitHub/AnotherOnes/LeRobot-Second-Brain      # wherever this vault is cloned
source tools/env.sh desktop                        # or: macbook
echo $ROBOT_PORT $TELEOP_PORT $DEVICE               # sanity
```

`tools/env.sh` sources `machines/<name>.env` and `cd`s into `$LEROBOT_DIR`. All workflow commands
below are written as `$RUN lerobot-…`, where `$RUN` is `uv run` (default) or empty inside conda.

## Desktop

```bash
cd ~/GitHub/AnotherOnes/lerobot
uv sync --locked --extra feetech            # already done; re-run after git pull
uv run lerobot-find-port --help             # proves the CLI resolves
```

Or `conda activate lerobot` and set `RUN=""` — see [[desktop-ubuntu]] for the env zoo.

## MacBook

See the checklist in [[macbook-m3]] (clone, `uv sync --locked --extra feetech`, copy calibration, fill `machines/macbook.env`).

## Hugging Face login (only needed to push/pull from the Hub)

```bash
$RUN hf auth login                                   # paste a write token; stored in ~/.cache/huggingface/token
HF_USER=$($RUN hf auth whoami 2>/dev/null | sed -n 's/^user=//p'); echo "$HF_USER"
```

The `sed` parser is needed because `hf` ≥ 1.19 prints `user=<name>` — the `awk` one-liner in the
official docs returns empty ([[hf-whoami-format]]). The "git credential helper" warning is harmless.
Never paste a token into a note or a commit.

## Optional

- `uv run wandb login` if you want W&B charts (`--wandb.enable=true`). All runs so far used `false`.
- `nvidia-smi -l 1` in a second terminal while training on the desktop.

## Resumen (ES)

En cada terminal: `source tools/env.sh desktop|macbook`. En el escritorio se usa `uv run` dentro de
`~/GitHub/AnotherOnes/lerobot`. El login de HF solo hace falta para subir/bajar del Hub; el usuario
se obtiene con `hf auth whoami | sed -n 's/^user=//p'`.
