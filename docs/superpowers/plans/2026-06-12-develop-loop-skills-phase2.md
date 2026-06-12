# Develop Loop Skills — Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the 7-phase SDLC skill ecosystem — add implementation through release-retro skills, activate routine/high_risk profiles, parent-child package orchestration, and CI enforce mode — while keeping MVP (3-phase FEAT-001) working.

**Architecture:** Extend the existing markdown-skill + YAML-state model. Phase 2 adds four phase skills under `.ai/skills/phases/04–07/`, expands `profiles.yaml` and `package.yaml` schema, updates lifecycle-loop classify/execution/parent-child sections, extends traceability for code columns, and hardens `loop-verify.sh` to be profile-aware with an enforce flag.

**Tech Stack:** Markdown skills (YAML frontmatter), YAML config, Bash (`loop-verify.sh`, `test-loop-verify.sh`), GitHub Actions.

**Prerequisite:** MVP plan complete (`docs/superpowers/plans/2026-06-12-develop-loop-skills.md`). Spec: `docs/superpowers/specs/2026-06-12-develop-loop-skills-design.md`.

---

## File map (Phase 2)

| Path | Responsibility |
|------|----------------|
| `.ai/config/profiles.yaml` | Activate `standard` (7 phases), `routine`, `high_risk` |
| `.ai/packages/_template/package.yaml` | All 7 phase slots + `children` schema |
| `.ai/skills/phases/04-implementation/SKILL.md` | Implementation plan, coding log, changed files |
| `.ai/skills/phases/04-implementation/reference.md` | Output templates |
| `.ai/skills/phases/05-code-review/SKILL.md` | Multi-lens review artifacts |
| `.ai/skills/phases/05-code-review/reference.md` | Review templates |
| `.ai/skills/phases/06-test-report/SKILL.md` | Test execution summary, coverage, release rec |
| `.ai/skills/phases/06-test-report/reference.md` | Report templates |
| `.ai/skills/phases/07-release-retro/SKILL.md` | Release notes, known issues, retro |
| `.ai/skills/phases/07-release-retro/reference.md` | Release templates |
| `.ai/skills/lifecycle-loop/SKILL.md` | 7-phase path map, profile-aware classify, parent-child gates |
| `.ai/skills/lifecycle-loop/reference.md` | Profile tables, parent-child examples |
| `.ai/skills/traceability/SKILL.md` | Code column + `implements:` frontmatter rules |
| `scripts/loop-verify.sh` | 7 phases, profile-driven artifacts, `--enforce` |
| `scripts/test-loop-verify.sh` | Tests for new phases + enforce flag |
| `.github/workflows/loop-verify.yml` | Enforce mode (required check) |
| `.ai/packages/FEAT-003/` | Full 7-phase demo package |
| `artifacts/FEAT-003/` | 7-phase narrative artifacts |
| `traceability/FEAT-003/matrix.md` | Full chain incl. code files |
| `.ai/packages/FEAT-PARENT/` + `FEAT-CHILD/` | Parent-child demo |
| `docs/examples/FEAT-003-walkthrough.md` | 7-phase + profile examples |
| `docs/examples/parent-child-walkthrough.md` | Parent-child gate flow |
| `.cursor/skills/04-implementation/` … `07-release-retro/` | Thin pointers |
| `AGENTS.md`, `README.md` | Updated skill table and Phase 2 scope |

**Unchanged:** FEAT-001 remains the 3-phase MVP demo; `loop-verify.sh FEAT-001` must still PASS after every task.

---

## Task 1: Expand profiles and package template

**Files:**
- Modify: `.ai/config/profiles.yaml`
- Modify: `.ai/packages/_template/package.yaml`

- [ ] **Step 1: Replace `profiles.yaml` with full 3-profile config**

```yaml
# .ai/config/profiles.yaml
standard:
  phases: [requirements, design, test-plan, implementation, code-review, test-report, release]
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
    implementation:
      - implementation-plan.md
      - changed-files.md
      - coding-log.md
      - review-log.md
    code-review:
      - ai-review.md
      - review-log.md
    test-report:
      - test-execution-summary.md
      - coverage-report.md
      - review-log.md
    release:
      - release-notes.md
      - known-issues.md
      - retro.md
      - review-log.md

routine:
  phases: [requirements, implementation, code-review, test-report, release]
  human_gates: []
  max_reentry: 2
  required_artifacts:
    requirements:
      - PRD.md
      - user-stories.md
      - acceptance-criteria.md
      - review-log.md
    implementation:
      - implementation-plan.md
      - changed-files.md
      - coding-log.md
      - review-log.md
    code-review:
      - ai-review.md
      - review-log.md
    test-report:
      - test-execution-summary.md
      - coverage-report.md
      - review-log.md
    release:
      - release-notes.md
      - known-issues.md
      - retro.md
      - review-log.md

high_risk:
  phases: [requirements, design, test-plan, implementation, code-review, test-report, release]
  human_gates: [requirements, design, test-plan, code-review, test-report, release]
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
    implementation:
      - implementation-plan.md
      - changed-files.md
      - coding-log.md
      - review-log.md
    code-review:
      - ai-review.md
      - security-review.md
      - review-log.md
    test-report:
      - test-execution-summary.md
      - coverage-report.md
      - review-log.md
    release:
      - release-notes.md
      - known-issues.md
      - retro.md
      - review-log.md
```

