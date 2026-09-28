# `--resume=true` fails without `--dataset.root` in lerobot 0.6.2

```
ValueError: resume() requires an explicit 'root' directory because it creates a DatasetWriter.
Writing into the revision-safe Hub snapshot cache (used when root=None) would corrupt the shared cache.
```

Seen 2026-09-28 resuming `local/so100_medicamento_frasco` at episode 16. Creating a dataset works
fine with `root=None` (it defaults to `$HF_LEROBOT_HOME/<repo_id>`), but `LeRobotDataset.resume()`
opens a *writer*, and 0.6.2 refuses to point a writer at a path it may have resolved from the Hub
snapshot cache. It does not fall back to the default — it raises, before a single frame is recorded.

Nothing is damaged when this happens: the episodes already on disk are complete and loadable. Fix and
carry on.

`tools/record.sh` now passes `--dataset.root` on **every** run, not only on resume, so the create path
and the resume path name the same directory and can never disagree:

```bash
ROOT="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}/${DATASET_PREFIX}/${NAME}"
… --dataset.repo_id=${DATASET_PREFIX}/${NAME} --dataset.root="$ROOT" … --resume=true
```

Worth the habit generally: a flag that is optional when creating something is not automatically
optional when reopening it.

Related: [[resume-counts-this-run]], [[file-exists-error-on-record]], [[06-record]], [[14-two-instruction-demo]].

## Resumen (ES)

En 0.6.2 `--resume=true` exige `--dataset.root`: al reanudar se abre un *writer* y lerobot se niega a
resolver la ruta sola. No se pierde nada — los episodios ya grabados están intactos. `tools/record.sh`
ahora pasa `--dataset.root` siempre, para que crear y reanudar apunten al mismo directorio.
