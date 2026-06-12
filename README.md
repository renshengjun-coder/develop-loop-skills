# develop-loop-skills

AI-native SDLC loop skills for Cursor, Codex, and Claude Code.

## Overview

Develop Loop turns coding agents into **engineering process executors** — producing reviewable, versioned, traceable artifacts across the full SDLC.

## Install

### 1. Global skills (once per machine)

From a clone of this repo (or after `npm i -g @develop-loop/skills`):

```bash
./scripts/build-pack.sh   # auto-run by bin/devloop if pack/ missing
./bin/devloop install --global
```

Installs 9 skills to `~/.cursor/skills/`, `~/.claude/skills/`, and a Develop Loop block in `~/.codex/AGENTS.md`.

### 2. Project scaffold (once per repo)

In your application repository (new or existing):

```bash
/path/to/develop-loop-skills/bin/devloop init
# optional: devloop init --with-ci
```

Creates `.ai/config/`, package template, `scripts/loop-verify.sh`, `AGENTS.md`, `artifacts/`, `traceability/`.

### 3. Verify

```bash
devloop doctor
```

### Upgrade

```bash
devloop install --global --upgrade
devloop init --upgrade
```

**Developing this repo** still uses `.ai/skills/` as source of truth and `.cursor/skills/` as thin pointers for dogfooding.

## Commands

Orchestrator slash command: **`/devloop`** (avoids collision with agent built-ins like Cursor's `/loop`).

| Command | Description |
|---------|-------------|
| `/devloop start <id>` | Create package, classify, select profile |
| `/devloop run <id>` | E2E orchestration (loop mode) |
| `/devloop run <id> --pipeline` | Single pass per phase |
| `/devloop gate <id> <phase>` | L2 gate check for one phase |
| `/devloop status <id>` | Package status and blockers |
| `/devloop classify <id>` | Re-run or confirm complexity classification |

All 7 phase skills are invokable **standalone** without the loop.

## Shipped (Phase 2)

- **7 phase skills:** requirements through release-retro
- **3 profiles:** `routine`, `standard`, `high_risk`
- **Parent-child packages:** orchestration in lifecycle-loop
- **CI enforce mode:** `--enforce` flag on `loop-verify.sh`

## Demo packages

| Package | Scope |
|---------|-------|
| FEAT-001 | MVP 3-phase (requirements → design → test-plan) |
| FEAT-003 | Full 7-phase with code in trace matrix |
| FEAT-PARENT / FEAT-CHILD | Parent-child release gate demo |

Walkthroughs: `docs/examples/FEAT-001-walkthrough.md`, `docs/examples/FEAT-003-walkthrough.md`, `docs/examples/parent-child-walkthrough.md`

## 3-level quality model

| Level | Owner | Evidence |
|-------|-------|----------|
| L1 | Phase skills | `review-log.md` self-check |
| L2 | Lifecycle loop | `gates/<phase>-<n>.md` |
| L3 | `loop-verify.sh` | Structural file checks (CI) |

## Directory layout

```text
.ai/
  config/profiles.yaml
  packages/<id>/
  skills/
artifacts/<id>/
traceability/<id>/
scripts/devloop-verify.sh
```

See `docs/superpowers/specs/2026-06-12-develop-loop-skills-design.md` for full design.

## Verify locally (L3)

```bash
./scripts/loop-verify.sh FEAT-001
./scripts/loop-verify.sh --enforce FEAT-003
./scripts/test-loop-verify.sh
```

CI runs `loop-verify` in **enforce mode** on pull requests (blocks merge when branch protection is configured).
