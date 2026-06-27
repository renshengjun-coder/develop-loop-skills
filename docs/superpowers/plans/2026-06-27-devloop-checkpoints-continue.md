# Devloop Checkpoints and Continue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add human-gate checkpoints plus `/devloop continue <id>` resume semantics to the devloop skill, package template, and shipped command surfaces without introducing new L3 enforcement requirements.

**Architecture:** This feature is doc-driven because `/devloop` orchestration lives in the devloop skill and its shipped references, not in a local runtime service. The implementation updates the devloop skill contract, persists checkpoint state in the package template via a new `run_control` block, and refreshes all shipped command surfaces so installed packs, initialized projects, and docs present the same checkpoint-aware workflow.

**Tech Stack:** Markdown skills, YAML package template, Bash packaging tests, build-pack pipeline

---

## File Structure

### Modified files

- `scripts/test-build-pack.sh`
  - add pack-level assertions that the built skill and template include `/devloop continue` and `run_control`
- `scripts/test-devloop-cli.sh`
  - add install/init regression checks for installed devloop skill text, initialized package template state, merged `AGENTS.md`, and Cursor rule hints
- `.ai/skills/devloop/SKILL.md`
  - add `/devloop continue`, checkpoint-aware `run` behavior, `run_control` state model, and status reporting rules
- `.ai/skills/devloop/reference.md`
  - update cheat sheet and add checkpoint/resume examples
- `.ai/packages/_template/package.yaml`
  - add the persistent `run_control` block with default running state
- `README.md`
  - update quick start, command tables, and package state docs to describe checkpoints and `continue`
- `AGENTS.md`
  - add `continue` to the devloop trigger list so this repo’s local guidance matches the shipped skill
- `templates/AGENTS.md`
  - add `/devloop continue <id>` to the command table shipped into initialized projects
- `templates/cursor/rules/devloop.mdc`
  - add `continue` to the orchestrator command hint for Cursor projects

### Verification commands

- `./scripts/test-build-pack.sh`
- `./scripts/test-devloop-cli.sh`
- `npm test`
- `./scripts/loop-verify.sh FEAT-001`
- `./scripts/loop-verify.sh --enforce FEAT-003`

---

### Task 1: Add Red Regressions for Shipped Checkpoint and Continue Surfaces

**Files:**
- Modify: `scripts/test-build-pack.sh`
- Modify: `scripts/test-devloop-cli.sh`
- Test: `./scripts/test-build-pack.sh`
- Test: `./scripts/test-devloop-cli.sh`

- [ ] **Step 1: Add pack-level assertions for devloop and package template shipping**

Insert these assertions in `scripts/test-build-pack.sh` after the existing skill presence loop:

```bash
grep -q "/devloop continue <id>" "$PACK/skills/devloop/SKILL.md" \
  || { echo "FAIL: devloop skill missing continue command"; exit 1; }
grep -q "^run_control:" "$PACK/templates/.ai/packages/_template/package.yaml" \
  || { echo "FAIL: package template missing run_control"; exit 1; }
grep -q "/devloop continue <id>" "$PACK/templates/AGENTS.md" \
  || { echo "FAIL: AGENTS template missing continue command"; exit 1; }
grep -q "/devloop start|run|continue|gate|status|classify" "$PACK/templates/.cursor/rules/devloop.mdc" \
  || { echo "FAIL: Cursor rule missing continue command"; exit 1; }
```

- [ ] **Step 2: Add install/init assertions for the installed skill and scaffolded project**

Insert these assertions in `scripts/test-devloop-cli.sh` after the existing installed-skill checks and after `devloop init --with-ci`:

```bash
grep -q "/devloop continue <id>" "$DEVLOOP_HOME/.cursor/skills/devloop/SKILL.md" \
  || { echo "FAIL: installed devloop skill missing continue command"; exit 1; }
```

```bash
[[ -f "$PROJ/.ai/packages/_template/package.yaml" ]] \
  || { echo "FAIL: package template missing"; exit 1; }
grep -q "^run_control:" "$PROJ/.ai/packages/_template/package.yaml" \
  || { echo "FAIL: initialized package template missing run_control"; exit 1; }
grep -q "/devloop continue <id>" "$PROJ/AGENTS.md" \
  || { echo "FAIL: AGENTS.md missing continue command"; exit 1; }
grep -q "/devloop start|run|continue|gate|status|classify" "$PROJ/.cursor/rules/devloop.mdc" \
  || { echo "FAIL: Cursor rule missing continue command"; exit 1; }
```

