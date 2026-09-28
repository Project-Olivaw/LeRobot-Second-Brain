# SmolVLA always has three camera slots — use them or leave them empty

`lerobot/smolvla_base` was pretrained with cameras named `camera1`, `camera2`, `camera3`, and
lerobot >= 0.6 refuses any other names unless you pass a `--rename_map`. The medicament run used:

```
--rename_map='{"observation.images.top": "observation.images.camera1",
               "observation.images.wrist": "observation.images.camera2"}'
```

The resulting policy's `config.json` still lists **three** image inputs — `camera3` exists and is
fed zeros at runtime. Two consequences:

1. **The same map must be used at eval.** `tools/eval.sh` and `tools/demo.sh` read it back out of
   the checkpoint's `train_config.json` automatically; only Hub ids without that file need `RENAME_MAP=`.
2. **Adding a third camera later is free architecturally** — record `base` as well and extend the
   map with `"observation.images.base": "observation.images.camera3"`. No config surgery, and the
   slot is already what the pretraining expects. This is why the cube task can use three cameras
   without changing the model.

Related: [[09-train-vla]], [[cameras]], [[camera-keys-are-baked-in]].

## Resumen (ES)

SmolVLA espera cámaras `camera1/2/3`; hay que pasar `--rename_map`. El tercer slot existe aunque no se use (se llena con ceros), así que añadir la cámara `base` como `camera3` no cuesta nada.
