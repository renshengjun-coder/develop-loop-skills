# Devloop Packaging & Installation — Design Spec

**Status:** Approved (brainstorming)
**Date:** 2026-06-12
**Related:** `docs/superpowers/specs/2026-06-12-develop-loop-skills-design.md`

## 1. Purpose

Make the Develop Loop skill ecosystem **easy to install and use** in two layers:

1. **User/system-level** — install once per machine; skills available in Cursor, Codex, and Claude Code across all projects.
2. **Project-level** — initialize once per repository (new or existing); scaffold config, scripts, and artifact directories so `/devloop` can run.

**User journey (target):**

```text
devloop install --global     # once per machine
cd my-app && devloop init    # once per project
/devloop start FEAT-001      # start working
```

## 2. Design principles

| Principle | Rationale |
|-----------|-----------|
| **Global = behavior** | SKILL.md definitions teach the agent SDLC orchestration, phase skills, and traceability rules. |
| **Project = state** | Packages, artifacts, gates, trace matrix, CI, and customizable `profiles.yaml` live in the repo. |
| **Self-contained global skills** | Global install copies **full** skill content — not pointers to `.ai/skills/` (that path does not exist in arbitrary projects). |
| **Explicit project init** | `devloop init` is idempotent and predictable; no hidden scaffold on first `/devloop start`. |
| **Templates bundled in package** | Profiles, package template, `AGENTS.md`, and verify scripts ship inside the distributable package and copy on `init`. |
| **Source of truth in this repo** | `.ai/skills/` remains the authoring source; `pack/` is built for distribution at release time. |

## 3. Architecture

```text
┌─────────────────────────────────────────────────────────┐
│  develop-loop-skills package (this repo)                │
│  pack/                                                    │
│    skills/          ← self-contained SKILL.md (9 skills) │
│    templates/       ← profiles, package template, CI     │
│  bin/devloop          ← install | init | upgrade | doctor │
└─────────────────────────────────────────────────────────┘
         │ install --global              │ init (per project)
         ▼                               ▼
┌──────────────────────┐       ┌──────────────────────────────┐
│ User-level skills    │       │ Project-level scaffold        │
│ ~/.cursor/skills/    │       │ .ai/config/                   │
│ ~/.claude/skills/    │       │ .ai/packages/_template/       │
│ ~/.codex/…           │       │ scripts/loop-verify.sh        │
└──────────────────────┘       │ AGENTS.md                     │
                                 │ artifacts/ traceability/      │
                                 │ .devloop-version (pin)        │
                                 │ optional .github/workflows/   │
                                 └──────────────────────────────┘
```

### 3.1 Skill inventory (distributed)

| Skill | Role |
|-------|------|
| `lifecycle-loop` | Orchestrator — `/devloop start\|run\|gate\|status\|classify` |
| `01-requirement` … `07-release-retro` | Phase skills (L1) |
| `traceability` | Trace matrix helper |

All nine skills are installed globally and referenced by project `AGENTS.md` / Cursor rules.

### 3.2 What stays project-local only

- `.ai/packages/<id>/` — change package manifests, gates, classification
- `artifacts/<id>/` — SDLC evidence (PRD, design, plans, review logs)
- `traceability/<id>/` — requirement-to-code matrix
- Application source code (`src/`, `lib/`, `tests/`, etc.) — normal repo paths; linked via `changed-files.md` and trace matrix

Demo packages (`FEAT-001`, `FEAT-003`, etc.) remain in the **skills repo** for documentation; `devloop init` does not copy them.

## 4. Distribution approach

**Primary:** Shell CLI (`bin/devloop`) + release tarball from this repository.

**Secondary:** npm package (`@org/devloop-skills`) wrapping the same `pack/` payload for `npx devloop init`.

| Approach | Verdict |
|----------|---------|
| **A. Shell installer + tarball** | **Primary** — no Node requirement, works in any repo |
| **B. npm package** | **Secondary** — semver and `npx` for JS-heavy teams |
| **C. Git submodule / manual copy** | **Rejected** — poor UX, hard to upgrade |

### 4.1 CLI commands

| Command | Scope | Behavior |
|---------|-------|----------|
| `devloop install --global` | User | Copy `pack/skills/` to runtime user skill directories |
| `devloop install --global --upgrade` | User | Refresh global skills to current package version |
| `devloop install --global --runtimes cursor,claude,codex` | User | Limit targets; default: all detected |
| `devloop init` | Project | Scaffold project files; skip existing paths |
| `devloop init --with-ci` | Project | Also add `.github/workflows/loop-verify.yml` |
| `devloop init --upgrade` | Project | Refresh templates and scripts; never touch packages/artifacts/traceability |
| `devloop init --force` | Project | Overwrite template files (with confirmation) |
| `devloop doctor` | Both | Verify global skills, project scaffold, verify script executable |