- [ ] **Step 2: Expand package template with all phase slots**

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
  implementation:
    status: pending
    artifact_version: null
  code-review:
    status: pending
    artifact_version: null
  test-report:
    status: pending
    artifact_version: null
  release:
    status: pending
    artifact_version: null
children: []
# Phase 2 parent-child example:
# children:
#   - id: FEAT-CHILD-001
#     relationship: implements
```

- [ ] **Step 3: Verify MVP still valid**

Run: `./scripts/loop-verify.sh FEAT-001`
Expected: `PASS` (FEAT-001 only has 3 archived phases; verifier checks archived phases only)

- [ ] **Step 4: Commit**

```bash
git add .ai/config/profiles.yaml .ai/packages/_template/package.yaml
git commit -m "feat: activate routine, high_risk, and 7-phase standard profiles"
```

---

## Task 2: Implementation phase skill (04-implementation)

**Files:**
- Create: `.ai/skills/phases/04-implementation/SKILL.md`
- Create: `.ai/skills/phases/04-implementation/reference.md`

- [ ] **Step 1: Write frontmatter and triggers**

```markdown
---
name: 04-implementation
description: >-
  Plans and executes approved design within scope. Produces implementation plan,
  changed-files manifest, and coding log. Use for implementation phase, coding,
  build feature, implement design — standalone or via /loop. Does not issue
  final gate PASS.
---
```

- [ ] **Step 2: Add Required inputs section**

- `package_id`
- Read `artifacts/<id>/01-requirements/acceptance-criteria.md` — scope boundary
- Read `artifacts/<id>/02-design/` — architecture, api-design (required if design phase archived)
- Read `artifacts/<id>/03-test-plan/test-cases.md` — tests to add/run
- Read `.ai/packages/<id>/package.yaml` — do not proceed if upstream phases for active profile are not `archived`
- For `routine` profile: requirements must be archived; design/test-plan may be skipped

- [ ] **Step 3: Add Generate steps with output templates**

Create under `artifacts/<package_id>/04-implementation/`:

| File | Content |
|------|---------|
| `implementation-plan.md` | Tasks mapped to AC IDs, file touch list, test plan, rollback approach |
| `changed-files.md` | Table: path, change type (add/modify/delete), AC/design ref |
| `coding-log.md` | Chronological log: date, files, summary, test commands run |
| `assumptions.md` | Deviations from design with rationale |

Frontmatter on each file:

```yaml
---
artifact_id: IMPL-001-plan
artifact_type: implementation
package_id: FEAT-003
version: v1
status: draft
traces:
  - implements: "artifacts/FEAT-003/02-design/architecture.md@v1"
  - satisfies: "AC-001"
related: []
---
```

**Code execution:** After writing `implementation-plan.md`, implement code in the repository per plan. Update `changed-files.md` with actual paths. Run tests; record commands and results in `coding-log.md`.

- [ ] **Step 4: Add Self-review checklist → `review-log.md`**

| Check | Rule |
|-------|------|
| Approved scope only | Every changed file maps to an AC or approved design section |
| Design conformance | No undocumented API/schema changes |
| Tests present | New/changed behavior has unit or integration tests |
| Error handling | Failure paths from design addressed in code |
| Traceability | `changed-files.md` lists all touched source paths |

Format: same table as `01-requirement` skill (`pass/fail/note`, blocking count).

- [ ] **Step 5: Add Human review, Archive, quality criteria**

Human review: only if profile `human_gates` includes `implementation` (not in any Phase 2 profile — AI path sets `status: reviewed`).

Archive steps:
1. Bump `version` in frontmatter if revised
2. Set `package.yaml` → `phases.implementation.status: archived`, `artifact_version: v<n>`
3. Invoke traceability skill to fill **Code File(s)** column in matrix from `changed-files.md`
4. Do NOT write gate PASS

- [ ] **Step 6: Add minimal example in `reference.md`**

Include a 15-line `changed-files.md` table and one `coding-log.md` entry.

- [ ] **Step 7: Verify skill sections**

Run: `grep -c '^##' .ai/skills/phases/04-implementation/SKILL.md`
Expected: ≥ 7 sections (Required inputs, Step 1–4 or equivalent Generate/Self Review/Human/Archive/Quality)

- [ ] **Step 8: Commit**

```bash
git add .ai/skills/phases/04-implementation/
git commit -m "feat: add 04-implementation phase skill"
```

---

## Task 3: Code review phase skill (05-code-review)

**Files:**
- Create: `.ai/skills/phases/05-code-review/SKILL.md`
- Create: `.ai/skills/phases/05-code-review/reference.md`

- [ ] **Step 1: Write frontmatter and triggers**

```markdown
---
name: 05-code-review
description: >-
  Evidence-grounded code review across general, security, performance,
  maintainability, and testability lenses. Use for code review phase, PR review,
  security review — standalone or via /loop. Does not issue final gate PASS.
