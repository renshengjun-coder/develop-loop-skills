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
- Current verifier posture: both `./scripts/loop-verify.sh FEAT-PARENT` and `./scripts/loop-verify.sh --enforce FEAT-PARENT` pass
- Traceability baseline: [matrix.md](matrix.md)
- Decision record baseline: [decision-records.md](decision-records.md)

## Phase and Gate Snapshot

| Phase | Package phase status | Artifact version | Latest gate | Notes |
|-------|----------------------|------------------|-------------|-------|
| requirements | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/requirements-1.md` | Human-gated for `standard`; no findings recorded. |
| design | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/design-1.md` | Gate asserts required artifacts and trace checks passed. |
| test-plan | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/test-plan-1.md` | Package became merge-ready after this gate. |
| implementation | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/implementation-1.md` | Gate binds implementation plan, changed files, `coding-log.md`, review log, and package evidence files. |
| code-review | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/code-review-1.md` | Gate binds the committed review artifacts declared by the active evidence policy. |
| test-report | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/test-report-1.md` | Gate binds the committed summary, coverage, review log, and package evidence files. |
| release | archived | `v1` | `pass` via `.ai/packages/FEAT-PARENT/gates/release-1.md` | Release gate satisfies the current light parent-child policy by binding child package, the child gate for the package's current archived phase, evidence index, and `child_evidence` metadata. |

## Traceability Coverage

| Evidence view | Summary |
|---------------|---------|
| Acceptance criteria coverage | `matrix.md` contains rows for `AC-001` through `AC-003`, all marked `covered`. |
| Design linkage | Each AC maps to an architecture section. |
| Test linkage | Each AC maps to a named test case (`TC-001` to `TC-003`). |
| Code linkage | Each AC maps to a concrete code path under `src/notifications/`. |
| Current limitations | Parent-child aggregation is intentionally light: the parent references child readiness by package, the child gate for the package's current archived phase, and child evidence index rather than copying child artifacts into the parent package. |

## Approvals, Waivers, and Findings

- Human-gated phases required by profile: `requirements`
- Recorded waivers: none recorded in package or traceability artifacts
- Open blocking findings in latest gates: none
- Evidence migration notes: human-readable package evidence and parent-child release checks are now controlled by `.ai/contracts/evidence-policy.yaml`; this package is verifier-clean under both baseline and `--enforce` runs.

## Child Readiness References

| Child package | Relationship | Child package status | Evidence references | Notes |
|---------------|--------------|----------------------|---------------------|-------|
| `FEAT-CHILD` | `implements` | `ready_for_merge` | `.ai/packages/FEAT-CHILD/package.yaml`, `.ai/packages/FEAT-CHILD/gates/test-plan-1.md`, [../FEAT-CHILD/package-evidence-index.md](../FEAT-CHILD/package-evidence-index.md) | Matches the current light parent-child release policy; the release gate may retain extra child gate references, but the child gate for the package's current archived phase is the required readiness anchor. |
