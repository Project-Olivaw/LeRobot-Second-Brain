# 07 — Inspect and replay a dataset

Do this before training: it catches wrong camera keys, dark feeds, and bad episodes for free.

## Visualize (rerun)

```bash
$RUN lerobot-dataset-viz --repo-id=${DATASET_PREFIX}/${NAME}
# add --episode-index=N to jump to one episode
```

## Dataset facts without a UI

```bash
python3 -c "import json; d=json.load(open('$HOME/.cache/huggingface/lerobot/${DATASET_PREFIX}/${NAME}/meta/info.json')); print({k:d[k] for k in ['codebase_version','robot_type','total_episodes','total_frames','fps']}); print([k for k in d['features'] if 'image' in k])"
```

The existing datasets' `info.json` are copied in `assets/train_configs/dataset_*.info.json`.

## Replay an episode on the follower (no leader, no cameras)

Plays back the recorded actions. It is also the **fallback demo** if a policy fails on stage ([[vla-demo-plan]]).

```bash
$RUN lerobot-replay \
    --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
    --dataset.repo_id=${DATASET_PREFIX}/${NAME} \
    --dataset.episode=0
```

Clear the workspace first — the arm moves exactly as recorded regardless of what is in front of it.

## Edit (delete bad episodes, merge)

`lerobot-edit-dataset --help` (0.5.x) supports deleting episodes and merging datasets; check the
flags on the installed version before relying on it.

## Resumen (ES)

`lerobot-dataset-viz` para ver el dataset en rerun; `lerobot-replay` reproduce un episodio en el
follower (sirve de plan B en la charla). Revisar `meta/info.json` para confirmar cámaras y fps.
