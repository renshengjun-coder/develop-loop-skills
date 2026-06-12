---
name: 04-implementation
description: >-
  Plans and executes approved design within scope. Produces implementation plan,
  changed-files manifest, and coding log. Use for implementation phase, coding,
  build feature, implement design — standalone or via /loop. Does not issue
  final gate PASS.
---

# Implementation Phase Skill

Fully owns the **implementation phase**. Runnable standalone or when invoked by lifecycle-loop.

## Required inputs

- `package_id`
- Read `artifacts/<package_id>/01-requirements/acceptance-criteria.md` — this is the scope boundary
- Read `artifacts/<package_id>/02-design/` — architecture and API design, required when the design phase is archived
- Read `artifacts/<package_id>/03-test-plan/test-cases.md` — tests to add and run, required when the test-plan phase is archived
- Read `.ai/packages/<package_id>/package.yaml` and `.ai/config/profiles.yaml` — determine the active profile and **do not proceed** unless every upstream phase listed for that profile is `archived`

For the `routine` profile, requirements must be `archived`; design and test-plan may be skipped and must not be treated as missing inputs. Use acceptance criteria as the implementation and test boundary when those phases are skipped.

## Step 1: Plan

Create or revise files under `artifacts/<package_id>/04-implementation/`:

| File | Content |
|------|---------|
| `implementation-plan.md` | Tasks mapped to AC IDs, file touch list, test plan, rollback approach |
| `changed-files.md` | Every repository path touched, change type (`add`/`modify`/`delete`), and AC/design reference |
| `coding-log.md` | Chronological entries with date, files, summary, test commands, and results |
| `assumptions.md` | Deviations from design or, for routine work, assumptions made without design; include rationale |

Write `implementation-plan.md` before changing repository code. Keep every planned task within approved acceptance criteria and archived design, when present.

### Frontmatter on generated implementation artifacts

```yaml
---
artifact_id: IMPL-001-plan
artifact_type: implementation
package_id: FEAT-003
version: v1
status: draft
traces:
  - implements: "artifacts/FEAT-003/02-design/architecture.md@v1"
  - satisfies: "AC-001"
related: []
---
```

Use this frontmatter on `implementation-plan.md`, `changed-files.md`, `coding-log.md`, and `assumptions.md`; `review-log.md` follows the existing phase review-log format and does not require frontmatter. Use the appropriate artifact ID and traces for each generated implementation artifact. Omit `implements` only when the active profile skipped design; each generated implementation artifact must include at least one `satisfies` trace.

## Step 2: Execute Code and Record Evidence

After writing `implementation-plan.md`:

1. Execute the planned repository changes. When code is in scope, implement the actual code; otherwise perform the approved tests, documentation, configuration, or other implementation work.
2. Add or update tests for changed behavior and design failure paths when applicable.
3. Update `changed-files.md` with every actual repository path touched, including source, tests, documentation, configuration, generated files, and other changed paths; remove paths that were planned but not changed.
4. Record each meaningful implementation step in `coding-log.md`, including files changed and a concise summary.
5. Run the planned tests and relevant repository checks; record every command, result, and unresolved failure in `coding-log.md`.
6. Record any deviation or newly discovered assumption in `assumptions.md` before self-review.

Do not claim implementation complete when planned repository changes were not executed, any touched repository path is absent from `changed-files.md`, or evidence for applicable tests and checks is missing from `coding-log.md`. A valid no-code, documentation-only, or configuration-only routine implementation may complete when its applicable checks were run and the rationale for non-applicable code, test, design, or error-handling checks is recorded in `coding-log.md` and `review-log.md`.

## Step 3: Self Review

Write `artifacts/<package_id>/04-implementation/review-log.md`:

```markdown
# Self Review — Implementation ({package_id})

| Check | Result | Note |
|-------|--------|------|
| Approved scope only | pass/fail | Every changed file maps to an AC or approved design section |
| Design conformance | pass/fail | No undocumented API/schema changes |
| Tests present | pass/fail | New or changed behavior has tests, or non-applicability has rationale |
| Error handling | pass/fail | Applicable failure paths are addressed, or non-applicability has rationale |
| Traceability | pass/fail | changed-files.md lists every touched repository path |

**Blocking failures:** <count>
**Recommendation:** <action if blocking > 0>
```

Fix blocking failures before proceeding. For `routine`, evaluate design conformance against acceptance criteria and document applicable assumptions because design may be skipped. For valid no-code, documentation-only, or configuration-only work, a check may pass as not applicable only when its rationale is recorded in the Note column.

## Step 4: Human Review

Read the active profile's `human_gates` in `.ai/config/profiles.yaml`.

If `implementation` is included, keep artifact `status: draft`, present the implementation summary and review log, wait for explicit approval, then set artifact `status: approved`.

If `implementation` is not included, set artifact `status: reviewed`. No Phase 2 profile includes an implementation human gate, so this is the normal AI-review path.

## Step 5: Archive

1. Bump `version` in frontmatter if this is a revision.
2. Update `.ai/packages/<package_id>/package.yaml` → `phases.implementation.status: archived`, `artifact_version: v<n>`.
3. Load `.ai/skills/traceability/SKILL.md` and fill the matrix **Code File(s)** column from `changed-files.md`.
4. **Do not** write gate PASS — lifecycle-loop owns L2.

## Quality criteria

- Implementation changes only approved scope and maps every touched repository path to an AC or approved design section
- When code, API, or schema changes are applicable, they conform to archived design decisions; deviations are explicit in `assumptions.md`
- New and changed behavior has relevant unit or integration tests; non-applicable tests and checks have recorded rationale
- `coding-log.md` contains reproducible commands and honest results for applicable tests and checks
- `changed-files.md` is an accurate manifest of every touched repository path
- Self-review has zero blocking failures before archive

See `reference.md` for changed-files and coding-log examples.
