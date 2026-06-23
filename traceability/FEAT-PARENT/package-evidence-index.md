# Package Evidence Index — FEAT-PARENT

## Package Summary

| Field | Value |
|-------|-------|
| Package ID | `FEAT-PARENT` |
| Owner | `demo` |
| Profile | `standard` |
| Mode | `loop` |
| Package status | `ready_for_release` |
| Children | `FEAT-CHILD` (`implements`) |

## Current Readiness

- Current package status: `ready_for_release`
- Latest gate posture: all seven lifecycle phases are archived with `pass` gates on attempt 1
- Current verifier posture: `scripts/loop-verify.sh --enforce FEAT-PARENT` currently fails on missing gate bindings for implementation `coding-log.md` plus release `known-issues.md` and `retro.md`
- Traceability baseline: [matrix.md](matrix.md)
- Decision record baseline: [decision-records.md](decision-records.md)

## Phase and Gate Snapshot

| Phase | Package phase status | Artifact version | Latest gate | Notes |
|-------|----------------------|------------------|-------------|-------|
| requirements | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/requirements-1.md` | Human-gated for `standard`; no findings recorded. |
| design | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/design-1.md` | Gate asserts required artifacts and trace checks passed. |
| test-plan | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/test-plan-1.md` | Package became merge-ready after this gate. |
| implementation | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/implementation-1.md` | Gate references implementation plan, changed files, and review log. |
| code-review | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/code-review-1.md` | Current committed gate binds only `ai-review.md` and `review-log.md`; richer review evidence is not yet claimed here. |
| test-report | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/test-report-1.md` | Current committed gate binds summary, coverage, and review log; richer release-readiness reporting is not yet claimed in this index. |
| release | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/release-1.md` | Release gate explicitly references child readiness evidence from `FEAT-CHILD`. |

## Traceability Coverage

| Evidence view | Summary |
|---------------|---------|
| Acceptance criteria coverage | `matrix.md` contains rows for `AC-001` through `AC-003`, all marked `covered`. |
| Design linkage | Each AC maps to an architecture section. |
| Test linkage | Each AC maps to a named test case (`TC-001` to `TC-003`). |
| Code linkage | Each AC maps to a concrete code path under `src/notifications/`. |
| Current limitations | Parent-child aggregation is still light: the parent release gate references child readiness, but the package remains on the lighter legacy code-review and test-report evidence shape. |

## Approvals, Waivers, and Findings

- Human-gated phases required by profile: `requirements`
- Recorded waivers: none recorded in package or traceability artifacts
- Open blocking findings in latest gates: none inside the committed gate files, but current verifier enforcement flags missing `artifacts_checked` bindings for implementation `coding-log.md` plus release `known-issues.md` and `retro.md`
- Evidence migration notes: this index adds a package-level audit entry point and records child readiness references without copying child artifacts into the parent package, while still showing the parent package is not yet fully verifier-clean

## Child Readiness References

| Child package | Relationship | Child package status | Evidence references | Notes |
|---------------|--------------|----------------------|---------------------|-------|
| `FEAT-CHILD` | `implements` | `ready_for_merge` | `.ai/packages/FEAT-CHILD/package.yaml`, `.ai/packages/FEAT-CHILD/gates/requirements-1.md`, `.ai/packages/FEAT-CHILD/gates/design-1.md`, `.ai/packages/FEAT-CHILD/gates/test-plan-1.md`, [../FEAT-CHILD/package-evidence-index.md](../FEAT-CHILD/package-evidence-index.md) | Mirrors the child references already recorded in the parent release gate and keeps the child package as the source of its own evidence. |
