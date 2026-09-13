# VLA Learning Roadmap — SO-100 + LeRobot

## Context

You own an SO-100 leader/follower pair (Feetech STS3215 7.4 V) and three cameras (a low-quality
webcam on a pole above the arms, plus better cameras on the wrist and at the base). You are
strong in AI/ML and agents but new to robotics and to Vision-Language-Action models.

The goal of this plan is **not** to ship a product. It is to build a durable mental model of how
VLAs work, by pairing each theory block with something you actually implement — either on the
real arm or as a small from-scratch model. The working directory
`/home/jayoungh/personalProjects/vlaLerobot` is currently empty, so everything here is greenfield.

The organizing idea: **modern VLAs are three things stacked** — (1) a vision-language backbone,
(2) a generative action head that emits *chunks* of continuous actions, (3) trained by imitation
on teleoperated demonstrations. You will build each layer bottom-up, from scratch, on your own
data, and only *then* fine-tune the real thing (SmolVLA, π₀). That order is what makes the
theory stick.

### Your hardware, honestly assessed

| Component | Status | Implication |
|---|---|---|
| RTX 5060 Ti 16 GB | Blackwell, sm_120 | Needs PyTorch cu128+ wheels. ACT/diffusion policies: comfortable. SmolVLA (450M) full fine-tune: fits at batch 8–16 in bf16, tight. π₀/π₀.5 (3.3B): **LoRA only**, and still tight — plan to rent for those. |
| 32 GB RAM | Adequate, not generous | 3 cameras × 30 Hz video decoding during training is the RAM/CPU bottleneck, not the GPU. Keep 640×480. |
| Ryzen 7 8700F (16 threads) | Fine | Video decode and dataloader workers live here. |
| SO-100, STS3215 7.4 V | Older/weaker than SO-101 | Fully supported in LeRobot v0.5 (`so100_follower` / `so100_leader`). More backlash and lower payload than SO-101 — keep tasks light (foam cubes, Lego, small blocks). |
| 3 cameras | Good, but bandwidth-constrained | Wrist + base are your primary pair. The pole webcam is a bonus third view. USB bandwidth contention is a real failure mode — see Phase 0. |

### Hard constraint to internalize early

Data quality dominates everything. A 450M model fine-tuned on 50 clean, consistent episodes beats
a 3B model on 200 sloppy ones. LeRobot's own guidance: ~50 episodes minimum, ~10 per spatial
variation, cameras **rigidly fixed**, and the sanity check *"could you do this task yourself
looking only at the camera feeds?"* If the answer is no, no model will either.

---

## What you get "almost from zero" vs. what you build from zero

This is the split you asked for.

### Almost from zero (use what exists — do NOT reimplement)

| Thing | Why not rebuild it |
|---|---|
| Servo bus driver / Feetech SDK | Solved, boring, easy to brick motors. |
| Calibration, teleoperation loop, dataset recording | `lerobot-calibrate`, `lerobot-teleoperate`, `lerobot-record` are mature and handle timing/video encoding correctly. |
| `LeRobotDataset` format + Hub hosting | Well-designed columnar+video format. Read it, don't replace it. |
| Pretrained VLA weights (`lerobot/smolvla_base`, π₀, π₀.5) | 30k GPU-hours of pretraining you cannot reproduce. |
| Training loop plumbing, LoRA/PEFT integration, checkpointing | `lerobot-train` handles it, including `--policy.peft_config.use_peft=true`. |
| Real-time inference, action queue, RTC | `lerobot-rollout` with `--inference.type=rtc`. |

### From zero (this is where the learning actually happens)

