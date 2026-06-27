---
name: lifecycle-loop
description: >-
  Orchestrates end-to-end SDLC for a change package. Classifies complexity,
  selects workflow profile, invokes phase skills, issues L2 gate decisions,
  controls loop/pipeline re-entry. Use for /devloop start, /devloop run, /devloop gate,
  /devloop status, /devloop classify, lifecycle, SDLC loop, quality gate.
---

# Lifecycle Loop Skill

Universal orchestrator for the Develop Loop SDLC. **Does not author phase artifacts** — delegates to phase skills and evaluates their outputs at L2.

## Commands

User-facing slash command is **`/devloop`** (not `/loop`) to avoid colliding with built-in agent commands such as Cursor's recurring `/loop`.

| Command | Behavior |
|---------|----------|
| `/devloop start <id>` | Create package from `_template`, classify, select profile, show execution plan |
| `/devloop run <id>` | Full E2E in **loop** mode (default); pauses at human-gate checkpoints and auto re-entry on gate fail |
| `/devloop run <id> --pipeline` | Single pass per phase; stop on first gate fail |
| `/devloop continue <id>` | Resume from a checkpoint or other stop state using the persisted `run_control` block |
| `/devloop gate <id> <phase>` | L2 gate check for one phase only; reject if `<phase>` is not in `active_profile` phases unless user explicitly overrides |
| `/devloop status <id>` | Summarize `package.yaml`, gates, blockers, phase readiness, and `run_control` |
| `/devloop classify <id>` | Re-run or confirm classification; update `classification.yaml` |

**Mode:** Read from command flag or `package.yaml` field `mode: loop | pipeline`. Switching mode mid-run requires explicit user command.

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

## Classify Steps

1. Gather signals from user input and repo context: scope, auth/PII/payment, data migration, new public API, infra change, bug vs feature, estimated size.
2. Apply the rule table below to suggest a tier.
3. Present `suggested_tier` + reasoning to the user; ask confirm or override.
4. Write `.ai/packages/<id>/classification.yaml` with `suggested_tier`, `active_profile`, `signals`, `confidence`, and `override` if any.
5. Do not proceed to execution until `active_profile` is set.

After confirm, set `active_profile` to the confirmed tier (`routine`, `standard`, or `high_risk`). Write matching `profile` field in `package.yaml`. Show the user the phase list and human gates from `profiles.yaml` for that profile before first `/devloop run`.

### Classification rule table

| Signal | Suggested tier |
|--------|----------------|
| Bug fix, docs-only, config tweak, single-file change | routine |
| Normal feature, limited blast radius, few services | standard |
| Auth, PII, payment, migration, new public API, infra, compliance | high_risk |

### classification.yaml template

```yaml
package_id: FEAT-001
suggested_tier: standard
active_profile: standard
signals:
  - type: feature
  - blast_radius: limited
confidence: medium
override: null
classified_at: "2026-06-12"
```

Record overrides as: `override: { by: "<name>", reason: "<text>", new_tier: standard }`.

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
6. If a run stops without reaching a human checkpoint or `done`, persist a stop block before returning control to the user:

```yaml
run_control:
  state: stopped
  stopped_at: <phase>
  reason: gate_fail | escalation | error | interrupted
  since: "<current-utc-timestamp>"
  next_action: "/devloop continue <id>"
```

7. Use the existing reason enum exactly:
   - `gate_fail` when pipeline mode stops on the first failed gate, or when loop mode stops because the failed gate must be revisited manually before any re-entry can proceed
   - `escalation` when `max_reentry` is exhausted, repeated blocking findings force escalation, or a waiver/manual decision is required
   - `error` when the phase skill or orchestration fails before a gate decision can complete
   - `interrupted` when the run is intentionally aborted before the current phase completes
8. Append a matching `stopped` history entry whenever one of those stop reasons is written, report `stopped_at`, `reason`, `since`, and `next_action`, then stop.
9. If all active profile phases pass, set `run_control.state: done`, clear `stopped_at` / `reason` / `next_action`, append a `done` history entry, and set package `status` to `ready_for_merge` or `ready_for_release` as today.

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

### Phase skill path map

| Phase key | Skill path | Artifact dir |
|-----------|------------|--------------|
| requirements | `.ai/skills/phases/01-requirement/SKILL.md` | `01-requirements` |
| design | `.ai/skills/phases/02-design/SKILL.md` | `02-design` |
| test-plan | `.ai/skills/phases/03-test-plan/SKILL.md` | `03-test-plan` |
| implementation | `.ai/skills/phases/04-implementation/SKILL.md` | `04-implementation` |
| code-review | `.ai/skills/phases/05-code-review/SKILL.md` | `05-code-review` |
| test-report | `.ai/skills/phases/06-test-report/SKILL.md` | `06-test-report` |
| release | `.ai/skills/phases/07-release-retro/SKILL.md` | `07-release-retro` |

## Gate Steps

Perform L2 final check. Phase skills cannot issue gate PASS — only this skill does.

### Checklist (all must pass for `result: pass`)

