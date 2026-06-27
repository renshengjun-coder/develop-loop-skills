# develop-loop-skills

AI-native SDLC loop skills for Cursor, Codex, and Claude Code.

## Overview

Develop Loop turns coding agents into **engineering process executors** — producing reviewable, versioned, traceable artifacts across the full SDLC.

The skill set is distributed in **two layers**:

| Layer | What | Where |
|-------|------|-------|
| **Global skills** | Agent behavior — orchestrator + 7 phase skills + traceability | `~/.cursor/skills/`, `~/.claude/skills/`, `~/.codex/AGENTS.md` |
| **Project scaffold** | Repo state — config, templates, verify scripts, artifact dirs | `.ai/`, `artifacts/`, `traceability/`, `AGENTS.md` |

Process evidence (PRD, design, gates) lives in `artifacts/`. Application code stays in your normal repo paths (`src/`, `tests/`, etc.) and is linked via `changed-files.md` and the trace matrix.

---

## Package (maintainers)

The distributable is built from this repo into `pack/` (gitignored). It is **not** committed — consumers get it via `devloop` CLI or npm.

### Build the pack

```bash
./scripts/build-pack.sh
```

Produces:

```text
pack/
  VERSION                 # e.g. 0.3.0 (from repo VERSION file)
  skills/                 # 9 self-contained SKILL.md trees
    lifecycle-loop/
    01-requirement/ … 07-release-retro/
    traceability/
  templates/              # copied into target projects by devloop init
    .ai/config/profiles.yaml
    .ai/packages/_template/package.yaml
    .ai/packages/_template/classification.yaml
    scripts/loop-verify.sh
    scripts/test-loop-verify.sh
    artifacts/.gitkeep
    traceability/.gitkeep
    AGENTS.md
    .cursor/rules/devloop.mdc
    .devloop-version
    .github/workflows/loop-verify.yml  (added to projects only via init --with-ci)
```

Source of truth for skills remains `.ai/skills/` in this repo. `build-pack.sh` copies them into `pack/skills/` for distribution.

### Verify the pack

```bash
./scripts/test-build-pack.sh      # layout: 9 skills + templates
./scripts/test-devloop-cli.sh     # install + init + doctor in temp dirs
./scripts/test-loop-verify.sh     # L3 verifier regression
```

Or run all via npm:

```bash
npm test
```

### CI

Two GitHub Actions workflows guard this repo:

| Workflow | Trigger | What it runs |
|----------|---------|--------------|
| `.github/workflows/build-pack.yml` | PRs/pushes touching `.ai/`, `bin/`, `templates/`, `VERSION`, or build scripts | `test-build-pack.sh` + `test-devloop-cli.sh` (pack layout + CLI install/init/doctor) |
| `.github/workflows/loop-verify.yml` | Pull requests | `loop-verify` in **enforce mode** (L3 contract checks) |

### Release checklist

1. Bump `VERSION` (and `package.json` `version` to match).
2. Run `npm test`.
3. Tag and publish (tarball from repo clone, or `npm publish` when configured).

Design: `docs/superpowers/specs/2026-06-12-devloop-packaging-design.md`

---

## Install (consumers)

### Option A — from a git clone (recommended today)

```bash
git clone https://github.com/renshengjun-coder/develop-loop-skills.git
cd develop-loop-skills

# 1. Global skills (once per machine)
./bin/devloop install --global

# 2. Project scaffold (once per app repo)
cd /path/to/my-app
/path/to/develop-loop-skills/bin/devloop init
# optional CI workflow:
/path/to/develop-loop-skills/bin/devloop init --with-ci

# 3. Verify
/path/to/develop-loop-skills/bin/devloop doctor
```

`bin/devloop` runs `build-pack.sh` automatically if `pack/` is missing.

### Option B — npm (when published)

```bash
npm i -g @develop-loop/skills
devloop install --global
cd my-app && devloop init --with-ci
devloop doctor
```

### Install targets per runtime

| Runtime | Global (`devloop install --global`) | Project (`devloop init`) |
|---------|-------------------------------------|---------------------------|
| **Cursor** | `~/.cursor/skills/<skill>/SKILL.md` | `.cursor/rules/devloop.mdc`, merged `AGENTS.md` |
| **Claude Code** | `~/.claude/skills/<skill>/SKILL.md` | merged `AGENTS.md` |
| **Codex** | Develop Loop block in `~/.codex/AGENTS.md` | merged `AGENTS.md` |

Limit runtimes: `devloop install --global --runtimes cursor,claude`

### Upgrade

```bash
devloop install --global --upgrade   # refresh global skills
devloop init --upgrade               # refresh project templates (never touches artifacts/ or packages/<id>/)
```

### `devloop` CLI reference

| Command | Description |
|---------|-------------|
| `devloop install --global` | Copy 9 skills to user-level agent dirs |
| `devloop install --global --upgrade` | Overwrite global skills with current pack version |
| `devloop install --global --runtimes cursor,claude,codex` | Limit install targets |
| `devloop init` | Scaffold project (idempotent; skips existing files) |
| `devloop init --with-ci` | Also add `.github/workflows/loop-verify.yml` |
| `devloop init --upgrade` | Refresh templates and verify scripts |
| `devloop init --force` | Overwrite template files (prompts for confirmation) |
| `devloop doctor` | Check global skills + project scaffold |

---

## Use (in your project)

After **global install** + **project init**, open your app repo in Cursor, Claude Code, or Codex.

### Quick start

