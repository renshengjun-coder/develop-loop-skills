---
name: traceability
description: >-
  Maintains requirement-to-design-to-test trace matrix and typed artifact links.
  Use after phase archive, when updating traceability, trace matrix, or requirement
  coverage map. Invokable standalone or from phase/loop skills.
---

# Traceability Skill

Maintains proven evidence that requirements flow through design, tests, and (later) code. Updates the trace matrix and validates frontmatter links.

## When to invoke

- After any phase Archive step
- When user asks for trace matrix, requirement coverage, or traceability update
- When lifecycle loop gate detects matrix gaps

## Update steps

1. Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` — extract all AC IDs (AC-001, AC-002, …).
2. Read `artifacts/<package_id>/02-design/architecture.md` and `api-design.md` — map ACs to design sections via headings and frontmatter `traces`.
3. Read `artifacts/<package_id>/03-test-plan/test-cases.md` — map TC IDs to AC IDs.
4. Read `.ai/packages/<package_id>/package.yaml` and latest gate files for status.
5. Fill or update `traceability/<package_id>/matrix.md` using the template in `traceability/_template/matrix.md`.
6. Use `N/A` + reason in Notes only when genuinely not applicable.
7. Append tradeoffs or overrides to `traceability/<package_id>/decision-records.md` when found in design artifacts.

## Matrix format

```markdown
# Traceability Matrix — {package_id}

| Req/AC ID | Design Section | Test Case(s) | Code File(s) | Status | Notes |
|-----------|----------------|--------------|--------------|--------|-------|
| AC-001 | Architecture §2 | TC-001 | N/A (MVP) | covered | |
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

**Gate binding:** Lifecycle loop gate files must list the same paths in `artifacts_checked` so L2 decisions bind to exact files.

## Self-check checklist

| Check | Pass criteria |
|-------|---------------|
| Every AC has a row | No missing AC IDs from acceptance-criteria.md |
| Design column filled or N/A | Reason required for N/A |
| Test column filled or N/A | ≥ 1 TC per AC for standard profile |
| Status column current | Aligns with latest gate results |

Write self-check result as a brief note at the bottom of `matrix.md` under `## Traceability self-check`.

## Constraints

- Do not issue gate PASS/FAIL — traceability is a helper skill only.
- Do not delete matrix history — update rows in place; note version in header if needed.
- Code File(s) column may be `N/A` until implementation phase (Phase 2).
