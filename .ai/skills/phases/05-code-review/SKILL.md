---
name: 05-code-review
description: >-
  Evidence-grounded code review across general, security, performance,
  maintainability, and testability lenses. Use for code review phase, PR review,
  security review — standalone or via /devloop. Does not issue final gate PASS.
---

# Code-Review Phase Skill

Fully owns the **code-review phase**. Runnable standalone or when invoked by lifecycle-loop.

## Required inputs

- `package_id`
- Read `artifacts/<package_id>/04-implementation/changed-files.md` — the review manifest
- Read every actual repository file listed in `changed-files.md`; for a deleted path, inspect the recorded deletion evidence and relevant remaining references instead
- Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` and archived `artifacts/<package_id>/02-design/` when present — the conformance boundary
- Read `.ai/packages/<package_id>/package.yaml`, `.ai/packages/<package_id>/classification.yaml`, and `.ai/config/profiles.yaml` — determine the active profile and **do not proceed** unless `phases.implementation.status: archived`
- Establish a coherent repository comparison source before review: record review type (`local` or `PR`), VCS/tool, exact baseline and target identities, diff range, commands/evidence, and included path classes

For a Git **local review**, resolve exact baseline and target commits, require checked-out `HEAD` to equal target, and compare the union of committed `<baseline>..<target>`, index-versus-target staged changes, working-tree-versus-index unstaged changes and deletions, and untracked files. For a Git **PR review**, resolve the exact base and PR-head commits, set baseline to `git merge-base <base> <target>`, and compare committed `<baseline>..<target>` only; do not mix staged, unstaged, or untracked local paths into PR scope unless explicitly changing to a local-overlay review. Record equivalent semantics for another VCS.

Compare `changed-files.md` against the selected coherent scope in both directions: every implementation path in scope must be listed, and every manifest path must be supported by the comparison or a documented generated/deletion source. Explicitly list and justify exclusions such as artifacts created by this code-review phase.

Review source, tests, documentation, configuration, generated files, and every other path in `changed-files.md`. Verify each non-deleted listed path exists. Treat a missing, unreadable, or unaccounted-for path, an unspecified comparison baseline/target/range, or a manifest/comparison mismatch as blocking; never silently narrow review scope.

## Step 1: Generate Reviews

Create or revise under `artifacts/<package_id>/05-code-review/`:

| File | Content |
|------|---------|
| `ai-review.md` | General findings, repository comparison, changed-path coverage, and AC/design-decision conformance |
| `security-review.md` | Auth, authorization, input validation, secrets, injection, and data-handling review |
| `performance-review.md` | Hot paths, N+1 behavior, resource use, caching, and latency notes |
| `maintainability-review.md` | Naming, duplication, complexity, coupling, and operability notes |
| `testability-review.md` | Test gaps, failure-path coverage, observability, and mockability |
| `blocking-issues.md` | Canonical list of must-fix findings before advance |
| `non-blocking-suggestions.md` | Canonical list of optional improvements |

Treat `ai-review.md` and `review-log.md` as the core human-readable evidence that gates and package evidence indexes should cite directly. `blocking-issues.md` should stay aligned with that audit trail whenever blockers exist or blocker history is part of the evidence set. The other lens artifacts remain phase evidence even when a lower-risk profile does not require each one for L2/L3 blocking checks.

### Frontmatter on generated review artifacts

```yaml
---
artifact_id: CR-001-ai-review
artifact_type: code-review
package_id: FEAT-003
version: v1
status: draft
traces:
  - reviews: "artifacts/FEAT-003/04-implementation/changed-files.md@v1"