| Thing you build | What it teaches |
|---|---|
| Naive BC policy (~200 lines) | Why single-step regression fails on real robots — jerk, drift, compounding error. |
| Action chunking + temporal ensembling | The single most important trick in modern VLAs. |
| Toy diffusion policy on 2D multimodal data | Why generative heads exist at all: demonstrations are multimodal, MSE regression averages modes into garbage. |
| Conditional flow matching head | What π₀ / SmolVLA / most 2026 VLAs actually use. |
| **Mini-VLA**: frozen SigLIP + small LM + flow-matching action expert | You will have built, end to end, the exact architecture of SmolVLA at 1/10 scale, on your own robot's data. |
| Evaluation harness + generalization rubric | Nobody hands you this. It's what separates a demo from a result. |

---

## The Roadmap

Assume **~10 h/week**. Total ≈ 16 weeks. Compress or stretch freely; the *order* matters more
than the calendar.

---

### Phase 0 — Hardware baseline and environment (Week 1)

**Theory (light, ~2 h)**
- Position-controlled servos: the STS3215 has an internal PID; you command *goal positions*, not
  torques. This is why "control theory" is mostly not on your critical path.
- Encoders, calibration, and normalization: why LeRobot maps raw ticks → normalized ranges, and
  why a policy trained on one arm transfers to another only if both are calibrated identically.
- Observation and action spaces: `observation.state` (6 joint positions) + `observation.images.*`
  → `action` (6 target joint positions). That's the entire interface. Everything else is learning.
- Control frequency and latency: why 30 Hz, and what happens when inference takes 100 ms.

**Build**
1. `uv venv --python 3.12` (LeRobot v0.5 requires Python ≥3.12; your system Python is 3.14, which
   is too new for parts of the wheel ecosystem — pin 3.12).
2. Install PyTorch from the **cu128 or cu130 index** first, verify `torch.cuda.get_device_capability()`
   returns `(12, 0)` and a matmul actually runs. Blackwell on a stale wheel fails with
   *"sm_120 is not compatible with the current PyTorch installation"* — get this out of the way now.
3. `pip install -e ".[feetech]"` for LeRobot + the Feetech SDK.
4. `lerobot-find-port` → record both `/dev/ttyACM*` ports. Add a udev rule mapping each arm to a
   stable symlink (`/dev/so100_leader`, `/dev/so100_follower`) so the ports stop swapping on reboot.
5. `lerobot-setup-motors` (leader and follower), then `lerobot-calibrate` for both with stable
   `--robot.id` / `--teleop.id` values. **Use the same ids forever** — calibration files are keyed on them.
6. `lerobot-teleoperate` with `--display_data=true` and all three cameras declared.

**Mini-project 0 — the diagnostic script you will use all semester**

Write `hardware/bench.py`: drives the teleop loop yourself via the Python API
(`SO100Leader.get_action()` → `SO100Follower.send_action()`), and logs:
- Achieved loop rate vs. target 30 Hz.
- Per-joint tracking error (leader command vs. follower `get_observation()` state).
- Camera frame arrival jitter per camera.

**What you're looking for:** whether all three cameras at 640×480@30 actually sustain 30 Hz on
your USB topology. Three MJPEG streams on one USB controller will silently drop to 15 Hz or stall
the control loop. Fix by (a) forcing MJPEG rather than raw, (b) spreading cameras across different
physical USB controllers (`lsusb -t` shows the tree), (c) dropping the pole webcam to 15 Hz or
lower resolution.

**Deliverable:** teleoperation running smoothly, a latency/jitter report, stable device symlinks.

**Gate:** do not proceed until you can teleoperate for 5 minutes with no dropped frames and
< 5° steady-state tracking error.

---

### Phase 1 — Imitation learning and why naive BC fails (Weeks 2–3)

**Theory (~6 h)**
- Behavioral cloning as supervised learning: `π(a|o)` fit by regression on (observation, action) pairs.
- **Covariate shift / compounding error** — the central problem. Ross & Bagnell's DAgger paper is
  the canonical treatment; read the problem statement even if you skip the algorithm.
