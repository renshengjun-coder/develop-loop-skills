# develop-loop-skills

AI-native SDLC loop skills for Cursor, Codex, and Claude Code.

## Overview

Develop Loop turns coding agents into **engineering process executors** — producing reviewable, versioned, traceable artifacts across the full SDLC.

## Install

Copy or symlink `.ai/skills/` into your target project. For Cursor, also copy pointer skills from `.cursor/skills/`.

| Runtime | Path |
|---------|------|
| Cursor | `.cursor/skills/` (pointers to `.ai/skills/`) |
| Codex | Read `AGENTS.md` in project root |
| Claude Code | `.claude/skills/` |

## Commands

| Command | Description |
|---------|-------------|
| `/loop start <id>` | Create package, classify, select profile |
| `/loop run <id>` | E2E orchestration (loop mode) |
| `/loop run <id> --pipeline` | Single pass per phase |
| `/loop gate <id> <phase>` | L2 gate check for one phase |
| `/loop status <id>` | Package status and blockers |

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
scripts/loop-verify.sh
```

See `docs/superpowers/specs/2026-06-12-develop-loop-skills-design.md` for full design.

## Verify locally (L3)

```bash
./scripts/loop-verify.sh FEAT-001
./scripts/loop-verify.sh --enforce FEAT-003
./scripts/test-loop-verify.sh
```

CI runs `loop-verify` in **enforce mode** on pull requests (blocks merge when branch protection is configured).
