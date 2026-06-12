# FEAT-001 Walkthrough — Ship notification email

Demo package demonstrating the full MVP evidence chain for Develop Loop.

**Feature:** Add email notification when an order ships.

## Evidence chain

```text
PRD.md (v1, approved)
  → architecture.md (derives_from PRD@v1)
  → test-cases.md (verifies AC-001..003)
  → gates/requirements-1.md, design-1.md, test-plan-1.md
  → traceability/FEAT-001/matrix.md
```

## Loop mode E2E (equivalent steps)

```text
/loop start FEAT-001
  → classification.yaml (standard)
  → package.yaml created

/loop run FEAT-001
  → 01-requirement-skill → gate requirements → pass
  → 02-design-skill → gate design → pass
  → 03-test-plan-skill → gate test-plan → pass
  → status: ready_for_merge
```

## Pipeline mode (narrative)

1. `/loop run FEAT-001 --pipeline` runs requirements → gate pass → design → gate **fail** (e.g. missing AC-002 in architecture).
2. Loop stops with gate report; user fixes `architecture.md`.
3. `/loop gate FEAT-001 design` → pass; resume `/loop run FEAT-001 --pipeline` from test-plan.

## Re-entry example (loop mode)

Design gate fail on attempt 1 → design-skill re-invoked with findings → `gates/design-2.md` pass. This demo shows attempt 1 pass only.

## MVP acceptance mapping (spec §8.2)

| Criterion | Evidence |
|-----------|----------|
| Standalone phase skills | `.ai/skills/phases/*/SKILL.md` |
| Loop E2E L1+L2 | `review-log.md` + `gates/*.md` |
| Pipeline stop/resume | Narrative above |
| Re-entry | Supported by loop skill; demo shows single-pass |
| L3 verify | `./scripts/loop-verify.sh FEAT-001` |
| Trace matrix | `traceability/FEAT-001/matrix.md` |
| Gate artifacts_checked | Gate files list real paths |
| Audit from Git | This walkthrough + linked files |
