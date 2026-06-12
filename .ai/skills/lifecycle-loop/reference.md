# Lifecycle Loop — Reference

## Command cheat sheet

```text
/devloop start FEAT-003          # create package + classify
/devloop run FEAT-003            # E2E loop mode
/devloop run FEAT-003 --pipeline # single pass
/devloop gate FEAT-003 design    # gate one phase
/devloop status FEAT-003         # status summary
/devloop classify FEAT-003       # re-classify
```

## Profile summary

### standard

| Setting | Value |
|---------|-------|
| phases | requirements → design → test-plan → implementation → code-review → test-report → release |
| human_gates | requirements |
| max_reentry | 3 |

### routine

| Setting | Value |
|---------|-------|
| phases | requirements → implementation → code-review → test-report → release |
| human_gates | (none) |
| max_reentry | 2 |

### high_risk

| Setting | Value |
|---------|-------|
| phases | requirements → design → test-plan → implementation → code-review → test-report → release |
| human_gates | requirements, design, test-plan, code-review, test-report, release |
| max_reentry | 3 |

## Gate file example

```md
# Gate: design (attempt 1)

result: pass
profile: standard
mode: loop

artifacts_checked:
  - artifacts/FEAT-003/02-design/architecture.md (v1)
  - artifacts/FEAT-003/02-design/review-log.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Traces to upstream requirements present
  - [x] Human approval recorded (if required)

findings: []
reentry: 0
next: test-plan
```

## Parent-child gate example (FEAT-PARENT)

```md
# Gate: release (attempt 1)

result: pass
profile: standard
mode: loop

artifacts_checked:
  - artifacts/FEAT-PARENT/07-release-retro/release-notes.md (v1)
  - artifacts/FEAT-PARENT/07-release-retro/review-log.md
  - .ai/packages/FEAT-CHILD/package.yaml
  - .ai/packages/FEAT-CHILD/gates/requirements-1.md
  - .ai/packages/FEAT-CHILD/gates/design-1.md
  - .ai/packages/FEAT-CHILD/gates/test-plan-1.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Child FEAT-CHILD readiness verified
  - [x] Human approval recorded (if required)

findings: []
reentry: 0
next: (complete)
```

## Escalation example

```text
Gate: design (attempt 3) — FAIL
Blocking: AC-002 not referenced in architecture.md
Re-entry budget exhausted (max_reentry: 3)

Action: Human must revise design or waive.
Next: /devloop gate FEAT-003 design (after fix)
```
