# Test Report - Reference

Use this file only after loading and following `SKILL.md`. These examples illustrate valid artifact shapes; they do not replace the Required inputs, freeze/revalidation rules, human-review rules, or Archive steps in the skill.

## Report frontmatter

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

Use appropriate IDs and all applicable TC/AC `validates` traces on each of the seven reports. A trace records what was evaluated, not that it passed.

Assign or bump all seven versions before self-review. Treat them as one frozen evidence set; any content correction requires a new seven-report version set and, when applicable, new approval. Archive never edits the frozen reports.

## Execution summary

```markdown
# Test Execution Summary

## Environment

- **Working directory:** `/repo`
- **Runner/CI identity:** GitHub Actions run `123456789` on `ubuntu-24.04` / x86_64
- **Runtime/tool versions:** Node 22.15.0; npm 10.9.2; lockfile digest `sha256:71...ab`; `npm ci` completed
- **Integration/E2E config:** `test.integration.json`; region `us-test-1`; secrets redacted (`TEST_API_TOKEN`: present)
- **Fixtures/data:** `fixtures/orders-v3.json` / `sha256:42...de`
- **Services/containers:** Postgres 16.3 image digest `sha256:91...7f` healthy; Mailpit 1.20.3 healthy

## Frozen upstream inputs

| Input | Exact path/version | Content digest | Revalidation |
|-------|--------------------|----------------|--------------|
| Acceptance criteria | `artifacts/FEAT-003/01-requirements/acceptance-criteria.md@v2` | `sha256:ac...12` | match |
| Test cases | `artifacts/FEAT-003/03-test-plan/test-cases.md@v2` | `sha256:tc...34` | match |
| Changed files | `artifacts/FEAT-003/04-implementation/changed-files.md@v3` | `sha256:cf...56` | match |
| Code-review evidence | `artifacts/FEAT-003/05-code-review/ai-review.md@v2`; `artifacts/FEAT-003/05-code-review/blocking-issues.md@v2` | `sha256:cr...78`; `sha256:bi...90` | match |

Revalidate this exact path/version/digest set before report freeze, approval/reviewed status, and archive. Route a changed AC/TC/changed-files/code-review input from requirements/test-plan/implementation/code-review respectively, stale active downstream phases, rerun through code-review, and restart test-report.

## Reviewed source snapshot

- **VCS / HEAD:** Git / `c72a410`
- **Dirty state:** dirty; staged, unstaged, deleted, and untracked paths included
- **Baseline / target / range:** `4b7a6c2` / `c72a410` / `4b7a6c2..c72a410` plus local overlay
- **Comparison commands:** `git rev-parse HEAD`; `git status --short`; code-review comparison commands
- **Comparison evidence/digest:** `sha256:8f...2c`; full output retained with code-review evidence
- **Code-review evidence:** `artifacts/FEAT-003/05-code-review/ai-review.md@v2`
- **Reconciliation:** pass; snapshot and exclusions match archived code review and `changed-files.md`

## Current results

| TC ID | AC ID | Level | Result | Command/check | Started (UTC) | Finished (UTC) | Duration | Exit | Evidence / disposition |
|-------|-------|-------|--------|---------------|---------------|----------------|----------|------|------------------------|
| TC-001 | AC-001 | integration | pass | `npm test -- email.test.ts` | 2026-06-12T08:00:00Z | 2026-06-12T08:00:04Z | 4.2s | 0 | Run 1 below |
| TC-002 | AC-002 | e2e | skip | No configured E2E command | N/A | N/A | N/A | N/A | GAP-001; WAIVER-001 permits archive only; no-go / AC failed |
| TC-003 | AC-001 | integration | pass | `npm test -- provider-timeout.test.ts` | 2026-06-12T09:14:00Z | 2026-06-12T09:14:05Z | 5.0s | 0 | Run 5 below; DEF-001 resolved |
| TC-R001 | AC-001 | integration | pass | `npm test -- order-state.test.ts` | 2026-06-12T09:20:00Z | 2026-06-12T09:20:03Z | 3.0s | 0 | Run 6 below |

## AC disposition

| AC ID | TC mapping | Disposition | Evidence / waiver |
|-------|------------|-------------|-------------------|
| AC-001 | TC-001, TC-003 | pass | Runs 1 and 5; DEF-001 resolved |
| AC-002 | TC-002 | waived-skip | GAP-001; WAIVER-001 permits archive only; no-go / matrix Status failed |

## Run history

### Run 1 - TC-001

    $ npm test -- email.test.ts
    4 tests passed
    TEST_API_TOKEN=[REDACTED]

### Run 3 - TC-003 (failed before remediation)

    $ npm test -- provider-timeout.test.ts
    1 test failed: expected retry, received immediate failure

### Run 5 - TC-003 (passing remediation validation)

    $ npm test -- provider-timeout.test.ts
    1 test passed

### Run 6 - TC-R001

    $ npm test -- order-state.test.ts
    3 tests passed

## Routine-derived cases

| TC ID | AC ID | Preconditions | Executable command/check | Expected |
|-------|-------|---------------|--------------------------|----------|
| TC-R001 | AC-001 | Fixture order exists | `npm test -- order-state.test.ts` | Shipment transition enqueues one email |
```

## Level report with N/A

```markdown
# E2E Test Report

**Result:** N/A
**Changed scope inspected:** `src/notifications/email.ts`, `tests/notifications/email.test.ts`
**Reason:** This repository has no configured E2E environment or command.
**Risk/follow-up:** GAP-001 blocks validation of AC-002 and forces `no-go`.
```

