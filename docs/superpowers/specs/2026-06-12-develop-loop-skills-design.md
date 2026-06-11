# Develop Loop AI Coding Skills — Design Spec

**Status:** Approved (brainstorming)
**Date:** 2026-06-12
**References:**

- `docs/requirements/2026-06-11-ai-native-loop-skills-ecosystem-design.md`
- `develop-loop-skills-requirement.md`

## 1. Purpose

Build an **AI-native SDLC skill ecosystem** that turns coding agents from code generators into **engineering process executors**. The system produces reviewable, versioned, traceable artifacts across the full software development lifecycle.

Core principle:

```text
AI Coding Loop =
  需求可追踪 · 设计可评审 · 测试可覆盖 · 代码可解释 · 质量可度量 · 过程可审计
```

### 1.1 What we are building

| Component | Role |
|-----------|------|
| **7 phase skills** | Independently invokable agent skills — each fully owns its development phase with high-quality outputs |
| **traceability skill** | Maintains requirement-to-design-to-test-to-code matrix and light trace links |
| **lifecycle-loop skill** | Universal orchestrator: classify, profile, execute/gate phases, re-entry, escalation (L2) |
| **Light CI** | Deterministic file/structure checks (L3); no LLM in CI |

### 1.2 What we are not building (pilot)

- TypeScript orchestration kernel or loop runtime
- Centralized workflow service or database
- Heavy JSON Schema envelopes, canonical digests, or stale-gate automation (deferred)
- Full routine/high-risk profiles and parent-child packages in MVP (designed, shipped later)

### 1.3 Enforcement model

**Skill-first + light CI (hybrid, simplified):**

- **L1:** Phase skills self-check via `review-log.md`
- **L2:** Lifecycle Loop skill evaluates and writes gate records (agent follows markdown steps)
- **L3:** `loop-verify.sh` + GitHub Actions verify required files exist; CI is authoritative for merge when enforced

---

## 2. Success factors

The ecosystem has **four co-equal pillars**. Weakness in any one undermines the whole — high-quality phase outputs without orchestration produce scattered docs; strong orchestration without phase depth automates poor artifacts.

```text
┌─────────────────────┐  ┌─────────────────────┐
│  Phase skill depth  │  │   Orchestration     │
│  (L1 per phase)     │  │   (L2 loop skill)   │
└──────────┬──────────┘  └──────────┬──────────┘
           │                        │
           └──────────┬─────────────┘
                      ▼
           ┌─────────────────────┐
           │  3-level quality    │
           │  + loop / pipeline  │
           └──────────┬──────────┘
                      ▼
           ┌─────────────────────┐
           │ Proven traceability │
           │ evidence in Git     │
           └─────────────────────┘
```

### 2.1 Phase skill quality

Each phase skill must **fully fulfill its development phase target with high quality**.

1. **Fulfill the phase objective end-to-end** — invoking only `01-requirement-skill` yields a complete, review-ready PRD with stories, acceptance criteria, risks, and boundaries — not a thin outline.
2. **Embed domain expertise** — checklists, anti-patterns, examples, and output templates specific to that phase.
3. **Run the lightweight four-step contract** — Generate → Self Review → Human Review (if required) → Archive — without depending on the loop skill.
4. **Produce gate-ready evidence** — artifacts + `review-log.md` that orchestration can evaluate at L2.

**Quality bar per phase skill `SKILL.md`:**

| Section | Purpose |
|---------|---------|
| Triggers & when to use | Discovery in any runtime |
| Required inputs | What to read from repo / user |
| Generate steps | Detailed instructions to produce all phase outputs |
| Output templates | Concrete file names and markdown structure |
| Self-review checklist | Actionable pass/fail table for `review-log.md` |
| Human review guidance | When to pause; how to record approval |
| Archive steps | Update `package.yaml`; invoke traceability when links change |
| Quality criteria | What “high quality” means for this phase (explicit) |
| Examples | At least one minimal good output reference |

### 2.2 Orchestration quality

The **lifecycle-loop skill** is equally critical. It is not a thin wrapper around phase skills — it is the engineering process engine.

The loop skill must reliably:

1. **Classify and profile** — select the right phases, human gates, and re-entry budget per package.
2. **Drive E2E execution** — clear markdown execution steps that guide the agent turn-by-turn (not scripts).
3. **Issue L2 gate decisions** — evaluate L1 evidence, cross-phase consistency, and profile rules; write append-only gate records.
4. **Control re-entry** — loop mode retries with findings; pipeline mode stops cleanly; escalation when budget exhausted.
5. **Maintain package state** — `package.yaml`, `classification.yaml`, and gate history stay consistent across long sessions.