---
```

- [ ] **Step 2: Add Required inputs**

- `package_id`
- Read `artifacts/<id>/04-implementation/changed-files.md` — files to review
- Read actual source files listed in changed-files
- Read design + AC for conformance checks
- Verify `phases.implementation.status: archived` in `package.yaml`

- [ ] **Step 3: Add Generate steps — outputs**

Under `artifacts/<package_id>/05-code-review/`:

| File | Content |
|------|---------|
| `ai-review.md` | General findings with file:line references |
| `security-review.md` | Auth, input validation, secrets, injection (required for `high_risk`) |
| `performance-review.md` | Hot paths, N+1, caching notes |
| `maintainability-review.md` | Naming, duplication, complexity |
| `testability-review.md` | Test gaps, mockability |
| `blocking-issues.md` | Must-fix items before advance |
| `non-blocking-suggestions.md` | Optional improvements |

Frontmatter `traces` example:

```yaml
traces:
  - reviews: "artifacts/FEAT-003/04-implementation/changed-files.md@v1"
```

- [ ] **Step 4: Add Self-review checklist**

| Check | Rule |
|-------|------|
| Evidence-grounded | Every finding cites file path (and line when possible) |
| Blocking vs non-blocking | `blocking-issues.md` separated from suggestions |
| AC coverage | Review notes whether each AC is implemented |
| Security lens | `security-review.md` non-empty for high_risk; N/A note for routine if truly N/A |
| Testability | Test gaps listed with suggested test names |

- [ ] **Step 5: Add Human review guidance**

If `code-review` in `human_gates` (high_risk: **yes**):
1. Present `blocking-issues.md` summary
2. Wait for human sign-off
3. Add `approval.md` with approver, date, and `blocking_count: 0`
4. Set `ai-review.md` frontmatter `status: approved`

If not in human_gates: set `status: reviewed` when no blocking issues remain.

- [ ] **Step 6: Archive steps**

Update `package.yaml` code-review phase; invoke traceability if matrix status should change.

- [ ] **Step 7: Commit**

```bash
git add .ai/skills/phases/05-code-review/
git commit -m "feat: add 05-code-review phase skill"
```

---

## Task 4: Test report phase skill (06-test-report)

**Files:**
- Create: `.ai/skills/phases/06-test-report/SKILL.md`
- Create: `.ai/skills/phases/06-test-report/reference.md`

- [ ] **Step 1: Write frontmatter and triggers**

```markdown
---
name: 06-test-report
description: >-
  Runs and documents test execution against the test plan. Produces execution
  summary, coverage, defects, and release recommendation. Use for test report,
  validation, QA results — standalone or via /loop. Does not issue final gate PASS.
---
```

- [ ] **Step 2: Add Required inputs**

- `package_id`
- Read `artifacts/<id>/03-test-plan/test-cases.md` — TC IDs to execute
- Read `artifacts/<id>/04-implementation/changed-files.md` — scope for coverage
- Verify `phases.code-review.status: archived`
- Run test commands from project (record actual stdout/summary in artifacts)

- [ ] **Step 3: Add Generate steps — outputs**

Under `artifacts/<package_id>/06-test-report/`:

| File | Content |
|------|---------|
| `test-execution-summary.md` | Per TC: pass/fail/skip, command, duration, evidence link |
| `unit-test-report.md` | Unit test results breakdown |
| `integration-test-report.md` | Integration results (or N/A with reason) |
| `e2e-test-report.md` | E2E results (or N/A with reason) |
| `coverage-report.md` | Line/branch coverage %, gaps vs changed files |
| `defects.md` | Open defects mapped to TC/AC |
| `release-recommendation.md` | go / no-go with risks |

Frontmatter:

```yaml
traces:
  - validates: "TC-001"
  - validates: "AC-001"
```

- [ ] **Step 4: Add Self-review checklist**

| Check | Rule |
|-------|------|
| AC coverage | Every AC has ≥ 1 executed TC with recorded result |
| Evidence complete | Commands and timestamps in execution summary |
| Failures documented | Failed TCs appear in `defects.md` with severity |
| Coverage reported | `coverage-report.md` covers changed source files |
| Release rec explicit | `release-recommendation.md` states go/no-go |

- [ ] **Step 5: Human review + Archive**

Human review if `test-report` in `human_gates` (high_risk: **yes**) — require `approval.md` before archive.

Archive: update `package.yaml`; traceability updates matrix **Status** column per AC.

- [ ] **Step 6: Commit**

```bash
git add .ai/skills/phases/06-test-report/
git commit -m "feat: add 06-test-report phase skill"
```

---

## Task 5: Release & retro phase skill (07-release-retro)

**Files:**
- Create: `.ai/skills/phases/07-release-retro/SKILL.md`
- Create: `.ai/skills/phases/07-release-retro/reference.md`

- [ ] **Step 1: Write frontmatter and triggers**

```markdown
---
name: 07-release-retro
description: >-
  Produces release notes, known issues, and retrospective. Closes the SDLC loop.
  Use for release, retro, ship, deploy — standalone or via /loop. Does not issue
  final gate PASS.
