# A VLA is not a two-hour project: 50 episodes and hours of GPU, or nothing

Asked on 2026-09-13 at 20:15: "can I have a SmolVLA picking a medicament box by 22:30 with 10 episodes?"
The honest answer, with the numbers that decide it:

- **Data floor.** HF's own SO-100 pick-place recipe (`docs/source/smolvla.mdx`) is **50 episodes =
  5 object positions × 10 repeats**; they report that 25 episodes "was not enough, leading to bad
  performance". Our 13-episode Lego run was "inconclusive" ([[2026-06-29-lego-skeleton-act]]).
  10 episodes produces a policy that *reacts*, not one that *works*.
- **Compute floor.** SmolVLA fine-tune: 20k steps ≈ **4 h on an A100** at batch 64. On the 5060 Ti
  (batch 8, encoder frozen) plan on ~1 s/step → an overnight run. ACT on the same data is ~30 min for
  10k steps and is the cheaper first signal ([[08-train-act]]).
- **The MacBook does not train.** M3 base, 16 GB unified memory, `mps`: ACT only as a smoke test,
  SmolVLA training several s/step. It records and runs inference ([[macbook-m3]]).
- **ZeroGPU minutes are not Jobs.** The "5 min ZeroGPU" on the billing page is the *Spaces* quota.
  HF Jobs need a positive prepaid credit balance: `t4-small` $0.40/h, `a10g-small` $1.00/h,
  `a10g-large` $1.50/h, `a100-large` $2.50/h (checked 2026-09-13) — [[hf-cloud-gpu]].
- **First-time setup eats the evening.** The Mac had no venv, no `hf`, empty calibration cache,
  `TODO` ports; 0.6.2 also needs `--extra core_scripts` ([[lerobot-06-extras]]).

What a 2-hour window *can* buy: a working recording station, 15-20 episodes pushed to the Hub, an
ACT job launched and a SmolVLA job left running overnight. Decision taken instead: record 50 episodes
on the desktop where everything already works, chain ACT → SmolVLA overnight, evaluate next morning
([[2026-09-medicaments-vla]]).

Related: [[good-dataset-rules]], [[updt-s-is-your-timer]], [[09-train-vla]].

## Resumen (ES)

Un VLA no sale en dos horas: HF necesita 50 episodios (25 no bastan) y ~4 h de A100 para 20k pasos.
La Mac no entrena (mps); los minutos de ZeroGPU no sirven para Jobs. Grabar 50 en el escritorio,
encadenar ACT → SmolVLA de noche y evaluar por la mañana.
