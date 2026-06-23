---
artifact_id: TR-002-coverage
artifact_type: test-report
package_id: FEAT-003
version: v1
status: reviewed
related:
  - "artifacts/FEAT-003/04-implementation/changed-files.md@v1"
  - "artifacts/FEAT-003/06-test-report/test-execution-summary.md@v1"
---

# Coverage Report — FEAT-003

This coverage summary is a lightweight, human-readable companion to the test execution summary. It is intended to show changed-path test attention for the demo package rather than to replace a raw coverage tool export.

| Changed path | Coverage |
|--------------|----------|
| src/notifications/email.ts | 92% lines |
| src/notifications/template.ts | 88% lines |
| src/notifications/idempotency.ts | 90% lines |

## Interpretation

- All changed production paths listed in `changed-files.md` have corresponding coverage entries.
- Coverage is presented only for the changed production modules in scope for FEAT-003.
- The repository does not attach a raw LCOV or HTML report for this demo package.
