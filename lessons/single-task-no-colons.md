# The task string must not contain colons or apostrophes

`--dataset.single_task="Play black Fool's mate: ..."` produced a task label that looked like a dict
(`{"Play black Fools mate": ...}`). draccus parses `key: value` inside argument strings as a mapping,
and a stray `'` breaks the shell/YAML quoting.

Rule: plain sentence, letters/digits/spaces/commas/hyphens only. Good:
`Pick up the medicament box and place it in the tray`.

This matters more for VLAs, where the string is a model input ([[09-train-vla]]).

## Resumen (ES)

La frase de la tarea no puede tener `:` ni `'`: draccus la interpreta como diccionario.