- [ ] **Step 3: Run pack layout regression to verify it fails before implementation**

Run:

```bash
./scripts/test-build-pack.sh
```

Expected: FAIL with `devloop skill missing continue command` or `package template missing run_control`.

- [ ] **Step 4: Run install/init regression to verify it fails before implementation**

Run:

```bash
./scripts/test-devloop-cli.sh
```

Expected: FAIL with `installed devloop skill missing continue command` or `initialized package template missing run_control`.

- [ ] **Step 5: Leave the suite red and move directly to implementation**

Do not commit the red tests alone. Continue immediately to Task 2 so the branch returns to green before the first checkpoint commit.

---

### Task 2: Implement Checkpoint-Aware Devloop Semantics

**Files:**
- Modify: `.ai/skills/devloop/SKILL.md`
- Modify: `.ai/skills/devloop/reference.md`
- Modify: `AGENTS.md`
- Test: `./scripts/test-build-pack.sh`

- [ ] **Step 1: Add `/devloop continue` to the devloop command surface**

Replace the opening command table in `.ai/skills/devloop/SKILL.md` with:

~~~md
| Command | Behavior |
|---------|----------|
| `/devloop start <id>` | Create package from `_template`, classify, select profile, show execution plan |
| `/devloop run <id>` | Full E2E in **loop** mode (default); pauses at human-gate checkpoints and auto re-entry on gate fail |
| `/devloop run <id> --pipeline` | Single pass per phase; stop on first gate fail |
| `/devloop continue <id>` | Resume from a checkpoint or other stop state using the persisted `run_control` block |
| `/devloop gate <id> <phase>` | L2 gate check for one phase only; reject if `<phase>` is not in `active_profile` phases unless user explicitly overrides |
| `/devloop status <id>` | Summarize `package.yaml`, gates, blockers, phase readiness, and `run_control` |
| `/devloop classify <id>` | Re-run or confirm classification; update `classification.yaml` |
~~~

Also update `AGENTS.md` trigger text from:

~~~md
| Devloop | `.ai/skills/devloop/SKILL.md` | `/devloop start\|run\|gate\|status\|classify` |

to:

~~~md
| Devloop | `.ai/skills/devloop/SKILL.md` | `/devloop start\|run\|continue\|gate\|status\|classify` |
~~~

- [ ] **Step 2: Add the persistent `run_control` state model to the skill**

Insert a new section in `.ai/skills/devloop/SKILL.md` immediately after `## Commands`:

~~~md
## Run Control State

Persist checkpoint and resume state in `.ai/packages/<id>/package.yaml` under `run_control`:

```yaml
run_control:
  state: running | paused | stopped | done
  stopped_at: <phase> | null
  reason: human_gate_checkpoint | gate_fail | escalation | error | interrupted | null
  since: "2026-06-26T09:00:00Z" | null
  next_action: "/devloop continue FEAT-003" | null
  history:
    - { at: "2026-06-26T09:00:00Z", event: paused, phase: requirements, reason: human_gate_checkpoint }
    - { at: "2026-06-26T09:30:00Z", event: continued, phase: requirements, by: user }
```

Back-compat: if `run_control` is absent, treat the package as `state: running` and infer resume from `phases.<name>.status` plus gate files.
~~~

- [ ] **Step 3: Replace the execution flow with checkpoint-aware `run` and explicit `continue` semantics**

Replace the existing `## Execution Steps` block in `.ai/skills/devloop/SKILL.md` with these sections:

~~~md
## Execution Steps

You are driving the SDLC loop for one package. Follow these steps in order. **Re-read package state from disk after each phase completes** — do not rely on conversation memory.

### `/devloop run <id>`

1. Read `.ai/packages/<id>/package.yaml` and list gate files in `.ai/packages/<id>/gates/`.
2. If `run_control.state` is `paused` or `stopped`, report `stopped_at`, `reason`, and `next_action`, then stop. Do **not** advance; require `/devloop continue <id>`.
3. Set or refresh `run_control.state: running`, clear stale `next_action`, and continue with phase driving.
4. After a phase listed in the active profile's `human_gates` passes its gate, write:

```yaml
run_control:
  state: paused
  stopped_at: <phase>
  reason: human_gate_checkpoint
  since: "<current-utc-timestamp>"
  next_action: "/devloop continue <id>"
```

