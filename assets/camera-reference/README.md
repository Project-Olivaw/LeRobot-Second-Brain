# Camera reference views — what each key looked like when the dataset was recorded

`tools/check_cameras.py` scores each live feed against the PNG named after its key, so a swapped or
moved camera is caught before a session instead of after a bad evaluation ([[camera-order-matters]]).

These frames are **not** "today's views". They were extracted from the recorded videos of
`Youngermaster/so100_medicamentos` (the dataset `smolvla_so100_medicamentos` was trained on) by
`tools/verify_cameras.py`, which writes `outputs/verify_cameras/recorded_<key>.png`. That is the
right reference: the policy's world is what the *dataset* saw, not what the room looks like now.

**Do not run `--save-reference` on a scene you have not verified** — it would freeze whatever is in
front of the cameras today as the definition of correct, including wrong aim and wrong light.
Re-generate from the dataset instead:

```bash
uv run python tools/verify_cameras.py so100_medicamentos
cp outputs/verify_cameras/recorded_top.png  assets/camera-reference/top.png
cp outputs/verify_cameras/recorded_base.png assets/camera-reference/base.png
```

## Why there is no `wrist.png`

The wrist camera is mounted on the gripper, so its view is a function of the arm's pose, not of the
scene. A single reference frame from the middle of one episode shows whatever the arm happened to be
pointing at (in this dataset: a white patch of table), and scoring a live frame against it produces a
number that means nothing — 0.18 with the camera perfectly correct. Fixed cameras (`top`, `base`) are
the ones a reference can police; the wrist is checked by eye in `tools/mac_cameras.sh` output.

## Brightness matters as much as framing

Measured 2026-09-29 on the MacBook: live feeds were **44-64% of the recorded brightness**
(top 91 vs 180, base 67 vs 152). The policy keys off pixels, so that is a real distribution shift.
Add light until the live means are close to the recorded ones before recording or demoing
([[lock-exposure-and-white-balance]], [[policy-does-not-survive-a-new-table]]).
