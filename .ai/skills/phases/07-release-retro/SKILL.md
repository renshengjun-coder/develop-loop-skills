---
name: 07-release-retro
description: >-
  Use when a package needs release notes, known issues, retrospective, rollback
  planning, ship, deploy, or release phase closure — standalone or via /devloop.
  Does not issue final gate PASS.
---

# Release & Retro Phase Skill

Fully owns the **release phase**. Runnable standalone or when invoked by devloop.

## Required inputs

- `package_id`
- Read `.ai/packages/<package_id>/package.yaml`, `.ai/packages/<package_id>/classification.yaml`, and `.ai/config/profiles.yaml` — determine the active profile and **do not proceed** unless `phases.test-report.status: archived`
- Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` and `user-stories.md` — scope for release notes
- Read `artifacts/<package_id>/04-implementation/changed-files.md` — shipped code scope, required when implementation is archived
- Read `artifacts/<package_id>/06-test-report/release-recommendation.md` — must state `go`, or cite an exact approved waiver at `.ai/packages/<package_id>/decisions/waiver-<id>.md`
- Read `artifacts/<package_id>/06-test-report/defects.md` when present — open defects for known-issues
- Read `artifacts/<package_id>/02-design/` and `03-test-plan/` when those phases are archived for the active profile

For the `routine` profile, design and test-plan may be skipped and must not be treated as missing inputs. Use acceptance criteria and test-report as the validation boundary.

## Step 1: Generate

Create or revise under `artifacts/<package_id>/07-release-retro/`:

| File | Content |
|------|---------|
| `release-notes.md` | User-facing changes grouped by US/AC, migration or config notes |
| `known-issues.md` | Shipped-with issues and workarounds, or explicit "none" with date |
| `retro.md` | What went well, what to improve, ≥ 1 action item |
| `rollback-plan.md` | Concrete steps to revert the release |

### Frontmatter

```yaml
---
artifact_id: REL-001-release-notes
artifact_type: release
package_id: FEAT-003
version: v1
status: draft
traces:
  - derives_from: "artifacts/FEAT-003/06-test-report/release-recommendation.md@v1"
related: []
---
```

Use frontmatter on all four generated artifacts with appropriate `artifact_id` values (`REL-001` through `REL-004`). `review-log.md` follows the phase self-review format and does not require frontmatter.

Release notes must match approved AC scope only. Reference the test-report `go`/`no-go` decision and any waivers.

## Step 2: Self Review

Write `artifacts/<package_id>/07-release-retro/review-log.md`:

| Check | Result | Note |
|-------|--------|------|
| Scope accurate | pass/fail | Release notes match merged AC scope only |
| Validation status | pass/fail | References test-report go/no-go or waiver |
| Known issues honest | pass/fail | Non-empty or explicit "none" with date |
| Rollback viable | pass/fail | `rollback-plan.md` has concrete steps |
| Retro actionable | pass/fail | ≥ 1 improvement action item |

Record `**Blocking failures:** <count>` and `**Recommendation:** <action>`.

Fix blocking failures before proceeding to Human Review or Archive.

## Step 3: Human Review

Read the active profile's `human_gates` in `.ai/config/profiles.yaml`.

If `release` is included in `human_gates` (`high_risk`: **yes**):

1. Keep all four report artifacts `status: draft`.
2. Present release notes, known issues, retro, and rollback plan.
3. Wait for explicit approval.
4. Write `approval.md` with approver, date, decision, and all four artifact paths with frozen versions.
5. Set all four report artifacts' frontmatter `status: approved`.

If `release` is not in `human_gates`: set `status: reviewed` on all four report artifacts after self-review passes.

## Step 4: Archive

1. Verify self-review has zero blocking failures.
2. Verify all four report artifacts have `status: approved` or `reviewed`; require `approval.md` when `release` is in `human_gates`.
3. Bump `version` in frontmatter if revised since last archive.
4. Update `.ai/packages/<package_id>/package.yaml` → `phases.release.status: archived`, `artifact_version: v<n>`
5. Set package `status: ready_for_release`
6. Load `.ai/skills/traceability/SKILL.md` — confirm matrix **Status** per AC aligns with test-report; update Notes if release changes auditor-facing status
7. **Do not** write gate PASS — devloop owns L2

## Quality criteria

- Release notes are user-facing and traceable to AC/US IDs
- Known issues are honest; "none" is explicit with date
- Rollback plan is actionable, not generic
- Retro contains at least one improvement action
- All four artifacts share consistent terminal status before archive
- Package ends at `ready_for_release` with current trace matrix

See `reference.md` for output templates.
