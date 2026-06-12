# Lifecycle Loop — Reference

## Command cheat sheet

```text
/loop start FEAT-001          # create package + classify
/loop run FEAT-001            # E2E loop mode
/loop run FEAT-001 --pipeline # single pass
/loop gate FEAT-001 design    # gate one phase
/loop status FEAT-001         # status summary
/loop classify FEAT-001       # re-classify
```

## Standard profile phase order (MVP)

```text
requirements → design → test-plan
```

Human gate: `requirements` only.

## Gate file example

```md
# Gate: design (attempt 1)

result: pass
profile: standard
mode: loop

artifacts_checked:
  - artifacts/FEAT-001/02-design/architecture.md (v1)
  - artifacts/FEAT-001/02-design/review-log.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Traces to upstream requirements present
  - [x] Human approval recorded (if required)

findings: []
reentry: 0
next: test-plan
```

## Escalation example

```text
Gate: design (attempt 3) — FAIL
Blocking: AC-002 not referenced in architecture.md
Re-entry budget exhausted (max_reentry: 3)

Action: Human must revise design or waive.
Next: /loop gate FEAT-001 design (after fix)
```
