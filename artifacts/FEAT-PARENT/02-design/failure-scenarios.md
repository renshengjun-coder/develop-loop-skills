# Failure Scenarios — FEAT-PARENT

## Provider timeout

Worker retries 3x with exponential backoff; then DLQ for manual replay.

## Duplicate ship event

Idempotency store rejects second enqueue; no duplicate email (AC-003).
