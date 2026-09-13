# `hf auth whoami` prints `user=<name>`; the docs' awk parser returns empty

The LeRobot docs use `HF_USER=$(NO_COLOR=1 hf auth whoami | awk -F': *' 'NR==1 {print $2}')`.
With `hf` CLI ≥ 1.19 the first line is `user=<name>`, so that yields an empty string and every
`${HF_USER}/...` repo id becomes `/...`.

Use: `HF_USER=$(hf auth whoami 2>/dev/null | sed -n 's/^user=//p')` (prefix with `uv run` if needed).

Also: the "Cannot authenticate through git-credential" warning at login is harmless; the token is
saved to `~/.cache/huggingface/token`, which is what LeRobot uses. Token name used in June: `SO-100`.
Never paste the token itself anywhere in this vault.

## Resumen (ES)

`hf auth whoami` ahora imprime `user=<nombre>`; usar `sed -n 's/^user=//p'` para obtener `HF_USER`.