**Quality bar for `lifecycle-loop/SKILL.md`:**

| Section | Purpose |
|---------|---------|
| Commands | `/loop start|run|gate|status|classify` |
| Classify steps | Rule table, human confirm/override, write `classification.yaml` |
| Execution steps | Agent turn-by-turn orchestration (§5.4) |
| Gate steps | L2 checklist, gate file template, pass/fail/stale rules |
| Loop vs pipeline | Explicit branch behavior on gate fail |
| Re-entry & stale | When to rewind phases after upstream change |
| Escalation | Stop conditions, waiver guidance, human handoff |
| Parent-child | Aggregate child gate status (Phase 2) |

**If orchestration is weak, phase skills run in isolation and traceability breaks across the lifecycle.**

### 2.3 Three-level quality model

All three levels must work together — this is a core success factor, not an optional overlay.

| Level | Owner | Must prove |
|-------|-------|------------|
| **L1** | Phase skills | Phase-local self-check via `review-log.md`; blocking items recorded |
| **L2** | Lifecycle loop | Cross-artifact gate decision in `gates/<phase>-<n>.md`; re-entry or advance |
| **L3** | `loop-verify.sh` + CI | Required files, gate records, approvals exist; merge block when enforced |

Rules:

- Phase skills **never** declare final gate PASS (L1 only).
- Loop skill **always** writes a gate file before advancing (L2).
- CI **never** runs the LLM; it verifies structural evidence (L3).
- A package is not “done” until all three levels agree for the active profile.

### 2.4 Loop and pipeline modes

Both modes are first-class — the loop skill must implement each correctly.

| Mode | Command | Behavior | Success signal |
|------|---------|----------|----------------|
| **Loop** | `/loop run <id>` | Auto re-enter failed phases up to `max_reentry`; agent self-drives to completion or escalation | E2E feature completes with gate history showing re-entry attempts |
| **Pipeline** | `/loop run <id> --pipeline` | Single pass per phase; stop on first gate fail; human fixes between runs | Clean stop with actionable gate report; resume picks up from failed phase |

Mode is stored in `package.yaml` and respected on every run. Switching mode mid-package is explicit (user command), not silent.

### 2.5 Proven evidence for traceability

Traceability is not a matrix checkbox — it is **auditable proof** that requirements flow through design, tests, code, and release.

Evidence chain (all in Git):

```text
requirement artifact (v1, frontmatter traces)
  → design artifact (derives_from: requirement@v1)
  → test case (verifies: AC-003)
  → code file (implements: design section 2.1)
  → test report (validates: TC-001)
  → gate record (artifacts_checked snapshot)
  → traceability/matrix.md (row per requirement ID)
```

**Proven evidence requirements:**

1. **Typed links** — `traces` / `related` in artifact frontmatter bind specific artifact versions.
2. **Trace matrix** — `traceability/<package_id>/matrix.md` updated by `traceability-skill` after each phase archive; every AC has design + test + code columns filled or explicitly `N/A` with reason.
3. **Gate binding** — each gate file lists `artifacts_checked` so the decision is tied to exact files reviewed.
4. **Decision records** — `traceability/<package_id>/decision-records.md` captures tradeoffs and overrides.
5. **CI verification** — L3 checks matrix exists and gate files reference real artifact paths.

An auditor (human or agent) must reconstruct **requirement → design → test → code → release** from Git alone without asking the LLM what happened.

### 2.6 Portability and standalone execution

Every skill — phase and loop — is a **runtime-neutral AI coding agent skill**:

- Authored once under `.ai/skills/`
- **Copied or symlinked** into runtime-specific skill folders:
  - Cursor: `.cursor/skills/<name>/SKILL.md`
  - Codex: per project `AGENTS.md` + skills path convention
  - Claude Code: `.claude/skills/<name>/SKILL.md`
- **Executable separately** — user can invoke `01-requirement-skill` for `FEAT-001` without ever running `/loop run`
- **Executable orchestrated** — `/loop run` tells the agent when to load which phase skill

No runtime-specific logic inside phase content. Runtime folders contain pointers or copies of the same `SKILL.md`.

### 2.7 Scoped ecosystem items (from approved design)

Included in this design:

- Seven dedicated, independently invokable phase skills
- One universal Lifecycle Loop skill
- Complexity classification and workflow profile selection
- Work-item change packages (light `package.yaml`; parent-child later)
- Light artifact metadata, trace links, findings (in review-log), gate attempts, approvals (profile-driven)

