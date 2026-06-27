---
name: 03-test-plan
description: >-
  Produces test strategy, test cases, edge cases, and regression set mapped to
  acceptance criteria. L1 self-check and archive. Use for test plan, test strategy,
  test cases, QA plan, coverage map — standalone or via /devloop. Does not issue
  final gate PASS.
---

# Test-Plan Phase Skill

Fully owns the **test-plan phase**. Runnable standalone or when invoked by devloop.

## Required inputs

- `package_id`
- `artifacts/<package_id>/01-requirements/acceptance-criteria.md`
- `artifacts/<package_id>/02-design/` (architecture, api-design)
- Verify `phases.requirements` and `phases.design` are `archived` in `package.yaml`

## Step 1: Generate

Create or revise under `artifacts/<package_id>/03-test-plan/`:

| File | Content |
|------|---------|
| `test-strategy.md` | Unit/integration/E2E levels, environments, tools |
| `test-cases.md` | TC-001 format with AC link, steps, expected result |
| `edge-cases.md` | Boundary and error cases |
| `regression-cases.md` | Smoke/regression set |

### Test case format

```markdown
### TC-001: Email sent on ship (AC-001)

**Level:** integration
**Steps:**
1. Create order with valid email
2. Transition to shipped
**Expected:** One email enqueued with tracking link
```

Frontmatter on `test-cases.md`:
```yaml
traces:
  - verifies: "AC-001"
```

## Step 2: Self Review

Write `review-log.md`:

| Check | Result | Note |
|-------|--------|------|
| AC coverage | pass/fail | Every AC has ≥ 1 TC |
| Exception paths | pass/fail | edge-cases.md non-empty |
| Boundary conditions | pass/fail | Boundary per critical AC |
| Security tests | pass/fail | Auth/permission if applicable |
| Regression set | pass/fail | regression-cases.md has smoke tests |

## Step 3: Human Review

Standard MVP: test-plan not in `human_gates`. Set `status: reviewed`.

## Step 4: Archive

1. Bump version if revised.
2. Update `package.yaml` → `phases.test-plan.status: archived`, `artifact_version: v<n>`.
3. Invoke traceability skill — fill Test Case(s) column for every AC.
4. Do not write gate PASS.

## Quality criteria

- Every AC is verifiable by at least one automated or manual test case
- Edge cases include invalid input and provider failure (from design failure-scenarios)
- Regression set is runnable in CI (when implementation exists)

See `reference.md` for TC template.
