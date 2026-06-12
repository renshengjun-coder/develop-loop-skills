---
artifact_id: DES-001-api
artifact_type: design
package_id: FEAT-001
version: v1
status: reviewed
owner: demo
created_at: 2026-06-12
traces:
  - derives_from: "artifacts/FEAT-001/01-requirements/PRD.md@v1"
related: []
---

# API Design — FEAT-001

## Event: OrderShipped

```json
{
  "orderId": "string",
  "customerEmail": "string",
  "trackingUrl": "string",
  "estimatedDelivery": "ISO8601"
}
```

## Internal: EnqueueEmail

POST `/internal/notifications/email` — idempotency header `Idempotency-Key: {orderId}:shipped`
