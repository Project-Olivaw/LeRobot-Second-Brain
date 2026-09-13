# Three cameras and two arms on one USB controller fail

Raw 640x480x3 @ 30 Hz ≈ 221 Mbit/s per camera; three exceed a USB 2.0 (480M) bus outright, and
even with MJPG a shared hub can drop frames or brown-out the servo adapters.

Symptoms: a camera fails to open / `failed to set fps=30` only when all three are attached;
`Incorrect status packet` from the follower right after the cameras connect.

Fixes, in order: `fourcc: MJPG` on every camera; spread cameras over **different physical USB
controllers** (the desktop has several — [[desktop-ubuntu]]); put the arms on a powered hub or direct
ports separate from the cameras; lower every camera to `fps: 15` as a last resort (consistently).
On a MacBook with few ports, use two cameras.

Related: [[mjpg-required-for-30fps]], [[incorrect-status-packet]], [[cameras]].

## Resumen (ES)

Tres cámaras crudas no caben en un bus USB 2.0 y comparten alimentación con los brazos. MJPG, controladores USB distintos, y brazos en hub alimentado.