---
```

- [ ] **Step 2: Add Required inputs**

- `package_id`
- Read all prior phase artifacts (requirements through test-report)
- Read `artifacts/<id>/06-test-report/release-recommendation.md` — must be `go` or waived
- Verify `phases.test-report.status: archived`

- [ ] **Step 3: Add Generate steps — outputs**

Under `artifacts/<package_id>/07-release-retro/`:

| File | Content |
|------|---------|
| `release-notes.md` | User-facing changes by AC/US, migration notes |
| `known-issues.md` | Shipped-with issues, workarounds |
| `retro.md` | What went well, what to improve, action items |
| `rollback-plan.md` | Steps to revert release if needed |

- [ ] **Step 4: Add Self-review checklist**

| Check | Rule |
|-------|------|
| Scope accurate | Release notes match merged AC scope only |
| Validation status | References test-report go/no-go |
| Known issues honest | Non-empty or explicit "none" with date |
| Rollback viable | `rollback-plan.md` has concrete steps |
| Retro actionable | ≥ 1 improvement action item |

- [ ] **Step 5: Human review + Archive**

Human review if `release` in `human_gates` (high_risk: **yes**).

Archive:
1. Update `package.yaml` → `phases.release.status: archived`
2. Set package `status: ready_for_release`
3. Invoke traceability for final matrix pass

- [ ] **Step 6: Commit**

```bash
git add .ai/skills/phases/07-release-retro/
git commit -m "feat: add 07-release-retro phase skill"
```

---

## Task 6: Lifecycle-loop — profiles, 7-phase map, classify

**Files:**
- Modify: `.ai/skills/lifecycle-loop/SKILL.md`
- Modify: `.ai/skills/lifecycle-loop/reference.md`

- [ ] **Step 1: Update Classify Steps — remove MVP-only restriction**

Replace the line:

```markdown
**MVP:** After confirm, set `active_profile: standard` (only active profile in `.ai/config/profiles.yaml`).
```

With:

```markdown
After confirm, set `active_profile` to the confirmed tier (`routine`, `standard`, or `high_risk`). Write matching `profile` field in `package.yaml`. Show the user the phase list and human gates from `profiles.yaml` for that profile before first `/loop run`.
```

- [ ] **Step 2: Expand phase skill path map**

Add to the existing table in `SKILL.md`:

| Phase key | Skill path | Artifact dir |
|-----------|------------|--------------|
| implementation | `.ai/skills/phases/04-implementation/SKILL.md` | `04-implementation` |
| code-review | `.ai/skills/phases/05-code-review/SKILL.md` | `05-code-review` |
| test-report | `.ai/skills/phases/06-test-report/SKILL.md` | `06-test-report` |
| release | `.ai/skills/phases/07-release-retro/SKILL.md` | `07-release-retro` |

- [ ] **Step 3: Add profile-aware phase skipping in Execution Steps**

Insert after step 3 under "Before each phase":

```markdown
5. Load `phases` list for `active_profile` from `profiles.yaml`. **Skip** phases not in the profile (e.g. `routine` skips `design` and `test-plan`). Do not gate skipped phases.
```

- [ ] **Step 4: Update final status line**

Change:

```markdown
Set `package.yaml` `status: ready_for_merge` (or `ready_for_release` when release phase exists).
```

To:

```markdown
- If profile includes `release` and release gate passes → `status: ready_for_release`
- Else if all profile phases pass → `status: ready_for_merge`
```

- [ ] **Step 5: Update `reference.md`**

Add three profile summary tables (phases, human_gates, max_reentry) copied from `profiles.yaml`.

- [ ] **Step 6: Verify**

Run: `grep -E '04-implementation|05-code-review|06-test-report|07-release-retro' .ai/skills/lifecycle-loop/SKILL.md | wc -l`
Expected: ≥ 4

- [ ] **Step 7: Commit**

```bash
git add .ai/skills/lifecycle-loop/
git commit -m "feat: lifecycle-loop 7-phase execution and profile-aware classify"
```

---

## Task 7: Lifecycle-loop — parent-child packages

**Files:**
- Modify: `.ai/skills/lifecycle-loop/SKILL.md` (Parent-Child section)
- Modify: `.ai/skills/lifecycle-loop/reference.md`
- Create: `docs/examples/parent-child-walkthrough.md`

- [ ] **Step 1: Replace stub Parent-Child section with full steps**

```markdown
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
2. For parent's active profile, determine required phases on **each child** (child uses its own `profile` from its `classification.yaml`).
3. **Child readiness:** each child must have all its profile phases `archived` with latest gate `result: pass`.
4. If any child fails readiness → parent gate `result: fail` with finding listing child id and missing phase.
5. Parent gate `artifacts_checked` includes child package paths:
   - `.ai/packages/<child_id>/package.yaml`
   - `.ai/packages/<child_id>/gates/<latest-pass-per-phase>`

