# 10 — Evaluate a policy on the real arm

Two ways. Both need the **same camera keys** as the training dataset ([[camera-keys-are-baked-in]]),
no leader arm, and a clear workspace. `--policy.path` accepts a local checkpoint folder or a Hub id.

## A. `lerobot-record` with a policy (works on 0.5.x; what the guides used)

Records the policy's rollouts into an `eval_` dataset, so you keep video evidence.

```bash
NAME=so100_medicament_box
POLICY=outputs/train/act_${NAME}/checkpoints/last/pretrained_model   # or ${HF_USER}/act_${NAME}
EVAL=eval_${NAME}_$(date +%Y%m%d_%H%M)                                # unique → no FileExistsError

$RUN lerobot-record \
    --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
    --robot.cameras="$CAMERAS" \
    --display_data=true \
    --dataset.repo_id=${DATASET_PREFIX}/${EVAL} \
    --dataset.single_task="Pick the medicament box and place it in the tray" \
    --dataset.num_episodes=10 \
    --dataset.episode_time_s=30 \
    --dataset.reset_time_s=10 \
    --dataset.push_to_hub=false \
    --policy.path=$POLICY
```

Wrapper: `tools/eval.sh <name> <policy_path> [episodes]`. Use → to end an episode early and ← to
mark a failed one for re-run; count successes by hand and write them in the experiment note.

## B. `lerobot-rollout` (0.5.2+; no recording, faster iteration)

```bash
$RUN lerobot-rollout \
    --strategy.type=base \
    --policy.path=$POLICY \
    --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
    --robot.cameras="$CAMERAS" \
    --task="Pick the medicament box and place it in the tray" \
    --duration=60
```

Other strategies: `episodic` (reset phases), `sentry` (continuous recording), `dagger`
(human-in-the-loop corrections). `--inference.type=rtc` smooths slow VLAs. Check `--help` on the installed version.

## Reading the result

- Arm bobs / hesitates / grabs air → the policy is uncertain; it is usually the data, not the
  optimizer. Compare with [[2026-07-13-fools-mate-act]] and [[act-limits-small-objects]].
- Systematic offset (always a few cm off in the same direction) → calibration changed since
  recording ([[calibration]]).
- Works only when the object is where it was in most demos → not enough pose variation ([[good-dataset-rules]]).
- Evaluate intermediate checkpoints too (`checkpoints/010000/pretrained_model`); the last one is not always the best.

## Resumen (ES)

Evaluar = `lerobot-record` con `--policy.path` y sin leader (graba un dataset `eval_*`), o
`lerobot-rollout` para iterar sin grabar. Mismas cámaras y claves que el dataset de entrenamiento.
Si el brazo duda o agarra aire, el problema suele ser el dataset, no el entrenamiento.
