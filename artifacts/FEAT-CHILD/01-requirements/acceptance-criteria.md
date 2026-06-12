---
artifact_id: REQ-001-ac
artifact_type: requirement
package_id: FEAT-CHILD
version: v1
status: approved
owner: demo
created_at: 2026-06-12
traces: []
related: []
---

# Acceptance Criteria — FEAT-CHILD

### AC-001: Email on ship (US-001)

**Given** an order in `shipped` status with valid customer email
**When** shipment is confirmed
**Then** exactly one transactional email is sent within 60 seconds

### AC-002: Tracking link (US-002)

**Given** a ship notification email was sent
**When** the customer opens the email
**Then** it contains order ID, tracking URL, and estimated delivery date

### AC-003: Idempotent send (US-001)

**Given** duplicate ship events for the same order
**When** notification service processes events
**Then** at most one email is delivered per order