### Constraints

- Do not copy child artifacts into parent `artifacts/` folder.
- Parent PRD may reference child IDs in scope; traceability stays per-package.
- Child packages run `/loop run` independently; parent `/loop run` checks children only at gate time.
```

- [ ] **Step 2: Add parent-child example to `reference.md`**

Document FEAT-PARENT / FEAT-CHILD-001 gate checklist snippet.

- [ ] **Step 3: Write `docs/examples/parent-child-walkthrough.md`**

Narrative: parent feature "Order dashboard" with child "Email notification service" (reuse FEAT-001 concept as child). Steps: create both packages, complete child loop, run parent release gate verifying child readiness.

- [ ] **Step 4: Commit**

```bash
git add .ai/skills/lifecycle-loop/ docs/examples/parent-child-walkthrough.md
git commit -m "feat: parent-child package orchestration in lifecycle-loop"
```

---

## Task 8: Traceability — code column and implementation links

**Files:**
- Modify: `.ai/skills/traceability/SKILL.md`

- [ ] **Step 1: Add implementation-phase update steps**

Insert after step 3 in Update steps:

```markdown
4. Read `artifacts/<package_id>/04-implementation/changed-files.md` — map AC IDs to source file paths for **Code File(s)** column.
5. Read `artifacts/<package_id>/06-test-report/test-execution-summary.md` — set matrix **Status** to `covered` or `failed` per AC.
```

(Renumber following steps.)

- [ ] **Step 2: Add `implements:` frontmatter rule**

```markdown
**Implementation / code artifacts:**
```yaml
traces:
  - implements: "artifacts/<package_id>/02-design/architecture.md@v1"
  - satisfies: "AC-001"
```

**Source files:** Add HTML comment at top of changed files when practical:
`<!-- implements: AC-001 design: architecture.md §2 -->`
```

- [ ] **Step 3: Update self-check for code column**

| Check | Pass criteria |
|-------|---------------|
| Code column filled or N/A | After implementation archived, every AC row has file path or N/A + reason |

- [ ] **Step 4: Remove MVP-only note**

Delete: `Code File(s) column may be N/A until implementation phase (Phase 2).`

- [ ] **Step 5: Commit**

```bash
git add .ai/skills/traceability/SKILL.md
git commit -m "feat: traceability code column and implementation links"
```

---

## Task 9: loop-verify.sh — 7 phases, profile-aware, enforce flag (TDD)

**Files:**
- Modify: `scripts/test-loop-verify.sh`
- Modify: `scripts/loop-verify.sh`

- [ ] **Step 1: Write failing tests for new phases and enforce**

Append to `scripts/test-loop-verify.sh`:

```bash
# Test 4: FEAT-001 still passes (regression)
output=$("$SCRIPT" FEAT-001 2>&1) || { echo "FAIL: FEAT-001 regression"; exit 1; }

# Test 5: --enforce turns matrix warning into failure
mkdir -p "$ROOT/.ai/packages/TEST-NOMATRIX/gates"
cat > "$ROOT/.ai/packages/TEST-NOMATRIX/package.yaml" <<'EOF'
id: TEST-NOMATRIX
owner: test
profile: routine
mode: loop
status: in_progress
phases:
  requirements:
    status: archived
    artifact_version: v1
children: []
EOF
echo "package_id: TEST-NOMATRIX" > "$ROOT/.ai/packages/TEST-NOMATRIX/classification.yaml"
mkdir -p "$ROOT/artifacts/TEST-NOMATRIX/01-requirements"
for f in PRD.md user-stories.md acceptance-criteria.md review-log.md; do
  echo "status: approved" > "$ROOT/artifacts/TEST-NOMATRIX/01-requirements/$f"
done
echo "result: pass" > "$ROOT/.ai/packages/TEST-NOMATRIX/gates/requirements-1.md"
if "$SCRIPT" TEST-NOMATRIX 2>/dev/null; then
  echo "FAIL: TEST-NOMATRIX should warn without matrix"
fi
if "$SCRIPT" --enforce TEST-NOMATRIX 2>/dev/null; then
  echo "FAIL: --enforce should fail without matrix"; exit 1
fi
rm -rf "$ROOT/.ai/packages/TEST-NOMATRIX" "$ROOT/artifacts/TEST-NOMATRIX"
echo "PASS: enforce flag works"

# Test 6: unknown phase in package fails gracefully
# (run after FEAT-003 exists — skip if FEAT-003 not yet created)
if [[ -d "$ROOT/.ai/packages/FEAT-003" ]]; then
  output=$("$SCRIPT" FEAT-003 2>&1) || { echo "FAIL: FEAT-003 should pass"; echo "$output"; exit 1; }
