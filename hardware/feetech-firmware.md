# Feetech firmware mismatch (3.9 vs 3.10) and the Windows VM fix

Recovered from the May 2026 `lerobot_arm_calibration` session memory (transcript lost).

## Symptom

`lerobot-calibrate` refused to connect: motor #5 (`wrist_roll`) reported firmware **3.10** while
motors 1-4 and 6 reported **3.9**. LeRobot's `feetech.py` `_assert_same_firmware()` hard-stops on any
mismatch. The arm was healthy — all 6 motors answered on the bus.

## Decision

Flash the five 3.9 motors **up** to 3.10 (official direction) with Feetech's **FD** software
(Windows-only), rather than patching the check out of LeRobot.

## Procedure (done 2026-05-30, reusable)

1. Ubuntu 24.04 host (kernel 6.17): built a **Windows 11 VM with QEMU/KVM + virt-manager** (VirtualBox
   kernel modules would not build). VM: 6 GB RAM, 4 vCPU, 64 GB disk at `/var/lib/libvirt/images/win11.qcow2`,
   UEFI secure boot + emulated TPM 2.0 (TIS). Local account via "Work/School → join domain instead".
   VM name: `win11`. Windows user `feetech`. Password reset scripts if locked out:
   `~/reset-feetech.sh`, `~/reset-feetech2.sh` (chntpw on the qcow2; run with `sudo`, last used 2026-09-10).
2. Installed **Feetech FD 1.9.8.3** inside the VM.
3. Adapter: **Waveshare Bus Servo Adapter** (9-12.6 V), USB id `1a86:55d3` (WCH CH34x). Passed to the VM
   with virt-manager "Redirect USB device" (SPICE usbredir). A FE-URT-1 is also owned but misplaced;
   the Waveshare adapter is sufficient.
4. In FD: COM3 @ 1,000,000 baud found all 6 STS3215 on the daisy chain at 12.3 V. Latest offered
   firmware = 3.10 (`SCServo21-GD32-TTL-250306.bin`), matching motor #5.
5. Upgrade tab → select ID → Online → Upgrade (0→100 %, no power-cycle prompt, silent success).
   Repeated for IDs 1, 2, 3, 4, 6. Verified each reads 3.10 by re-clicking Online.
   Per-ID flashing on the **assembled** arm worked — no need to isolate motors.
6. Released the adapter back to the host; the arm reappeared as `/dev/ttyACM0`; calibration succeeded.

## When to reuse

- Any future `firmware` mismatch on either arm (the leader was never audited).
- Replacing a burned/broken servo with a new one: it will likely ship with a different version — flash
  it to match before LeRobot will talk to the bus.
- The VM still exists on the desktop and can be booted from virt-manager. It is not needed on the Mac
  unless a flash is required there (then UTM/Parallels + USB passthrough would be the equivalent).

## Resumen (ES)

LeRobot no conecta si los motores tienen firmware distinto. En mayo el motor 5 estaba en 3.10 y los
demás en 3.9; se subieron todos a 3.10 con el software FD de Feetech dentro de una VM Windows 11
(QEMU/KVM, adaptador Waveshare por USB passthrough). La VM `win11` sigue en el escritorio para
futuros flasheos, por ejemplo al reemplazar un servo.
