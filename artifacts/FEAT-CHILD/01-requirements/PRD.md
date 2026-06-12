---
artifact_id: REQ-001-prd
artifact_type: requirement
package_id: FEAT-CHILD
version: v1
status: approved
owner: demo
created_at: 2026-06-12
traces: []
related:
  - artifacts/FEAT-CHILD/02-design/architecture.md
---

# PRD: Ship notification email

## Problem

Customers do not know when their order has shipped unless they check the app manually.

## Goals

- Send a transactional email when an order transitions to `shipped`
- Include tracking link and estimated delivery date

## Non-goals

- SMS or push notifications (future work)
- Marketing emails

## Users

- End customers with a valid email on file

## Scope

Order service ship event → notification service → email provider

## Constraints

- Ship API p99 latency must remain < 200ms
- Email send must be idempotent per order

## Assumptions

- Email provider API available with 99.9% uptime

## Risks

- Provider outage delays email — mitigated by async queue and retry
