# rerun / Vulkan / EGL warnings are noise; read the Python traceback

With `--display_data=true` rerun prints `No config found`, `EGL says it can present...`, Vulkan
device warnings, and `ioctl(VIDIOC_QBUF): Bad file descriptor` shows up from V4L2. None of them
stop anything. When teleop or record "fails with rerun", the real error is the Python traceback
below (in June it was the camera fps error hidden under 90 lines of rerun output).

If rerun itself is the problem (headless, SSH), drop `--display_data=true`; recording works without it.

## Resumen (ES)

Los avisos de rerun/Vulkan/EGL no son el error; el error real está en el traceback de Python más abajo.
