# Troubleshooting — symptom → fix

| Symptom | Cause | Fix / note |
|---|---|---|
| `failed to set fps=30 (actual_fps=20.0)` | camera in raw YUYV mode | add `fourcc: MJPG` — [[mjpg-required-for-30fps]] |
| `failed to set capture_width=640 (actual_width=1920)` / `failed to set fourcc=MJPG` | opened by `/dev/videoN` string → FFMPEG backend | use integer index — [[integer-index-not-dev-path]] |
| A camera fails only when all three are attached | USB bandwidth / power | [[usb-bandwidth-three-cams]] |
| Wrong camera under a key (wrist/base swapped) | indices shifted | re-probe and look at the PNGs — [[04-find-cameras]] |
| `ConnectionError ... Incorrect status packet` | servo bus / power glitch | retry, reseat, PSU, port — [[incorrect-status-packet]] |
| `Could not open port` / permission denied | wrong port or not in `dialout` | [[02-find-ports]] |
| `lerobot-calibrate`: firmware version mismatch | motors on 3.9 and 3.10 | flash via FD in the Win11 VM — [[feetech-firmware]] |
| Follower offset vs leader during teleop | different homing pose at calibration | recalibrate both — [[calibrate-same-pose]] |
| `FileExistsError` on record/eval | dataset folder already exists | delete or unique name — [[file-exists-error-on-record]] |
| `FileExistsError` on train | `output_dir` exists | new name / `--resume` — [[train-refuses-to-overwrite]] |
| Task label looks like a dict | colon/apostrophe in `single_task` | [[single-task-no-colons]] |
| "I pulled the repo, must I recreate conda?" / version differs from the checkout | conda env is a pip install; uv venv metadata stale | `uv sync --locked --extra …` after every checkout; `import lerobot; lerobot.__file__` to see which one runs — [[conda-env-is-not-the-checkout]] |
| `HF_USER` empty | `hf auth whoami` format changed | [[hf-whoami-format]] |
| Arrow keys ignored while recording | focus (Wayland/SSH) or macOS Accessibility permission | [[12-recording-keys]] |
| Wall of rerun / Vulkan / EGL warnings | noise | read the Python traceback — [[rerun-warnings-are-harmless]] |
| CUDA out of memory | batch too large for image count | lower `--batch_size` — [[updt-s-is-your-timer]] |
| GPU utilisation < 80 % | dataloader-bound | raise `--num_workers` — [[updt-s-is-your-timer]] |
| Policy bobs / hovers / grabs air at eval | inconsistent or under-specified demos, task too long | [[act-limits-small-objects]], [[dont-move-the-scene]], [[good-dataset-rules]] |
| Policy always a few cm off in the same direction | calibration changed since recording | [[calibration]] |
| Policy works only at one object position | no pose variation in data | [[good-dataset-rules]] |
| Policy cannot build input / missing key | camera keys differ from training | [[camera-keys-are-baked-in]] |
| Torch imports but crashes at first kernel (Blackwell) | wrong CUDA wheel | cu128 index; test with a real matmul — [[desktop-ubuntu]] |
| Motor LEDs dark / blinking | cable / overload / wrong PSU voltage | [[so100-arms]] |
| `ImportError: 'datasets' is required but not installed` on any `lerobot-*` (0.6.x) | extras split | `--extra core_scripts` — [[lerobot-06-extras]] |
| Policy fails on a different table / at the venue | background out of distribution | bring the scene kit — [[policy-does-not-survive-a-new-table]] |
| Checkpoint fails to load on the other machine (`config.json` field errors) | lerobot version mismatch | same commit on both — [[policy-travels-as-a-folder]] |
| "Can we have a VLA tonight?" | data + compute floors | [[no-same-evening-vla]] |

## Resumen (ES)

Tabla de síntoma → causa → lección. Las más frecuentes: MJPG, índice entero de cámara, ancho de
banda USB, `status packet`, `FileExistsError`, y políticas que dudan por datasets inconsistentes.
