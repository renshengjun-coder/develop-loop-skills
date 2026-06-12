---
name: 01-requirement
description: >-
  Produces PRD, user stories, acceptance criteria, risks, and boundaries for a
  feature package. Runs L1 self-check and archive. Use for requirements phase,
  PRD, user stories, acceptance criteria — standalone or via /loop. Does not
  issue final gate PASS.
---

# Requirements Phase Skill

Fully owns the **requirements phase** for a change package. Runnable standalone or when invoked by lifecycle-loop.

## Required inputs

- `package_id` (e.g. `FEAT-001`) from user or `.ai/packages/<id>/package.yaml`
- Feature description, constraints, stakeholders from user
- Read `.ai/config/profiles.yaml` for `human_gates` (standard profile: human gate at requirements)

If `package.yaml` does not exist and user did not run `/loop start`, create artifact folder only or ask user to run `/loop start <id>` first.

## Step 1: Generate

Create or revise files under `artifacts/<package_id>/01-requirements/`:

| File | Content |
|------|---------|
| `PRD.md` | Problem, Goals, Non-goals, Users, Scope, Constraints, Assumptions, Risks |
| `user-stories.md` | Stories as `US-001: As a … I want … So that …` |
| `acceptance-criteria.md` | `AC-001` with Given/When/Then, linked to US-IDs |
| `open-questions.md` | Unresolved questions |
| `out-of-scope.md` | Explicit exclusions |
| `risk-list.md` | Risks with mitigation |

### Frontmatter (every artifact file)

```yaml
---
artifact_id: REQ-001-prd
artifact_type: requirement
package_id: FEAT-001
version: v1
status: draft
owner: ""
created_at: YYYY-MM-DD
traces: []
related: []
---
```

## Step 2: Self Review

Write `artifacts/<package_id>/01-requirements/review-log.md`:

```markdown
# Self Review — Requirements ({package_id})

| Check | Result | Note |
|-------|--------|------|
| Clear user value | pass/fail | Problem names user and pain |
| Testable AC | pass/fail | Every AC has measurable outcome |
| No ambiguity | pass/fail | No vague terms without definition |
| Boundaries defined | pass/fail | out-of-scope.md non-empty |
| Acceptance criteria exist | pass/fail | ≥ 1 AC per user story |
| Risks identified | pass/fail | ≥ 1 risk with mitigation |

**Blocking failures:** <count>
**Recommendation:** <action if blocking > 0>
```

Fix blocking failures before proceeding.

## Step 3: Human Review

If `requirements` is in `human_gates` for active profile (standard: **yes**):

1. Keep `status: draft` on artifacts; present summary to user.
2. Wait for explicit approval.
3. Set `status: approved` on `PRD.md` and `acceptance-criteria.md` frontmatter.
4. Optionally add `approval.md` with approver name and date.

If not in `human_gates`: set `status: reviewed` on artifacts.

## Step 4: Archive

1. Bump `version` in frontmatter if this is a revision (v1 → v2).
2. Update `.ai/packages/<package_id>/package.yaml`:
   ```yaml
   phases:
     requirements:
       status: archived
       artifact_version: v1
   ```
3. Load `.ai/skills/traceability/SKILL.md` and seed matrix rows from AC IDs.
4. **Do not** write gate PASS — lifecycle-loop owns L2.

## Quality criteria

- PRD is review-ready, not a bullet outline
- Every user story has ≥ 1 testable acceptance criterion
- Out-of-scope is explicit (reduces scope creep)
- Open questions are honest (not hidden assumptions)

## Anti-patterns

- Vague AC: "System should be fast" → define metric
- Missing non-goals → scope creep in design
- User stories without persona → untestable requirements

See `reference.md` for output templates and examples.