related: []
---
```

Use this frontmatter on all seven generated review artifacts with the appropriate artifact ID. Keep all seven `status: draft` until Step 4. `review-log.md` follows the phase self-review format and does not require frontmatter.

### Evidence and coverage rules

1. Add a repository comparison section to `ai-review.md`: review type, comparison source/tool, exact baseline and target identities, diff range, commands/evidence used, included path classes, documented exclusions, and the bidirectional reconciliation result with `changed-files.md`. For local review, confirm the current working tree is based on target and include staged, unstaged, deleted, and untracked paths. For PR review, record base commit, target PR-head commit, merge-base baseline, and committed PR diff only.
2. Add a changed-path coverage table to `ai-review.md` with one row for **every** path in `changed-files.md`: path, change type, comparison evidence, file evidence inspected, AC/design reference, and review disposition.
3. Add an AC conformance table to `ai-review.md`; record whether each AC is implemented and cite supporting or contradicting file evidence.
4. Add a design-decision conformance inventory to `ai-review.md`. Enumerate every applicable archived design decision, contract, constraint, and documented tradeoff; record `conforms`, `deviates`, or `N/A`, with implementation evidence and rationale. Any undocumented deviation is blocking.
5. Record findings in the applicable lens report with a stable ID, severity, repository `file:line` when possible, AC/design reference when applicable, evidence, impact, and required action or suggestion.
6. Copy each finding ID into exactly one canonical list: `blocking-issues.md` or `non-blocking-suggestions.md`.
7. If a lens has no findings, record the files and evidence inspected plus a "no findings" conclusion. For routine work, `security-review.md` may use N/A only with a concrete rationale. For `high_risk`, `security-review.md` must be substantive and non-empty.
8. Do not infer correctness from `changed-files.md` alone. Findings and no-finding conclusions must be grounded in the actual listed repository files, deletion evidence, and recorded repository comparison.

Classify as **blocking** any issue that violates an AC or archived design, creates a correctness or security defect, risks data loss, leaves a changed path unreviewed, or prevents required behavior from being verified. Keep optional improvements non-blocking.

### Blocking issue ledger and phase re-entry

`blocking-issues.md` is an auditable ledger with append-only transition history. Record `blocking_count: <unresolved count>` and retain every blocker after resolution. Each blocker must include:

- Stable ID and current `status: open | resolved`, derived from its latest transition
- `source`: originating lens artifact and finding ID
- Evidence, impact, and required action
- `earliest_affected_phase`: `requirements`, `design`, `test-plan`, `implementation`, or `code-review`
- Timestamped transitions such as `opened`, `routed`, `phase_rearchived`, `review_corrected`, `review_rerun`, and `resolved`, each with actor/source and evidence

Never edit or delete an existing transition; append a new transition and derive current status from the latest event. Recalculate `blocking_count` from blockers whose latest transition is not `resolved`.

Route each blocker to the earliest affected phase in the active profile:

| Finding affects | Earliest phase |
|-----------------|----------------|
| Requirement intent, scope, ambiguity, or AC correctness | `requirements` |
| Architecture, API/data contract, constraint, tradeoff, or design decision | `design` |
| Test strategy, planned coverage, test-case correctness, or missing planned scenario | `test-plan` |
| Code, implementation tests, configuration, documentation, or implementation evidence | `implementation` |
| Missing/incomplete review evidence or artifacts, review-ledger defects, or code-review self-review failures | `code-review` |

If that phase is skipped by the active profile, route to the earliest active downstream phase that can resolve it and record the skipped-phase rationale. Do not repair upstream or implementation artifacts from code review.

For a `code-review` blocker, correct the review-local artifact or evidence in phase; do not mark upstream phases stale or edit upstream artifacts. Append a `review_corrected` transition, refresh the repository comparison when relevant, bump all seven review artifact versions, rerun all five lenses, refresh all seven artifacts, and rerun self-review. Append `review_rerun` and `resolved` only after the full rerun closes the blocker.

For every blocker routed to an upstream phase:

1. Stop code review, append a `routed` transition, and reopen the earliest affected phase.
2. Apply stale handling: mark the earliest affected phase and every active downstream phase `pending`, treat their old gates as `stale`, and retain old gates for audit.
3. Rerun active phases once, in order, from the earliest affected phase through implementation; revise, self-review, and re-archive each with current evidence and new artifact versions where changed.
4. Restart code review from Required inputs using newly archived evidence and a fresh repository comparison. Bump all seven review artifact versions, rerun all five lenses, and refresh all seven artifacts.
5. Append `phase_rearchived`, `review_rerun`, and finally `resolved` transitions with artifact versions, changed paths, tests/checks, and resolution evidence. Resolve only after rerun evidence closes the finding.

## Step 2: Self Review

Write `artifacts/<package_id>/05-code-review/review-log.md`:

| Check | Result | Note |
|-------|--------|------|
| Evidence-grounded | pass/fail | Every finding cites a repository path and line when possible |
| Repository comparison | pass/fail | Coherent local or PR scope recorded; exact baseline, target, range, and included path classes reconciled |
| Changed-path coverage | pass/fail | Every path in changed-files.md and repository comparison has an evidence-backed disposition or justified exclusion |
| Blocking vs non-blocking | pass/fail | Ledger retains timestamped transitions, routes earliest affected phase, and count equals open blockers |
| AC coverage | pass/fail | Every AC has an implementation-conformance result |
| Design-decision conformance | pass/fail | Every applicable archived decision/contract/constraint is inventoried |
| Security lens | pass/fail | Substantive for high_risk; concrete N/A rationale only when allowed |
| Testability | pass/fail | Test gaps include suggested test names |

Record `**Blocking failures:** <count>` and `**Recommendation:** <action>`. The count must equal unresolved entries in `blocking-issues.md`. A failed self-review check must create or update a blocker and enter Step 3. Self-review failures and open blockers block Step 4 and archive, but they do not block Step 3 resolution work.

## Step 3: Resolve Blocking Issues

Resolve every open blocker through its applicable code-review in-phase correction or upstream stale/downstream rerun flow above. Then rerun Step 1 and Step 2 until all self-review checks pass and `blocking_count: 0`. Only then proceed to Step 4.

## Step 4: Review Status and Human Review

Read the active profile's `human_gates` in `.ai/config/profiles.yaml`.

If `code-review` is included (`high_risk`: **yes**):

1. Keep all seven review artifacts `status: draft` and present the `blocking-issues.md` summary and resolution history.
2. Verify `blocking_count: 0`, all self-review checks pass, and affected findings were rerun.
3. Refresh `traceability/<package_id>/package-evidence-index.md` so the package audit view reflects current code-review status, latest gate-ready evidence, and any resolved blockers before sign-off.
4. Wait for explicit human sign-off.
5. Write `approval.md` with approver, date, and `blocking_count: 0`.
6. Set all seven review artifacts' frontmatter `status: approved`.

If `code-review` is not included, set all seven review artifacts' frontmatter `status: reviewed` only after `blocking_count: 0` and self-review passes.

## Step 5: Archive

1. Bump `version` in generated review artifact frontmatter if this is a revision.
2. Verify the recorded repository comparison is current, every changed path remains accounted for, `blocking-issues.md` retains all resolved entries with `blocking_count: 0`, and all seven review artifacts are `approved` for a human gate or `reviewed` otherwise.
3. Update `.ai/packages/<package_id>/package.yaml` → `phases.code-review.status: archived`, `artifact_version: v<n>`.
4. Load `.ai/skills/traceability/SKILL.md` and update matrix Status or Notes when code-review findings change AC coverage or status, then refresh `traceability/<package_id>/package-evidence-index.md` so it cites the archived code-review evidence and any approval.
5. **Do not** write gate PASS — lifecycle-loop owns L2.

## Quality criteria

- A coherent local or PR repository comparison records exact baseline, target, range, included path classes, and bidirectional reconciliation with `changed-files.md`
- Every path in `changed-files.md` is inspected and has an evidence-backed disposition; missing, deleted, generated, and non-code paths are explicitly accounted for
- Every finding is reproducible from cited repository evidence, with `file:line` when possible
- `ai-review.md` records conformance for every AC and inventories every applicable archived design decision, contract, constraint, and tradeoff
- `blocking-issues.md` remains the canonical human-readable blocker ledger and is reflected accurately in the package evidence index
- All five review lenses are present; `security-review.md` is substantive for `high_risk`
- Blocking issues and non-blocking suggestions are separated; the ledger retains timestamped transition history; review-local blockers rerun code review in phase, while upstream blockers stale and rerun downstream phases
- Archive occurs only with `blocking_count: 0`, all seven review artifacts in the required `approved` or `reviewed` status, and trace/package audit views refreshed to the same evidence revision
- Package and traceability state are current, and no phase artifact claims gate PASS

See `reference.md` for concise review and approval templates.
