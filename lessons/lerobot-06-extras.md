# lerobot ≥ 0.6: every CLI dies with "'datasets' is required" unless you install `core_scripts`

Seen 2026-09-13 on the MacBook (lerobot 0.6.2-dev): after `uv sync --locked --extra feetech --extra smolvla`,
`lerobot-record --help` raises

```
ImportError: 'datasets' is required but not installed. Install it with: pip install 'lerobot[dataset]'
```

In 0.6 `datasets`/`pyarrow`, `pynput` (keyboard events) and `rerun` (display) moved to extras.
`core_scripts` = `dataset` + `hardware` + `viz`. The full line for a record/train/eval machine:

```bash
uv sync --locked --extra core_scripts --extra feetech --extra smolvla --extra training
```

0.5.x only needed `--extra feetech`. Every flag used by `tools/*.sh` was re-checked against
0.6.2 `--help` the same day and still exists (`--policy.path` included).

Related: [[01-environment]], [[macbook-m3]].

## Resumen (ES)

En lerobot 0.6 `datasets`, `pynput` y `rerun` son extras: sin `--extra core_scripts` ningún
`lerobot-*` arranca. Línea completa arriba.
