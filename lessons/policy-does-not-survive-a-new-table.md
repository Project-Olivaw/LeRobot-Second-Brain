# A policy trained on one table does not survive a different table — move the scene, not the model

Question (2026-09-13): "if I change the table color, will the policy still work?" **No, not reliably.**
ACT and SmolVLA condition on the whole image. A table, cloth or lighting the dataset never contained
is out of distribution; the arm hesitates, hovers or reaches the wrong place. SmolVLA's pretraining
on many community SO-100 scenes makes it *less* brittle than ACT trained from scratch, but a
50-episode fine-tune on a single scene narrows it right back to that scene.

**Measured, 2026-09-29.** The rig was moved to another desk with different light "to simulate the
venue". The arm then reached and **bobbed up and down without ever closing on an object** — the
classic out-of-distribution signature ([[act-limits-small-objects]]). The cameras were not unplugged
and the keys were not swapped; only the framing and the background changed. Scored against the views
the dataset was recorded with:

| camera | before the move | after the move |
|---|---|---|
| `top`  | 0.70 | **-0.14** |
| `base` | 0.65 | **0.08** |

A negative correlation means the overhead camera had nothing in common with its recorded view: it
had ended up aimed mostly at a wall with the mat squeezed into the bottom of the frame, and `base`
had become a close-up of one bottle. Brightness was still at 0.68x (top) and 0.42x (base) of the
recorded scene even after "adding a bit more light".

So the thing that must travel is not "the mat and the objects" — it is the **camera geometry**:
where each lens sits relative to the mat and the arm. Mount the cameras to the same board as the mat
and the arm, never to the desk, so moving the desk cannot re-aim them. Then re-aim against the
references with `tools/aim_cameras.py`, which prints a live score while you nudge a camera.

What actually works, in order of cost:

1. **Make the scene portable.** A matte, uniform mat (distinct from the box) with the spawn area
   marked, the tray, and the camera mounts fixed relative to the arm base — ideally all on one board.
   If the cameras mostly see the mat, the table underneath stops mattering. This is the demo kit in
   [[vla-demo-plan]] and the same rule as [[dont-move-the-scene]].
2. **Lighting jitter in training** — `--dataset.image_transforms.enable=true` (brightness /
   contrast / saturation). Helps with venue light, does nothing for a new background or layout.
3. **Record the variation.** Only once the single-scene policy works: e.g. 25 episodes on mat A +
   25 on mat B, 2-3 lighting levels, same fixtures. More data, not more model.

Object positions generalise only inside the recorded spawn area; the same logic applies.

Related: [[good-dataset-rules]], [[2026-07-13-fools-mate-act]], [[camera-keys-are-baked-in]].

## Resumen (ES)

Cambiar la mesa rompe la política: mira toda la imagen. Solución: llevar la escena (tapete, bandeja,
soportes de cámara fijos al brazo), jitter de luz en el entrenamiento, y solo después grabar variación.
