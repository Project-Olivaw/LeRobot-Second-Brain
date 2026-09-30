# ConnectionError … Incorrect status packet = bus or power, not config

`ConnectionError: Failed to write 'Lock' on id_=5 ... Incorrect status packet!` appeared on the
first Fool's mate recording, right after all three cameras had connected fine. The motor id in the
message (5 = `wrist_roll`) is where the daisy chain lost a reply.

**2026-09-30, second occurrence — and a way to narrow it down fast.** This time it was the *leader*,
`Failed to write 'Torque_Enable' on id_=2` (`shoulder_lift`), raised from the `torque_disabled`
context manager restoring torque on exit. Immediately afterwards `tools/identify_arms.py` read all
six motors on both arms cleanly (leader 6/6). That contrast is the diagnostic:

> **Reads clean + a torque write failing = power, not wiring.** A read costs almost no current; the
> reply only gets corrupted on a write that engages torque, which is when the servo actually draws.
> If reads had failed on the same id, it would be a cable or a connector instead.

So run `uv run python tools/identify_arms.py` first whenever this appears — it is read-only and takes
seconds. Then, for a torque-write failure specifically: confirm **that arm's** PSU (the leader needs
its own supply; USB alone will not hold six servos), and put the arm in a low resting pose before
starting, so `shoulder_lift` is not taking the whole arm's weight the instant torque engages.

Checklist, in order:
1. Retry — it is often transient.
2. Reseat the follower USB cable and the 3-pin servo connectors around the failing id.
3. Check the follower PSU; servo brown-outs cause this, and cameras sharing USB power make it worse
   ([[usb-bandwidth-three-cams]]).
4. Confirm the port is still the follower (`lerobot-find-port`); ACM numbers swap on replug.
5. Look at the red LEDs: all steady = wiring OK; one dark = cable; blinking = overload or wrong voltage.

Related: [[so100-arms]], [[02-find-ports]].

## Resumen (ES)

El error de `status packet` es de cable/alimentación en el bus de servos: reintentar, reasentar conectores, revisar fuente, confirmar puerto.