fi
```

- [ ] **Step 2: Run tests to verify new failures**

Run: `./scripts/test-loop-verify.sh`
Expected: FAIL on Test 5 (`--enforce` not implemented) and possibly Test 6 if FEAT-003 missing (acceptable until Task 10)

- [ ] **Step 3: Implement profile-aware `loop-verify.sh`**

Key changes:

1. Parse optional `--enforce` flag; set `ENFORCE=1` when present; shift package id arg.
2. Expand phase→dir map:

```bash
phase_to_dir() {
  case "$1" in
    requirements) echo "01-requirements" ;;
    design) echo "02-design" ;;
    test-plan) echo "03-test-plan" ;;
    implementation) echo "04-implementation" ;;
    code-review) echo "05-code-review" ;;
    test-report) echo "06-test-report" ;;
    release) echo "07-release-retro" ;;
    *) echo "" ;;
  esac
}
```

3. Add `required_files_for_phase()` function with case branches for each profile+phase combination (mirror `profiles.yaml` lists exactly).

4. Human-gate check: read `human_gates` for active profile from `profiles.yaml` per phase (grep-based, same style as MVP requirements check).

5. Matrix check:

```bash
if [[ ! -f "$TRACE_MATRIX" ]]; then
  if [[ "${ENFORCE:-0}" -eq 1 ]]; then
    err "missing traceability/$PKG_ID/matrix.md (enforce mode)"
  else
    warn "missing traceability/$PKG_ID/matrix.md"
  fi
fi
```

6. For `high_risk` code-review: require `security-review.md` when phase archived.

- [ ] **Step 4: Run tests**

Run: `chmod +x scripts/loop-verify.sh scripts/test-loop-verify.sh && ./scripts/test-loop-verify.sh`
Expected: `All loop-verify tests passed` (Test 6 skipped or passes depending on FEAT-003)

Run: `./scripts/loop-verify.sh FEAT-001`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add scripts/loop-verify.sh scripts/test-loop-verify.sh
git commit -m "feat: profile-aware loop-verify with enforce flag"
```

---

## Task 10: FEAT-003 full 7-phase demo package

**Files:**
- Create: `.ai/packages/FEAT-003/package.yaml`
- Create: `.ai/packages/FEAT-003/classification.yaml`
- Create: `.ai/packages/FEAT-003/gates/*.md` (7 gate files)
- Create: `artifacts/FEAT-003/` (all 7 phase dirs)
- Create: `traceability/FEAT-003/matrix.md`
- Create: `traceability/FEAT-003/decision-records.md`
- Create: `docs/examples/FEAT-003-walkthrough.md`

**Demo feature:** Same domain as FEAT-001 — "Add email notification when an order ships" — but with full implementation through release (can reference stub/minimal code paths in `changed-files.md`).

- [ ] **Step 1: Create package + classification**

```yaml
# .ai/packages/FEAT-003/package.yaml
id: FEAT-003
owner: demo
profile: standard
mode: loop
status: ready_for_release
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
  implementation:
    status: archived
    artifact_version: v1
  code-review:
    status: archived
    artifact_version: v1
  test-report:
    status: archived
    artifact_version: v1
  release:
    status: archived
    artifact_version: v1
children: []
```

```yaml
# .ai/packages/FEAT-003/classification.yaml
package_id: FEAT-003
suggested_tier: standard
active_profile: standard
signals:
  - type: feature
  - blast_radius: limited
confidence: high
override: null
classified_at: "2026-06-12"
```

- [ ] **Step 2: Create phases 01–03 artifacts**

Reuse structure from FEAT-001/FEAT-002 (3 ACs). Ensure PRD `status: approved`.

- [ ] **Step 3: Create phase 04 artifacts**

`implementation-plan.md`, `changed-files.md` (e.g. `src/notifications/email.ts`, `tests/notifications/email.test.ts`), `coding-log.md`, `review-log.md`.

- [ ] **Step 4: Create phase 05 artifacts**

`ai-review.md`, `performance-review.md`, `blocking-issues.md` (empty blocking), `review-log.md`.

- [ ] **Step 5: Create phase 06 artifacts**

`test-execution-summary.md` (TC-001..004 pass), `coverage-report.md`, `release-recommendation.md` (`go`), `review-log.md`.

- [ ] **Step 6: Create phase 07 artifacts**

`release-notes.md`, `known-issues.md`, `retro.md`, `review-log.md`.

- [ ] **Step 7: Create 7 gate files**

`gates/requirements-1.md` through `gates/release-1.md` — all `result: pass` with real `artifacts_checked` paths.

- [ ] **Step 8: Create traceability matrix**

Full matrix: 3 AC rows with design section, TC IDs, code file paths, status `covered`.

- [ ] **Step 9: Write walkthrough**

