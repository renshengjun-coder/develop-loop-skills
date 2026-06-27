---
name: 06-test-report
description: >-
  Use when a package needs test-report, validation, QA results, test execution,
  coverage evidence, defects, or release recommendation; standalone or via /devloop.
  Does not issue final gate PASS.
---

# Test-Report Phase Skill

Fully owns the **test-report phase**. Runnable standalone or when invoked by devloop.

## Required inputs

- `package_id`
- Read `.ai/packages/<package_id>/package.yaml`, `.ai/packages/<package_id>/classification.yaml`, and `.ai/config/profiles.yaml` to determine the active profile; **do not proceed** unless `phases.code-review.status: archived`
- Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` as the validation and traceability boundary
- Read `artifacts/<package_id>/03-test-plan/test-cases.md` and preserve its TC IDs when the test-plan phase is active; require `phases.test-plan.status: archived`
- Read `artifacts/<package_id>/04-implementation/changed-files.md` as the coverage scope
- Read `artifacts/<package_id>/04-implementation/coding-log.md`, project manifests, CI configuration, and repository documentation to discover actual project test and coverage commands
- Read archived `artifacts/<package_id>/05-code-review/` findings and repository-comparison evidence so validation targets known risks and binds to the reviewed source
- Establish the tested source snapshot before execution. For Git, record `HEAD` commit SHA, dirty/clean state, baseline, target, comparison range, included staged/unstaged/deleted/untracked path classes, commands, comparison-output digest or stable evidence link, and exclusions; record equivalent identities for another VCS. Reconcile it with the archived code-review comparison and `changed-files.md`
- Record a frozen upstream input set with exact paths, versions, and content digests for acceptance criteria, test cases when present, changed-files, and every code-review artifact used as evidence. For routine work with no test-plan, record test cases as `N/A - profile skipped`; a missing required version is blocking
- Record a secret-safe execution environment identity: runner/host or CI run identity, OS/architecture, runtimes and dependency-lock state, relevant integration/E2E configuration names and non-secret values, fixture/data-set versions, and required service/container names, image digests/versions, and health state. Redact secrets and credentials; record secret names or presence only

Do not use test evidence for an unreviewed source snapshot or changed upstream input set. Revalidate exact paths, versions, and content digests before freeze, approval, and archive. Route a changed input from its earliest affected phase: acceptance criteria -> `requirements`; test cases -> `test-plan`; changed-files -> `implementation`; code-review evidence or source snapshot -> `code-review`. Mark that phase and active downstream phases `pending`, treat old gates as `stale`, retain them for audit, rerun through code-review, then restart test-report. Expected test-generated output may be excluded only when code review documented the same exclusion.

For the `routine` profile, test-plan may be skipped and must not be treated as a missing input. Derive a minimal executable validation case for every AC, assign stable IDs such as `TC-R001`, and record the derived cases in `test-execution-summary.md`; do not create or modify `03-test-plan` artifacts. A derived case must name its AC, command or executable check, preconditions, and expected result. If no project command can execute it, record it as `skip` with the reason and recommend `no-go`.

## Step 1: Build and Execute the Validation Set

1. Build an AC-to-TC inventory from archived test cases or routine-derived cases. Every AC requires at least one mapped validation case and an explicit aggregate disposition; unavailable execution is recorded as `skip`, never omitted.
2. Select commands that exist in the actual project. Prefer documented targeted commands, then the relevant broader suite. Never invent a passing result, substitute an unrelated command, or silently omit a required case.
3. Run each applicable command from a recorded working directory and secret-safe execution environment identity. For every run, record the exact command, UTC start and finish timestamps, duration, exit code, relevant environment/service/fixture identities, and actual stdout/stderr evidence or an explicitly identified verbatim summary.
4. Determine each TC result:
   - `pass`: the command/check ran successfully and its expected result was observed.
   - `fail`: the command exited non-zero or the expected result was not observed.
   - `skip`: the required validation did not run; include the concrete blocker, earliest affected phase, and owner/follow-up.
   Aggregate each AC as `pass`, `fail`, `skip`, or `waived`; `waived` retains and cites the underlying failed/skipped results and exact waiver.
5. Preserve failed and superseded run evidence. Append reruns and state which run is current; never rewrite history to make the final result appear cleaner. A later pass closes a prior failure only with recorded root cause, remediation, and resolution evidence, or an explicit approved waiver.

`N/A` is permitted only for a test level, coverage measure, or changed path that genuinely does not apply, and always requires a concrete reason. `N/A` and `skip` are not passes. An unwaived skip fails self-review and blocks archive because the plan requires every AC to have at least one executed TC with a recorded result. An approved waiver can allow archive of an honest report while keeping the skipped result visible, matrix Status `failed`, and release recommendation `no-go` unless the waiver explicitly accepts release risk. Recommend `go` only when every AC's required validations executed and passed, or an exact approved waiver accepts each remaining failure/skip; waived results remain visible and the waiver decision is cited. Incomplete or misleading evidence may not archive.

## Step 2: Generate Reports

Create or revise these seven artifacts under `artifacts/<package_id>/06-test-report/`:

| File | Content |
|------|---------|
| `test-execution-summary.md` | AC-to-TC inventory and per TC pass/fail/skip result, exact command/check, timestamps, duration, exit code, stdout/stderr evidence, and evidence links |
| `unit-test-report.md` | Unit results breakdown, failures, and applicable N/A rationale |
| `integration-test-report.md` | Integration results breakdown, or N/A with reason |
| `e2e-test-report.md` | E2E results breakdown, or N/A with reason |
| `coverage-report.md` | Actual line/branch coverage when available, changed-file coverage inventory, gaps, and honest N/A reasons |
| `defects.md` | Open defects and validation gaps mapped to failed/skipped TC and AC IDs |
| `release-recommendation.md` | Explicit `go` or `no-go`, evidence summary, open risks, and required follow-up |

### Frontmatter on generated report artifacts

```yaml
---
artifact_id: TR-001-execution-summary
artifact_type: test-report
package_id: FEAT-003
version: v1
status: draft
traces:
  - validates: "TC-001"
  - validates: "AC-001"
