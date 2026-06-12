---
artifact_id: TST-001-strategy
artifact_type: test-plan
package_id: FEAT-003
version: v1
status: reviewed
owner: demo
created_at: 2026-06-12
traces:
  - verifies: "AC-001"
related: []
---

# Test Strategy — FEAT-003

## Levels

- **Unit:** Idempotency store, template rendering
- **Integration:** Event → queue → worker (mock provider)
- **E2E:** Full ship flow in staging

## Tools

pytest, testcontainers (Redis), provider mock

## AC mapping

| AC | Primary level |
|----|---------------|
| AC-001 | integration |
| AC-002 | unit + integration |
| AC-003 | integration |