5. Append a `paused` history entry, report the checkpoint, and stop.
6. If all active profile phases pass, set `run_control.state: done`, clear `stopped_at` / `reason` / `next_action`, append a `done` history entry, and set package `status` to `ready_for_merge` or `ready_for_release` as today.

### `/devloop continue <id>`

1. Re-read `.ai/packages/<id>/package.yaml`, `classification.yaml`, and gate files.
2. Resolve the resume point from `run_control.reason`:
   - `human_gate_checkpoint` → start with the next phase after `stopped_at`
   - `gate_fail` or `escalation` → re-enter the failed phase
   - `error` or `interrupted` → re-run the earliest non-archived phase from its start
3. Set `run_control.state: running`, append a `continued` history entry, and drive forward until the next checkpoint, stop, or `done`.
4. If `run_control.state` is already `done`, report completion and do nothing.

### `/devloop status <id>`

Always include:
- `run_control.state`
- `run_control.stopped_at`
- `run_control.reason`
- `run_control.since`
- `run_control.next_action`
~~~

- [ ] **Step 4: Update the devloop reference with the new command and checkpoint examples**

Replace the cheat sheet in `.ai/skills/devloop/reference.md` with:

~~~md
## Command cheat sheet

```text
/devloop start FEAT-003             # create package + classify
/devloop run FEAT-003               # start loop; pauses at human checkpoints
/devloop continue FEAT-003          # resume from checkpoint or stop
/devloop run FEAT-003 --pipeline    # single pass
/devloop gate FEAT-003 design       # gate one phase
/devloop status FEAT-003            # status + run_control summary
/devloop classify FEAT-003          # re-classify
```
~~~

Then add this new example section below the cheat sheet:

~~~md
## Checkpoint example

```text
/devloop run FEAT-003
→ requirements archived
→ requirements gate passed
→ paused at human gate checkpoint
→ next: /devloop continue FEAT-003

/devloop status FEAT-003
→ state: paused
→ stopped_at: requirements
→ reason: human_gate_checkpoint
→ next_action: /devloop continue FEAT-003

/devloop continue FEAT-003
→ resumes at design
```
~~~

- [ ] **Step 5: Rebuild the pack and rerun the pack regression**

Run:

```bash
./scripts/test-build-pack.sh
```

Expected: PASS with `build-pack layout OK`, proving the packed devloop skill now ships `/devloop continue`.

---

### Task 3: Update the Shipped Package Template and Command Surfaces

**Files:**
- Modify: `.ai/packages/_template/package.yaml`
- Modify: `README.md`
- Modify: `templates/AGENTS.md`
- Modify: `templates/cursor/rules/devloop.mdc`
- Modify: `scripts/test-devloop-cli.sh`
- Test: `./scripts/test-devloop-cli.sh`

- [ ] **Step 1: Add `run_control` defaults to the package template**

Insert this block in `.ai/packages/_template/package.yaml` between `status:` and `phases:`:

```yaml
run_control:
  state: running
  stopped_at: null
  reason: null
  since: null
  next_action: null
  history: []
```

- [ ] **Step 2: Update the shipped AGENTS and Cursor rule command lists**

Replace the command table in `templates/AGENTS.md` with:

```md
| Command | Description |
|---------|-------------|
| `/devloop start <id>` | Create package, classify, select profile |
| `/devloop run <id>` | E2E orchestration (loop mode; pauses at human checkpoints) |
| `/devloop continue <id>` | Resume from a checkpoint or other stop state |
| `/devloop run <id> --pipeline` | Single pass per phase |
| `/devloop gate <id> <phase>` | L2 gate check for one phase |
| `/devloop status <id>` | Package status, blockers, and run-control state |
| `/devloop classify <id>` | Re-run complexity classification |
```

Replace the orchestrator hint in `templates/cursor/rules/devloop.mdc` with:

```md
- Orchestrator: `/devloop start|run|continue|gate|status|classify`
```

- [ ] **Step 3: Update README quick start and command documentation**

Make these exact README edits:

1. Replace the quick start snippet with:

```text
/devloop start FEAT-001          # create package, classify, pick profile
/devloop run FEAT-001            # start E2E loop; pauses at human checkpoints
/devloop continue FEAT-001       # resume from the last checkpoint or stop
/devloop status FEAT-001         # package status, blockers, run_control
```

