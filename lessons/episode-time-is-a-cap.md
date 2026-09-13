# episode_time_s is a safety cap, not a target — press → when done

Recording phases end when you press **→** or when the timer runs out. Most episodes should end
by keypress right after the object is placed. In the Lego dataset the average episode was ~47 s and
in Fool's mate ~99 s — long tails of idle frames that the policy then has to model.

Set the cap generously (30 s for one pick, 120 s for multi-step) and press → promptly. Idle frames
at the end are worse than a shorter cap.

Related: [[12-recording-keys]], [[good-dataset-rules]].

## Resumen (ES)

`episode_time_s` es un tope; pulsar → en cuanto termina la tarea para no grabar segundos de brazo quieto.
