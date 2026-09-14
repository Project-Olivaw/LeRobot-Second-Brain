# `git pull` in the lerobot checkout does not change a pip-installed conda env

Asked on 2026-09-13 22:00: "I did `git pull` in `~/GitHub/AnotherOnes/lerobot` and got a lot of changes —
should I delete and recreate the conda `lerobot` env?" No. The two are unrelated:

- `conda activate lerobot` (miniforge3) holds a **plain `pip install lerobot==0.5.1`** in its own
  `site-packages`. Teleop kept working after the pull precisely because nothing in that env moved.
- The checkout is consumed by the **uv venv** (`.venv`, editable install). *That* one follows the
  checkout, and its metadata goes stale until you run `uv sync --locked --extra …` again — that is what
  had to be done tonight (it still reported 0.5.2 while the tree was already at 0.6.2-dev).
- There was even a second `lerobot` conda env (miniconda3, 0.4.3, editable from `~/SO-arm/lerobot`)
  that the shell never activates. Check with `python -c "import lerobot; print(lerobot.__version__, lerobot.__file__)"`
  and `pip show lerobot | grep Editable` before trusting any "which version am I on" belief.

Rule: the version that records the dataset is the version that trains and evaluates it (0.6 writes
dataset format v3.0, unreadable by 0.5). Pick one runner per project and write it in `machines/*.env`
(`RUN="uv run"` for the medicaments project). Recreating a conda env at 22:00 is a way to lose the
recording window, not a fix.

Related: [[desktop-ubuntu]], [[lerobot-06-extras]], [[01-environment]], [[2026-09-medicaments-vla]].

## Resumen (ES)

Un `git pull` en el checkout no toca el conda `lerobot` (pip 0.5.1, independiente). Lo que sí sigue al
checkout es el venv de uv (editable), y hay que volver a hacer `uv sync` tras cada pull. Comprobar
versión y ruta con `lerobot.__file__`; grabar, entrenar y evaluar siempre con la misma versión.
