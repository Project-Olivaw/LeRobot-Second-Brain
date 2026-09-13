# Vary the object pose, never the fixtures, cameras or board

During the Fool's mate recording the board was nudged between some episodes "so the arm could
adjust". Without a visual anchor tied to the target square, this creates demos where the same
image → different joint targets. The policy averages them and hovers.

Rule: within a dataset, keep cameras, mounts, tray/bin, mat, and lighting **fixed**. Vary only what
the policy must generalise over — the object's position and yaw inside a marked area. Add lighting
variation only after a first policy works. If a fixture must move, that is a new dataset.

Also: never move or re-aim a camera after recording; the policy will see a different world at eval.

Related: [[good-dataset-rules]], [[camera-keys-are-baked-in]].

## Resumen (ES)

Dentro de un dataset no mover cámaras, bandeja ni tablero; variar solo la posición del objeto.