`docs/examples/FEAT-003-walkthrough.md` covering:
- `/loop classify` selecting each profile tier
- Full 7-phase loop path
- Evidence chain through code column

- [ ] **Step 10: Verify**

Run: `./scripts/loop-verify.sh FEAT-003`
Expected: `PASS`

Run: `./scripts/loop-verify.sh --enforce FEAT-003`
Expected: `PASS` (no warnings)

- [ ] **Step 11: Commit**

```bash
git add .ai/packages/FEAT-003/ artifacts/FEAT-003/ traceability/FEAT-003/ docs/examples/FEAT-003-walkthrough.md
git commit -m "feat: add FEAT-003 full 7-phase demo package"
```

---

## Task 11: Parent-child demo packages

**Files:**
- Create: `.ai/packages/FEAT-PARENT/package.yaml`
- Create: `.ai/packages/FEAT-PARENT/classification.yaml`
- Create: `.ai/packages/FEAT-CHILD/package.yaml` (copy FEAT-001 state, rename)
- Create: minimal `artifacts/FEAT-PARENT/07-release-retro/` + gates

- [ ] **Step 1: Create FEAT-CHILD from FEAT-001**

Copy `.ai/packages/FEAT-001/` → `FEAT-CHILD`, `artifacts/FEAT-001/` → `artifacts/FEAT-CHILD`, `traceability/FEAT-001/` → `traceability/FEAT-CHILD`. Replace all IDs with `FEAT-CHILD`.

- [ ] **Step 2: Create FEAT-PARENT package**

```yaml
# .ai/packages/FEAT-PARENT/package.yaml
id: FEAT-PARENT
owner: demo
profile: standard
mode: loop
status: ready_for_release
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
  implementation:
    status: archived
    artifact_version: v1
  code-review:
    status: archived
    artifact_version: v1
  test-report:
    status: archived
    artifact_version: v1
  release:
    status: archived
    artifact_version: v1
children:
  - id: FEAT-CHILD
    relationship: implements
```

Parent artifacts: minimal 7-phase set where PRD scope references child package. Parent `gates/release-1.md` `artifacts_checked` includes `.ai/packages/FEAT-CHILD/package.yaml`.

- [ ] **Step 3: Verify both packages**

Run: `./scripts/loop-verify.sh FEAT-CHILD && ./scripts/loop-verify.sh FEAT-PARENT`
Expected: both `PASS`

- [ ] **Step 4: Commit**

```bash
git add .ai/packages/FEAT-PARENT/ .ai/packages/FEAT-CHILD/ artifacts/FEAT-PARENT/ artifacts/FEAT-CHILD/ traceability/FEAT-CHILD/
git commit -m "feat: add parent-child demo packages FEAT-PARENT and FEAT-CHILD"
```

---

## Task 12: CI enforce mode

**Files:**
- Modify: `.github/workflows/loop-verify.yml`
- Create: `docs/ci/branch-protection.md`

- [ ] **Step 1: Update workflow to enforce**

```yaml
name: Loop Verify
on:
  pull_request:
    paths:
      - '.ai/**'
      - 'artifacts/**'
      - 'traceability/**'
      - 'scripts/loop-verify.sh'
  workflow_dispatch:
    inputs:
      package_id:
        description: 'Package ID to verify'
        default: 'FEAT-003'
      enforce:
        description: 'Enforce mode (fail on warnings)'
        type: boolean
        default: true

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify package
        run: |
          PKG="${{ github.event.inputs.package_id || 'FEAT-003' }}"
          ENFORCE="${{ github.event.inputs.enforce }}"
          chmod +x scripts/loop-verify.sh scripts/test-loop-verify.sh
          ./scripts/test-loop-verify.sh
          if [[ "$ENFORCE" == "true" || "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
            ./scripts/loop-verify.sh --enforce "$PKG"
          else
            ./scripts/loop-verify.sh "$PKG"
          fi
```

- [ ] **Step 2: Write branch protection doc**

`docs/ci/branch-protection.md`:

```markdown
# Branch Protection — Loop Verify

1. GitHub → Settings → Branches → Add rule for `main`
2. Require status check: **Loop Verify / verify**
3. PRs touching `.ai/`, `artifacts/`, `traceability/`, or `scripts/loop-verify.sh` must pass `./scripts/loop-verify.sh --enforce <package_id>`

Default CI package: `FEAT-003` (full 7-phase). MVP package `FEAT-001` remains valid for local smoke tests.
```

- [ ] **Step 3: Verify locally**

Run: `./scripts/test-loop-verify.sh && ./scripts/loop-verify.sh --enforce FEAT-003`
Expected: all pass

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/loop-verify.yml docs/ci/branch-protection.md
git commit -m "ci: enable loop-verify enforce mode on pull requests"
```

---

## Task 13: Cursor pointers, AGENTS.md, README

**Files:**
- Create: `.cursor/skills/04-implementation/SKILL.md`
- Create: `.cursor/skills/05-code-review/SKILL.md`
- Create: `.cursor/skills/06-test-report/SKILL.md`
- Create: `.cursor/skills/07-release-retro/SKILL.md`
- Modify: `AGENTS.md`
- Modify: `README.md`

- [ ] **Step 1: Create four pointer skills**

Each file (example for 04-implementation):

```markdown
---
name: 04-implementation
description: Plans and executes approved design within scope. Source skill in .ai/skills/.
---