related: []
---
```

Use this frontmatter on all seven generated report artifacts with the appropriate artifact ID. Include `validates` traces for every TC and AC evidenced or evaluated by that artifact; a trace is not a claim that the result passed. Keep all seven `status: draft` until Step 4. `review-log.md` follows the phase self-review format and does not require frontmatter.

### Evidence and reporting rules

- `test-execution-summary.md` is the canonical run ledger. Record the frozen upstream input set, tested source snapshot/code-review reconciliation, secret-safe execution environment identity, complete AC-to-TC disposition map, and every planned or derived TC exactly once in the current-result table; retain prior run evidence in chronological history.
- `release-recommendation.md` is the canonical human-readable release posture for this phase. It must match the outcomes shown in `test-execution-summary.md`, `coverage-report.md`, `defects.md`, and the package evidence index; it may not present skipped, failed, waived, or N/A results as a clean pass.
- Record actual stdout/stderr after redacting secrets and credentials without hiding result or failure semantics. If output must be shortened, label the excerpt as truncated, preserve the exact result summary and failure text, and link a secret-safe stable full-output artifact when one exists. Do not paraphrase away warnings or failures.
- Break unit, integration, and E2E results down by executed command and TC. A level report may be N/A only when it names the changed scope inspected and explains why that level does not apply.
- In `coverage-report.md`, reconcile every source, test, documentation, configuration, generated, and deleted path from `changed-files.md`. Report measured line/branch percentages only from actual tool output. When measurement is unavailable, state `N/A`, the attempted or missing command/tool, affected paths, and resulting risk; never estimate percentages.
- In `defects.md`, assign stable defect or validation-gap IDs, severity, current status, TC/AC links, reproduction evidence, earliest affected phase, required action, and append-only transition history. Every failed TC must map to a defect; every skipped required validation must map to a validation gap.
- An approved waiver must live at `.ai/packages/<package_id>/decisions/waiver-<id>.md` and name approver, reason, exact TC/AC scope, accepted risk, and expiry/revisit condition. A waiver does not rewrite a `fail`/`skip` result or erase prior failure history.
- Recommend `go` only when every AC is executed/pass or covered by an approved waiver, prior failures have resolution evidence or waiver, no unwaived blocking defect/gap remains, and coverage evidence/gaps meet project acceptance. Recommend `no-go` otherwise. Human report approval does not change results or recommendation.

### Defect routing and re-entry

Route every defect/gap to the earliest affected active phase: requirement intent -> `requirements`; architecture/contract -> `design`; planned-case correctness/missing scenario -> `test-plan`; source, implementation tests, configuration, or docs -> `implementation`; reviewed-source/review evidence -> `code-review`; report transcription, evidence-link, or report self-review defect -> `test-report`. If the natural phase is skipped, route to the earliest active downstream phase that can resolve it and record why.

An unresolved routed issue may remain in a complete archived `no-go` report, with affected ACs `failed`. When resolving an upstream issue, mark the earliest affected phase and every active downstream phase `pending`, treat old gates as `stale`, retain old evidence, rerun active phases through code-review, establish a fresh reviewed snapshot, and restart test-report. For a test-report-local fix, change no upstream/source artifact; append `report_corrected`, rerun affected validation when results/evidence could change, rebuild and bump the complete seven-report set, and self-review again. Resolve an item only after appending root cause, remediation, rerun/resolution evidence, or an approved waiver.

## Step 3: Freeze Version and Self Review

Before self-review, assign or bump the version on all seven reports as one coherent evidence set, revalidate the exact upstream input set and tested source snapshot, and freeze their evidence content. Any later evidence/content correction invalidates self-review and approval: begin a new draft revision, bump all seven versions, and repeat Step 3. Do not edit an approved version in place.

Write `artifacts/<package_id>/06-test-report/review-log.md`:

| Check | Result | Note |
|-------|--------|------|
| Upstream inputs and source | pass/fail | Exact AC/TC/changed-files/code-review paths, versions, digests, and tested source match; no drift before freeze |
| AC coverage | pass/fail | Every AC has at least one executed TC with recorded `pass`/`fail` result, or an exact approved waiver for skipped validation |
| Evidence complete | pass/fail | Exact commands/checks, UTC timestamps, durations, exits, secret-safe environment identity, and actual output are recorded |
| Failures documented | pass/fail | Failed/skipped TCs route to earliest phase; closed prior failures have root-cause/resolution evidence or waiver |
| Coverage reported | pass/fail | Every changed file is reconciled; actual coverage or an honest N/A reason is recorded |
| Release rec explicit | pass/fail | `release-recommendation.md` states `go` or `no-go` and follows the evidence |
| Version set frozen | pass/fail | All seven exact report versions are assigned, coherent, and unchanged since review began |
| Reproducible and honest | pass/fail | Reruns preserve history; N/A, skips, waivers, warnings, and failures are not presented as passes |

Record `**Blocking failures:** <count>` and `**Recommendation:** <action>`. A failed executed test does not by itself fail self-review when it is completely and honestly reported. An unwaived skipped validation does fail self-review because the required TC did not execute. A failed self-review check blocks human review and archive; correct the reports, add an exact approved waiver, or rerun validation until every check passes.

## Step 4: Report Status and Human Review

Read the active profile's `human_gates` in `.ai/config/profiles.yaml`.

If `test-report` is included in `human_gates` (`high_risk`: **yes**):

1. Keep all seven report artifacts `status: draft`.
2. Revalidate the exact upstream input set and source snapshot, refresh `traceability/<package_id>/package-evidence-index.md`, then present the execution summary, defects, coverage gaps, and release recommendation without hiding failures or N/A results.
3. Wait for explicit human sign-off.
4. Write `approval.md` with approver, date, decision, acknowledged release recommendation, and all seven exact artifact paths and frozen versions.
5. Revalidate the upstream input set/source snapshot and verify the seven reports still match those exact versions, then set all seven report artifacts' frontmatter `status: approved`. This status transition is the only allowed post-sign-off change; after it, any correction requires a new version and new approval.

If `test-report` is not included in `human_gates`, revalidate the upstream input set/source snapshot, refresh `traceability/<package_id>/package-evidence-index.md`, then set all seven report artifacts' frontmatter `status: reviewed` after self-review passes. Review status means the evidence is accepted for archive; it never converts a failed or skipped validation into a pass.

## Step 5: Archive

1. Revalidate the exact upstream input set and tested source snapshot, verify all self-review checks pass, verify no unwaived skipped validation remains, verify all seven reports have the required `approved` or `reviewed` status, and require `approval.md` when the active profile includes the test-report human gate.
2. Do not change report content, status, or version during archive. Archive binds the already reviewed/approved frozen set.
3. Update `.ai/packages/<package_id>/package.yaml` -> `phases.test-report.status: archived`, `artifact_version: v<n>` using the frozen set version.
4. Load `.ai/skills/traceability/SKILL.md` and update the matrix **Status** and **Notes** per AC, then refresh `traceability/<package_id>/package-evidence-index.md` so the package audit entry point reflects the archived test-report evidence and release posture:
   - `covered` only when all required validations passed.
   - `failed` when any required validation failed, was skipped, or lacks executable evidence; retain `failed` when a waiver permits a `go`, and cite the waiver.
   - Cite current TC IDs, frozen report version, defects/gaps, waivers, and material N/A rationale in Notes.
5. **Do not** write gate PASS - devloop owns L2.

## Quality criteria

- Every AC maps to planned or routine-derived TCs with at least one executed `pass`/`fail` result, or an exact approved waiver for skipped validation
- AC coverage self-review fails on unwaived skips; approved waivers keep affected matrix Status `failed` and cite accepted risk
- Commands, working directory, UTC timestamps, duration, exit code, secret-safe execution environment/dependency/service/fixture identity, and actual output make every result reproducible
- Test evidence is bound to the exact versioned upstream input set and reviewed source snapshot; drift routes from the earliest changed phase and triggers stale/re-entry
- All seven reports contain applicable `validates` traces and agree on TC/AC outcomes
- `release-recommendation.md` states the honest package release posture and stays aligned with defects, coverage gaps, waivers, matrix status, and the package evidence index
- Unit, integration, E2E, and coverage N/A claims are specific, justified, and never presented as passes
- Every changed path is reconciled in coverage reporting; measured percentages come only from actual coverage output
- Failed and skipped validations remain visible, route to the earliest affected phase, and force `no-go` unless an exact approved waiver permits `go`
- Prior failures close only with root-cause/remediation/resolution evidence or explicit waiver
- All seven versions are assigned before self-review; high-risk approval enumerates them; archive never mutates them
- Archive occurs only after self-review passes, required high-risk human approval exists, and package audit views are refreshed to the same frozen evidence revision
- Package and per-AC traceability state are current, and no phase artifact claims gate PASS

See `reference.md` for concise execution, coverage, defect, recommendation, and approval templates.
