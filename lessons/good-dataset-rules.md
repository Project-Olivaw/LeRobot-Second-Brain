# What makes a dataset the policy can actually learn from

Distilled from two runs and the LeRobot guide:

1. **One task, one motion.** Reach → grasp → place, ≤ 30 s. No waiting for humans mid-episode.
2. **Big, high-contrast object.** ≥ 5 cm, matte, distinct from the mat. Chess pieces failed.
3. **Fixed scene.** Cameras, mounts, tray, mat, light never move within a dataset ([[dont-move-the-scene]]).
4. **Vary the object pose** on a grid + random yaw across episodes; cover the whole spawn area.
5. **Consistent, smooth demos.** Practice with teleop first; same approach path; press ← on any wobble.
6. **50 episodes minimum**, 100-300 for robustness. Quality before count.
7. **Press → immediately** when placed ([[episode-time-is-a-cap]]).
8. **Two cameras**: fixed top + wrist, lit, MJPG 640x480@30 ([[cameras]]).
9. **Descriptive task string**, no `:`/`'` ([[single-task-no-colons]]) — VLAs read it.
10. **Inspect before training** ([[07-inspect-replay]]) and evaluate with counts, saving eval episodes.

Related: [[act-limits-small-objects]], [[2026-07-13-fools-mate-act]].

## Resumen (ES)

Una tarea corta, objeto grande y contrastado, escena fija, variar solo la posición del objeto, demos suaves, 50+ episodios, dos cámaras, → al terminar, revisar antes de entrenar.
