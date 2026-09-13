# YYYY-MM-DD — <task> — <policy>

**Status:** planned | recording | training | evaluated — success/fail
**Machine:** desktop | macbook | hf-jobs · **lerobot version:** x.y.z

## Goal
One sentence: what the arm should do, and what "success" means (measurable).

## Setup
| Item | Value |
|---|---|
| Robot / ids | `so100_follower` `my_awesome_follower_arm` · `so100_leader` `my_awesome_leader_arm` |
| Cameras | keys + indices used (link the `.env` commit) |
| Calibration | date of the JSONs used |
| Scene | objects, fixtures, lighting, what varied between episodes |
| Task string | exact `single_task` |

## Dataset
| repo_id | episodes | frames | fps | size | where |
|---|---|---|---|---|---|

Recording notes (discarded takes, incidents).

## Training
Exact command (or link to `assets/train_configs/<file>`), wall-clock, `updt_s`, final loss.

## Evaluation
Protocol (episodes, object poses), success count, qualitative behaviour, checkpoint(s) tried.

## What we learned
- bullet → link to a `lessons/` note when it is general.

## Next
What to change in the next iteration.

## Resumen (ES)
2-4 líneas.
