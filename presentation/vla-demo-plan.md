# VLA talk — live demo plan ("From Token to Torque", AI Medellín)

Slides repo: https://github.com/Youngermaster/VLA-introduction-slides (Slidev, ES/EN, `/practice` mode,
offline). The deck's title metaphor says "SO-101"; **the hardware on stage is an SO-100 pair** —
say "SO-ARM100 / SO-100" when pointing at the arm, or fix the wording in the deck.

## What the deck already commits to (read this before changing anything)

Slide `demo-live` (`slides.md:439-487`) and `monologue/es.md` §demo-live promise **exactly two
instructions, 4 minutes, act 04 of 5**:

1. `agarra el Complejo B` — run it, **stay silent while it runs**.
2. Reposition the objects.
3. Change **only the sentence** to `agarra el frasco de zinc`, saying it out loud while typing.
4. When the arm goes to the other object — stop talking and let them applaud.
5. Then: *"No hay un if en ninguna parte."*

Failure protocol is already written: do not retry more than twice, press **B** for the backup video,
move on without drama (`backup-demo`, `slides.md:514`).

So the demo is **language conditioning on two medicine objects** — not stacking. "Agarra el rojo,
encima" belongs to the *animated* `act-vs-vla` scene; making it real is [[2026-09-cubes-stacking-vla]].

### Gaps between the deck and reality (2026-09-27)

| Deck says | Reality | Fix |
|---|---|---|
| `--policy.path=$HF_USER/smolvla-medicamentos` | nothing is on the Hub; the policy is a local checkpoint named `smolvla_so100_medicament_box` | push it ([[11-hub-sync]]) and align the name, or edit `slides.md:465` |
| `--robot.type=so101_follower` (`slides.md:466`) | the arm is an **SO-100** | change to `so100_follower` — this line is run on stage |
| two instructions | only the box dataset exists (50 eps); no zinc bottle | record the bottle dataset ([[2026-09-medicaments-vla]]) |
| `agarra el Complejo B` (Spanish) | the dataset's task string is English | re-record or `modify_tasks`; the sentence you say must be the sentence it was trained on |
| "SO-101" in 15 places (README, locales, monologue) | SO-100 | cosmetic except `slides.md:466`, but worth fixing for honesty |
| `--device=mps` | correct for `lerobot-rollout` (`--policy.device` is the *training* flag) | the deck's own stage note already says this — it is right |

## Running it

`tools/demo.sh "<instruction>" [seconds]` is that command wired to the current machine (it reads
ports, cameras and the rename map, and enables `--inference.type=rtc`). Fallback:
`lerobot-replay` of a recorded episode ([[07-inspect-replay]]) — identical motion, no inference.
Keep it ready in a second terminal; the audience still sees the arm move.

## Machine on stage: MacBook Pro M3 ([[macbook-m3]])

How the policy gets here: trained on the desktop, pushed to the Hub, pulled on the Mac — the folder,
the version rule and what else must travel are in [[policy-travels-as-a-folder]]. The scene kit is not
optional: a new table breaks the policy ([[policy-does-not-survive-a-new-table]]).

Pre-flight (**a week before** for the `mps` dry run; the rest the day before, on Wi-Fi):
- [ ] Desktop and Mac on the same lerobot commit (experiment note records it).
- [ ] `machines/macbook.env` filled and committed (ports, camera indices).
- [ ] Arms identified, not assumed: `uv run python tools/identify_arms.py` prints FOLLOWER/LEADER
      6/6 ([[identify-arms-by-homing-offset]]).
- [ ] **Continuity Camera off on the iPhone.** It steals an index and hangs the run with a
      `TimeoutError` ([[iphone-continuity-camera-breaks-runs]]). This killed the first Mac teleop.
- [ ] Cameras verified **by content, not by index**: `uv run python tools/check_cameras.py` — `top`
      and `base` must match their references in `assets/camera-reference/`; then
      `uv run python tools/verify_cameras.py so100_medicamentos`, where every recorded key must
      best-match itself ([[camera-order-matters]]). The wrist has no reference on purpose — its view
      follows the arm pose, so a single frame proves nothing.