- **Multimodality of human demonstrations**: two humans (or the same human twice) reach the same
  cube via different trajectories. MSE regression on multimodal data converges to the *mean* of the
  modes, which is often an invalid action. Hold onto this — it's the whole reason Phase 3 exists.
- What makes a good dataset: variation budgeting, why you record 10 episodes per cube position
  rather than 50 positions × 1, why cameras must not move.

**Build — from scratch**
1. Record your first real dataset with `lerobot-record`: a pick-and-place task, 5 spatial
   variations × 10 episodes = 50 episodes, `--dataset.single_task="Pick up the red cube and put it
   in the bin"`, `--dataset.episode_time_s`, `--dataset.reset_time_s` tuned, all three cameras
   declared with consistent names (`wrist`, `base`, `top`).
2. `lerobot-replay` episode 0 on the follower. This tests hardware repeatability and is a great
   reality check on how much the arm's backlash costs you.
3. **`from_scratch/01_bc/`** — write your own training script that reads `LeRobotDataset` directly
   (use the class, write your own loop): a ResNet18 or small CNN encoder per camera + joint state
   → MLP → 6 actions, MSE loss. No LeRobot policy code.
4. Deploy it yourself: a ~60-line inference loop that reads observations, runs your net, sends
   actions at 30 Hz.

**Expected outcome: it will be bad.** Jerky, drifting, freezes mid-reach. This is the point.
Write down *exactly how* it fails in `notes/01-bc-failure-modes.md`. Every architectural choice
in the rest of the roadmap is an answer to one of these failures.

**Reading:** ALOHA/ACT paper §problem setup; the DAgger problem statement; LeRobot's
"what makes a good dataset" blog post.

---

### Phase 2 — Action chunking, transformers, ACT (Weeks 3–5)

**Theory (~8 h)**
- **Action chunking**: predict `k` future actions (typically 50 at 30 Hz ≈ 1.7 s) instead of one.
  Cuts the effective horizon by `k`, which directly attacks compounding error, and lets the policy
  commit to one mode instead of dithering.
- **Temporal ensembling**: overlapping chunks averaged with exponential weighting → smooth motion.
- ACT's architecture: a DETR-style encoder-decoder transformer, with a **CVAE** whose latent `z`
  absorbs demonstrator style variation, so the decoder isn't forced to average modes.
- Why the CVAE latent is set to zero at inference, and what that means.

**Build**
1. **From scratch (`from_scratch/02_chunking/`)**: take your Phase 1 network, change the head to
   output `(k, 6)` instead of `(6,)`, add temporal ensembling in the inference loop. Nothing else.
   Measure the improvement. This one change should be dramatic — that's the lesson.
2. **Use what exists**: train real ACT on the same dataset —
   `lerobot-train --policy.type=act --dataset.repo_id=... --policy.device=cuda`.
   ~100k steps, comfortable on 16 GB.
3. Evaluate with `lerobot-rollout --strategy.type=base --policy.path=...`.
4. Read `src/lerobot/policies/act/modeling_act.py` line by line and diff it mentally against your
   own implementation. This is the highest-value code-reading exercise in the whole roadmap.

**Deliverable:** a working ACT policy on real hardware + a written comparison of your
from-scratch chunked policy vs. ACT (`notes/02-chunking.md`). You now have a **baseline** for
everything that follows.

**Reading:** ACT / "Learning Fine-Grained Bimanual Manipulation with Low-Cost Hardware" (Zhao et al., 2023).

---

### Phase 3 — Generative action heads: diffusion and flow matching (Weeks 5–7)

This is the **most important theory phase**. Almost every 2026 VLA differs from ACT primarily in
its action head, and that head is a generative model.

**Theory (~12 h)**
- DDPM: forward noising process, reverse denoising, `ε`-prediction, the training objective.
  You need the *mechanics*, not the full score-matching derivation.
- **Diffusion Policy**: diffusion over action *sequences* conditioned on observations. Why it
  handles multimodality where MSE cannot.
