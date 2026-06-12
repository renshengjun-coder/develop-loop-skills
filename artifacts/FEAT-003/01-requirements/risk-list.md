# Risk List — FEAT-003

| Risk | Mitigation |
|------|------------|
| Email provider outage | Async queue with retry and DLQ |
| Duplicate ship events | Idempotency key per order ID |
