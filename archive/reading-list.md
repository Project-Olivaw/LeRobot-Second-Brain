# Reading Index — by topic, not by book

**Rule:** read the named section only, when the build step needs it. Never read a whole book
"to prepare". If a topic bites you three times, *then* go read its full chapter.

## Sources (all free)

| Tag | What | Where |
|---|---|---|
| `ETH` | Robot Learning: From Fundamentals to Foundation Models, ETH Zürich Spring 2026 (Oier Mees). Slides + recordings + homework. | cvg.ethz.ch/lectures/Robot-Learning/ |
| `ETH-HW` | Course homework repo (HW3 = imitation learning on an SO-101) | github.com/mees-robot-learning-course/ethz-course-2026 |
| `MIT` | MIT 6.S184 Flow Matching & Diffusion Models, 2026. Notes PDF + 3 labs. | diffusion.csail.mit.edu |
| `UDL` | Understanding Deep Learning — Prince (fallback, free) | udlbook.com |
| `TED` | Underactuated Robotics / Robotic Manipulation — Tedrake (fallback, free) | underactuated.mit.edu · manipulation.csail.mit.edu |
| `MR` | Modern Robotics — Lynch & Park (fallback, free) | Ch. 3–6, 9 only |
| `LR` | LeRobot docs + local source in `vendor/lerobot/` | huggingface.co/docs/lerobot |

---

## Phase 0 — Hardware baseline

| Topic | Read exactly | Why now |
|---|---|---|
| Position-controlled servos, goal positions vs torque | `LR` so100 docs, "Configure the motors" | You're setting motor IDs; wrong mental model = bricked EEPROM |
| Calibration & normalization | `LR` so100 docs, "Calibrate" section | A miscalibrated arm silently corrupts every dataset you record |
| Joint space vs task space, MDP framing | `ETH` Week 2 "Robot Control & MDPs" slides | Decides your action space later (joint vs end-effector) |
| Forward kinematics / Jacobians *(only if blocked)* | `MR` Ch. 4–5 | Only needed if you go to end-effector control or scripted experts |
| Why grasping is hard | Intro to Autonomous Robots, `grasping` chapter | Explains your gripper's failures and sim-to-real gap |

## Phase 1 — Behavioral cloning & why it fails

| Topic | Read exactly | Why now |
|---|---|---|
| Behavioral cloning basics | `ETH` Week 3 "Imitation Learning" slides + recording | The whole phase |
| Covariate shift / compounding error | `ETH` Week 3, DAgger portion | Explains the drift you will observe |
| **DAgger, hands-on** | `ETH-HW` hw3, Exercise 2 | Reference implementation with a known-good success rate |
| Multimodal demonstrations | `ETH` Week 6 "Generative Models", first third | The reason Phase 3 exists — preview it here |
| What makes a good dataset | `LR` blog "what makes a good dataset" | Before you record 50 episodes you can't reuse |

## Phase 2 — Action chunking & ACT

| Topic | Read exactly | Why now |
|---|---|---|
| Sequence models for control, ACT | `ETH` Week 7 "Sequence Modeling and Transformers" | ACT is on the reading list for that week |
| ACT architecture in detail | ACT paper (Zhao 2023) §3 + `vendor/lerobot/src/lerobot/policies/act/modeling_act.py` | Diff the paper against real code |
| CVAE latent | `UDL` Ch. 17 (VAEs) — skim | ACT's latent absorbs demonstrator style |
| Transformers *(only if rusty)* | `UDL` Ch. 12 | Skip if you know them |

## Phase 3 — Generative action heads

| Topic | Read exactly | Why now |
|---|---|---|
| ODEs/SDEs for generative models | `MIT` Lecture 1 + **Lab 1** | Foundation for everything below |
| **Flow matching** | `MIT` Lecture 2 + **Lab 2** | *The* mechanism inside SmolVLA and pi0 |
| Score matching / diffusion | `MIT` Lecture 3-A | The predecessor you're comparing against |
| Classifier-free guidance | `MIT` Lecture 3-B | Shows up in conditioned policies |
| Diffusion Policy (applied) | `ETH` Week 6 + guest lecture by Cheng Chi (its lead author) | Policy-level view of the same math |
| Diffusion, book version *(fallback)* | `UDL` Ch. 18 | If MIT notes move too fast |

## Phase 4 — VLM backbones & mini-VLA

| Topic | Read exactly | Why now |
|---|---|---|
| Latent spaces, DiT, VAEs | `MIT` Lecture 4 + **Lab 3** | You're building an action expert on a latent |
| Generalist / language-conditioned policies | `ETH` Week 9 "Generalist Robot Policies" + guest lecture by Quan Vuong (Physical Intelligence, pi0) | Primary source for the pi0 design |
| SmolVLA architecture | SmolVLA paper arXiv 2506.01844 — **ablations section especially** | Closest model to your hardware & GPU |
| Embodied reasoning | `ETH` Week 10 | Where instruction-following breaks |

## Phase 5 — Fine-tuning real VLAs

| Topic | Read exactly | Why now |
|---|---|---|
| LoRA / PEFT | LeRobot `--policy.peft_config.use_peft` docs | 16GB VRAM makes this mandatory for pi0 |
| Real-Time Chunking | RTC paper + `vendor/lerobot/src/lerobot/policies/rtc/` | Keeps 30Hz control with a slow VLA |

## Phase 6 — Evaluation & beyond

| Topic | Read exactly | Why now |
|---|---|---|
| RL for robots | `ETH` Weeks 4–5 + `ETH-HW` hw4 | If you push past the imitation ceiling |
| HIL-SERL | HIL-SERL paper (Luo et al. 2024) | Human-in-the-loop RL on your arm |
| World models | `ETH` Week 8 | Optional frontier direction |
| Open problems | `ETH` Week 11 | Where the field is stuck |
