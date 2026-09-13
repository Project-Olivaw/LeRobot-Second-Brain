# 02 — Find the arm ports

Ports identify the USB serial adapter of each arm. Linux names (`/dev/ttyACM0/1`) depend on plug
order and can swap after a reboot; macOS names (`/dev/tty.usbmodem<serial>`) are stable per device.

```bash
$RUN lerobot-find-port
```

Flow: it lists the ports, then asks *"Remove the USB cable from your MotorsBus and press Enter"*.
Unplug **one** arm's USB, press Enter → it prints that arm's port. Reconnect, repeat for the other arm.

Write the result into `machines/<machine>.env` (`ROBOT_PORT` = follower, `TELEOP_PORT` = leader) and
commit if it changed. On the desktop the known mapping is follower `/dev/ttyACM1`, leader `/dev/ttyACM0`.

Shortcut when only checking: `ls /dev/ttyACM*` (Linux) or `ls /dev/tty.usbmodem*` (macOS).

## If a connection fails

- `Could not open port`: wrong port or the other arm — re-run the finder.
- Permission denied on Linux: `sudo usermod -aG dialout $USER` and re-login (desktop already has it).
- `Incorrect status packet` after the port opened: bus/power issue, not a port issue — [[incorrect-status-packet]].

## Resumen (ES)

`lerobot-find-port`: desconectas un brazo cuando lo pide y te dice su puerto. En Linux los nombres
cambian al reconectar; en macOS son estables. Guardar el resultado en `machines/<máquina>.env`.
