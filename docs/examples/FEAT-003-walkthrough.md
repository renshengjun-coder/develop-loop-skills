# FEAT-003 Walkthrough — Full 7-Phase Loop

**Feature:** Add email notification when an order ships (same domain as FEAT-001, extended through release).

## Profile classification examples

| Tier | When to use | Phases |
|------|-------------|--------|
| routine | Bug fix, docs, small config | requirements → implementation → code-review → test-report → release |
| standard | Normal feature (FEAT-003) | All 7 phases |
| high_risk | Auth, PII, payment, migration | All 7 phases + human gates at most phases |

### Classify examples

**routine** — bug fix in email template only:

```text
/devloop classify FEAT-003
# Signals: bug fix, single-file change
# Result: active_profile: routine → phases skip design and test-plan
```

**standard** — FEAT-003 (this package):

```text
/devloop classify FEAT-003
# Signals: feature, limited blast radius
# Result: active_profile: standard → all 7 phases
```

**high_risk** — if shipment email touched PII or payment:

```text
/devloop classify FEAT-003
# Signals: PII in email content, compliance
# Result: active_profile: high_risk → human gates at requirements, design, test-plan, code-review, test-report, release
```

Confirm `active_profile` in `classification.yaml` and matching `profile` in `package.yaml`.

## 7-phase evidence chain

```text
requirements (PRD, AC) → design (architecture) → test-plan (TC-001..004)
  → implementation (changed-files.md, code paths)
  → code-review → test-report (go) → release (release-notes)
```

Trace matrix: `traceability/FEAT-003/matrix.md` — code column filled for AC-001..003.

## Verify

```bash
./scripts/devloop-verify.sh FEAT-003
./scripts/devloop-verify.sh --enforce FEAT-003
```

## Phase 2 acceptance checklist

| Criterion | Evidence |
|-----------|----------|
| All 7 phases + full standard profile | FEAT-003 package + `profiles.yaml` |
| routine profile skips design/test-plan | Classify example above |
| high_risk human gates | `profiles.yaml` human_gates |
| Parent-child gate | FEAT-PARENT `gates/release-1.md` |
| CI enforce | `.github/workflows/devloop-verify.yml` |
| Code in trace matrix | `traceability/FEAT-003/matrix.md` |
| FEAT-001 MVP unchanged | `loop-verify.sh FEAT-001` PASS |