2. Replace the slash-command table rows with:

```md
| `/devloop start <id>` | Create package from template, classify, select profile |
| `/devloop run <id>` | E2E orchestration (loop mode; pauses after human-gate checkpoints) |
| `/devloop continue <id>` | Resume from a checkpoint, gate-fail stop, error stop, or interrupted run |
| `/devloop run <id> --pipeline` | Single pass per phase; stop on first gate fail |
| `/devloop gate <id> <phase>` | L2 gate check for one phase |
| `/devloop status <id>` | Summarize package, gates, blockers, and `run_control` |
| `/devloop classify <id>` | Re-run or confirm complexity classification |
```

3. Add this line under `Where things live`:

```md
| Run control state | `.ai/packages/<id>/package.yaml` → `run_control` |
```

- [ ] **Step 4: Run the install/init regression to verify the shipped scaffold is green**

Run:

```bash
./scripts/test-devloop-cli.sh
```

Expected: PASS with `devloop CLI integration tests`, proving:
- installed devloop skill contains `/devloop continue`
- initialized package template contains `run_control`
- merged `AGENTS.md` contains the continue command
- Cursor rule hint contains `continue`

- [ ] **Step 5: Commit the feature once the shipping surfaces are green**

```bash
git add \
  scripts/test-build-pack.sh \
  scripts/test-devloop-cli.sh \
  .ai/skills/devloop/SKILL.md \
  .ai/skills/devloop/reference.md \
  .ai/packages/_template/package.yaml \
  README.md \
  AGENTS.md \
  templates/AGENTS.md \
  templates/cursor/rules/devloop.mdc
git commit -m "feat: add devloop checkpoints and continue command"
```

---

### Task 4: Run Full Verification and Compatibility Checks

**Files:**
- Test: `npm test`
- Test: `./scripts/loop-verify.sh FEAT-001`
- Test: `./scripts/loop-verify.sh --enforce FEAT-003`

- [ ] **Step 1: Run the full repository test suite**

Run:

```bash
npm test
```

Expected:

```text
PASS: build-pack layout OK
PASS: devloop CLI integration tests
All loop-verify tests passed
```

- [ ] **Step 2: Verify legacy committed demo packages remain valid**

Run:

```bash
./scripts/loop-verify.sh FEAT-001
./scripts/loop-verify.sh --enforce FEAT-003
```

Expected for both commands:

```text
PASS (0 warnings)
```

- [ ] **Step 3: Manually confirm the shipped checkpoint surfaces**

Run:

```bash
rg -n "/devloop continue|run_control|human_gate_checkpoint" \
  .ai/skills/devloop/SKILL.md \
  .ai/skills/devloop/reference.md \
  .ai/packages/_template/package.yaml \
  README.md \
  AGENTS.md \
  templates/AGENTS.md \
  templates/cursor/rules/devloop.mdc
```

Expected: matches in all seven files, showing the command and state model are documented consistently.

- [ ] **Step 4: Do not create an extra verification-only commit**

If all checks pass and no files changed during verification, stop here. Keep the branch ready for review without adding a no-op commit.

---

## Self-Review

### Spec coverage

- Hard-stop after every human gate: covered in Task 2 via checkpoint-aware `/devloop run` edits in `.ai/skills/devloop/SKILL.md`
- Explicit `/devloop continue <id>` command: covered in Tasks 2 and 3 across the lifecycle skill, reference, README, AGENTS surfaces, and Cursor rule
- Persistent `run_control` block in `package.yaml`: covered in Task 3 via `.ai/packages/_template/package.yaml`
- `status` exposes `run_control`: covered in Task 2 and README updates in Task 3
- Backward compatibility with existing demo packages and no new L3 rule: covered in Task 4 via direct `loop-verify.sh` checks on `FEAT-001` and `FEAT-003`
- Pack/build/install surfaces ship the new behavior: covered in Tasks 1 and 3 via `test-build-pack.sh` and `test-devloop-cli.sh`

### Placeholder scan

- No `TBD`, `TODO`, or “similar to above” placeholders remain.
- Every code-edit step includes the exact snippet to add or replace.
- Every verification step includes an exact command and expected result.

### Type consistency

- `run_control.state` values are consistently `running | paused | stopped | done`
- `run_control.reason` values are consistently `human_gate_checkpoint | gate_fail | escalation | error | interrupted | null`
- Command naming is consistent everywhere as `/devloop continue <id>`
