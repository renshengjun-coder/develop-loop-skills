---
artifact_id: TR-001-execution-summary
artifact_type: test-report
package_id: FEAT-PARENT
version: v1
status: reviewed
traces:
  - validates: "TC-001"
  - validates: "TC-002"
  - validates: "TC-003"
  - validates: "AC-001"
  - validates: "AC-002"
  - validates: "AC-003"
related: []
---

# Test Execution Summary — FEAT-PARENT

| TC ID | AC ID | Result | Command |
|-------|-------|--------|---------|
| TC-001 | AC-001 | pass | `npm test -- email.test.ts` |
| TC-002 | AC-002 | pass | `npm test -- template.test.ts` |
| TC-003 | AC-003 | pass | `npm test -- idempotency.test.ts` |
