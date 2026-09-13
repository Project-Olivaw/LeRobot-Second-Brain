# ACT needs consistent, single-step demos; small objects and waiting phases break it

ACT predicts a chunk of 100 future actions (3.3 s at 30 fps) from one observation and executes
it open-loop (`n_action_steps=100` by default). It learns the *average* demonstrator behaviour for
each visual context. Consequences seen in [[2026-07-13-fools-mate-act]]:

- Long idle phases (waiting for the human) dominate the data; the reach becomes a rare event.
- Multi-modal demos (board shifted, different approach paths) average into a hover/bob.
- Millimetre grasps on small dark pieces at 640x480 are below what resnet18 features + 50 demos resolve.
- It does not "know" it failed; there is no feedback unless you record corrections (DAgger — `lerobot-rollout --strategy.type=dagger`).

What works: one continuous reach-grasp-place, object ≥ 5 cm, high contrast, ≤ 30 s, 50-100 demos,
object pose varied, everything else fixed. For reactive behaviour lower `n_action_steps` (e.g. 25)
or use temporal ensembling. This is not "ACT is bad" — it is the standard baseline and still the
best ROI for single-task grasp-and-place; VLAs add language and pretraining, not magic precision.

Related: [[good-dataset-rules]], [[dont-move-the-scene]], [[08-train-act]].

## Resumen (ES)

ACT ejecuta 3.3 s de acciones a ciegas y aprende el promedio de las demos: tareas largas con esperas, piezas pequeñas y demos inconsistentes producen un brazo que duda. Una acción, objeto grande, escena fija.
