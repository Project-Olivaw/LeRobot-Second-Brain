# ACT cannot be the fallback for a language demo — it never sees the instruction

Verified on lerobot 0.6.2 (2026-09-27): `src/lerobot/policies/act/modeling_act.py` contains no
tokenizer and no task/language handling at all. ACT's inputs are images + robot state, full stop.
SmolVLA's processor (`processor_smolvla.py`) tokenizes the task description and feeds it to the VLM.

Consequence for [[14-two-instruction-demo]]: on the **merged** two-instruction dataset, where both
objects sit in frame and only the sentence says which to pick, ACT sees the same pixels paired with
two different target trajectories. It averages them — the hover/bob failure of
[[2026-07-13-fools-mate-act]], for exactly the same reason. Training ACT on the merged dataset is
not a fallback; it is a policy that cannot succeed by construction.

The real fallbacks for the stage, in order:

1. **`lerobot-replay`** of a recorded episode — no inference, identical motion, always works.
2. **ACT trained on ONE half** (`so100_medicamento_caja` alone). It can pick the box reliably, but
   it will pick the box whatever you say — so use it to show *manipulation*, never *language*.
3. SmolVLA on `cpu` with a lower control rate, if `mps` stutters ([[policy-inference-is-bursty]]).

Corollary: ACT is still the right baseline for a **single-instruction** dataset, which is how
[[08-train-act]] uses it. The rule is one instruction per ACT policy.

Related: [[balance-the-instructions]], [[09-train-vla]].

## Resumen (ES)

ACT no lee la instrucción: no tiene tokenizer. En el dataset fusionado de dos frases promedia las
dos trayectorias y falla igual que Fool's mate. El plan B de la charla es `lerobot-replay`, o un ACT
entrenado con una sola mitad (agarra siempre el mismo objeto, no demuestra lenguaje).
