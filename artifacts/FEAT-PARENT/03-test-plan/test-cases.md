---
artifact_id: TST-001-cases
artifact_type: test-plan
package_id: FEAT-PARENT
version: v1
status: reviewed
owner: demo
created_at: 2026-06-12
traces:
  - verifies: "AC-001"
  - verifies: "AC-002"
  - verifies: "AC-003"
related: []
---

# Test Cases — FEAT-PARENT

### TC-001: Email sent on ship (AC-001)

**Level:** integration
**Steps:** Publish OrderShipped with valid email; wait for worker
**Expected:** Provider receives one send request within 60s

### TC-002: Email contains tracking (AC-002)

**Level:** unit
**Steps:** Render template with fixture payload
**Expected:** Output contains orderId, trackingUrl, estimatedDelivery

### TC-003: Duplicate event idempotent (AC-003)

**Level:** integration
**Steps:** Publish same OrderShipped twice
**Expected:** Provider called once

### TC-004: Provider failure retry (edge)

**Level:** integration
**Steps:** Mock provider 503 then 200
**Expected:** Email sent after retry
