---
name: 02-design
description: >-
  Produces architecture, API design, data model, tradeoffs, and failure scenarios
  from approved requirements. L1 self-check and archive. Use for design phase,
  architecture, API design, data model, system design — standalone or via /devloop.
  Does not issue final gate PASS.
---

# Design Phase Skill

Fully owns the **design phase**. Runnable standalone or when invoked by devloop.

## Required inputs

- `package_id`
- Read `artifacts/<package_id>/01-requirements/` — PRD, acceptance-criteria.md
- Read `.ai/packages/<package_id>/package.yaml` — **do not proceed** if `phases.requirements.status` is not `archived`
- Read `classification.yaml` for active profile

## Step 1: Generate

Create or revise under `artifacts/<package_id>/02-design/`:

| File | Content |
|------|---------|
| `architecture.md` | Components, interfaces, data flow (mermaid encouraged) |
| `api-design.md` | Endpoints/events, request/response shapes |
| `data-model.md` | Entities, relationships |
| `tradeoffs.md` | Decision, options considered, rationale |
| `failure-scenarios.md` | Error paths, retries, degradation |

### Frontmatter

```yaml
---
artifact_id: DES-001-architecture
artifact_type: design
package_id: FEAT-001
version: v1
status: draft
traces:
  - derives_from: "artifacts/FEAT-001/01-requirements/PRD.md@v1"
related: []
---
```

Reference every AC ID in architecture or api-design (section map or table).

## Step 2: Self Review

Write `review-log.md`:

| Check | Result | Note |
|-------|--------|------|
| Requirement coverage | pass/fail | Every AC referenced |
| Performance considered | pass/fail | NFRs addressed |
| Reliability/failure | pass/fail | failure-scenarios.md has ≥ 2 scenarios |
| Security noted | pass/fail | Auth/data handling if applicable |
| Testability | pass/fail | Testable interfaces |
| Tradeoffs documented | pass/fail | tradeoffs.md has ≥ 1 decision |

## Step 3: Human Review

Standard MVP profile: design is **not** in `human_gates`. Set `status: reviewed` on artifacts.

If profile includes `design` in `human_gates`: wait for approval, set `status: approved`.

## Step 4: Archive

1. Bump version if revised.
2. Update `package.yaml` → `phases.design.status: archived`, `artifact_version: v<n>`.
3. Invoke traceability skill to fill Design Section column in matrix.
4. Do not write gate PASS.

## Quality criteria

- Design covers all approved ACs — no orphan requirements
- Failure scenarios are concrete (not "handle errors gracefully")
- Tradeoffs name rejected options and why

See `reference.md` for architecture outline.
