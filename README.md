# develop-loop-skills

AI-native SDLC loop skills for Cursor, Codex, and Claude Code.

## Overview

Develop Loop turns coding agents into **engineering process executors** — producing reviewable, versioned, traceable artifacts across the full SDLC.

If you are adopting Develop Loop in an application repo, start with **Install (consumers)** and **Use (in your project)** below. The maintainer packaging notes are included later for contributors to this framework itself.

The skill set is distributed in **two layers**:

| Layer | What | Where |
|-------|------|-------|
| **Global skills** | Agent behavior — orchestrator + 7 phase skills + traceability | `~/.cursor/skills/`, `~/.claude/skills/`, `~/.codex/AGENTS.md` |
| **Project scaffold** | Repo state — config, templates, verify scripts, artifact dirs | `.ai/`, `artifacts/`, `traceability/`, `AGENTS.md` |

Phase evidence such as PRDs, design docs, review logs, and release notes lives in `artifacts/`. Gate records live in `.ai/packages/<id>/gates/`. Package-level traceability evidence lives in `traceability/`. Application code stays in your normal repo paths (`src/`, `tests/`, etc.) and is linked via `changed-files.md` and the trace matrix.

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
    devloop/
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

If you installed from a local git clone, rebuild the generated `pack/` before upgrading so the global install picks up the latest skill sources:

```bash
git pull
./scripts/build-pack.sh
./bin/devloop install --global --upgrade
cd /path/to/my-app
/path/to/develop-loop-skills/bin/devloop init --upgrade
/path/to/develop-loop-skills/bin/devloop doctor
```

If you installed via npm, use the published CLI directly:

```bash
devloop install --global --upgrade   # refresh global skills
devloop init --upgrade               # refresh template-managed project files
```

`devloop init --upgrade` updates scaffolded files such as:
- `.ai/config/profiles.yaml`
- `.ai/packages/_template/package.yaml`
- `scripts/loop-verify.sh`
- `.cursor/rules/devloop.mdc`
- `.devloop-version`
- the Develop Loop block inside `AGENTS.md`

It does **not** rewrite package-specific working evidence under `.ai/packages/<id>/`, `artifacts/<id>/`, or `traceability/<id>/`.

After upgrading from a release that used `lifecycle-loop`, remove stale global skill dirs manually:

```bash
rm -rf ~/.cursor/skills/lifecycle-loop ~/.claude/skills/lifecycle-loop
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

Important: standalone phase skills create or update phase artifacts, but they do **not** issue a final pass decision on their own. The authoritative L2 gate record is written by `/devloop run` or `/devloop gate`.

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

### How Develop Loop enforces quality

Develop Loop does not try to guarantee quality with a single check. It uses a 3-level loop so both humans and automation can inspect the same evidence:

| Level | Owner | What it checks | Typical evidence |
|-------|-------|----------------|------------------|
| L1 | Phase skill | Phase-local completeness and self-review | `review-log.md` plus phase artifacts |
| L2 | `/devloop` orchestrator | Whether a phase is allowed to advance | `.ai/packages/<id>/gates/<phase>-<n>.md` |
| L3 | `loop-verify.sh` + `.ai/contracts/evidence-policy.yaml` | Whether the recorded evidence is structurally valid and CI-safe | package files, gate bindings, traceability files, parent-child release bindings |

In practice, this means the framework helps guarantee:
- each archived phase has a defined evidence set for the active profile
- gate records bind the exact artifact paths used for the decision
- traceability evidence exists at the package level, not only inside phase folders
- higher-risk work uses more human checkpoints than routine work
- CI can independently reject missing or inconsistent evidence even if a phase looked complete locally

It does **not** automatically guarantee business correctness, good product decisions, or runtime behavior by itself. L3 is a structural quality door, not a substitute for thoughtful requirements, real tests, or human review.

### How to review design quality

If the active profile includes `design`, the clearest review flow is:

1. Open `traceability/<id>/package-evidence-index.md` to see current readiness, latest gates, and links.
2. Review `artifacts/<id>/02-design/architecture.md` and `artifacts/<id>/02-design/review-log.md`.
3. Open `.ai/packages/<id>/gates/design-<n>.md` and confirm the design gate passed with the expected `artifacts_checked`, findings, and approvals.
4. Check `traceability/<id>/matrix.md` to confirm acceptance criteria map into the design sections you just reviewed.
5. Run `/devloop status <id>` or `./scripts/loop-verify.sh --enforce <id>` if you want an up-to-date package-level quality view.

### How to review implementation quality

For implementation quality, use the same package-first approach but inspect the later phases:

1. Start at `traceability/<id>/package-evidence-index.md`.
2. Review `artifacts/<id>/04-implementation/implementation-plan.md`, `changed-files.md`, `coding-log.md`, and that phase's `review-log.md`.
3. Review `.ai/packages/<id>/gates/implementation-<n>.md`, then the latest `code-review` and `test-report` gates.
4. Use `traceability/<id>/matrix.md` to verify AC → design → test → code links are still intact after implementation.
5. Run `./scripts/loop-verify.sh <id>` for a normal package check or `./scripts/loop-verify.sh --enforce <id>` for CI-level strictness.

The key idea is that you should not judge implementation quality from code alone. Develop Loop expects reviewers to check the linked evidence chain: requirements, design, changed scope, review findings, validation results, and final gate posture.

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
- **Parent-child packages:** orchestration in devloop
- **Packaging CLI:** `bin/devloop` (global install + project init)
- **CI enforce mode:** `--enforce` flag on `loop-verify.sh`

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

Primary human audit entry point per package: `traceability/<id>/package-evidence-index.md`. The trace matrix remains the detailed AC-to-evidence map, while the package evidence index summarizes readiness, latest gates, approvals, waivers, and linked evidence in one place.

Human-readable package evidence is contract-defined in `.ai/contracts/evidence-policy.yaml`. The current policy requires both `matrix.md` and `package-evidence-index.md`, requires those files to appear in each archived gate's `artifacts_checked` list, and treats missing human-readable package evidence as an error.

Parent-child release verification is also policy-driven. For parents with children, the current policy requires bindings to the child package manifest, the child gate for the child's current archived phase, the child package evidence index, and a readable `child_evidence` block that records `status`, `package`, `latest_gate`, and `evidence_index`.

For human review, start at `traceability/<id>/package-evidence-index.md` and follow its links into `matrix.md`, gates, and phase artifacts as needed.

CI runs `loop-verify` in **enforce mode** on pull requests when branch protection is configured (`docs/ci/branch-protection.md`).