1. Phase folder has all `required_artifacts` for `active_profile` in the configured evidence policy. `profiles.yaml` selects the phase list, human gates, and policy reference; it is not the authoritative artifact contract.
2. `review-log.md` exists with no unresolved **blocking** failures.
3. Typed trace links present in artifact frontmatter (upstream references for design/test-plan).
4. Human approval recorded if phase is in `human_gates` (`status: approved` in frontmatter or `approval.md`).
5. `traceability/<id>/matrix.md` and `traceability/<id>/package-evidence-index.md` exist and have no blocking gaps for this phase (invoke traceability skill if missing or stale).
6. Gate `artifacts_checked` binds the exact artifact paths reviewed for this decision, including the phase artifact set, package evidence files, and child references when applicable.

### Gate file template

Write to `.ai/packages/<id>/gates/<phase>-<attempt>.md`:

```md
# Gate: <phase> (attempt <n>)

result: pass | fail | stale | error
profile: standard
mode: loop | pipeline

artifacts_checked:
  - artifacts/<id>/<phase-folder>/<file>.md@v1
  - artifacts/<id>/<phase-folder>/review-log.md@v1
  - traceability/<id>/matrix.md
  - traceability/<id>/package-evidence-index.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Traces to upstream requirements present
  - [x] Human approval recorded (if required)
  - [x] Package evidence index and matrix reflect this phase outcome
  - [x] Exact evidence bindings recorded in artifacts_checked

findings:
  - severity: blocking | non-blocking
    message: <description>
    action: <recommended fix>

reentry: <count>
next: <next-phase-name | same-phase-for-reentry>
```

Never set `result: pass` with unchecked checklist items or open blocking findings.
Treat `artifacts_checked` as the package-level audit binding for the gate: list the exact evidence set a reviewer would need to reconstruct the decision, and do not mix current and stale evidence snapshots in one gate record.
Use `path/to/file.md@v1` for new artifact-version bindings. The verifier still accepts the older `path/to/file.md (v1)` form for compatibility, but new or refreshed gates should use `@v1`.

## Loop vs Pipeline

| Mode | Command | On gate fail |
|------|---------|--------------|
| **Loop** (default) | `/devloop run <id>` | Re-invoke phase skill up to `max_reentry`, then escalate |
| **Pipeline** | `/devloop run <id> --pipeline` | Stop immediately; user fixes and re-runs |

Store mode in `package.yaml`. Respect it on every run.

## Re-entry and Stale Handling

**Re-entry:** Count attempts per phase from gate files (`reentry` field). Compare against `max_reentry` in `profiles.yaml`.

**Stale:** When upstream artifact `version` in frontmatter or `artifact_version` in `package.yaml` changes:
1. Mark downstream phases `pending` in `package.yaml`.
2. Do not treat old gate files as valid for changed evidence.
3. Re-run from earliest affected phase.

Prior gate files remain in `gates/` for audit — write new attempts, do not delete old ones.

## Escalation Steps

Stop auto-retry and report to the user when:

- `max_reentry` exhausted for a phase
- Same blocking finding repeats without meaningful artifact change
- Phase skill returns `error` (tool failure, missing context)
- User requests waiver → write `.ai/packages/<id>/decisions/waiver-<id>.md` with reason + approver; gate stays `fail`, progression is explicit only

Escalation report must list: open findings, gate attempt history, suggested human actions, next command (`/devloop gate`, `/devloop run`, or manual phase skill).

## Parent-Child Packages

A parent package coordinates multiple child packages without copying artifacts.

### package.yaml schema

```yaml
children:
  - id: FEAT-CHILD-001
    relationship: implements   # implements | depends_on
```

### Before parent release gate (when children exist)

1. Read each `children[].id` → load `.ai/packages/<child_id>/package.yaml`.
2. Load each child's `profile` from `package.yaml` (or `classification.yaml` if package profile is unset).
3. For the light parent-child release check currently implemented, require release-gate references that point to each child's package state and singular latest child gate evidence.
4. If any required child reference is missing or inconsistent → parent `release` gate `result: fail` with a finding listing the child id and missing evidence.
5. Parent `release` gate `artifacts_checked` includes child package paths:
   - `.ai/packages/<child_id>/package.yaml`
   - `traceability/<child_id>/package-evidence-index.md`
   - `.ai/packages/<child_id>/gates/<latest-pass-gate>`
6. Parent `release` gate includes a readable `child_evidence:` block that names each child's `status`, `package`, `latest_gate`, and `evidence_index` so the package-level audit trail stays human-readable as well as machine-checkable.

### Constraints

- Do not copy child artifacts into parent `artifacts/` folder.
- Parent PRD may reference child IDs in scope; traceability stays per-package.
- Parent package evidence indexes summarize child release-readiness references by reference; they do not duplicate child artifacts.
- Child packages run `/devloop run` independently; parent `/devloop run` currently performs only the light release-gate child evidence check described above.

## Constraints

- **Do not** author phase artifacts (PRD, architecture, test cases, code).
- **Do not** declare gate PASS from phase skills — L2 only here.
- **Always** write a gate file before advancing to the next phase.
- **Always** re-read `package.yaml`, gates, and artifacts from disk after each phase.
- **Always** invoke phase skills by loading their `SKILL.md` — do not inline phase work.
