# 12 — Recording keys and phases

Recording is a loop of *record phase* → *reset phase* per episode. You control the transitions.

| Key | Effect |
|---|---|
| **→** (Right arrow) | End the current phase **now** and advance (end the episode after the object is placed; skip the reset wait). |
| **←** (Left arrow) | **Discard** the current episode and re-record it. Keep bad demos out. |
| **Esc** | Stop the whole session. Episodes already saved are kept (and uploaded if `push_to_hub=true`). |

Per episode: (1) record until you press → or `episode_time_s` elapses; (2) reset the scene during
`reset_time_s` or press →; (3) auto-save, counter advances. There is no confirm step.
`episode_time_s` is only a cap ([[episode-time-is-a-cap]]).

## Where the keys are read from

- **Linux X11 (desktop):** captured globally via `pynput`; they work with the rerun window focused.
  If a press seems ignored, click the terminal.
- **Linux Wayland / headless / SSH:** LeRobot (≥ 0.5.2, commit b4e454c0) falls back to a terminal
  listener — the terminal must be focused.
- **macOS:** `pynput` needs the terminal app allowed under Privacy & Security → Accessibility
  (and Input Monitoring). Without it, keys are silently ignored.

## Habits that produced clean data

- Press → the instant the task is complete; do not hold the pose or wander.
- Use ← generously: a wobbly grasp costs more than the 30 s to redo it.
- Reset the scene to a *new* object pose each time (vary), but never move cameras or fixtures ([[dont-move-the-scene]]).

## Resumen (ES)

→ termina la fase y avanza, ← descarta y repite, Esc termina la sesión. En X11 las teclas son
globales; en Wayland/SSH hay que tener la terminal enfocada; en macOS hay que dar permiso de
Accesibilidad a la terminal. Pulsar → justo al terminar y ← sin miedo.