---

## 3. Architecture

### 3.1 Skill inventory

| Skill | Phase | Quality level |
|-------|-------|---------------|
| `01-requirement` | Requirements | L1 |
| `02-design` | Design | L1 |
| `03-test-plan` | Test planning | L1 |
| `04-implementation` | Implementation | L1 |
| `05-code-review` | Code review | L1 |
| `06-test-report` | Validation / test report | L1 |
| `07-release-retro` | Release & retro | L1 |
| `traceability` | Trace matrix & edges | Helper (no gate) |
| `lifecycle-loop` | Classify, orchestrate, gate | L2 |

`quality-gate` from the Chinese requirement doc is **absorbed into `lifecycle-loop`** as L2 gate steps. Phase skills never declare final gate PASS.

### 3.2 Three-level quality model

```text
Level 1 — Phase Skill Self-Check
  Load context → generate artifacts → self-review checklist → review-log.md
  Cannot issue final gate pass

Level 2 — Lifecycle Loop Final Check
  Read package + profile → verify L1 + cross-phase trace → write gate file
  → re-enter phase (loop mode) or stop (pipeline / escalation)

Level 3 — Lightweight CI
  Required files, package phase status, gate files exist
  Authoritative for merge when enforcement enabled
```

### 3.3 Complexity classification and profiles

At `/loop start <id>`, the loop skill classifies and writes `classification.yaml`:

| Tier | Typical signals |
|------|-----------------|
| **routine** | Bug fix, docs, small config |
| **standard** | Normal feature, limited blast radius |
| **high_risk** | Auth, PII, payment, migration, new public API, infra |

Human confirms or overrides; override recorded in `classification.yaml`.

Profiles in `.ai/config/profiles.yaml` define:

- Required phases (routine may skip/lite design and test-plan)
- `human_gates` — which phases need human approval before archive
- `max_reentry` — loop mode retry budget
- `required_artifacts` per phase (for CI)

**MVP:** Only `standard` profile active for phases `requirements`, `design`, `test-plan`. Classifier runs; routine and high_risk profiles stubbed for Phase 2.

### 3.4 Change packages

Each work item: `.ai/packages/<package_id>/`

```yaml
# package.yaml (light)
id: FEAT-001
owner: Andy
profile: standard
mode: loop          # loop | pipeline
phases:
  requirements:
    status: archived    # pending | in_progress | archived
    artifact_version: v1
  design:
    status: pending
children: []          # Phase 2: child package refs
```

Parent-child rules (Phase 2): parent gates reference child gate outcomes; no artifact copying.

---

## 4. Lightweight phase contract

Every phase skill follows the same four steps:

```text
Generate → Self Review → Human Review (if profile requires) → Archive
```

### 4.1 Generate

Create or revise phase documents under `artifacts/<package_id>/<phase>/`.

### 4.2 Minimal frontmatter

```yaml
---
artifact_id: REQ-001-prd
artifact_type: requirement
package_id: FEAT-001
version: v1
status: draft          # draft | reviewed | approved
owner: Andy
created_at: 2026-06-12
traces:
  - satisfies: REQ-001
related:
  - artifacts/FEAT-001/02-design/architecture.md
---
```

### 4.3 Self review

`artifacts/<package_id>/<phase>/review-log.md` — checklist table with pass/fail and blocking count.

### 4.4 Human review

Profile-driven. Routine: skip unless escalated. Standard MVP: human at `requirements`. Record via `status: approved` in frontmatter or `approval.md`.

### 4.5 Archive

Update `.ai/packages/<package_id>/package.yaml` phase status. Invoke `traceability` skill if matrix is stale. **Do not write gate PASS.**

### 4.6 Deferred heaviness

Not in MVP: separate envelope YAML per artifact, canonical digests, structured finding IDs, append-only decisions store. Gate files are simple markdown.

---

## 5. Lifecycle Loop skill

### 5.1 Role

Single orchestrator. **Does not author phase artifacts by default.** Instructs the agent via markdown steps to load phase skills, wait for archive, run gate steps, and handle re-entry.

**§3.6 execution logic is prose instructions inside `SKILL.md` — not scripts, pseudocode runtime, or TypeScript.**

### 5.2 Commands

| Command | Behavior |
|---------|----------|
| `/loop start <id>` | Create package, classify, select profile, show plan |
| `/loop run <id>` | E2E, loop mode (default) |
| `/loop run <id> --pipeline` | Single pass, no auto re-entry |
| `/loop gate <id> <phase>` | L2 gate for one phase |
| `/loop status <id>` | Summarize package, gates, blockers |
| `/loop classify <id>` | Re-run or confirm classification |

