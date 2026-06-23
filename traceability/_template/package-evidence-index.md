# Package Evidence Index — <PACKAGE-ID>

## Package Summary

| Field | Value |
|-------|-------|
| Package ID | `<PACKAGE-ID>` |
| Owner | `<owner>` |
| Profile | `<profile>` |
| Mode | `<mode>` |
| Package status | `<status>` |
| Children | `<none-or-summary>` |

## Current Readiness

- Current package status: `<status>`
- Latest gate posture: `<latest-gate-summary>`
- Traceability baseline: [matrix.md](matrix.md)
- Decision record baseline: [decision-records.md](decision-records.md)

## Phase and Gate Snapshot

| Phase | Package phase status | Artifact version | Latest gate | Notes |
|-------|----------------------|------------------|-------------|-------|
| requirements | `<status>` | `<version>` | `<gate-result>` | `<notes>` |
| design | `<status>` | `<version>` | `<gate-result>` | `<notes>` |
| test-plan | `<status>` | `<version>` | `<gate-result>` | `<notes>` |
| implementation | `<status-or-n/a>` | `<version-or-n/a>` | `<gate-result-or-n/a>` | `<notes>` |
| code-review | `<status-or-n/a>` | `<version-or-n/a>` | `<gate-result-or-n/a>` | `<notes>` |
| test-report | `<status-or-n/a>` | `<version-or-n/a>` | `<gate-result-or-n/a>` | `<notes>` |
| release | `<status-or-n/a>` | `<version-or-n/a>` | `<gate-result-or-n/a>` | `<notes>` |

## Traceability Coverage

| Evidence view | Summary |
|---------------|---------|
| Acceptance criteria coverage | `<summary>` |
| Design linkage | `<summary>` |
| Test linkage | `<summary>` |
| Code linkage | `<summary>` |
| Current limitations | `<honest caveats>` |

## Approvals, Waivers, and Findings

- Human-gated phases required by profile: `<list>`
- Recorded waivers: `<none-or-summary>`
- Open blocking findings in latest gates: `<none-or-summary>`
- Evidence migration notes: `<summary>`

## Child Readiness References

Use this section only when the package has child packages. Reference child package readiness and gate status here without copying child artifacts into the parent package.

| Child package | Relationship | Child package status | Evidence references | Notes |
|---------------|--------------|----------------------|---------------------|-------|
| `<child-id>` | `<relationship>` | `<status>` | `<links>` | `<notes>` |
