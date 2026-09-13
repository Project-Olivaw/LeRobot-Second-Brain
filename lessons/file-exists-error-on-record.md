# FileExistsError on record/eval: the dataset folder already exists

`lerobot-record` creates `~/.cache/huggingface/lerobot/<repo_id>` **before** connecting the
robot. A crash or Ctrl+C during startup leaves an empty scaffold, and the next run with the same
`repo_id` fails with `FileExistsError`. This bit us twice (Lego eval, Fool's mate eval ×2), and the
Fool's mate evals ended up as two 0-episode folders holding 3.3 GB of orphan video.

Fixes: `rm -rf ~/.cache/huggingface/lerobot/<repo_id>`, or use a unique name. `tools/eval.sh`
appends a timestamp to the eval repo id so this cannot happen. To *append* to a real dataset use
`--resume=true` instead.

Related: [[train-refuses-to-overwrite]] (same idea for `output_dir`).

## Resumen (ES)

Si `lerobot-record` falla al arrancar deja la carpeta creada y el siguiente intento da `FileExistsError`. Borrar la carpeta o usar otro nombre; `--resume=true` para añadir episodios.
