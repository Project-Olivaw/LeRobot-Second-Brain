# Size training runs from the logged updt_s, not from estimates

The trainer prints `updt_s` (seconds per update) and `smp/s` on every log line. After ~1 minute:
`steps = budget_seconds / updt_s`. Measured on the RTX 5060 Ti, ACT fp32, batch 8:
~0.08 s/step with one 640x480 camera, ~0.25 s/step with three.

GPU utilisation under ~80 % in `nvidia-smi -l 1` means the dataloader is the bottleneck → raise
`--num_workers`. Near 100 % with a sluggish desktop → lower workers to 6, not the batch.
CUDA OOM → lower `--batch_size` (16 → 12 → 8).

Related: [[08-train-act]], [[desktop-ubuntu]].

## Resumen (ES)

Usar `updt_s` del log para calcular cuántos pasos caben en el tiempo disponible: 1 cámara ≈ 0.08 s/paso, 3 cámaras ≈ 0.25 s/paso en la 5060 Ti.
