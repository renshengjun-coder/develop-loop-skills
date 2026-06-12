# Release & Retro — Reference

Use this file only after loading and following `SKILL.md`. These examples illustrate valid artifact shapes.

## Frontmatter (all four artifacts)

```yaml
---
artifact_id: REL-002-known-issues
artifact_type: release
package_id: FEAT-003
version: v1
status: draft
traces:
  - derives_from: "artifacts/FEAT-003/06-test-report/release-recommendation.md@v1"
related: []
---
```

Use `REL-001` through `REL-004` for release-notes, known-issues, retro, and rollback-plan respectively.

## Release notes

```markdown
# Release Notes — FEAT-003 v1

## Summary

Ship notification email when an order transitions to `shipped`.

## Changes by acceptance criteria

| AC ID | User story | Change |
|-------|------------|--------|
| AC-001 | US-001 | Email sent on shipment transition |
| AC-002 | US-001 | Email includes tracking link and ETA |
| AC-003 | US-002 | Duplicate shipment events do not send duplicate emails |

## Migration / configuration

- Set `EMAIL_PROVIDER_API_KEY` in deployment environment
- Run database migration `20260612_add_shipment_email_log.sql`

## Validation reference

Test report: `artifacts/FEAT-003/06-test-report/release-recommendation.md` — **go**
```

## Known issues

```markdown
# Known Issues — FEAT-003

**As of:** 2026-06-12

| ID | Issue | Workaround | Target fix |
|----|-------|------------|------------|
| KI-001 | Email template renders slowly for large orders | None required for MVP volume | Monitor in retro |

If none: `No known issues as of 2026-06-12.`
```

## Retro

```markdown
# Retrospective — FEAT-003

## What went well

- Trace matrix stayed current through implementation
- Test plan AC coverage was complete before coding

## What to improve

- Add E2E environment earlier for AC-002 validation

## Action items

| ID | Action | Owner | Due |
|----|--------|-------|-----|
| AI-001 | Provision staging E2E mail sandbox | demo | next sprint |
```

## Rollback plan

```markdown
# Rollback Plan — FEAT-003

1. Disable feature flag `shipment_email_enabled=false`
2. Revert commit range containing `src/notifications/email.ts`
3. Roll back migration `20260612_add_shipment_email_log.sql`
4. Verify order shipment still works without email side effects
5. Confirm no queued emails remain in outbox table
```

## Self-review log

```markdown
# Self Review — Release (FEAT-003)

| Check | Result | Note |
|-------|--------|------|
| Scope accurate | pass | Matches AC-001..003 only |
| Validation status | pass | Test report go cited |
| Known issues honest | pass | Explicit none with date |
| Rollback viable | pass | Five concrete steps |
| Retro actionable | pass | AI-001 listed |

**Blocking failures:** 0
**Recommendation:** Ready for archive
```

## Approval (high_risk)

```markdown
# Release Approval

approver: Jordan Lee
date: 2026-06-12
decision: approved
acknowledged_test_report: go
reviewed_artifacts:
  - `artifacts/FEAT-003/07-release-retro/release-notes.md@v1`
  - `artifacts/FEAT-003/07-release-retro/known-issues.md@v1`
  - `artifacts/FEAT-003/07-release-retro/retro.md@v1`
  - `artifacts/FEAT-003/07-release-retro/rollback-plan.md@v1`
```
