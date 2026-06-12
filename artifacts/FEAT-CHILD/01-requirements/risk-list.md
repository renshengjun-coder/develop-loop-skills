# Risk List — FEAT-CHILD

| Risk | Mitigation |
|------|------------|
| Email provider outage | Async queue with retry and DLQ |
| Duplicate ship events | Idempotency key per order ID |
