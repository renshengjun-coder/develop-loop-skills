# Devloop — Reference

## Command cheat sheet

```text
/devloop start FEAT-003             # create package + classify
/devloop run FEAT-003               # start loop; pauses at human checkpoints
/devloop continue FEAT-003          # resume from checkpoint or stop
/devloop run FEAT-003 --pipeline    # single pass
/devloop gate FEAT-003 design       # gate one phase
/devloop status FEAT-003            # status + run_control summary
/devloop classify FEAT-003          # re-classify
```

## Checkpoint example

```text
/devloop run FEAT-003
→ requirements archived
→ requirements gate passed
→ paused at human gate checkpoint
→ next: /devloop continue FEAT-003

/devloop status FEAT-003
→ state: paused
→ stopped_at: requirements
→ reason: human_gate_checkpoint
→ next_action: /devloop continue FEAT-003

/devloop continue FEAT-003
→ resumes at design
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
  - artifacts/FEAT-003/02-design/architecture.md@v1
  - artifacts/FEAT-003/02-design/review-log.md@v1
  - traceability/FEAT-003/matrix.md
  - traceability/FEAT-003/package-evidence-index.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Traces to upstream requirements present
  - [x] Human approval recorded (if required)
  - [x] Package evidence index and matrix reflect this phase outcome
  - [x] Exact evidence bindings recorded in artifacts_checked

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
  - artifacts/FEAT-PARENT/07-release-retro/release-notes.md@v1
  - artifacts/FEAT-PARENT/07-release-retro/known-issues.md@v1
  - artifacts/FEAT-PARENT/07-release-retro/retro.md@v1
  - artifacts/FEAT-PARENT/07-release-retro/review-log.md@v1
  - traceability/FEAT-PARENT/matrix.md
  - traceability/FEAT-PARENT/package-evidence-index.md
  - .ai/packages/FEAT-CHILD/package.yaml
  - traceability/FEAT-CHILD/package-evidence-index.md
  - .ai/packages/FEAT-CHILD/gates/release-1.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile
  - [x] Human approval recorded (if required)
  - [x] Package evidence index and matrix reflect this phase outcome
  - [x] Exact evidence bindings recorded in artifacts_checked

child_evidence:
  - child_id: FEAT-CHILD
    status: ready_for_release
    package: .ai/packages/FEAT-CHILD/package.yaml
    latest_gate: .ai/packages/FEAT-CHILD/gates/release-1.md
    evidence_index: traceability/FEAT-CHILD/package-evidence-index.md

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
