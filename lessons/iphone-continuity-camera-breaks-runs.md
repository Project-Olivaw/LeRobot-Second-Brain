# The iPhone Continuity Camera steals an index and hangs the run — it is not a permissions problem

Symptom (MacBook, 2026-09-29): `tools/teleop.sh` connected the arms, then died. The cameras all
"worked" in the probe. The actual error, reproduced through lerobot's own camera path:

```
TimeoutError: Timed out waiting for frame from camera OpenCVCamera(3) after 1000 ms.
              Read thread alive: True.
WARNING  Error reading frame in background thread: OpenCVCamera(3) read failed (status=False).
```

Index 3 was **`Juan Manuel's iPhone Camera`**. An idle Continuity Camera *opens* — `isOpened()` is
true, `cv2` hands back a legal all-black frame in a quick probe — but it never delivers a stream, so
lerobot's background read thread times out and the whole session dies. It is the worst failure shape
there is: it passes a shallow check and fails in the real code path.

Two separate harms, so fix both:

1. **It occupies an AVFoundation index**, pushing the real cameras around — the swap in
   [[camera-order-matters]] and [[camera-indices-shift-on-replug]].
2. **Referencing that index hangs the run**, as above.

**Fix — no airplane mode needed, and nothing to change on the Mac:**
on the *iPhone*, Settings > General > AirPlay & Continuity > **Continuity Camera → off**.
The phone keeps its signal, Wi-Fi, notifications, everything. It simply stops advertising itself as a
webcam. (It also publishes a second device, "iPhone Desk View Camera", so one phone can cost two
indices.) Locking the phone or moving it out of range is not a fix: it reappears mid-session.

Then **re-run `tools/check_cameras.py`** — removing a device can renumber the ones that remain.

Do not chase camera permissions for this. A permission problem makes *every* camera black, forever,
and is fixed in System Settings > Privacy & Security > Camera + fully quitting the terminal app.
A single dead index among working ones is a device problem, not a permission one.

Related: [[macbook-m3]], [[cameras]], [[camera-keys-are-baked-in]].

## Resumen (ES)

La Continuity Camera del iPhone ocupa un índice y, aunque "abre", nunca entrega frames: lerobot
muere con `TimeoutError` en `OpenCVCamera(3)`. No es problema de permisos y no hace falta modo avión:
en el iPhone, Ajustes > General > AirPlay y Continuidad > Cámara de Continuidad → desactivar. Luego
volver a correr `tools/check_cameras.py`, porque quitar un dispositivo renumera los demás.
