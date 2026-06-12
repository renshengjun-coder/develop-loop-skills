# Parent-Child Walkthrough — FEAT-PARENT / FEAT-CHILD

**Parent:** Order dashboard with shipment notifications (`FEAT-PARENT`)  
**Child:** Email notification service (`FEAT-CHILD`, 3-phase MVP package — only requirements/design/test-plan listed in `package.yaml`, even though `profile: standard`)

## 1. Create both packages

```text
/devloop start FEAT-CHILD
# Classify as standard; child completes requirements → design → test-plan only (MVP scope)

/devloop start FEAT-PARENT
# Classify as standard; parent runs full 7-phase profile
```

Add child reference to parent `package.yaml`:

```yaml
children:
  - id: FEAT-CHILD
    relationship: implements
```

## 2. Complete child loop

```text
/devloop run FEAT-CHILD
```

Child progression:

```text
requirements → design → test-plan
```

Each phase archives with L1 `review-log.md` and L2 gate pass. Child ends at `status: ready_for_merge`.

Verify child:

```bash
./scripts/devloop-verify.sh FEAT-CHILD
```

## 3. Run parent release gate

```text
/devloop run FEAT-PARENT
# Parent progresses through all profile phases through test-report

/devloop gate FEAT-PARENT release
```

Lifecycle-loop checks **child readiness** before parent release gate passes:

- `.ai/packages/FEAT-CHILD/package.yaml` shows child phases `archived`
- Latest child gates are `result: pass`

**Evidence:** `.ai/packages/FEAT-PARENT/gates/release-1.md`

```text
artifacts_checked:
  - .ai/packages/FEAT-CHILD/package.yaml
  - .ai/packages/FEAT-CHILD/gates/requirements-1.md
  - .ai/packages/FEAT-CHILD/gates/design-1.md
  - .ai/packages/FEAT-CHILD/gates/test-plan-1.md
```

### Fail example

If child `test-plan` is still `pending`, parent release gate returns `result: fail` with finding:

```text
Child FEAT-CHILD not ready: test-plan phase not archived
```

## Constraints

- Child artifacts stay under `artifacts/FEAT-CHILD/` — not copied into parent
- Traceability matrix is per-package

## Verify

```bash
./scripts/devloop-verify.sh FEAT-CHILD
./scripts/devloop-verify.sh FEAT-PARENT
```