# Implementation Phase

**Source of truth:** `.ai/skills/phases/04-implementation/SKILL.md`

Read and follow the source skill file in this repository. Do not use this pointer without loading the full skill.
```

Repeat for `05-code-review`, `06-test-report`, `07-release-retro` with matching descriptions from each source skill frontmatter.

- [ ] **Step 2: Update `AGENTS.md` skill table**

Add rows:

| Implementation | `.ai/skills/phases/04-implementation/SKILL.md` | implement, coding, build |
| Code Review | `.ai/skills/phases/05-code-review/SKILL.md` | code review, PR review, security review |
| Test Report | `.ai/skills/phases/06-test-report/SKILL.md` | test report, validation, QA |
| Release & Retro | `.ai/skills/phases/07-release-retro/SKILL.md` | release, retro, ship |

- [ ] **Step 3: Update README**

Replace "MVP scope vs Phase 2" section with:

- **Shipped:** 7 phase skills, 3 profiles, parent-child, CI enforce
- **Demo packages:** FEAT-001 (3-phase), FEAT-003 (7-phase), FEAT-PARENT/FEAT-CHILD
- Commands: `./scripts/loop-verify.sh --enforce FEAT-003`

- [ ] **Step 4: Commit**

```bash
git add .cursor/skills/ AGENTS.md README.md
git commit -m "docs: Phase 2 skill pointers and updated agent entry"
```

---

## Task 14: Phase 2 acceptance verification

**Files:**
- Modify: `docs/examples/FEAT-003-walkthrough.md` (add checklist)

- [ ] **Step 1: Run full verification script**

```bash
# L3 regression + enforce
./scripts/test-loop-verify.sh
./scripts/loop-verify.sh FEAT-001
./scripts/loop-verify.sh --enforce FEAT-003
./scripts/loop-verify.sh FEAT-PARENT
./scripts/loop-verify.sh FEAT-CHILD

# All 7 phase skills exist
for n in 01-requirement 02-design 03-test-plan 04-implementation 05-code-review 06-test-report 07-release-retro; do
  test -f ".ai/skills/phases/$n/SKILL.md" || { echo "MISSING $n"; exit 1; }
done

# Profiles active
grep -q '^routine:' .ai/config/profiles.yaml
grep -q '^high_risk:' .ai/config/profiles.yaml
grep -q 'implementation:' .ai/config/profiles.yaml

# Parent-child in lifecycle-loop
grep -q 'Child readiness' .ai/skills/lifecycle-loop/SKILL.md

# Classify no longer MVP-only
! grep -q 'only active profile' .ai/skills/lifecycle-loop/SKILL.md

echo "Phase 2 acceptance checks passed"
```

Expected: all commands exit 0.

- [ ] **Step 2: Add acceptance checklist to FEAT-003 walkthrough**

Map spec §8.3 Stage 2–3 criteria:

| Criterion | Evidence |
|-----------|----------|
| All 7 phases + full standard profile | FEAT-003 package + profiles.yaml |
| routine profile skips design/test-plan | walkthrough classify example |
| high_risk human gates | profiles.yaml + walkthrough |
| Parent-child gate | FEAT-PARENT gates/release-1.md |
| CI enforce | `.github/workflows/loop-verify.yml` |
| Code in trace matrix | traceability/FEAT-003/matrix.md |
| FEAT-001 MVP unchanged | loop-verify FEAT-001 PASS |

- [ ] **Step 3: Final commit**

```bash
git add docs/examples/FEAT-003-walkthrough.md
git commit -m "docs: Phase 2 acceptance verification checklist"
```

---

## Spec coverage self-review

| Spec section | Task |
|--------------|------|
| §3.3 routine + high_risk profiles | Task 1, 6 |
| §3.4 parent-child packages | Task 7, 11 |
| §5.3 Parent-child checks | Task 7 |
| §5.4 7-phase execution | Task 6 |
| §6 Phase 04–07 outputs | Tasks 2–5 |
| §8.3 Stage 2 (7 phases) | Task 10 |
| §8.3 Stage 3 (CI enforce + profiles + parent-child) | Tasks 1, 7, 11, 12 |
| §10 L3 extended checks | Task 9 |
| §2.5 Code in evidence chain | Task 8, 10 |

**Regression:** FEAT-001 (MVP 3-phase) must pass `loop-verify.sh` after every task — verified in Tasks 1, 9, 14.

**No placeholder steps.** All phase skills include concrete file names, checklists, and frontmatter examples.

---

Plan complete and saved to `docs/superpowers/plans/2026-06-12-develop-loop-skills-phase2.md`. Two execution options:

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