```text
/devloop start FEAT-001          # create package, classify, pick profile
/devloop run FEAT-001            # start E2E loop; pauses at human checkpoints
/devloop continue FEAT-001       # resume from the last checkpoint or stop
/devloop status FEAT-001         # package status, blockers, run_control
```

### Agent slash commands

Orchestrator: **`/devloop`** (not `/loop` — avoids Cursor built-in collision).

| Command | Description |
|---------|-------------|
| `/devloop start <id>` | Create package from template, classify, select profile |
| `/devloop run <id>` | E2E orchestration (loop mode; pauses after human-gate checkpoints) |
| `/devloop continue <id>` | Resume from a checkpoint, gate-fail stop, escalation stop, error stop, or interrupted run |
| `/devloop run <id> --pipeline` | Single pass per phase; stop on first gate fail |
| `/devloop gate <id> <phase>` | L2 gate check for one phase |
| `/devloop status <id>` | Summarize package, gates, blockers, and `run_control` |
| `/devloop classify <id>` | Re-run or confirm complexity classification |

### Standalone phase skills

You do not need `/devloop run` for every task. Invoke phase skills directly, e.g.:

- Requirements — PRD, user stories, acceptance criteria
- Design — architecture, API design
- Test plan — test strategy, test cases
- Implementation — plan, code, `changed-files.md`
- Code review — AI review artifacts
- Test report — execution summary, coverage
- Release & retro — release notes, retro

Each phase writes to `artifacts/<id>/<phase-folder>/` and updates `.ai/packages/<id>/package.yaml`.

### Where things live

| What | Path |
|------|------|
| Change package manifest | `.ai/packages/<id>/package.yaml` |
| Run control state | `.ai/packages/<id>/package.yaml` → `run_control` |
| Gate decisions (L2) | `.ai/packages/<id>/gates/` |
| SDLC artifacts | `artifacts/<id>/` |
| Trace matrix | `traceability/<id>/matrix.md` |
| Workflow profiles | `.ai/config/profiles.yaml` |
| Application code | Normal repo paths (`src/`, `lib/`, `tests/`, …) |

### Example walkthroughs

| Package | Scope |
|---------|-------|
| FEAT-001 | MVP 3-phase (requirements → design → test-plan) |
| FEAT-003 | Full 7-phase with code in trace matrix |
| FEAT-PARENT / FEAT-CHILD | Parent-child release gate demo |

See `docs/examples/FEAT-001-walkthrough.md`, `docs/examples/FEAT-003-walkthrough.md`, `docs/examples/parent-child-walkthrough.md`.

---

## Developing this repo

This repository **dogfoods** the skills differently from consumer projects:

- **Authoring:** `.ai/skills/` (source of truth)
- **Cursor pointers:** `.cursor/skills/` (thin stubs → `.ai/skills/`)
- **Demos:** `FEAT-001`, `FEAT-003`, etc. ship here for docs; `devloop init` does **not** copy them

To work on skills here, edit `.ai/skills/` and use the pointer layout under `.cursor/skills/`. Run `./scripts/build-pack.sh` before testing the distributable CLI.

---

## Shipped features

- **7 phase skills:** requirements through release-retro
- **3 profiles:** `routine`, `standard`, `high_risk`
- **Parent-child packages:** orchestration in lifecycle-loop
- **Packaging CLI:** `bin/devloop` (global install + project init)
- **CI enforce mode:** `--enforce` flag on `loop-verify.sh`

## 3-level quality model

| Level | Owner | Evidence |
|-------|-------|----------|
| L1 | Phase skills | `review-log.md` self-check |
| L2 | Lifecycle loop | `gates/<phase>-<n>.md` |
| L3 | `loop-verify.sh` + `.ai/contracts/evidence-policy.yaml` | Contract-driven structural checks for package, traceability, and gate evidence (CI) |

Primary human audit entry point per package: `traceability/<id>/package-evidence-index.md`. The trace matrix remains the detailed AC-to-evidence map, while the package evidence index summarizes readiness, latest gates, approvals, waivers, and linked evidence in one place.

Human-readable package evidence is now contract-defined in `.ai/contracts/evidence-policy.yaml`. The current policy requires both `matrix.md` and `package-evidence-index.md`, requires those files to appear in each archived gate's `artifacts_checked` list, and sets compatibility posture to `when_missing: error` for the `human_readable_evidence` section.

Parent-child release verification is also policy-driven. The current policy enables a light release binding set for parents with children: child package manifest, the child gate for the package's current archived phase, child package evidence index, and a `child_evidence` block that records `status`, `package`, `latest_gate`, and `evidence_index`. Those fields must agree with each other, so a child bound to `gates/release-*.md` should also report a release-ready child status rather than a merge-ready one.

## Directory layout (consumer project after `devloop init`)

```text
.ai/
  config/profiles.yaml
  packages/<id>/
artifacts/<id>/
traceability/<id>/
scripts/loop-verify.sh
AGENTS.md
.devloop-version
```

Full SDLC design: `docs/superpowers/specs/2026-06-12-develop-loop-skills-design.md`

## Verify locally (L3)

```bash
./scripts/loop-verify.sh FEAT-001
./scripts/loop-verify.sh --enforce FEAT-003
./scripts/test-loop-verify.sh
```

For human review, start at `traceability/<id>/package-evidence-index.md` and follow its links into `matrix.md`, gates, and phase artifacts as needed.

CI runs `loop-verify` in **enforce mode** on pull requests when branch protection is configured (`docs/ci/branch-protection.md`).
