# Develop Loop AI Coding Skills — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an MVP AI-native SDLC skill ecosystem — 3 high-quality phase skills, lifecycle-loop orchestrator, traceability skill, demo package, and L3 verify script — portable to Cursor, Codex, and Claude Code.

**Architecture:** Runtime-neutral `SKILL.md` files under `.ai/skills/` drive agent behavior (no TS orchestration). Package state lives in `.ai/packages/<id>/`; narrative artifacts in `artifacts/<id>/`. L1 = phase self-check, L2 = loop gate files, L3 = `loop-verify.sh`.

**Tech Stack:** Markdown skills (YAML frontmatter), YAML config, Bash (`loop-verify.sh`), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-06-12-develop-loop-skills-design.md`

---

## File map (MVP)

| Path | Responsibility |
|------|----------------|
| `.ai/config/profiles.yaml` | Standard profile: phases, human_gates, max_reentry, required_artifacts |
| `.ai/packages/_template/package.yaml` | Copy template for new packages |
| `.ai/packages/_template/classification.yaml` | Classification record template |
| `.ai/skills/lifecycle-loop/SKILL.md` | `/devloop` commands, classify, execution, gate, escalation |
| `.ai/skills/lifecycle-loop/reference.md` | Command cheat sheet, profile table, examples |
| `.ai/skills/traceability/SKILL.md` | Matrix + frontmatter link maintenance |
| `.ai/skills/phases/01-requirement/SKILL.md` | Requirements phase (standalone + L1) |
| `.ai/skills/phases/02-design/SKILL.md` | Design phase |
| `.ai/skills/phases/03-test-plan/SKILL.md` | Test-plan phase |
| `artifacts/FEAT-001/` | Demo narrative artifacts (3 phases) |
| `.ai/packages/FEAT-001/` | Demo package state + gates |
| `traceability/FEAT-001/matrix.md` | Demo trace matrix |
| `scripts/devloop-verify.sh` | L3 structural verifier |
| `scripts/test-loop-verify.sh` | Bash tests for verifier |
| `.github/workflows/devloop-verify.yml` | CI observe mode |
| `AGENTS.md` | Codex/generic agent entry |
| `README.md` | Install + usage guide |
| `.cursor/skills/*/SKILL.md` | Thin pointers to `.ai/skills/` |

Phase 2 (out of MVP scope, listed at end): `04-implementation` through `07-release-retro`, routine/high_risk profiles, parent-child.

---

## Task 1: Repository scaffold

**Files:**
- Create: `.ai/config/profiles.yaml`
- Create: `.ai/packages/_template/package.yaml`
- Create: `.ai/packages/_template/classification.yaml`
- Create: `.gitkeep` placeholders under `.ai/skills/`, `artifacts/`, `traceability/`
- Create: `AGENTS.md`
- Create: `README.md`

- [ ] **Step 1: Create `profiles.yaml`**

```yaml
# .ai/config/profiles.yaml
standard:
  phases: [requirements, design, test-plan]
  human_gates: [requirements]
  max_reentry: 3
  required_artifacts:
    requirements:
      - PRD.md
      - user-stories.md
      - acceptance-criteria.md
      - review-log.md
    design:
      - architecture.md
      - review-log.md
    test-plan:
      - test-strategy.md
      - test-cases.md
      - review-log.md

# Phase 2 — uncomment when implementing
# routine:
#   phases: [requirements, implementation, code-review, test-report, release]
#   human_gates: []
#   max_reentry: 2
# high_risk:
#   phases: [requirements, design, test-plan, implementation, code-review, test-report, release]
#   human_gates: [requirements, design, test-plan, code-review, test-report, release]
#   max_reentry: 3
```

- [ ] **Step 2: Create package template**

```yaml
# .ai/packages/_template/package.yaml
id: PKG-ID-HERE
owner: ""
profile: standard
mode: loop
status: in_progress
phases:
  requirements:
    status: pending
    artifact_version: null
  design:
    status: pending
    artifact_version: null
  test-plan:
    status: pending
    artifact_version: null
children: []
```

```yaml
# .ai/packages/_template/classification.yaml
package_id: PKG-ID-HERE
suggested_tier: standard
active_profile: standard
signals: []
confidence: medium
override: null
classified_at: null
```

- [ ] **Step 3: Create `AGENTS.md`**

```markdown
# Develop Loop Skills

AI-native SDLC skills for end-to-end software development.

## Skills (source of truth: `.ai/skills/`)

| Skill | Path | Trigger |
|-------|------|---------|
| Lifecycle Loop | `.ai/skills/lifecycle-loop/SKILL.md` | `/devloop start\|run\|gate\|status\|classify` |
| Requirements | `.ai/skills/phases/01-requirement/SKILL.md` | PRD, user stories, acceptance criteria |
| Design | `.ai/skills/phases/02-design/SKILL.md` | architecture, API design |
| Test Plan | `.ai/skills/phases/03-test-plan/SKILL.md` | test strategy, test cases |
| Traceability | `.ai/skills/traceability/SKILL.md` | trace matrix, requirement links |

## State

- Package manifest: `.ai/packages/<id>/package.yaml`
- Artifacts: `artifacts/<id>/`
- Trace matrix: `traceability/<id>/matrix.md`
```

- [ ] **Step 4: Create `README.md` skeleton**

Include sections: Overview, Install (copy `.ai/skills` to Cursor/Codex/Claude), Commands (`/devloop start`, `/devloop run`, standalone phase skills), MVP scope (3 phases), 3-level quality model, Directory layout.

- [ ] **Step 5: Verify scaffold**

Run: `find .ai artifacts traceability -type f | sort`
Expected: `profiles.yaml`, both templates, `AGENTS.md`, `README.md`

- [ ] **Step 6: Commit**

```bash
git add .ai/ AGENTS.md README.md artifacts/.gitkeep traceability/.gitkeep
git commit -m "feat: scaffold develop-loop directory layout and config"
```

---

## Task 2: Lifecycle loop skill

**Files:**
- Create: `.ai/skills/lifecycle-loop/SKILL.md`
- Create: `.ai/skills/lifecycle-loop/reference.md`

- [ ] **Step 1: Write skill frontmatter and triggers**

```markdown
---
name: lifecycle-loop
description: >-
  Orchestrates end-to-end SDLC for a change package. Classifies complexity,
  selects workflow profile, invokes phase skills, issues L2 gate decisions,
  controls loop/pipeline re-entry. Use for /devloop start, /devloop run, /devloop gate,
  /devloop status, /devloop classify, lifecycle, SDLC loop, quality gate.
---
```

- [ ] **Step 2: Add Commands section**

Document all six commands with exact behavior per spec §5.2. Include mode flag `--pipeline` and package_id argument.

- [ ] **Step 3: Add Classify steps**

Include rule table (routine / standard / high_risk signals), human confirm/override flow, and exact `classification.yaml` write instructions. MVP: always set `active_profile: standard` after confirm.

- [ ] **Step 4: Add Execution steps (agent guide)**

Write imperative prose (not code) covering all 8 bullets from spec §5.4:
- Re-read disk state after each phase
- Skip archived+pass phases
- Stale upstream → rewind downstream
- Load phase skill by name from `.ai/skills/phases/`
- Wait for `archived` + `review-log.md`
- Run Gate steps before advance
- Loop vs pipeline fail branches
- Final `ready_for_merge` status

Include phase-skill path map:

| Phase key | Skill path |
|-----------|------------|
| requirements | `.ai/skills/phases/01-requirement/SKILL.md` |
| design | `.ai/skills/phases/02-design/SKILL.md` |
| test-plan | `.ai/skills/phases/03-test-plan/SKILL.md` |

- [ ] **Step 5: Add Gate steps**

L2 checklist (5 items from spec §5.5). Gate file template with `result`, `profile`, `mode`, `artifacts_checked`, `checklist`, `findings`, `reentry`, `next`. Rules: never pass without checklist complete; write to `gates/<phase>-<n>.md` with incrementing attempt number.

- [ ] **Step 6: Add Loop vs pipeline, re-entry, stale, escalation sections**

Copy behavior table from spec §2.4. Re-entry: read `max_reentry` from `profiles.yaml`. Escalation stop conditions from spec §5.6. Stale: if `artifact_version` in `package.yaml` changes, mark downstream `pending`.

- [ ] **Step 7: Add Constraints section**

- Do not author phase artifacts
- Do not declare gate PASS from phase skills
- Always write gate file before next phase
- Re-read files from disk; do not rely on conversation memory

- [ ] **Step 8: Write `reference.md`**

Command cheat sheet, standard profile phase order, gate file example, escalation example.

- [ ] **Step 9: Verify skill completeness**

Run: `grep -c '^##' .ai/skills/lifecycle-loop/SKILL.md`
Expected: ≥ 8 sections (Commands, Classify, Execution, Gate, Loop/Pipeline, Re-entry, Escalation, Constraints)

- [ ] **Step 10: Commit**

```bash
git add .ai/skills/lifecycle-loop/
git commit -m "feat: add lifecycle-loop orchestrator skill"
```

---

## Task 3: Traceability skill

**Files:**
- Create: `.ai/skills/traceability/SKILL.md`
- Create: `traceability/_template/matrix.md`

- [ ] **Step 1: Write skill frontmatter**

```markdown
---
name: traceability
description: >-
  Maintains requirement-to-design-to-test trace matrix and typed artifact links.
  Use after phase archive, when updating traceability, trace matrix, or requirement
  coverage map. Invokable standalone or from phase or devloop skills.
---
```

- [ ] **Step 2: Add matrix template**

```markdown
# Traceability Matrix — {package_id}

| Req/AC ID | Design Section | Test Case(s) | Code File(s) | Status | Notes |
|-----------|----------------|--------------|--------------|--------|-------|
| AC-001 | | | | pending | |
```

Save as `traceability/_template/matrix.md`.

- [ ] **Step 3: Add Generate/Update steps**

Instructions:
1. Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` for AC IDs
2. Read design `architecture.md` frontmatter `traces` / headings for design sections
3. Read `test-cases.md` for TC IDs mapped to ACs
4. Fill matrix rows; use `N/A` + reason only when genuinely not applicable
5. Write `traceability/<package_id>/matrix.md`
6. Append decisions to `traceability/<package_id>/decision-records.md` when tradeoffs found

- [ ] **Step 4: Add frontmatter link rules**

When updating artifacts, ensure:
- Design docs: `traces: [{ derives_from: "artifacts/<id>/01-requirements/PRD.md@v1" }]`
- Test cases: `traces: [{ verifies: "AC-001" }]`
- Gate binding: loop skill lists same paths in `artifacts_checked`

- [ ] **Step 5: Add self-check checklist for traceability**

| Check | Pass criteria |
|-------|---------------|
| Every AC has a row | No missing AC IDs |
| Design column filled or N/A | Reason required for N/A |
| Test column filled or N/A | At least one TC per AC for standard profile |
| Status column current | Matches latest gate results |

- [ ] **Step 6: Commit**

```bash
git add .ai/skills/traceability/ traceability/_template/
git commit -m "feat: add traceability skill and matrix template"
```

---

## Task 4: Requirements phase skill (01-requirement)

**Files:**
- Create: `.ai/skills/phases/01-requirement/SKILL.md`
- Create: `.ai/skills/phases/01-requirement/reference.md` (output templates)

- [ ] **Step 1: Write frontmatter with standalone triggers**

Description must include: PRD, user stories, acceptance criteria, requirements phase — usable with or without `/devloop`.

- [ ] **Step 2: Add Required inputs**

- `package_id` from user or `.ai/packages/<id>/package.yaml`
- User feature description, constraints, stakeholders
- Read `profiles.yaml` for human_gates (requirements = human gate in standard)

- [ ] **Step 3: Add Generate steps with output templates**

Create under `artifacts/<package_id>/01-requirements/`:

**PRD.md** — sections: Problem, Goals, Non-goals, Users, Scope, Constraints, Assumptions, Risks

**user-stories.md** — `As a / I want / So that` format with story IDs (US-001)

**acceptance-criteria.md** — AC IDs (AC-001), given/when/then, linked to US-IDs

**open-questions.md**, **out-of-scope.md**, **risk-list.md**

Each file gets frontmatter per spec §4.2 (`artifact_id`, `package_id`, `version`, `status: draft`).

- [ ] **Step 4: Add Self-review checklist → `review-log.md`**

| Check | Rule |
|-------|------|
| Clear user value | Problem statement names user and pain |
| Testable AC | Every AC has measurable outcome |
| No ambiguity | No vague terms (fast, easy, etc.) without definition |
| Boundaries defined | out-of-scope.md is non-empty |
| Acceptance criteria exist | ≥ 1 AC per US |
| Risks identified | ≥ 1 risk with mitigation |

Format: table with pass/fail/note; count blocking failures.

- [ ] **Step 5: Add Human review guidance**

If `requirements` in `human_gates` for active profile: set `status: draft`, present summary, wait for user approval, then set `status: approved` on PRD + `acceptance-criteria.md` frontmatter. Optional `approval.md` with approver + date.

- [ ] **Step 6: Add Archive steps**

1. Bump `version` in frontmatter if revised
2. Set `.ai/packages/<id>/package.yaml` → `phases.requirements.status: archived`, `artifact_version: v<n>`
3. Load traceability skill to seed matrix rows from AC IDs
4. Do NOT write gate PASS

- [ ] **Step 7: Add quality criteria + minimal example in reference.md**

Include a 10-line example AC and one complete user story as reference.

- [ ] **Step 8: Commit**

```bash
git add .ai/skills/phases/01-requirement/
git commit -m "feat: add 01-requirement phase skill"
```

---

## Task 5: Design phase skill (02-design)

**Files:**
- Create: `.ai/skills/phases/02-design/SKILL.md`
- Create: `.ai/skills/phases/02-design/reference.md`

- [ ] **Step 1: Frontmatter + standalone triggers**

Triggers: architecture, API design, data model, system design, technical design.

- [ ] **Step 2: Required inputs**

- `package_id`
- Read `artifacts/<id>/01-requirements/` (PRD, AC) — design must not proceed if requirements not archived
- Read `classification.yaml` for profile

- [ ] **Step 3: Generate steps — outputs**

Under `artifacts/<package_id>/02-design/`:

- `architecture.md` — components, interfaces, data flow (mermaid encouraged)
- `api-design.md` — endpoints/events, request/response shapes
- `data-model.md` — entities, relationships
- `tradeoffs.md` — decision, options, rationale
- `failure-scenarios.md` — error paths, retries, degradation

Frontmatter `traces: [{ derives_from: "artifacts/<id>/01-requirements/PRD.md@v<n>" }]`

- [ ] **Step 4: Self-review checklist**

| Check | Rule |
|-------|------|
| Requirement coverage | Every AC referenced in architecture or api-design |
| Performance considered | Non-functional requirements addressed |
| Reliability/failure | failure-scenarios.md has ≥ 2 scenarios |
| Security noted | Auth/data handling mentioned if applicable |
| Testability | Components expose testable interfaces |
| Tradeoffs documented | tradeoffs.md has ≥ 1 decision |

- [ ] **Step 5: Human review, Archive, quality criteria**

Human review: only if profile `human_gates` includes `design` (not in MVP standard — AI-only path sets `status: reviewed`).

Archive: update `package.yaml` design phase; invoke traceability to fill design columns in matrix.

- [ ] **Step 6: Commit**

```bash
git add .ai/skills/phases/02-design/
git commit -m "feat: add 02-design phase skill"
```

---

## Task 6: Test-plan phase skill (03-test-plan)

**Files:**
- Create: `.ai/skills/phases/03-test-plan/SKILL.md`
- Create: `.ai/skills/phases/03-test-plan/reference.md`

- [ ] **Step 1: Frontmatter + standalone triggers**

Triggers: test plan, test strategy, test cases, QA plan, coverage map.

- [ ] **Step 2: Required inputs**

- Requirements AC file, design docs
- Verify requirements + design phases archived in `package.yaml`

- [ ] **Step 3: Generate steps — outputs**

Under `artifacts/<package_id>/03-test-plan/`:

- `test-strategy.md` — levels (unit/integration/e2e), environments, tools
- `test-cases.md` — TC-001 format: links to AC-00x, steps, expected result
- `edge-cases.md` — boundary and error cases
- `regression-cases.md` — smoke/regression set

Frontmatter `traces: [{ verifies: "AC-001" }]` per case file or per-case table inside.

- [ ] **Step 4: Self-review checklist**

| Check | Rule |
|-------|------|
| AC coverage | Every AC has ≥ 1 TC |
| Exception paths | edge-cases.md non-empty |
| Boundary conditions | At least one boundary per critical AC |
| Security tests | Auth/permission cases if applicable |
| Regression set | regression-cases.md lists smoke tests |

- [ ] **Step 5: Archive + traceability**

Archive test-plan phase; invoke traceability to fill test case columns in matrix for every AC.

- [ ] **Step 6: Commit**

```bash
git add .ai/skills/phases/03-test-plan/
git commit -m "feat: add 03-test-plan phase skill"
```

---

## Task 7: Demo package FEAT-001

**Files:**
- Create: `.ai/packages/FEAT-001/package.yaml`
- Create: `.ai/packages/FEAT-001/classification.yaml`
- Create: `.ai/packages/FEAT-001/gates/*.md` (3 gate files, pass)
- Create: `artifacts/FEAT-001/` (full 3-phase artifacts)
- Create: `traceability/FEAT-001/matrix.md`
- Create: `traceability/FEAT-001/decision-records.md`
- Create: `docs/examples/FEAT-001-walkthrough.md`

**Demo feature:** "Add email notification when an order ships" (small, realistic).

- [ ] **Step 1: Create package + classification**

```yaml
# .ai/packages/FEAT-001/package.yaml
id: FEAT-001
owner: demo
profile: standard
mode: loop
status: ready_for_merge
phases:
  requirements:
    status: archived
    artifact_version: v1
  design:
    status: archived
    artifact_version: v1
  test-plan:
    status: archived
    artifact_version: v1
children: []
```

```yaml
# .ai/packages/FEAT-001/classification.yaml
package_id: FEAT-001
suggested_tier: standard
active_profile: standard
signals:
  - type: feature
  - blast_radius: limited
confidence: high
override: null
classified_at: "2026-06-12"
```

- [ ] **Step 2: Create requirements artifacts**

Write `PRD.md`, `user-stories.md` (2 stories), `acceptance-criteria.md` (3 ACs: AC-001..003), `review-log.md` (all pass), supporting files. PRD `status: approved` (human gate satisfied).

- [ ] **Step 3: Create design artifacts**

`architecture.md`, `api-design.md`, `tradeoffs.md`, `failure-scenarios.md`, `review-log.md`. Frontmatter `derives_from` links to requirements v1.

- [ ] **Step 4: Create test-plan artifacts**

`test-strategy.md`, `test-cases.md` (TC-001..004 mapping to ACs), `edge-cases.md`, `review-log.md`.

- [ ] **Step 5: Create gate files (L2 evidence)**

Three files: `gates/requirements-1.md`, `gates/design-1.md`, `gates/test-plan-1.md` — all `result: pass`, with `artifacts_checked` listing real paths.

- [ ] **Step 6: Create traceability matrix**

Full matrix: 3 rows for AC-001..003 with design sections and TC IDs filled; status `covered`.

- [ ] **Step 7: Write walkthrough doc**

`docs/examples/FEAT-001-walkthrough.md` documenting:
- `/devloop start FEAT-001` equivalent steps taken
- Loop mode E2E path
- Pipeline mode fail/resume example (narrative)
- Evidence chain diagram (requirement → design → test → gate)

- [ ] **Step 8: Commit**

```bash
git add .ai/packages/FEAT-001/ artifacts/FEAT-001/ traceability/FEAT-001/ docs/examples/
git commit -m "feat: add FEAT-001 demo package with full evidence chain"
```

---

## Task 8: loop-verify.sh (L3) + tests

**Files:**
- Create: `scripts/devloop-verify.sh`
- Create: `scripts/test-loop-verify.sh`

- [ ] **Step 1: Write failing test script**

```bash
#!/usr/bin/env bash
# scripts/test-loop-verify.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/devloop-verify.sh"

# Test 1: FEAT-001 demo package passes
output=$("$SCRIPT" FEAT-001 2>&1) || { echo "FAIL: FEAT-001 should pass"; echo "$output"; exit 1; }
echo "$output" | grep -q "PASS" || { echo "FAIL: expected PASS"; exit 1; }

# Test 2: missing package fails
if "$SCRIPT" NONEXISTENT 2>/dev/null; then
  echo "FAIL: NONEXISTENT should fail"; exit 1
fi
echo "PASS: NONEXISTENT correctly failed"

# Test 3: package missing review-log fails
mkdir -p "$ROOT/.ai/packages/TEST-BAD/gates"
cp "$ROOT/.ai/packages/FEAT-001/package.yaml" "$ROOT/.ai/packages/TEST-BAD/package.yaml"
sed -i '' 's/FEAT-001/TEST-BAD/g' "$ROOT/.ai/packages/TEST-BAD/package.yaml"
cp "$ROOT/.ai/packages/FEAT-001/classification.yaml" "$ROOT/.ai/packages/TEST-BAD/"
sed -i '' 's/FEAT-001/TEST-BAD/g' "$ROOT/.ai/packages/TEST-BAD/classification.yaml"
if "$SCRIPT" TEST-BAD 2>/dev/null; then
  echo "FAIL: TEST-BAD should fail without artifacts"; exit 1
fi
rm -rf "$ROOT/.ai/packages/TEST-BAD"
echo "PASS: TEST-BAD correctly failed"

echo "All loop-verify tests passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `chmod +x scripts/test-loop-verify.sh && ./scripts/test-loop-verify.sh`
Expected: FAIL — `loop-verify.sh` not found

- [ ] **Step 3: Implement `loop-verify.sh`**

```bash
#!/usr/bin/env bash
# scripts/devloop-verify.sh — L3 structural verifier (no LLM)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_ID="${1:?Usage: loop-verify.sh <package_id>}"
PKG_DIR="$ROOT/.ai/packages/$PKG_ID"
ART_DIR="$ROOT/artifacts/$PKG_ID"
TRACE_MATRIX="$ROOT/traceability/$PKG_ID/matrix.md"
PROFILES="$ROOT/.ai/config/profiles.yaml"
ERRORS=0
WARNINGS=0

err() { echo "ERROR: $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN: $1"; WARNINGS=$((WARNINGS + 1)); }

[[ -f "$PKG_DIR/package.yaml" ]] || { err "missing package.yaml"; echo "FAIL ($ERRORS errors)"; exit 1; }
[[ -f "$PKG_DIR/classification.yaml" ]] || err "missing classification.yaml"

PROFILE=$(grep -E '^profile:' "$PKG_DIR/package.yaml" | awk '{print $2}')
[[ -n "$PROFILE" ]] || err "package.yaml missing profile"

# Read archived phases from package.yaml (lines with status: archived under phases)
ARCHIVED_PHASES=$(awk '/^  [a-z-]+:$/{phase=$1; gsub(/:/,"",phase)} /status: archived/{print phase}' "$PKG_DIR/package.yaml")

for phase in $ARCHIVED_PHASES; do
  case "$phase" in
    requirements) dir="01-requirements" ;;
    design) dir="02-design" ;;
    test-plan) dir="03-test-plan" ;;
    *) err "unknown phase: $phase"; continue ;;
  esac
  PHASE_DIR="$ART_DIR/$dir"
  [[ -d "$PHASE_DIR" ]] || { err "missing artifacts/$PKG_ID/$dir"; continue; }
  [[ -f "$PHASE_DIR/review-log.md" ]] || err "missing review-log in $dir"
  # Required artifacts from profiles.yaml (simplified: hardcode standard MVP set)
  case "$phase" in
    requirements)
      for f in PRD.md user-stories.md acceptance-criteria.md; do
        [[ -f "$PHASE_DIR/$f" ]] || err "missing $dir/$f"
      done
      if grep -q 'human_gates:.*requirements' "$PROFILES" 2>/dev/null; then
        grep -q 'status: approved' "$PHASE_DIR/PRD.md" 2>/dev/null || err "requirements human gate: PRD not approved"
      fi
      ;;
    design)
      [[ -f "$PHASE_DIR/architecture.md" ]] || err "missing design/architecture.md"
      ;;
    test-plan)
      [[ -f "$PHASE_DIR/test-strategy.md" ]] || err "missing test-plan/test-strategy.md"
      [[ -f "$PHASE_DIR/test-cases.md" ]] || err "missing test-plan/test-cases.md"
      ;;
  esac
  GATE_COUNT=$(find "$PKG_DIR/gates" -name "${phase}-*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ "$GATE_COUNT" -ge 1 ]] || err "no gate file for phase $phase"
done

[[ -f "$TRACE_MATRIX" ]] || warn "missing traceability/$PKG_ID/matrix.md"

if [[ $ERRORS -gt 0 ]]; then
  echo "FAIL ($ERRORS errors, $WARNINGS warnings)"
  exit 1
fi
echo "PASS ($WARNINGS warnings)"
exit 0
```

- [ ] **Step 4: Run tests**

Run: `chmod +x scripts/devloop-verify.sh scripts/test-loop-verify.sh && ./scripts/test-loop-verify.sh`
Expected: `All loop-verify tests passed`

Run: `./scripts/devloop-verify.sh FEAT-001`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add scripts/
git commit -m "feat: add L3 loop-verify script with tests"
```

---

## Task 9: GitHub Actions (observe mode)

**Files:**
- Create: `.github/workflows/devloop-verify.yml`

- [ ] **Step 1: Write workflow**

```yaml
name: Loop Verify
on:
  pull_request:
    paths:
      - '.ai/**'
      - 'artifacts/**'
      - 'traceability/**'
      - 'scripts/devloop-verify.sh'
  workflow_dispatch:
    inputs:
      package_id:
        description: 'Package ID to verify'
        default: 'FEAT-001'

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify package
        run: |
          PKG="${{ github.event.inputs.package_id || 'FEAT-001' }}"
          chmod +x scripts/devloop-verify.sh
          ./scripts/devloop-verify.sh "$PKG"
      - name: Report (observe mode)
        if: failure()
        run: echo "::warning::Loop verify failed — observe mode, not blocking merge yet"
```

- [ ] **Step 2: Document observe mode in README**

Add note: Stage 1 CI reports failures as warnings; Stage 2 makes check required.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/devloop-verify.yml README.md
git commit -m "ci: add loop-verify workflow in observe mode"
```

---

## Task 10: Cursor skill pointers + README finalize

**Files:**
- Create: `.cursor/skills/lifecycle-loop/SKILL.md` (pointer)
- Create: `.cursor/skills/01-requirement/SKILL.md` (pointer)
- Create: `.cursor/skills/02-design/SKILL.md` (pointer)
- Create: `.cursor/skills/03-test-plan/SKILL.md` (pointer)
- Create: `.cursor/skills/traceability/SKILL.md` (pointer)
- Modify: `README.md` (complete install guide)

- [ ] **Step 1: Create pointer skills**

Each `.cursor/skills/<name>/SKILL.md`:

```markdown
---
name: <name>
description: <same as .ai/skills source>
---

# <Name>

**Source of truth:** `.ai/skills/<path>/SKILL.md`

Read and follow the source skill file in this repository. Do not use this pointer without loading the full skill.
```

- [ ] **Step 2: Complete README**

Sections:
1. What is Develop Loop
2. Four success pillars (phase quality, orchestration, 3-level quality, traceability)
3. Quick start: `/devloop start FEAT-002`, `/devloop run FEAT-002`
4. Standalone phase skill usage
5. Install for Cursor / Codex / Claude Code
6. MVP scope vs Phase 2
7. Running `loop-verify.sh` locally

- [ ] **Step 3: Commit**

```bash
git add .cursor/skills/ README.md
git commit -m "docs: add Cursor skill pointers and complete README"
```

---

## Task 11: MVP acceptance verification

**Files:**
- Modify: `docs/examples/FEAT-001-walkthrough.md` (add verification checklist)

- [ ] **Step 1: Run full verification checklist**

```bash
# Structural L3
./scripts/devloop-verify.sh FEAT-001

# Skill files exist
test -f .ai/skills/lifecycle-loop/SKILL.md
test -f .ai/skills/phases/01-requirement/SKILL.md
test -f .ai/skills/phases/02-design/SKILL.md
test -f .ai/skills/phases/03-test-plan/SKILL.md
test -f .ai/skills/traceability/SKILL.md

# Demo evidence chain
test -f traceability/FEAT-001/matrix.md
ls .ai/packages/FEAT-001/gates/*.md | wc -l | grep -q 3

# Section completeness in lifecycle-loop
grep -q "Execution steps" .ai/skills/lifecycle-loop/SKILL.md
grep -q "Gate steps" .ai/skills/lifecycle-loop/SKILL.md
grep -q "pipeline" .ai/skills/lifecycle-loop/SKILL.md
```

Expected: all commands exit 0; `loop-verify.sh` prints PASS.

- [ ] **Step 2: Add acceptance checklist to walkthrough**

Map each spec §8.2 criterion to evidence file path (8 items).

- [ ] **Step 3: Final commit**

```bash
git add docs/examples/FEAT-001-walkthrough.md
git commit -m "docs: add MVP acceptance verification checklist"
```

---

## Phase 2 backlog (separate plan after MVP ships)

Not in this plan's execution scope. Track as follow-up:

| Item | Files to create |
|------|-----------------|
| 04-implementation skill | `.ai/skills/phases/04-implementation/SKILL.md` |
| 05-code-review skill | `.ai/skills/phases/05-code-review/SKILL.md` |
| 06-test-report skill | `.ai/skills/phases/06-test-report/SKILL.md` |
| 07-release-retro skill | `.ai/skills/phases/07-release-retro/SKILL.md` |
| routine + high_risk profiles | `.ai/config/profiles.yaml` |
| Parent-child packages | lifecycle-loop reference + package.yaml schema |
| CI enforce mode | `.github/workflows/devloop-verify.yml` branch protection |

---

## Spec coverage self-review

| Spec section | Task |
|--------------|------|
| §2.1 Phase skill quality | Tasks 4, 5, 6 |
| §2.2 Orchestration | Task 2 |
| §2.3 3-level quality | Tasks 2, 4-6 (L1), 7 (L2 demo), 8 (L3) |
| §2.4 Loop/pipeline | Task 2 § Execution + Gate |
| §2.5 Traceability evidence | Tasks 3, 7 |
| §2.6 Portability | Tasks 1, 10 |
| §3 Profiles + packages | Tasks 1, 7 |
| §4 Phase contract | Tasks 4, 5, 6 |
| §5 Lifecycle loop | Task 2 |
| §8 MVP criteria | Task 11 |
| §10 Light CI | Tasks 8, 9 |

No placeholder steps. Phase 2 explicitly deferred.
