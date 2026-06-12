---
artifact_id: DES-001-architecture
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

# Architecture — Ship notification

## Overview

Order service publishes `OrderShipped` event. Notification service consumes, enqueues email job. Worker sends via email provider.

## Components

- **OrderService** — emits ship event
- **NotificationService** — queue producer + idempotency store
- **EmailWorker** — consumes queue, calls provider
- **EmailProvider** — external API

## Data flow

```mermaid
flowchart LR
  OrderService -->|OrderShipped| NotificationService
  NotificationService --> Queue
  Queue --> EmailWorker
  EmailWorker --> EmailProvider
```

## AC coverage

| AC ID | Section |
|-------|---------|
| AC-001 | Notification flow §2 |
| AC-002 | Email template §3 |
| AC-003 | Idempotency §4 |

## Idempotency

Dedupe key: `order_id` + `event_type=shipped` in Redis before enqueue.
