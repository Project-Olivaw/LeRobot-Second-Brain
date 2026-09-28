# In a multi-task dataset, balance the instructions and keep them lexically distinct

A language-conditioned policy learns P(action | image, instruction). Two failure modes come from
the dataset, not the model:

1. **Imbalance.** If one instruction has 3x the episodes, the policy drifts toward that behaviour
   whatever you say. Keep episode counts within roughly ±20% of each other, and check with
   `tools/tasks.sh <dataset>` after merging.
2. **Overlapping wording.** `pick up the red cube` and `pick up the red cube and stack it` share
   almost every token; the distinguishing part arrives late and is easy to ignore. Make the
   instructions differ *early* and by content words, e.g. `agarra el cubo rojo` vs
   `pon el cubo rojo encima del azul`.

Also: whatever the instruction, the *visual* start state must be consistent with it. If "stack"
episodes always begin with the blue cube already placed, the policy can cheat by reading the scene
instead of the sentence. Record some pick episodes with the other cube already on the board too, so
the sentence is the only reliable signal.

Related: [[good-dataset-rules]], [[09-train-vla]], [[single-task-no-colons]].

## Resumen (ES)

En un dataset multi-tarea hay que equilibrar el número de episodios por instrucción (±20%) y usar frases que se diferencien pronto y por palabras de contenido. Además, el estado visual inicial no debe delatar la instrucción, o el modelo ignora el lenguaje.
