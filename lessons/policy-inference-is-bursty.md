# A chunked policy is bursty, not slow — measure the recompute, not the average

ACT, SmolVLA and pi0 predict `n_action_steps` actions at once, then replay them from a queue.
So the cost profile is: one expensive **recompute**, then N nearly-free steps. The average latency
is meaningless; what decides whether the arm stutters is *recompute vs the 33 ms control period*.

Measured on the desktop (RTX 5060 Ti) with `tools/bench_policy.py`, 2026-09-27:

| policy | cameras | n_action_steps | recompute | cached step | recompute every |
|---|---|---|---|---|---|
| `smolvla_so100_medicament_box` | 3 | 50 | **152 ms** | 1.6 ms | 1.7 s |
| `act_so100_medicament_box` | 2 | 100 | **10 ms** | 0.3 ms | 3.3 s |
| the same SmolVLA on **CPU** | 3 | 50 | **924 ms** | 1.5 ms | 1.7 s |

CPU is the pessimistic bound for the MacBook: a 0.93 s freeze every 1.7 s, i.e. ~28 stalled control
steps. `mps` should land between the two — measure it, do not assume.

So SmolVLA stalls ~5 control steps every 1.7 s even on the GPU. That is small but visible, and
`mps` on the MacBook is expected to be several times slower — measure it there before the talk:

```bash
uv run python tools/bench_policy.py <policy> mps
```

Mitigation, in order: `--inference.type=rtc` (real-time chunking — `tools/demo.sh` sets it by
default, `RTC=1` for `tools/eval.sh`); then a smaller `n_action_steps`; then fall back to ACT,
which is ~15x cheaper per recompute.

Related: [[10-evaluate]], [[vla-demo-plan]], [[macbook-m3]].

## Resumen (ES)

Una política por chunks no es lenta de forma uniforme: recalcula un bloque caro y luego repite pasos gratis. Lo que importa es el costo del recálculo (SmolVLA 152 ms en la 5060 Ti, ACT 10 ms). Medir en la Mac con `tools/bench_policy.py` y usar `--inference.type=rtc`.