### 5.3 SKILL.md structure

1. Triggers and commands
2. Classify steps (rule table + write `classification.yaml`)
3. **Execution steps** — agent turn-by-turn behavior (see §5.4)
4. **Gate steps** — checklist + gate file template
5. Re-entry and stale handling (light: version bump → re-run affected phases)
6. Escalation and waiver steps
7. Parent-child checks (Phase 2)
8. Constraints — do not author phase content; always write gate file before advance

### 5.4 Execution steps (agent guide, not code)

The agent:

1. Re-reads `package.yaml` and latest gates from disk after each phase.
2. Skips phases already `archived` with latest gate `pass`.
3. On upstream artifact version change, marks downstream `pending` and returns to earliest affected phase.
4. Announces phase start; **loads the matching phase skill** with `package_id`.
5. Waits until phase shows `archived` and `review-log.md` exists.
6. Follows **Gate steps**; writes `.ai/packages/<id>/gates/<phase>-<n>.md`.
7. On `pass` → next phase. On `fail`:
   - **pipeline:** stop and report
   - **loop:** re-invoke phase skill with findings if under `max_reentry`; else escalate
8. When all phases pass → set package `ready_for_merge` / `ready_for_release`; summarize.

### 5.5 Gate file (light)

```md
# Gate: design (attempt 2)

result: pass
profile: standard
mode: loop

artifacts_checked:
  - artifacts/FEAT-001/02-design/architecture.md (v2)
  - artifacts/FEAT-001/02-design/review-log.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Traces to upstream requirements present
  - [x] Human approval recorded (if required)

findings: []
reentry: 1
next: test-plan
```

### 5.6 Escalation

Stop auto-retry when: `max_reentry` exhausted; repeated blocking finding without artifact change; tool error; user waiver request. Report open findings and gate history.

---

## 6. Phase skill outputs (quality targets)

Each skill must meet the outputs and self-checks from `develop-loop-skills-requirement.md`. Summary:

| Skill | Key outputs | Self-check focus |
|-------|-------------|------------------|
| **01-requirement** | PRD, user stories, AC, open questions, out-of-scope, risks | User value, testability, ambiguity, boundaries |
| **02-design** | Architecture, API, data model, sequences, tradeoffs, failure scenarios | Requirement coverage, perf/reliability/security, testability |
| **03-test-plan** | Strategy, unit/integration/E2E cases, edge/regression | AC coverage, exceptions, boundaries, security |
| **04-implementation** | Plan, task breakdown, changed files, code summary | Approved scope only, design conformance, tests, error handling |
| **05-code-review** | General, security, performance, maintainability, testability reviews | Evidence-grounded findings, blocking vs non-blocking |
| **06-test-report** | Execution summary, pass/fail, coverage, defects, release recommendation | Evidence completeness, AC coverage |
| **07-release-retro** | Release notes, known issues, retro | Scope, validation status, rollback viability |

**traceability:** Matrix linking requirement IDs → design → test cases → code files → status.

---

## 7. Repository layout

```text
develop-loop-skills/
  .ai/
    config/
      profiles.yaml
    packages/
      <package_id>/
        package.yaml
        classification.yaml
        gates/
        decisions/           # optional MVP
    skills/
      lifecycle-loop/
        SKILL.md
        reference.md
      traceability/
        SKILL.md
      phases/
        01-requirement/SKILL.md
        02-design/SKILL.md
        ... (07 phases)

  artifacts/
    <package_id>/
      01-requirements/
      02-design/
      ...

  traceability/
    <package_id>/
      matrix.md
      decision-records.md

  scripts/
    loop-verify.sh

  .github/workflows/
    loop-verify.yml

  .cursor/skills/          # copies or symlinks to .ai/skills/*
  AGENTS.md                # Codex / generic agent entry
  README.md
```

**Conventions:**

- Phase skills write under `artifacts/<package_id>/`
- Loop writes under `.ai/packages/<package_id>/`
- One source of truth: `.ai/skills/`; runtime folders are copies or thin pointers

---

## 8. MVP and rollout

### 8.1 MVP deliverables

| Priority | Item |
|----------|------|
| P0 | `lifecycle-loop` skill with `/loop` commands |
| P0 | `01-requirement`, `02-design`, `03-test-plan` — **high-quality, standalone** |
| P0 | `traceability` skill |
| P0 | `profiles.yaml` (standard, 3 phases) |
| P0 | Example package `FEAT-001` walkthrough |
| P1 | Remaining 4 phase skills |
| P1 | `loop-verify.sh` observe mode |
| P2 | CI enforce, routine/high_risk profiles, parent-child |