### 4.2 Build step

`scripts/build-pack.sh` (release CI):

1. Copy `.ai/skills/**` → `pack/skills/` with stable directory names (`lifecycle-loop`, `01-requirement`, …).
2. Expand any pointer-only `.cursor/skills/` stubs into full skill bodies in `pack/skills/`.
3. Copy templates: `profiles.yaml`, `_template/`, `AGENTS.md`, workflow YAML → `pack/templates/`.
4. Stamp version into `pack/VERSION`.

## 5. Install targets per runtime

| Runtime | Global (`devloop install --global`) | Project (`devloop init`) |
|---------|-------------------------------------|---------------------------|
| **Cursor** | `~/.cursor/skills/<name>/SKILL.md` | Optional `.cursor/rules/devloop.mdc` — short pointer: use `/devloop`, read `AGENTS.md`. Skip `.cursor/skills/` duplicates when global skills detected. |
| **Claude Code** | `~/.claude/skills/<name>/SKILL.md` | Project `AGENTS.md` from template |
| **Codex** | User-level skills path or append block to `~/.codex/AGENTS.md` per Codex convention at ship time | Project root `AGENTS.md` |

`devloop doctor` reports missing global skills, uninitialized project, or version mismatch between `.devloop-version` and installed package.

## 6. `devloop init` — file manifest

**Creates when absent (never overwrites without `--force` or `--upgrade` on template paths):**

| Path | Purpose |
|------|---------|
| `.ai/config/profiles.yaml` | Workflow profiles (`routine`, `standard`, `high_risk`) |
| `.ai/packages/_template/package.yaml` | New change package template |
| `.ai/packages/_template/classification.yaml` | Classification template |
| `scripts/loop-verify.sh` | L3 structural verifier |
| `scripts/test-loop-verify.sh` | Verify script self-test (optional) |
| `AGENTS.md` | Codex / generic agent skill table and state paths |
| `artifacts/.gitkeep` | Artifact root |
| `traceability/.gitkeep` | Trace matrix root |
| `.devloop-version` | Pinned distributable version (e.g. `0.2.0`) |

**Optional (`--with-ci`):**

| Path | Purpose |
|------|---------|
| `.github/workflows/loop-verify.yml` | PR structural checks |

### 6.1 Merge behavior

- If `AGENTS.md` already exists, **merge** the Develop Loop section (skill table + state paths) instead of replacing the file.
- `--upgrade` refreshes: `profiles.yaml`, `_template/`, verify scripts, workflow YAML, `.devloop-version`. Does **not** modify `.ai/packages/<id>/`, `artifacts/<id>/`, or `traceability/<id>/`.

### 6.2 Idempotency

Running `devloop init` multiple times is safe. Output summarizes created, skipped, and upgraded paths.

## 7. Versioning

- **Global skills:** updated via `devloop install --global --upgrade`; no per-project pin required for skills to function.
- **Project templates:** pinned in `.devloop-version`; `devloop init --upgrade` aligns templates with a newer package release.
- **Semver:** breaking changes to gate file format or `profiles.yaml` schema bump major; document in `CHANGELOG.md`.
- **v1:** no automatic migration of existing gate files; manual re-run or documented migration steps only.

## 8. Repository layout (this package)

```text
develop-loop-skills/
  .ai/skills/              # authoring source of truth (unchanged)
  pack/                    # built distributable (gitignored or committed at release)
    skills/
    templates/
    VERSION
  bin/devloop
  scripts/build-pack.sh
  package.json             # optional npm metadata
```

The skills development repo may continue to use `.ai/skills/` + `.cursor/skills/` pointers for dogfooding; the **distributable** uses `pack/skills/` only.

## 9. Success criteria

1. New user can run `devloop install --global` then `devloop init` in an empty repo and invoke `/devloop start FEAT-001` with a working scaffold.
2. Existing repo with code but no devloop can run `devloop init` without clobbering application source or existing `AGENTS.md` content.
3. `devloop doctor` passes on a correctly initialized project.
4. Global skills work in Cursor, Claude Code, and Codex without project-level skill duplicates.
5. `./scripts/loop-verify.sh --enforce <id>` runs after init with no manual file copying.

## 10. Out of scope (v1)

- Cursor Marketplace / plugin distribution
- Native Windows installer (document WSL / Git Bash)
- Monorepo multi-root init
- Remote skill registry or auto-update daemon
- Renaming `loop-verify.sh` to `devloop-verify.sh` (may follow in a separate change)

## 11. Implementation handoff

Next step: invoke **writing-plans** skill to produce an implementation plan for `bin/devloop`, `pack/` build, README install guide, and CI for release artifacts.
