# A policy trained on one table does not survive a different table — move the scene, not the model

Question (2026-09-13): "if I change the table color, will the policy still work?" **No, not reliably.**
ACT and SmolVLA condition on the whole image. A table, cloth or lighting the dataset never contained
is out of distribution; the arm hesitates, hovers or reaches the wrong place. SmolVLA's pretraining
on many community SO-100 scenes makes it *less* brittle than ACT trained from scratch, but a
50-episode fine-tune on a single scene narrows it right back to that scene.

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
