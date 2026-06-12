# Tradeoffs — FEAT-CHILD

## Async queue vs sync send

**Chosen:** Async queue
**Rationale:** Ship API p99 < 200ms; provider latency isolated
**Rejected:** Sync send in ship handler
