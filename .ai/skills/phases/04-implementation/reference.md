# Implementation — Reference

## Example changed-files.md

```markdown
---
artifact_id: IMPL-001-changed-files
artifact_type: implementation
package_id: FEAT-003
version: v1
status: draft
traces:
  - implements: "artifacts/FEAT-003/02-design/architecture.md@v1"
  - satisfies: "AC-001"
related: []
---
# Changed Files
| Path | Change type | AC/design ref |
|------|-------------|---------------|
| `src/notifications/email.ts` | add | AC-001; architecture.md §Notification flow |
```

## Example coding-log.md entry

```markdown
### 2026-06-12 — Implement shipment email dispatch

**Files:** `src/notifications/email.ts`, `tests/notifications/email.test.ts`
**Summary:** Added queue-backed email dispatch and provider-failure handling for AC-001.
**Tests:** `npm test -- tests/notifications/email.test.ts` — pass (4 tests)
**Assumptions/deviations:** None.
```
