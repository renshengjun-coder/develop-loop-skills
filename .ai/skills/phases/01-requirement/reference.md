# Requirements — Reference

## Example user story

```markdown
### US-001: Order ship notification

**As a** customer who placed an order
**I want** to receive an email when my order ships
**So that** I know when to expect delivery
```

## Example acceptance criterion

```markdown
### AC-001: Email sent on ship (US-001)

**Given** an order in `shipped` status with a valid customer email
**When** the shipment is confirmed in the order service
**Then** exactly one transactional email is sent within 60 seconds
**And** the email contains order ID, tracking link, and estimated delivery date
```

## PRD section outline

```markdown
## Problem
## Goals
## Non-goals
## Users
## Scope
## Constraints
## Assumptions
## Risks
```
