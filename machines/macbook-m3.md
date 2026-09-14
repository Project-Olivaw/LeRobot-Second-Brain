# Machine: MacBook Pro M3 (portable recording station)

Purpose: take the arms and cameras anywhere (the talk, another room), **record datasets and push
them to the Hub**, run **inference** with a policy pulled from the Hub. Training happens on
[[hf-cloud-gpu]] or the desktop, not here (no CUDA; `mps` works for ACT inference and light training only).

Status: **not yet set up** — the `TODO` fields in `machines/macbook.env` must be filled on first use.
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
3. Find ports: `uv run lerobot-find-port` — macOS names are `/dev/tty.usbmodem<serial>`; unlike Linux
   they are **stable per physical device**, so once found, write them into `machines/macbook.env`.
   No `chmod` needed on macOS.
4. Find cameras: `uv run lerobot-find-cameras opencv` — backend is **AVFoundation**, ids are plain
   integers, no `/dev/video*`. The built-in FaceTime camera is normally index 0; USB cams come after.
   Open `outputs/captured_images/*.png` to map indices to `top` / `wrist` / `base`, then fill the env.
   Keep `fourcc: MJPG` and 640x480@30 so the data matches the desktop datasets.
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
