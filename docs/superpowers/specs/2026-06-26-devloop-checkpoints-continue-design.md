# Design: Human-gate checkpoints + `continue` resume

- **Date:** 2026-06-26
- **Status:** Approved (design)
- **Scope:** `lifecycle-loop` orchestrator behavior, `package.yaml` state model, `devloop` command set
- **Related:** `.ai/skills/lifecycle-loop/SKILL.md`, `.ai/config/profiles.yaml`, `.ai/contracts/evidence-policy.yaml`

## Problem

`/devloop run` executes the full SDLC end-to-end in loop mode. Once a human approves
the requirements artifact, the orchestrator immediately continues into design and every
subsequent phase. Two gaps:

1. **No intentional stop after human approval.** Approving the requirements artifact also
   implicitly authorizes the entire rest of the loop. Users want approval of one phase to
   be separate from consent to run the remaining phases.
2. **No explicit resume.** If the loop stops for any reason (intentional checkpoint, gate
   failure/escalation, phase-skill error, or an interrupted/ended session), there is no
   first-class command to resume from where it stopped. Resume is only implicit (re-running
   `run`, which skips `archived`+`pass` phases).

## Goals

- After every **human gate** in the active profile, the loop hard-stops at a checkpoint and
  requires an explicit command to proceed.
- A `/devloop continue <id>` command resumes from any stop point.
- State is persisted, human-readable, and auditable, consistent with the existing
  "`package.yaml` is the single source of truth, re-read from disk each phase" model.

## Non-goals (YAGNI)

- No `/devloop stop` or `/devloop pause` command. A manual stop is just the session ending;
  on-disk state already reflects progress.
- No mid-phase sub-step resume. An interruption inside a phase re-runs that phase from the
  start (phase skills create-or-revise artifacts idempotently).
- No new **enforced** L3 verifier rule for the new state block, so existing committed
  packages (FEAT-001/003/PARENT/CHILD) remain valid without migration.

## Decisions (from brainstorming)

| Question | Decision |
|----------|----------|
| Where does the loop hard-stop? | After **every human gate** in the active profile |
| Default or opt-in? | **New default** behavior of `/devloop run` |
| What does `continue` resume from? | **Any** stop: checkpoint, gate-fail/escalation, error, interrupted |
| `run` vs `continue` while paused | Only **`continue`** advances past a checkpoint/stop. `run` while paused/stopped reports state and does nothing |
| Mid-phase interruption | Re-run the **earliest non-archived** phase from its start |
| State persistence | **Explicit `run_control` block in `package.yaml`** |

## State model — `run_control` in `package.yaml`

```yaml
run_control:
  state: running | paused | stopped | done
  stopped_at: <phase> | null          # phase the loop paused/stopped at
  reason: human_gate_checkpoint | gate_fail | escalation | error | interrupted | null
  since: "2026-06-26T09:00:00Z"
  next_action: "/devloop continue FEAT-003"
  history:                            # append-only audit (optional but recommended)
    - { at: "2026-06-26T09:00:00Z", event: paused, phase: requirements, reason: human_gate_checkpoint }
    - { at: "2026-06-26T09:30:00Z", event: continued, phase: requirements, by: user }
```

**Back-compat:** `run_control` is optional. When absent, the orchestrator treats the package
as `state: running` and infers the resume point from `phases.<name>.status` + gate files.

### State transitions

| From | Trigger | To |
|------|---------|-----|
| (none)/`running` | `/devloop run` starts driving | `running` |
| `running` | human-gate phase passes its gate (approval already recorded) | `paused` (`reason: human_gate_checkpoint`, `stopped_at: <phase>`) |
| `running` | gate fail in pipeline mode, or re-entry budget exhausted | `stopped` (`reason: gate_fail`/`escalation`) |
| `running` | phase skill returns error | `stopped` (`reason: error`) |
| `running` | session ends mid-phase (detected on next invocation) | treated as `interrupted` |
| `paused`/`stopped` | `/devloop continue` | `running` |
| `running` | all profile phases complete | `done` |

## Command behavior

### `/devloop run <id>` (checkpoint-aware, new default)

1. Set `run_control.state: running`.
2. Drive phases as today (respecting `loop`/`pipeline` mode and stale/re-entry rules).
3. **After** a phase listed in the profile's `human_gates` passes its gate, write
   `state: paused`, `stopped_at: <phase>`, `reason: human_gate_checkpoint`, `next_action`,
   append a `paused` history entry, and **stop**. Report the checkpoint and next command.
4. If invoked while `state` is `paused` or `stopped`: do **not** advance. Report the current
   state and instruct the user to run `/devloop continue <id>`.
5. `routine` (no human gates) runs straight through to `state: done`.

### `/devloop continue <id>` (new)

1. Re-read `package.yaml` + gate files.
2. Resolve the resume point from `run_control.reason`:

   | Reason | Resume behavior |
   |--------|-----------------|
   | `human_gate_checkpoint` | Advance to the **next** phase after `stopped_at` |
   | `gate_fail` / `escalation` | Re-enter the **failed** phase |
   | `error` / `interrupted` | Re-run the **earliest non-archived** phase from its start |

3. Set `state: running`, append a `continued` history entry, then drive until the next
   checkpoint, stop, or `done`.
4. On a `done` package: report completion, no-op.

### `/devloop status <id>`

Add a `run_control` summary line: `state`, `stopped_at`, `reason`, `since`, and the exact
`next_action` command.

## Edge cases

- **Checkpoint vs approval:** the checkpoint fires *after* human approval and gate pass, so it
  is a distinct "proceed to next phase?" consent, not a re-approval of the artifact.
- **Pipeline + checkpoints coexist:** pipeline governs fail behavior; checkpoints govern
  human-gate stops. Both can apply in one run.
- **high_risk:** many human gates → a checkpoint after each; `continue` is used repeatedly.
- **Legacy packages** without `run_control`: inferred as `running`; `continue` still resolves
  resume from phase statuses.

## Files to change

- `.ai/skills/lifecycle-loop/SKILL.md` — commands table; Run/Continue/Checkpoint steps; state model.
- `.ai/skills/lifecycle-loop/reference.md` — command cheat sheet; checkpoint + continue examples.
- `.ai/packages/_template/package.yaml` — add `run_control` with `state: running`.
- `README.md` — command tables + quick start (`continue`, checkpoint note).
- `AGENTS.md`, `templates/AGENTS.md`, `templates/cursor/rules/devloop.mdc` — add `continue` to command lists.
- Rebuild pack via `scripts/build-pack.sh`.

## Verification

- `npm test` (build-pack layout + devloop CLI + loop-verify regression) stays green.
- `./scripts/loop-verify.sh --enforce FEAT-003` and `./scripts/loop-verify.sh FEAT-001`
  remain `PASS` (no new enforced rule; `run_control` is optional).
- Manual walkthrough: a `standard` package pauses after requirements; `continue` proceeds to
  design; status reflects `run_control` throughout.

## Open questions

None. Ready for implementation planning.
