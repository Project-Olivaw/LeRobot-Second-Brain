# "It was 85-90% on the desktop" — that was a different policy on an easier task

Asked 2026-09-29, after the two-instruction policy missed most grasps on the MacBook. The first
thing to check was not the Mac. The two numbers are not comparable:

| | the 80-90% run | what is running on the Mac |
|---|---|---|
| policy | `smolvla_so100_medicament_box` | `smolvla_so100_medicamentos` |
| instructions | one, English | **two**, Spanish — the model must read the sentence |
| objects on the mat | **one** (the Complejo B box) | **two** — the other one is a distractor |
| target | ESP32 car | chessboard |
| episodes | 50 | 200 (100 + 100) |
| evaluated | yes, several sessions on the desktop | **never — on any machine** |

The two-instruction policy has no desktop number at all: Step 4 of [[14-two-instruction-demo]]
("evaluate on the desktop, then publish") was never filled in — it was trained, pushed and taken
straight to the Mac. So "it worked on Linux" is a memory of a *different, easier* policy.

Why the new task is genuinely harder, not just different: a distractor in frame means the model must
both **choose** the right object and **grasp** it, and choosing wrong costs a whole episode. The
single-object policy could not choose wrong.

**The rule this buys:** never compare a new policy against an old policy's success rate, and never
let a policy reach a demo without a measured number on the machine it was trained on. Evaluating
`smolvla_so100_medicamentos` on the desktop is what separates "the Mac is the problem" from "the
policy is the problem" — one afternoon that decides which of the two to fix.

Related: [[act-limits-small-objects]], [[balance-the-instructions]], [[camera-order-matters]].

## Resumen (ES)

El 80-90% era de `smolvla_so100_medicament_box`: una sola instrucción, **un solo objeto** en la mesa,
destino el carro ESP32, 50 episodios. Lo que corre en la Mac es `smolvla_so100_medicamentos`: dos
instrucciones, **dos objetos** (uno distractor), 200 episodios — y **nunca se evaluó en ninguna
máquina**. No son comparables. Evaluarla en el escritorio es lo que distingue "es la Mac" de "es la
política".
