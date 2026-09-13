# ConnectionError … Incorrect status packet = bus or power, not config

`ConnectionError: Failed to write 'Lock' on id_=5 ... Incorrect status packet!` appeared on the
first Fool's mate recording, right after all three cameras had connected fine. The motor id in the
message (5 = `wrist_roll`) is where the daisy chain lost a reply.

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