## Coverage report

```markdown
# Coverage Report

## Tool result

- **Command:** `npm test -- --coverage`
- **Line coverage:** 88.4%
- **Branch coverage:** 76.1%
- **Evidence:** Actual command summary below.

| Changed path | Type | Coverage/result | Gap or N/A reason |
|--------------|------|-----------------|-------------------|
| `src/notifications/email.ts` | source | 91% lines; 80% branches | Provider timeout branch uncovered |
| `docs/runbook.md` | documentation | N/A | Executable coverage does not apply; link check passed |
```

When no coverage tool exists, use `N/A`, name the missing or attempted command, list affected changed paths, and state the risk. Never estimate a percentage.

## Defect/gap routing ledger

```markdown
# Defects

| ID | Type | Severity | Status | TC / AC | Earliest affected phase | Reproduction evidence | Required action |
|----|------|----------|--------|---------|-------------------------|-----------------------|-----------------|
| DEF-001 | defect | blocking | resolved | TC-003 / AC-001 | implementation | Run 3 exits 1 on provider timeout | Fix retry handling and rerun TC-003 |
| GAP-001 | validation-gap | blocking | open | TC-002 / AC-002 | test-plan | No configured E2E command | Add executable E2E validation |

### DEF-001 transition history

| Timestamp | Event | Evidence |
|-----------|-------|----------|
| 2026-06-12T08:10:00Z | opened / routed | Run 3 failure; implementation is earliest affected phase |
| 2026-06-12T09:00:00Z | phase_rearchived | Implementation and code-review rerun against source `c72a410` |
| 2026-06-12T09:15:00Z | resolved | Root cause: missing timeout retry; remediation commit and passing Run 5 |
```

Keep transitions append-only. A passing rerun alone does not resolve a prior failure; record root cause, remediation, and resolution evidence, or cite an exact approved waiver. For a report-local issue, append `report_corrected`, bump the complete seven-report set, and repeat self-review/approval. For upstream resolution, stale and rerun active downstream phases through code-review before restarting test-report.

## Release recommendation

```markdown
# Release Recommendation

**Recommendation:** no-go

| Signal | Result | Evidence |
|--------|--------|----------|
| Prior failure | resolved | TC-003 / DEF-001 root cause, remediation, and passing Run 5 |
| Skipped validation | present | TC-002 / GAP-001 |
| Coverage | gap | AC-002 E2E behavior unvalidated |

**Risks:** AC-002 has no executed E2E evidence.
**Required follow-up:** Resolve GAP-001, rerun TC-002, and revise all reports.
```

An unwaived skip fails self-review and blocks archive. Use `go` only when every AC's required validation executed/pass, or each remaining failure/skip has an explicit approved waiver at `.ai/packages/FEAT-003/decisions/waiver-<id>.md` that accepts release risk. Keep waived results visible and matrix Status `failed`; cite the waiver and accepted risk.

## Approved waiver

```markdown
# Waiver: WAIVER-001

approver: Jordan Lee
date: 2026-06-12
scope: TC-002 / AC-002
reason: E2E environment unavailable during the approved release window
accepted_risk: AC-002 lacks executed E2E evidence; result remains skip and matrix Status remains failed
expires_or_revisit: Before the next release
```

## Self-review log

```markdown
# Self Review - Test Report (FEAT-003)

| Check | Result | Note |
|-------|--------|------|
| Upstream inputs and source | pass | Exact input paths, versions, digests, and tested source match; no drift before freeze |
| AC coverage | pass | 2/2 ACs have executed validation or approved waiver; AC-002 is waived-skip/no-go/failed |
| Evidence complete | pass | Commands, UTC timestamps, durations, exits, secret-safe environment identity, and actual output recorded |
| Failures documented | pass | DEF-001 root cause/resolution recorded; GAP-001 routed to test-plan |
| Coverage reported | pass | Every changed path reconciled |
| Release rec explicit | pass | Evidence and WAIVER-001 require no-go; archive approval is not release approval |
| Version set frozen | pass | All seven reports frozen at v2 before self-review |
| Reproducible and honest | pass | Failures, skip, and rerun history retained |

**Blocking failures:** 0
**Recommendation:** Ready for required human review as an honest report; release remains `no-go`.
```

## High-risk approval

```markdown
# Test Report Approval

approver: Jordan Lee
date: 2026-06-12
decision: approved-for-archive
acknowledged_release_recommendation: no-go
reviewed_artifacts:
  - `artifacts/FEAT-003/06-test-report/test-execution-summary.md@v2`
  - `artifacts/FEAT-003/06-test-report/unit-test-report.md@v2`
  - `artifacts/FEAT-003/06-test-report/integration-test-report.md@v2`
  - `artifacts/FEAT-003/06-test-report/e2e-test-report.md@v2`
  - `artifacts/FEAT-003/06-test-report/coverage-report.md@v2`
  - `artifacts/FEAT-003/06-test-report/defects.md@v2`
  - `artifacts/FEAT-003/06-test-report/release-recommendation.md@v2`
```

Revalidate the exact upstream input set and source snapshot, then verify all seven exact versions before setting their status to `approved`; repeat revalidation before archive. Approval accepts the report evidence for archive; it does not change test outcomes or authorize release. Archive does not edit approved reports.
