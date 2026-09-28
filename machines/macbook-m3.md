# Machine: MacBook Pro M3 (portable recording station)

Purpose: take the arms and cameras anywhere (the talk, another room), **record datasets and push
them to the Hub**, run **inference** with a policy pulled from the Hub. Training happens on
[[hf-cloud-gpu]] or the desktop, not here (no CUDA; `mps` works for ACT inference and light training only).

Status (2026-09-27): venv installed at `~/GitHub/AnotherOnes/lerobot` (0.6.2-dev `8c894413c`, torch 2.11,
`mps` available, `hf` CLI 1.30 inside the venv), calibration copied. **Blocked on cameras** — the first
probe saw only the built-in FaceTime camera plus one black feed, none of the three USB cameras
(step 4 below is the fix). Still `TODO`: ports (`tools/find_ports.sh`), camera indices, Accessibility
permission, `uv run hf auth login`, first teleop.

The policy and dataset it needs are already on the Hub:
`tools/pull.sh policy smolvla_so100_medicament_box`.
Everything below is what changes versus [[desktop-ubuntu]]; the workflows are otherwise identical.

## First-time setup checklist

1. Install LeRobot (Python 3.12, uv):
   ```bash
   cd ~/GitHub/AnotherOnes/lerobot            # already cloned here (same path as the desktop); lerobot 0.6.2-dev
   uv sync --locked --extra core_scripts --extra feetech --extra smolvla --extra training
   # 0.6.x: `datasets`, `pynput` and `rerun` moved to extras; without `core_scripts` every lerobot-* CLI
   # dies with "'datasets' is required but not installed". 0.5.x only needed --extra feetech.
   uv run lerobot-find-port                # sanity: CLI works
   ```
   Pin the same release the dataset/policy was made with when possible (desktop = 0.5.2). A newer
   release is fine for recording new datasets; note the version in the experiment note.
2. Copy the calibration JSONs from `assets/calibration/` — commands in [[calibration]].
3. **Find BOTH ports in one sitting:** `tools/find_ports.sh`.
   `lerobot-find-port` detects **one bus per run** — it diffs the port list across a single unplug —
   so a lone run only ever gives you one arm. The wrapper runs it twice (follower, then leader) and
   prints the two `export` lines to paste into `machines/macbook.env`. macOS names
   (`/dev/tty.usbmodem<serial>`) are **stable per physical device**, so once found they stay. No
   `chmod` needed.


4. **Cameras — this is the step that fails on macOS.** Run `tools/mac_cameras.sh` first; it
   answers the three questions `lerobot-find-cameras` cannot:

   - **Does macOS see the camera at all?** (`system_profiler SPCameraDataType`). If a USB camera is
     missing *here*, it is a USB problem, not a LeRobot problem — see the hub/power notes below.
   - **Does this terminal have camera permission?** A camera that opens but returns an **all-black
     frame** is almost always permission: macOS hands out black frames instead of an error.
     Fix in *System Settings → Privacy & Security → Camera*, enable your terminal app, then **fully
     quit and reopen it**. The prompt only appears once; if it was dismissed, the app stays denied.
   - **Which OpenCV index is which?** The script opens indices 0-7, warms each up and reports mean
     brightness, so black feeds are labelled as such.

   Known symptom (seen 2026-09): the probe returned **two** images — one completely black and one
   from the **built-in FaceTime camera** — and none of the three USB cameras. That is the signature
   of permission-denied plus index 0 being the internal camera. Work through, in order:

   a. Grant camera permission to the terminal, quit and reopen it.
   b. Turn off **Continuity Camera** (iPhone → Settings → General → AirPlay & Continuity), which
      otherwise occupies an index.
   c. Use a **powered** USB-C hub. Three UVC cameras plus two arms exceed what MacBook ports supply,
      and an under-powered camera enumerates as nothing or as black frames.
   d. Plug the cameras in **one at a time**, waiting for each to appear in `system_profiler`. Some
      UVC cameras reserve full uncompressed bandwidth on connect, so three at once get refused where
      three in sequence succeed.
   e. Swap cables — thin/long USB cables are often charge-only or too lossy for 480 Mbit/s.

   Then map indices to keys with `uv run lerobot-find-cameras opencv` and the saved PNGs in
   `outputs/captured_images/`, and write them into `machines/macbook.env`. **Keep `top` / `wrist` /
   `base` pointing at the same physical cameras as the desktop** — a swap silently ruins inference
   ([[camera-order-matters]]). macOS has no `/dev/v4l/by-id` equivalent, so re-check the images
   every session.


5. `hf auth login` and set `HF_USER` (see [[hf-whoami-format]]); recording on the Mac should push to
   the Hub (`PUSH_TO_HUB=true` in the env) so [[hf-cloud-gpu]] can train.
6. Recording keys: LeRobot's keyboard listener (`pynput`) needs the terminal app to be allowed under
   **System Settings → Privacy & Security → Accessibility** (and Input Monitoring). If arrow keys
   are ignored, that is the reason — see [[12-recording-keys]].
7. Run `tools/teleop.sh` — the follower must mirror the leader with no offset. Then record.

## Device / performance notes

- `--policy.device=mps` for inference on Apple Silicon (ACT runs fine). Some ops may fall back to
  CPU; set `PYTORCH_ENABLE_MPS_FALLBACK=1` if a kernel is missing. SmolVLA inference on `mps` is
  slower than a 5060 Ti; use a small `n_action_steps`/RTC if the arm stutters, or run the demo from the desktop policy checkpoint on `cpu` and accept lower control rate.
- USB-C hub: put the two arms on one hub port group and the cameras on another; the M3 has few
  ports and one saturated bus reproduces [[usb-bandwidth-three-cams]].
- Power: the arms need their own PSU; the Mac only provides data.
- Wayland/X11 is irrelevant here; rerun (`--display_data=true`) works natively.

## Presentation-day kit (see [[vla-demo-plan]])

Arms + PSU, 2 cameras + mounts, USB-C hub, the scene objects, this repo cloned, calibration copied,
policy pulled from the Hub *before* leaving Wi-Fi, and one recorded episode ready for `lerobot-replay` as a fallback.

## Resumen (ES)

La MacBook es la estación portátil: grabar datasets y correr inferencia; entrenar en HF Jobs.
Pendiente configurar: puertos `/dev/tty.usbmodem*` (estables en macOS), índices de cámara
(AVFoundation, la FaceTime suele ser 0), permisos de Accesibilidad para las flechas, `hf auth login`.
Dispositivo `mps`. Copiar la calibración desde `assets/calibration/`.