- [ ] **Light up to the recorded brightness.** Measured 2026-09-29: the Mac's feeds were 44-64% of
      the dataset's (top 91 vs 180, base 67 vs 152). The policy keys off pixels, so this is the most
      likely cause of a demo that works at home and misses on stage.
- [ ] Calibration JSONs copied; `tools/teleop.sh` shows no offset.
- [ ] Policy **and its VLM backbone** pulled. SmolVLA loads `HuggingFaceTB/SmolVLM2-500M-Video-Instruct`
      from the Hub at construction time — it is a *separate* download from the policy, so pulling only
      the policy still leaves the demo dead offline. Loading the policy once on Wi-Fi caches both.
      Dataset pulled too, for the `lerobot-replay` fallback and `verify_cameras.py`.
- [ ] `uv run python tools/bench_policy.py "$DEMO_POLICY" mps` — the recompute must stay well under
      the chunk duration, or the arm stutters ([[policy-inference-is-bursty]]). On the 5060 Ti it is
      152 ms per chunk; if the Mac is over ~1.5 s, demo the ACT policy instead.
- [ ] Inference dry run with `tools/eval.sh` at the venue lighting if possible; measure loop rate.
- [ ] Exposure/white balance: cannot be locked on macOS ([[lock-exposure-and-white-balance]]) — bring
      your own light and re-check the feeds at the venue.
- [ ] Terminal has Accessibility permission (arrow keys).
- [ ] rerun window arranged on the projector (camera feeds are a good visual).
- [ ] Scene kit: mat with spawn area, tray, box, bottle, wrist light, tape to fix everything.
- [ ] Power strip; the arms' PSU; USB-C hub with cameras and arms on separate ports.

Command cheat-sheet (after `source tools/env.sh macbook`):

```bash
tools/teleop.sh                                   # 1. teleop
tools/eval.sh so100_medicament_box ${HF_USER}/smolvla_so100_medicament_box 3   # 2. policy (records eval_*)
$RUN lerobot-replay --robot.type=$ROBOT_TYPE --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
     --dataset.repo_id=${HF_USER}/so100_medicament_box --dataset.episode=0             # 4. fallback
```

## Story beats that come from this vault

- Data collection is the product: [[good-dataset-rules]] in one slide (fixed scene, vary the object, → promptly).
- Why the chess demo failed ([[2026-07-13-fools-mate-act]]) is a better teaching moment than a success:
  action chunking, averaging over inconsistent demos, small objects.
- ACT vs SmolVLA: same dataset, ACT = single-task baseline; VLA = pretrained VLM + language.
- Compute reality: 20k ACT steps ≈ 26 min on a 5060 Ti; SmolVLA fine-tune on an A10G via HF Jobs ([[hf-cloud-gpu]]).

## Risks

| Risk | Mitigation |
|---|---|
| Venue lighting differs from training | record 10 episodes at the venue in the morning and fine-tune? unrealistic — instead record the training set with 2-3 lighting levels, and bring the wrist light |
| Venue table / background differs | bring the mat + tray + camera mounts as one kit — [[policy-does-not-survive-a-new-table]] |
| USB / power glitch on stage | [[incorrect-status-packet]] checklist; spare cables; replay fallback |
| `mps` inference too slow | run ACT baseline instead of SmolVLA, or lower fps; test beforehand |
| Camera index shift on the Mac | probe at the venue; `.env` is a one-line fix |

## Resumen (ES)

Demo en la charla con la MacBook: teleoperación, luego la política recogiendo la caja de medicamento
con instrucción en lenguaje, y `lerobot-replay` como plan B. El hardware es SO-100 aunque el título
diga SO-101. Preparar todo el día anterior con Wi-Fi (modelo y dataset descargados, permisos, luz).
