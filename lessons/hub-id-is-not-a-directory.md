# A Hub id is not a directory — the demo scripts silently dropped the rename_map

`machines/macbook.env` sets `DEMO_POLICY=Youngermaster/smolvla_so100_medicamentos` (a Hub id, which
is the right thing — it works offline once cached). But `demo_live.sh`, `demo.sh` and `eval.sh` all
read the training rename map like this:

```bash
if [ -f "$POLICY/train_config.json" ]; then ...     # false for a Hub id!
```

For a Hub id that test is false, so no `--rename_map` was passed. And `lerobot-rollout` does not
then fall back to the map baked into the checkpoint — it **overwrites it**:

```python
# src/lerobot/rollout/context.py
preprocessor_overrides={
    "device_processor": {"device": cfg.device},
    "rename_observations_processor": {"rename_map": cfg.rename_map},   # empty -> map erased
}
```

Mercifully it fails loudly rather than driving the arm on scrambled inputs — the same file validates
first and raises `Visual feature mismatch between policy and robot hardware. Policy expects:
{observation.images.camera1, camera2, camera3} Robot provides: {observation.images.top, wrist, base}`.

**Fix:** `policy_dir()` in `tools/_common.sh` resolves a Hub id to its cached snapshot directory
(`snapshot_download(..., local_files_only=True)`), so a Hub id behaves exactly like a local path —
both for the rename map and for `cameras_for_policy`. All three scripts use it now.

Two traps inside the fix, both hit while writing it:

- **The map is at the TOP level of `train_config.json`**, not under `dataset`. `cfg.rename_map`, not
  `cfg.dataset.rename_map`.
- **`policy_dir` must use the venv python (`$RUN python`), not `python3`.** `huggingface_hub` is only
  installed in the lerobot venv; the system python3 raises `ModuleNotFoundError`, the `except`
  swallows it, and the function returns "" — reintroducing the exact bug it was written to fix,
  silently. Verify with `DRY=1 tools/demo_live.sh` and check `--rename_map` is in the printed command.

Related: [[camera-order-matters]], [[smolvla-camera-slots]], [[policy-travels-as-a-folder]].

## Resumen (ES)

`DEMO_POLICY` es un id del Hub, no un directorio, así que `[ -f "$POLICY/train_config.json" ]` era
falso y los scripts no pasaban `--rename_map`; `lerobot-rollout` entonces **borra** el mapa que trae
el checkpoint y aborta con "Visual feature mismatch". `policy_dir()` en `tools/_common.sh` resuelve
el id a su snapshot en caché. Ojo: el mapa está en la raíz de `train_config.json`, y `policy_dir`
debe usar el python del venv, no `python3`, o devuelve "" en silencio.
