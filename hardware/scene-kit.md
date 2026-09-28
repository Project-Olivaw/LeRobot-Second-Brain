# The scene kit (the mat, the board, the light)

A policy learns pixels. Everything the cameras see is part of the input — including the table. That
is why a policy trained on one desk fails on another ([[policy-does-not-survive-a-new-table]]), and
why the fix is not a better model but a **scene that travels**.

## The green mat: yes, with three conditions

Putting a vibrant green mat on the desk and taking it wherever the arm goes is the right instinct —
it turns "my desk" from an uncontrolled variable into a prop you own. Conditions:

1. **Matte, not glossy.** A shiny mat mirrors the ceiling lights, so the background changes with the
   room even though the mat did not. Fabric or matte vinyl; no laminate.
2. **Mid-saturation, not neon.** A very saturated green pushes the camera's auto-white-balance
   around and casts a green tint onto the objects (colour bleed onto a *red* and *blue* cube is
   exactly what you do not want). A calm grass/olive green gives the same contrast without the
   tint. This is not chroma-key — nothing is being keyed out; the policy *wants* to see the mat.
3. **Lock the cameras.** The mat fixes the background; auto-exposure and auto-white-balance can
   still change the pixels when the venue light differs. Run `tools/lock_cameras.sh` before
   recording and before the demo ([[lock-exposure-and-white-balance]]). Note macOS cannot do this.

Green also has a practical advantage for this project: red and blue cubes and a white/black
chessboard are all maximally distinct from it, in both hue and brightness.

## What travels with the arm

| Item | Why | Note |
|---|---|---|
| The mat | the background the policy trained on | roll it, do not fold — creases read as edges |
| Tape-marked spawn grid | the 5 object positions | mark the mat itself, not the table |
| The place target (chessboard / ESP32 car / tray) | a fixture, must land in the same spot | mark its outline on the mat so it goes back identically |
| The objects | the things the instructions name | bring spares — a dented box looks different |
| A light | the venue's ceiling is not your ceiling | small LED panel, same position relative to the mat |
| Camera mounts | the *view* is baked into the dataset | mark the arm-relative position; do not re-aim at the venue |
| Tape measure / phone photo of the setup | to rebuild the layout fast | take a photo of the finished scene at recording time |

Take that photo. When something goes wrong at the venue, comparing the live `top` feed against the
recording-day photo is the fastest diagnosis you have.

## Fixed vs varied

Within one dataset ([[dont-move-the-scene]], [[good-dataset-rules]]):

- **Fixed:** mat, board/target position, camera mounts and angles, light, arm base position.
- **Varied:** the object's position (a marked grid) and yaw; the distractor object's position.
- **Varied only after a first policy works:** lighting level (2-3 steps), small mat shifts.

## Resumen (ES)

Un tapete verde que viaja con el brazo es buena idea: convierte "mi escritorio" en un accesorio
controlado. Condiciones: mate (no brillante), verde medio (no neón, para que no tiña los cubos) y
fijar exposición/balance de blancos con `tools/lock_cameras.sh`. Viaja todo lo que la cámara ve:
tapete, tablero, marcas de posición, objetos, luz y monturas de cámara. Tomar una foto de la escena
el día de la grabación para poder reconstruirla en el sitio.
