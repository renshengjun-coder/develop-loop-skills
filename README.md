# develop-loop-skills

AI-native SDLC loop skills for Cursor, Codex, and Claude Code.

## Overview

Develop Loop turns coding agents into **engineering process executors** — producing reviewable, versioned, traceable artifacts across requirements, design, and test planning (MVP scope).

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

Phase skills (`01-requirement`, `02-design`, `03-test-plan`) are invokable **standalone** without the loop.

## MVP scope

- **Phases:** requirements → design → test-plan (standard profile)
- **Skills:** lifecycle-loop, traceability, 3 phase skills
- **Demo:** `FEAT-001` example package

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
