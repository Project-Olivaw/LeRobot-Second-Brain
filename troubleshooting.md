# Troubleshooting — symptom → fix

| Symptom | Cause | Fix / note |
|---|---|---|
| `failed to set fps=30 (actual_fps=20.0)` | camera in raw YUYV mode | add `fourcc: MJPG` — [[mjpg-required-for-30fps]] |
| `failed to set capture_width=640 (actual_width=1920)` / `failed to set fourcc=MJPG` | opened by `/dev/videoN` string → FFMPEG backend | use integer index — [[integer-index-not-dev-path]] |
| A camera reports `absent` / only two feeds although three are plugged in | two cameras of the same model share one `/dev/v4l/by-id` name | pin the USB port with `CAM_*_PATH` — [[identical-cameras-need-by-path]] |
| A camera fails only when all three are attached | USB bandwidth / power | [[usb-bandwidth-three-cams]] |
| Wrong camera under a key (wrist/base swapped) | indices shifted | re-probe and look at the PNGs — [[04-find-cameras]] |
| `ConnectionError ... Incorrect status packet` | servo bus / power glitch | retry, reseat, PSU, port — [[incorrect-status-packet]] |
| `Could not open port` / permission denied | wrong port or not in `dialout` | [[02-find-ports]] |
| `lerobot-calibrate`: firmware version mismatch | motors on 3.9 and 3.10 | flash via FD in the Win11 VM — [[feetech-firmware]] |
| Follower offset vs leader during teleop | different homing pose at calibration | recalibrate both — [[calibrate-same-pose]] |
| `resume() requires an explicit 'root' directory` | 0.6.2 refuses to open a writer without `--dataset.root` | pass it (tools/record.sh does) — [[resume-needs-dataset-root]] |
| Resumed recording overshoots the episode target / a half-episode is in the dataset | `num_episodes` counts this run; Esc mid-episode saves the stub | pass the target to `record_medicamentos.sh`; → then Esc, or ← then Esc — [[resume-counts-this-run]] |
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
| `Could not connect on port '...TODO'` | profile still has the placeholder port | fill `machines/<machine>.env` — [[02-find-ports]] |
| Follower goes limp / drops at teleop start | leader and follower ports swapped | `uv run python tools/identify_arms.py` — [[identify-arms-by-homing-offset]] |
| Camera opens but every frame is black (macOS) | terminal lacks Camera permission, or index shifted | `tools/mac_cameras.sh`, `tools/check_cameras.py` — [[camera-indices-shift-on-replug]] |
| Multi-instruction policy ignores the sentence | trained ACT, or one object per dataset | [[act-has-no-language-input]], [[balance-the-instructions]] |
| SmolVLA training dies in ~90 s with a camera-name error | `smolvla_base` expects `camera1/2/3` | pass `--rename_map` — [[smolvla-camera-slots]] |
| Arm pauses rhythmically during a rollout | chunk recompute is slower than the control period | `--inference.type=rtc`; measure with `tools/bench_policy.py` — [[policy-inference-is-bursty]] |
| Policy works at home, fails at the venue | light/background changed; auto-exposure shifted | bring the scene kit, lock the cameras — [[scene-kit]], [[lock-exposure-and-white-balance]] |
| macOS probe finds only the FaceTime camera and/or a black frame | terminal lacks camera permission; Continuity Camera holds an index; unpowered hub | `tools/mac_cameras.sh` — [[macbook-m3]] |
| `lerobot-find-port` only gives one arm | it detects one bus per run, by design | run it twice — `tools/find_ports.sh` |
| Policy hesitates / reaches slightly wrong, "needs more data" | camera order swapped since training | [[camera-order-matters]] |
| `403 ... rights to create a dataset under the namespace "local"` | `push_to_hub()` uses the dataset's own repo_id | re-point it first — `tools/push_dataset.py` / [[11-hub-sync]] |
| Multi-task policy ignores the instruction | instructions imbalanced or too similar, or the scene gives the answer away | [[balance-the-instructions]] |

## Resumen (ES)

Tabla de síntoma → causa → lección. Las más frecuentes: MJPG, índice entero de cámara, ancho de
banda USB, `status packet`, `FileExistsError`, y políticas que dudan por datasets inconsistentes.
