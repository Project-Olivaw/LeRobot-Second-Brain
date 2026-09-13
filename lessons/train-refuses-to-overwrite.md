# lerobot-train refuses an existing output_dir

`lerobot-train` raises `FileExistsError` if `--output_dir` already exists. Either delete the
folder, use a new `--output_dir`/`--job_name` per run (`..._fast`, `..._v2`), or resume with
`--config_path=<run>/checkpoints/last/pretrained_model/train_config.json --resume=true`.

`tools/train_act.sh` and `tools/train_smolvla.sh` take a suffix so runs never collide.

Related: [[file-exists-error-on-record]].

## Resumen (ES)

Entrenar sobre un `output_dir` existente falla; usar nombre nuevo, borrar, o `--resume=true`.
