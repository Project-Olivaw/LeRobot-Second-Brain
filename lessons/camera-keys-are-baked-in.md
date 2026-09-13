# Camera keys and views are part of the dataset; indices are per machine

A dataset stores `observation.images.top`, `.wrist`, … The policy learns those views. At eval:

- The **keys** must be identical (`top`, `wrist`), or the policy cannot build its input.
- The **physical view** behind each key must be the same (same camera, mount, angle), or the
  policy sees a different world.
- The **index/port** (`0`, `2`, `/dev/tty…`) is *not* stored — it is machine-specific and lives
  in `machines/<machine>.env`. Moving the arm + cameras to the MacBook is fine as long as the same
  camera ends up under the same key.

Answering the July question "do I have to keep it plugged in for 12 h?": no. The training reads the
recorded videos; cameras only matter again at eval.

Related: [[cameras]], [[04-find-cameras]].

## Resumen (ES)

Las claves de cámara (`top`, `wrist`) y sus vistas viven en el dataset; los índices/puertos son de cada máquina y van en el `.env`.
