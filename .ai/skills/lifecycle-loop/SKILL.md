---
name: lifecycle-loop
description: >-
  Orchestrates end-to-end SDLC for a change package. Classifies complexity,
  selects workflow profile, invokes phase skills, issues L2 gate decisions,
  controls loop/pipeline re-entry. Use for /loop start, /loop run, /loop gate,
  /loop status, /loop classify, lifecycle, SDLC loop, quality gate.
---

# Lifecycle Loop Skill

Universal orchestrator for the Develop Loop SDLC. **Does not author phase artifacts** — delegates to phase skills and evaluates their outputs at L2.

## Commands

| Command | Behavior |
|---------|----------|
| `/loop start <id>` | Create package from `_template`, classify, select profile, show execution plan |
| `/loop run <id>` | Full E2E in **loop** mode (default); auto re-entry on gate fail |
| `/loop run <id> --pipeline` | Single pass per phase; stop on first gate fail |
| `/loop gate <id> <phase>` | L2 gate check for one phase only; reject if `<phase>` is not in `active_profile` phases unless user explicitly overrides |
| `/loop status <id>` | Summarize `package.yaml`, gates, blockers, phase readiness |
| `/loop classify <id>` | Re-run or confirm classification; update `classification.yaml` |

**Mode:** Read from command flag or `package.yaml` field `mode: loop | pipeline`. Switching mode mid-run requires explicit user command.

## Classify Steps

1. Gather signals from user input and repo context: scope, auth/PII/payment, data migration, new public API, infra change, bug vs feature, estimated size.
2. Apply the rule table below to suggest a tier.
3. Present `suggested_tier` + reasoning to the user; ask confirm or override.
4. Write `.ai/packages/<id>/classification.yaml` with `suggested_tier`, `active_profile`, `signals`, `confidence`, and `override` if any.
5. Do not proceed to execution until `active_profile` is set.

After confirm, set `active_profile` to the confirmed tier (`routine`, `standard`, or `high_risk`). Write matching `profile` field in `package.yaml`. Show the user the phase list and human gates from `profiles.yaml` for that profile before first `/loop run`.

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

### Before each phase

1. Read `.ai/packages/<id>/package.yaml` and list gate files in `.ai/packages/<id>/gates/`.
2. Load `active_profile` from `classification.yaml` and read `.ai/config/profiles.yaml` for `phases`, `human_gates`, `max_reentry`.
3. If this phase is `archived` and its latest gate is `pass`, skip to the next phase.
4. If an upstream `artifact_version` changed since the last gate for this phase, mark downstream phases `pending` in `package.yaml`, treat affected gates as `stale`, and return to the earliest affected phase.
5. Load `phases` list for `active_profile` from `profiles.yaml`. **Skip** phases not in the profile (e.g. `routine` skips `design` and `test-plan`). Do not gate skipped phases.

### Run the phase

1. Tell the user which phase is starting.
2. Load and follow the matching phase skill (see path map below) with this `package_id`.
3. Wait until the phase skill finishes Archive: artifacts written, `review-log.md` present, `package.yaml` shows this phase as `archived`.

### Gate the phase

1. Follow **Gate Steps** below for this phase name.
2. Write `.ai/packages/<id>/gates/<phase>-<n>.md` (increment attempt number `n`).
3. If `result: pass` → continue to next phase in plan.
4. If `result: fail`:
   - **pipeline** mode: stop and report findings; do not re-invoke phase skill.
   - **loop** mode: if re-entry count for this phase is below `max_reentry`, invoke the same phase skill with gate findings as revision input, then gate again.
   - If re-entry budget exhausted → follow **Escalation Steps** and stop.

### After all profile phases pass

1. If profile includes `release` and release gate passes → set `package.yaml` `status: ready_for_release`
2. Else if all profile phases pass → set `package.yaml` `status: ready_for_merge`
3. Summarize: phases completed, gate history, human approvals, open blockers.

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

1. Phase folder has all `required_artifacts` for `active_profile` in `profiles.yaml`.
2. `review-log.md` exists with no unresolved **blocking** failures.
3. Typed trace links present in artifact frontmatter (upstream references for design/test-plan).
4. Human approval recorded if phase is in `human_gates` (`status: approved` in frontmatter or `approval.md`).
5. `traceability/<id>/matrix.md` has no blocking gaps for this phase (invoke traceability skill if missing).

### Gate file template

Write to `.ai/packages/<id>/gates/<phase>-<attempt>.md`:

```md
# Gate: <phase> (attempt <n>)

result: pass | fail | stale | error
profile: standard
mode: loop | pipeline

artifacts_checked:
  - artifacts/<id>/<phase-folder>/<file>.md (v1)
  - artifacts/<id>/<phase-folder>/review-log.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Traces to upstream requirements present
  - [x] Human approval recorded (if required)

findings:
  - severity: blocking | non-blocking
    message: <description>
    action: <recommended fix>

reentry: <count>
next: <next-phase-name | same-phase-for-reentry>
```

Never set `result: pass` with unchecked checklist items or open blocking findings.

## Loop vs Pipeline

| Mode | Command | On gate fail |
|------|---------|--------------|
| **Loop** (default) | `/loop run <id>` | Re-invoke phase skill up to `max_reentry`, then escalate |
| **Pipeline** | `/loop run <id> --pipeline` | Stop immediately; user fixes and re-runs |

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

Escalation report must list: open findings, gate attempt history, suggested human actions, next command (`/loop gate`, `/loop run`, or manual phase skill).

## Parent-Child Packages

A parent package coordinates multiple child packages without copying artifacts.

### package.yaml schema

```yaml
children:
  - id: FEAT-CHILD-001
    relationship: implements   # implements | depends_on
```

### Before parent release or design gate (when children exist)

1. Read each `children[].id` → load `.ai/packages/<child_id>/package.yaml`.
2. Load each child's `profile` from `package.yaml` (or `classification.yaml` if package profile is unset).
3. **Child readiness:** each child must have every phase **listed in that child's `package.yaml`** `archived` with latest gate `result: pass`. A child may run a subset of its profile phases (e.g. 3-phase MVP child under `standard` profile); only phases present in the child's manifest are checked.
4. If any child fails readiness → parent gate `result: fail` with finding listing child id and missing phase.
5. Parent gate `artifacts_checked` includes child package paths:
   - `.ai/packages/<child_id>/package.yaml`
   - `.ai/packages/<child_id>/gates/<latest-pass-per-phase>`

### Constraints

- Do not copy child artifacts into parent `artifacts/` folder.
- Parent PRD may reference child IDs in scope; traceability stays per-package.
- Child packages run `/loop run` independently; parent `/loop run` checks children only at gate time.

## Constraints

- **Do not** author phase artifacts (PRD, architecture, test cases, code).
- **Do not** declare gate PASS from phase skills — L2 only here.
- **Always** write a gate file before advancing to the next phase.
- **Always** re-read `package.yaml`, gates, and artifacts from disk after each phase.
- **Always** invoke phase skills by loading their `SKILL.md` — do not inline phase work.
