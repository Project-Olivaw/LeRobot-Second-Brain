# `--dataset.num_episodes` counts THIS run, not the dataset — and Esc mid-episode saves the stub

Two things about pausing a long recording, both read out of `lerobot_record.py` (0.6.2) rather than
assumed, because both cost episodes if you get them wrong.

## 1. The counter restarts every run

```python
recorded_episodes = 0
while recorded_episodes < cfg.dataset.num_episodes and not events["stop_recording"]:
```

`recorded_episodes` is local to the run. With `--resume=true` and `--dataset.num_episodes=100` on a
dataset that already holds 15 episodes, you get **115**, not 100. `tools/record_medicamentos.sh` now
takes the number you pass as the **target for the whole dataset** and asks lerobot only for the
remainder (`resuming …: 15 recorded, 85 to go`), so the same command can be repeated after every
block and it stops at the target.

## 2. Esc during an episode keeps the half-recorded episode

After the record loop exits, the reset phase is skipped when `stop_recording` is set, and then:

```python
if events["rerecord_episode"]:
    ...
    dataset.clear_episode_buffer()
    continue
dataset.save_episode()
```

Nothing special-cases "the operator stopped in the middle": the truncated episode is **saved**. An
episode that ends with the arm frozen half-way to the object is exactly the demonstration you do not
want 200 of the way through ([[good-dataset-rules]]).

So, to walk away safely:

- **Preferred:** finish the episode normally (press → the moment the object lands), then press **Esc**
  during the *reset* phase. The last good episode is kept and the session closes cleanly.
- **If you must stop mid-motion:** press **←** first (discard this episode), then **Esc**. With
  `rerecord_episode` set, the buffer is cleared and the loop exits without saving the stub.
- Videos finish encoding on exit — let the process end by itself rather than Ctrl-C'ing it.

Related: [[12-recording-keys]], [[episode-time-is-a-cap]], [[file-exists-error-on-record]], [[14-two-instruction-demo]].

## Resumen (ES)

`--dataset.num_episodes` cuenta los episodios de **esta** ejecución: con `--resume` y 100 sobre 15 ya
grabados quedan 115. Por eso `tools/record_medicamentos.sh` recibe el objetivo total y pide solo lo
que falta. Además, pulsar Esc en medio de un episodio **guarda** el episodio truncado: lo correcto es
terminar con → y pulsar Esc en la fase de reset, o pulsar ← (descartar) y luego Esc si hay que parar
en mitad del movimiento.