### 8.2 MVP success criteria

**Phase quality**

1. User copies skills to Cursor/Codex/Claude Code and invokes **any MVP phase skill standalone** with production-quality output.

**Orchestration + 3-level quality**

2. `/loop start` + `/loop run` (loop mode) completes requirements → design → test-plan with L1 review-logs, L2 gate files, and updated `package.yaml`.
3. `/loop run <id> --pipeline` stops on first gate fail with a clear report; resume after fix succeeds.
4. Re-entry works in loop mode: fail design gate → revise → pass on retry; gate history shows multiple attempts.
5. L3 `loop-verify.sh` reports structural gaps without running an LLM.

**Proven traceability**

6. `traceability/FEAT-001/matrix.md` links every AC to design section, test case, and status.
7. Gate files list `artifacts_checked` matching real artifact paths and versions.
8. An auditor can follow the evidence chain from Git alone for the demo package.

### 8.3 Rollout stages

| Stage | Goal |
|-------|------|
| 0 | Skills in repo; manual loop on demo package |
| 1 | CI observe; tune file checks |
| 2 | All 7 phases + full standard profile on real feature |
| 3 | CI enforce + additional profiles + parent-child |

---

## 9. Runtime portability

| Runtime | Install |
|---------|---------|
| **Cursor** | Copy `.ai/skills/phases/*` and `lifecycle-loop` to `.cursor/skills/` (or symlink) |
| **Codex** | Point `AGENTS.md` to `.ai/skills/` paths |
| **Claude Code** | Copy to `.claude/skills/` |

Root `AGENTS.md`:

```markdown
## Develop Loop

- Orchestrator: `.ai/skills/lifecycle-loop/SKILL.md` — `/loop start|run|gate|status`
- Phases: `.ai/skills/phases/*/SKILL.md` — invokable standalone
- State: `.ai/packages/<id>/` · Artifacts: `artifacts/<id>/`
```

**Standalone rule:** Every phase `SKILL.md` must open with standalone usage, e.g. “Use when user asks for requirements, PRD, user stories, or acceptance criteria for a feature — with or without `/loop`.”

---

## 10. Light CI (L3)

`scripts/loop-verify.sh` checks:

1. `package.yaml` and `classification.yaml` exist
2. Archived phases have required artifacts + `review-log.md`
3. Gate file exists per archived phase
4. Human-gated phases show approval when profile requires
5. `traceability/<id>/matrix.md` exists (warn → fail when enforced)

CI does not run the loop or judge semantic quality.

---

## 11. Implementation decomposition

Ordered for writing-plans:

1. **Scaffold** — `.ai/` layout, `profiles.yaml`, package templates, `AGENTS.md`, README install guide
2. **Lifecycle loop skill** — full `SKILL.md` (commands, classify, execution, gate, loop/pipeline, escalation) — **P0, equal priority**
3. **MVP phase skills** — requirement, design, test-plan with deep quality content — **P0, equal priority**
4. **Traceability skill** — matrix, frontmatter link rules, gate binding — **P0**
5. **Demo package FEAT-001** — E2E in both loop and pipeline modes; evidence chain documented
6. **loop-verify + CI** — L3 structural checks including matrix and gate file presence
7. **Phase 2** — remaining 4 phase skills; full 7-phase standard profile; routine/high_risk profiles

**Build order rationale:** Phase skills, lifecycle-loop orchestration, and traceability are **built in parallel** — all three are P0 success factors. Demo package FEAT-001 validates the full 3-level model and proven evidence chain before expanding scope.

---

## 12. Design decisions log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Orchestration | Markdown skill steps, not TS | User requirement; agent drives loop |
| Gate issuer | Lifecycle loop only | Ecosystem §4.2 L2 |
| Phase contract | Light 4-step + frontmatter | User preference for simplicity |
| Commands | `loop` not `develop-loop` | User clarification |
| Phase skills | Portable, standalone, high quality | Co-equal success factor |
| Orchestration | Lifecycle loop skill, loop + pipeline modes | Co-equal success factor |
| 3-level quality | L1 self-check → L2 gate → L3 CI | Co-equal success factor |
| Traceability | Proven evidence chain in Git | Co-equal success factor |
| MVP profile | Standard, 3 phases | Incremental delivery |
| CI | Light shell script | L3 without heavy kernel |