- **Conditional Flow Matching / rectified flow**: learn a velocity field transporting noise → data
  along (nearly) straight paths. Simpler objective than diffusion, and crucially **fewer inference
  steps** — which is why π₀ and SmolVLA use it and diffusion policies are being displaced.
- The competing approach: **discretized action tokens** (RT-2, OpenVLA, π₀-FAST with the FAST
  tokenizer). Understand the tradeoff — autoregressive token generation is simple and reuses the
  LM head, but quantizes continuous control and is slower per action.
- Inference latency budget: why a 10-step denoiser at 30 Hz control is a hard engineering problem,
  and what Real-Time Chunking (RTC) does about it.

**Build — from scratch, three escalating steps**
1. **`from_scratch/03_generative/toy_2d.py`** — a deliberately trivial dataset: points on two
   crossing spirals, or a 2D "reach around the obstacle either left or right" dataset. Fit it with
   (a) MSE regression, (b) DDPM, (c) conditional flow matching. Plot all three. You will *see* MSE
   collapse to the invalid midpoint and the generative models capture both modes. **Do not skip
   this.** It is 150 lines and it is the moment VLAs start making sense.
2. **`from_scratch/03_generative/flow_policy.py`** — a flow-matching action-chunk head on your real
   robot dataset: same vision encoder as Phase 2, but the head is a velocity field
   `v_θ(a_t, t, context)` and inference integrates it over ~10 Euler steps.
3. **Use what exists**: train LeRobot's `diffusion` policy on the same dataset and compare against
   your flow head and against ACT.

**Deliverable:** `notes/03-generative-heads.md` — a written explanation, in your own words, of why
generative action heads replaced regression, with your own toy-2D plots as evidence.

**Reading:** Diffusion Policy (Chi et al., 2023); Flow Matching for Generative Modeling
(Lipman et al., 2022); Rectified Flow (Liu et al., 2022); the FAST tokenizer paper.

---

### Phase 4 — Vision-language backbones and the mini-VLA (Weeks 7–9)

**Theory (~12 h)**
- ViT and SigLIP: images → patch tokens. Why SigLIP's contrastive pretraining gives useful
  robot-relevant features off the shelf.
- VLM anatomy: PaliGemma (π₀'s backbone), SmolVLM2 (SmolVLA's backbone). How image tokens and text
  tokens get interleaved into one sequence.
- **What makes a VLM into a VLA**: the language instruction conditions the action head, so one
  policy serves many tasks and can (sometimes) generalize to novel phrasings.
- Architectural taxonomy — be able to place any new model on this map:
  - *Action expert vs. LM head*: π₀, π₀.5, SmolVLA attach a separate flow-matching expert;
    RT-2, OpenVLA, π₀-FAST emit action tokens from the LM head itself.
  - *Which layers see robot state*: SmolVLA feeds sensorimotor state as an extra token and
    cross-attends the expert to only half the VLM's layers (a deliberate speed/quality tradeoff —
    read the SmolVLA paper's ablations on this specifically).
  - *Frozen vs. tuned backbone*: what LoRA changes and why it's the only option on 16 GB for 3B models.
- Cross-embodiment pretraining: Open X-Embodiment, why a model pretrained on 20 other robots
  transfers to your SO-100 at all, and what "embodiment gap" means concretely.

**Build — the capstone from-scratch project**

