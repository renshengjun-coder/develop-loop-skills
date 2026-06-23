---
name: traceability
description: >-
  Maintains requirement-to-design-to-test trace matrix, package evidence index,
  and typed artifact links. Use after phase archive, when updating traceability,
  package audit evidence, trace matrix, or requirement coverage map. Invokable
  standalone or from phase or devloop skills.
---

# Traceability Skill

Maintains proven evidence that requirements flow through design, tests, code, gates, and package-level audit views. Updates the trace matrix, package evidence index, and validates frontmatter links.

## When to invoke

- After any phase Archive step
- When user asks for trace matrix, requirement coverage, or traceability update
- When lifecycle loop gate detects matrix or package evidence index gaps

## Update steps

1. Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` — extract all AC IDs (AC-001, AC-002, …).
2. Read `artifacts/<package_id>/02-design/architecture.md` and `api-design.md` — map ACs to design sections via headings and frontmatter `traces`.
3. Read `artifacts/<package_id>/03-test-plan/test-cases.md` — map TC IDs to AC IDs.
4. Read `artifacts/<package_id>/04-implementation/changed-files.md` — map AC IDs to source file paths for **Code File(s)** column.
5. Read `artifacts/<package_id>/06-test-report/test-execution-summary.md` — set matrix **Status** to `covered` or `failed` per AC.
6. Read `.ai/packages/<package_id>/package.yaml` and latest gate files for status.
7. Fill or update `traceability/<package_id>/matrix.md` using the template in `traceability/_template/matrix.md`.
8. Fill or update `traceability/<package_id>/package-evidence-index.md` as the primary package-level audit entry point: summarize phase status, latest gates, approvals, waivers, open blockers, traceability coverage, and release posture with links to supporting evidence.
9. Check that latest gate files bind the same current artifact paths through `artifacts_checked`; note any stale or incomplete gate binding in the matrix Notes or package evidence index blockers section.
10. Use `N/A` + reason in Notes only when genuinely not applicable.
11. Append tradeoffs or overrides to `traceability/<package_id>/decision-records.md` when found in design artifacts.

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

**Gate binding:** Lifecycle loop gate files must list the same paths in `artifacts_checked` so L2 decisions bind to exact files, including the current `traceability/<package_id>/matrix.md` and `traceability/<package_id>/package-evidence-index.md` package evidence paths for every gate.

**Package evidence index:** Keep `traceability/<package_id>/package-evidence-index.md` aligned with the latest archived phase artifacts and latest gate attempt per phase. It is the top-level human-readable audit entry point; it must point to the same evidence set the gate files bind.

## Self-check checklist

| Check | Pass criteria |
|-------|---------------|
| Every AC has a row | No missing AC IDs from acceptance-criteria.md |
| Design column filled or N/A | Reason required for N/A |
| Test column filled or N/A | ≥ 1 TC per AC for standard profile |
| Code column filled or N/A | After implementation archived, every AC row has file path or N/A + reason |
| Status column current | Aligns with latest gate and test-report results |
| Package evidence index current | Latest phase/gate status, blockers, approvals, and key links match current package state |

Write self-check result as a brief note at the bottom of `matrix.md` under `## Traceability self-check`, and refresh the package evidence index summary when the traceability status changes.

## Constraints

- Do not issue gate PASS/FAIL — traceability is a helper skill only.
- Do not delete matrix history — update rows in place; note version in header if needed.
