---
name: traceability
description: >-
  Maintains requirement-to-design-to-test trace matrix and typed artifact links.
  Use after phase archive, when updating traceability, trace matrix, or requirement
  coverage map. Invokable standalone or from phase/loop skills.
---

# Traceability Skill

Maintains proven evidence that requirements flow through design, tests, and code. Updates the trace matrix and validates frontmatter links.

## When to invoke

- After any phase Archive step
- When user asks for trace matrix, requirement coverage, or traceability update
- When lifecycle loop gate detects matrix gaps

## Update steps

1. Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` — extract all AC IDs (AC-001, AC-002, …).
2. Read `artifacts/<package_id>/02-design/architecture.md` and `api-design.md` — map ACs to design sections via headings and frontmatter `traces`.
3. Read `artifacts/<package_id>/03-test-plan/test-cases.md` — map TC IDs to AC IDs.
4. Read `artifacts/<package_id>/04-implementation/changed-files.md` — map AC IDs to source file paths for **Code File(s)** column.
5. Read `artifacts/<package_id>/06-test-report/test-execution-summary.md` — set matrix **Status** to `covered` or `failed` per AC.
6. Read `.ai/packages/<package_id>/package.yaml` and latest gate files for status.
7. Fill or update `traceability/<package_id>/matrix.md` using the template in `traceability/_template/matrix.md`.
8. Use `N/A` + reason in Notes only when genuinely not applicable.
9. Append tradeoffs or overrides to `traceability/<package_id>/decision-records.md` when found in design artifacts.

## Matrix format

```markdown
# Traceability Matrix — {package_id}

| Req/AC ID | Design Section | Test Case(s) | Code File(s) | Status | Notes |
|-----------|----------------|--------------|--------------|--------|-------|
| AC-001 | Architecture §2 | TC-001 | src/notifications/email.ts | covered | |
```

**Status values:** `pending`, `covered`, `failed`, `N/A`

## Frontmatter link rules

When creating or updating artifacts, set typed links in YAML frontmatter:

**Design artifacts:**
```yaml
traces:
  - derives_from: "artifacts/<package_id>/01-requirements/PRD.md@v1"
```

**Test artifacts:**
```yaml
traces:
  - verifies: "AC-001"
```

**Implementation / code artifacts:**
```yaml
traces:
  - implements: "artifacts/<package_id>/02-design/architecture.md@v1"
  - satisfies: "AC-001"
```

**Source files:** Add HTML comment at top of changed files when practical:
`<!-- implements: AC-001 design: architecture.md §2 -->`

**Gate binding:** Lifecycle loop gate files must list the same paths in `artifacts_checked` so L2 decisions bind to exact files.

## Self-check checklist

| Check | Pass criteria |
|-------|---------------|
| Every AC has a row | No missing AC IDs from acceptance-criteria.md |
| Design column filled or N/A | Reason required for N/A |
| Test column filled or N/A | ≥ 1 TC per AC for standard profile |
| Code column filled or N/A | After implementation archived, every AC row has file path or N/A + reason |
| Status column current | Aligns with latest gate and test-report results |

Write self-check result as a brief note at the bottom of `matrix.md` under `## Traceability self-check`.

## Constraints

- Do not issue gate PASS/FAIL — traceability is a helper skill only.
- Do not delete matrix history — update rows in place; note version in header if needed.