**`from_scratch/04_mini_vla/`** — assemble a real VLA at small scale:
- Frozen SigLIP-base as the vision encoder over your wrist + base cameras.
- A small frozen text encoder (or a tiny LM) for the instruction string.
- A trainable cross-attention **action expert** with the **flow-matching head from Phase 3**.
- Trained on a **multi-task** dataset you record: 3–4 distinct tasks
  ("pick up the red cube", "pick up the blue cube", "push the cube to the left", "put the cube in
  the bin"), ~40 episodes each, with correct per-episode task strings.
- Success criterion: swapping the language instruction at inference changes the behavior.

This will underperform SmolVLA — of course it will, it has no large-scale pretraining. That
contrast *is* the lesson, and it sets you up perfectly for Phase 5.

**Reading:** SmolVLA (arXiv 2506.01844) — read this one twice, it is the closest to your setup;
π₀ (Black et al., 2024); OpenVLA; RT-2; the Open X-Embodiment paper.

---

### Phase 5 — Fine-tuning real VLAs on your arm (Weeks 9–12)

Now you use the big models, and you understand every component.

**Theory (~6 h)**
- LoRA/PEFT: which matrices get adapters, rank selection, why it's ~memory-free relative to full FT.
- Catastrophic forgetting vs. the (empirically surprising) resistance of pretrained VLAs to it.
- Real-Time Chunking: how to keep 30 Hz control with a policy whose forward pass takes ~50–100 ms.
- Async inference: policy server / robot client split, and when it's worth it.

**Build**
1. **SmolVLA full fine-tune** — your primary target, and the right size for your GPU:
   ```
   lerobot-train --policy.path=lerobot/smolvla_base \
     --dataset.repo_id=$HF_USER/<your-dataset> \
     --batch_size=<start at 8, raise until OOM> --steps=20000 \
     --policy.device=cuda --wandb.enable=true
   ```
   Expect ~10–16 GB at batch 8. Budget 6–12 h on a 5060 Ti (the 4 h figure in the docs is for an A100).
   Use bf16 and 2 cameras for the main runs; keep the third recorded for ablation.
2. **Deploy and evaluate**:
   ```
   lerobot-rollout --strategy.type=base --policy.path=$HF_USER/<model> \
     --robot.type=so100_follower --robot.port=/dev/so100_follower \
     --robot.cameras="{...}" --task="<exact string from your dataset>" \
     --inference.type=rtc --inference.rtc.execution_horizon=10
   ```
   The `--task` string **must match** what you recorded. This trips up everyone once.
3. **π₀ / π₀.5 with LoRA** — `--policy.type=pi0 --policy.peft_config.use_peft=true`. At 3.3B this
   is genuinely tight on 16 GB; expect to fight it. This is the right moment to use
   `lerobot-train --job.target=a10g-small` (HF Jobs, pay-as-you-go) rather than burning a week on
   memory tuning. Renting an A10G/A100 for a few hours is the correct engineering call here.
4. **Ablation study** (the actual scientific content of this phase): same dataset, compare
   ACT vs. diffusion vs. SmolVLA vs. π₀-LoRA vs. your Phase 4 mini-VLA on identical eval episodes.

**Deliverable:** a fine-tuned SmolVLA on the Hub that follows multiple language instructions on
your SO-100, plus `notes/05-ablation.md` with the comparison table.

---

### Phase 6 — Evaluation, generalization, and where to go next (Weeks 12–16)

**Theory (~6 h)**
- What "success rate" actually means and why single-number reporting is misleading.
- Generalization axes, tested independently: novel object position → novel distractor → novel
  lighting → novel object instance → novel instruction phrasing → novel task composition.
  The 2026 literature's recurring finding: VLAs have **robust motor skills but brittle language
  grounding** — they'll execute a beautiful grasp on the wrong object. Design your eval to expose this.
- Beyond pure imitation: HIL-SERL and RL fine-tuning; DAgger-style interactive correction
  (`lerobot-rollout --strategy.type=dagger` gives you this out of the box).

**Build**
1. **`eval/protocol.md` + `eval/score.py`** — a fixed eval suite: N trials per condition, scripted
   initial states, blind scoring rubric, per-axis breakdown. Build this from scratch; it's genuinely
   not provided and it's what makes your results mean anything.
2. Run the full generalization matrix against your best policy.
3. Pick **one** direction to go deep:
   - **RL fine-tuning** — HIL-SERL on top of your SmolVLA to push success rate past the imitation ceiling.
   - **Sim-to-real** — MuJoCo (not Isaac Sim: better contact fidelity for manipulation, `pip
     install mujoco`, and it won't compete with training for your 16 GB). Official SO-101 MJCF is
     in MuJoCo Menagerie, and you can drive the simulated follower with your *real* leader arm.
     Multiplies your data budget and gives reproducible eval, but adds a domain-gap problem — and
     VLA vision backbones are pretrained on real photographs, so MuJoCo's OpenGL renders are
     out-of-distribution for them.
   - **Long-horizon / hierarchy** — multi-stage tasks, subtask annotation (LeRobot v0.5 added
     subtask annotation tooling for exactly this), SARM-style stage-aware rewards.
   - **Contribute upstream** — LeRobot v0.5 supports third-party policy plugins via pip. Package
     your mini-VLA as one.

---

## Repository scaffolding to create

```
vlaLerobot/
├── README.md                  # roadmap status, current phase, links to notes
├── pyproject.toml             # uv-managed, python 3.12 pinned, torch from cu128 index
├── notes/                     # ← the knowledge deliverable; one .md per phase
│   ├── 00-hardware.md
│   ├── 01-bc-failure-modes.md
│   ├── 02-chunking.md
│   ├── 03-generative-heads.md
│   ├── 04-vla-anatomy.md
│   └── 05-ablation.md
├── hardware/
│   ├── bench.py               # Phase 0 latency/jitter/tracking diagnostic
│   ├── cameras.py             # camera index discovery + bandwidth check
│   └── udev/99-so100.rules    # stable /dev symlinks for leader & follower
├── from_scratch/
│   ├── common/dataset.py      # thin wrapper over LeRobotDataset for your own training loops
│   ├── common/deploy.py       # generic 30 Hz inference loop for any of your policies
│   ├── 01_bc/
│   ├── 02_chunking/
│   ├── 03_generative/         # toy_2d.py, flow_policy.py
│   └── 04_mini_vla/           # SigLIP + text encoder + flow-matching action expert
├── experiments/               # one dir per lerobot-train run: exact command, config, results
├── eval/
│   ├── protocol.md            # fixed conditions, trial counts, scoring rubric
│   └── score.py
└── datasets/
    └── cards/                 # recording protocol per dataset: variations, camera geometry, task strings
```

**Reuse rather than rewrite:** `LeRobotDataset` (loading, video decode, normalization stats),
`lerobot.robots.so_follower.SO100Follower` / `lerobot.teleoperators.so_leader.SO100Leader`
(hardware I/O), `lerobot.cameras.opencv.OpenCVCameraConfig`, and
`lerobot.utils.visualization_utils` (rerun logging). Your from-scratch code should own the
*model and the training objective* — nothing below that line.

---

## Practical notes specific to your setup

- **Camera naming is permanent.** Whatever you call them in `--robot.cameras` at record time must
  match at rollout time. Pick `wrist`, `base`, `top` on day one and never change them.
- **Two cameras for main runs, three recorded.** Record all three so you can ablate, but train the
  expensive models on wrist + base. The pole webcam's quality is the least of its problems — it's
  the 50% extra video decode and VRAM cost that will hurt on 16 GB / 32 GB.
- **The wrist camera is your highest-value view** for manipulation. If forced to choose one, choose it.
- **Rigidly mount everything.** A camera that shifts 2 cm between recording and evaluation
  invalidates the dataset. Clamp or hot-glue the pole and base mounts.
- **`--dataset.streaming_encoding=true`** on recording — v0.5 added it and it removes the dead time
  between episodes, which materially improves how many episodes you'll actually record.
- **Push datasets to the Hub.** They're your real asset, they're small, and the online dataset
  visualizer is genuinely useful for spotting bad episodes.
- **Weights & Biases from day one** (`--wandb.enable=true`). You will run dozens of trainings and
  the ablation table in Phase 5 depends on having comparable logs.
- **Budget for renting.** ~$5–20 of A10G/A100 time via `--job.target` at the π₀ stage will save you
  a week. Your 16 GB card is the right tool for Phases 0–4 and for SmolVLA; it is the wrong tool
  for 3B full fine-tunes.

---

## Reading list

**Decision: real hardware throughout.** Simulation was considered and deliberately declined as the
primary track. MuJoCo remains available as an optional Phase 6 branch (official SO-101 MJCF exists
in MuJoCo Menagerie, and LeRobot has LIBERO/Meta-World eval support), but the roadmap above runs
on the real SO-100.

### Books — foundations (all legally free from their authors)

There is **no good VLA textbook** and there won't be one soon; the field turns over faster than
books ship. These five cover the layers underneath. The VLA layer itself is the paper list below.

| # | Book | What it's for here | Read |
|---|---|---|---|
| 1 | **Understanding Deep Learning** — Prince (MIT Press, udlbook.com) | Highest value. Best-illustrated ML book there is. | **Ch. 18 diffusion**, Ch. 12 transformers, Ch. 17 VAEs → Phases 3–4 |
| 2 | **Underactuated Robotics** + **Robotic Manipulation** — Tedrake (underactuated.mit.edu, manipulation.csail.mit.edu) | Robotics vocabulary + imitation learning from a Diffusion Policy co-author. Updated Fall 2025. | **Underactuated Ch. 21 "Imitation Learning"** → Phases 1–3. Note: the *Manipulation* notes have no BC/diffusion chapter. |
| 3 | **Modern Robotics** — Lynch & Park (Cambridge, free PDF + Coursera) | What your 6 joint values physically mean. 2017, zero learning content — read selectively. | Ch. 3–6 (rigid motion, FK, Jacobians, IK), Ch. 9 trajectories → Phase 0 |
| 4 | **Probabilistic ML: Advanced Topics** — Murphy (probml.github.io) | Rigorous backstop when Prince is too light. ~1400 pp — reference, not read-through. | Generative-model chapters → Phase 3 |
| 5 | **RL: An Introduction** — Sutton & Barto 2nd ed. | Policy/trajectory/rollout vocabulary; RL fine-tuning. Skip if already known. | Ch. 1–3 now, rest at Phase 6 |

### Flow matching — the gap books don't cover

Flow matching is what π₀ and SmolVLA actually use, and no textbook covers it well yet
(Prince Ch. 18 is diffusion; Murphy is normalizing flows). Use these instead for Phase 3 —
both are free and both beat any book chapter:

- **MIT 6.S184 — Introduction to Flow Matching and Diffusion Models**, 2026 edition
  (diffusion.csail.mit.edu). Self-contained lecture notes (arXiv 2506.02070), slides, recordings,
  and **labs that build a latent diffusion model from scratch**. Lecture 2 is flow matching:
  conditional/marginal probability paths, vector fields, the training objective. This maps
  one-to-one onto Phase 3.
- **Flow Matching Guide and Code** — Lipman et al., Meta AI (arXiv:2412.06264). ~200 pages by the
  method's inventor, with working code.

### Evaluated and rejected

- **Introduction to Autonomous Robots** (Correll et al., MIT Press 2022) — its DL chapter stops at
  perceptron/MLP/CNN/RNN: no attention, transformers, diffusion, or policies. Roughly half the book
  is mobile robotics (SLAM, localization, mapping, path planning), irrelevant to a fixed-base arm.
  No free PDF (compile the CC-BY-NC-ND LaTeX yourself). **Exception:** the `grasping` chapter
  (friction, contact deformation, suction, parallel-jaw grippers) is directly about your SO-100's
  gripper and explains why grasping is what simulators get wrong. Read that one chapter.
- **StatQuest Illustrated Guide to Neural Networks and AI** — good but introductory; nothing on
  diffusion, flow matching, policies, or robotics. Below the level this project needs.

### Papers — the VLA layer

**Phase 1–2 (foundations)**
1. ACT — *Learning Fine-Grained Bimanual Manipulation with Low-Cost Hardware* (Zhao et al., 2023)
2. DAgger — *A Reduction of Imitation Learning to Structured Prediction* (Ross et al., 2011) — problem statement only
3. LeRobot docs: `il_robots`, `cameras`, and the "what makes a good dataset" blog post

**Phase 3 (generative heads)**
4. *Diffusion Policy* (Chi et al., 2023)
5. *Flow Matching for Generative Modeling* (Lipman et al., 2022)
6. *Rectified Flow* (Liu et al., 2022)
7. *FAST: Efficient Action Tokenization for VLAs* (π₀-FAST)

**Phase 4–5 (VLAs proper)**
8. **SmolVLA** (arXiv 2506.01844) — closest to your hardware; read twice
9. π₀ (Black et al., 2024) and π₀.5
10. OpenVLA; RT-1; RT-2
11. Open X-Embodiment
12. *LeRobot: An Open-Source Library for End-to-End Robot Learning* (arXiv 2602.22818)

**Phase 6 (evaluation and beyond)**
13. HIL-SERL
14. Real-Time Chunking
15. A 2026 VLA survey for the current architecture landscape (e.g. arXiv 2607.06706)
16. VLA-REPLICA — low-cost reproducible real-world VLA benchmarking, directly relevant to your eval design

---

## Verification

Each phase has a concrete, testable gate. Do not advance past a failed gate.

| Phase | Verification |
|---|---|
| 0 | `hardware/bench.py` reports sustained 30 Hz, < 5° tracking error, no camera frame drops over 5 min. `torch.cuda.get_device_capability() == (12, 0)` and a bf16 matmul runs. |
| 1 | 50-episode dataset visible in the HF dataset viewer with all episodes valid. `lerobot-replay` reproduces episode 0 on hardware. Your from-scratch BC policy runs at 30 Hz and fails in ways you have *documented*. |
| 2 | ACT achieves > 50% success on the trained cube positions over 20 rollouts. Your from-scratch chunked policy measurably beats your Phase 1 policy. |
| 3 | Toy-2D plots show MSE collapsing to the mean while diffusion and flow capture both modes. Your flow-matching policy runs on hardware at 30 Hz. |
| 4 | Mini-VLA changes its behavior when you change the instruction string, with the scene held fixed. |
| 5 | Fine-tuned SmolVLA beats ACT on the eval suite and follows ≥ 3 distinct instructions. Ablation table complete. |
| 6 | Full generalization matrix run, with per-axis success rates and a written analysis of where language grounding breaks. |

**End-to-end smoke test at any point:**
```bash
lerobot-teleoperate --robot.type=so100_follower --robot.port=/dev/so100_follower \
  --robot.id=<id> --robot.cameras="{wrist: {...}, base: {...}}" \
  --teleop.type=so100_leader --teleop.port=/dev/so100_leader --teleop.id=<id> \
  --display_data=true
```
If this works, your hardware, calibration, cameras, and environment are all sound.
```bash
lerobot-rollout --strategy.type=base --policy.path=<model> --robot.type=so100_follower \
  --robot.port=/dev/so100_follower --robot.cameras="{...}" --task="<exact training string>" --duration=60
```
If this works, your whole stack is sound.

---

## First concrete steps (if you approve)

1. Scaffold the repo layout above with a `pyproject.toml` pinned to Python 3.12 and torch cu128.
2. Write `hardware/bench.py` and `hardware/cameras.py`.
3. Write `notes/00-hardware.md` as a template and fill it from the bench run.
4. Draft `datasets/cards/` recording protocol for your first pick-and-place task.

Phase 0 install and calibration require you at the keyboard (plugging motors one at a time,
moving joints through their range), so those stay manual — the plan covers the exact commands.
