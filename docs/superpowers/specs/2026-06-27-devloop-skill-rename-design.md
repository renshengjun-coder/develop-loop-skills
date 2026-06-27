# Devloop Skill Rename — Design Spec

**Status:** Approved (brainstorming)
**Date:** 2026-06-27
**Related:** `docs/superpowers/specs/2026-06-12-devloop-packaging-design.md`, `docs/superpowers/specs/2026-06-12-develop-loop-skills-design.md`

## 1. Purpose

Align the orchestrator skill **folder name**, **skill `name:`**, and **user-facing branding** with `devloop` — matching README and `/devloop` slash commands. Remove the legacy `lifecycle-loop` identifier.

**Problem today:** Slash commands use `/devloop`, but the skill lives at `lifecycle-loop/` with `name: lifecycle-loop`. Agents and skill pickers show the old name after global install.

**Goal:** One name everywhere for the orchestrator: **`devloop`**.

## 2. Naming contract

| Surface | Before | After |
|---------|--------|-------|
| Source folder | `.ai/skills/lifecycle-loop/` | `.ai/skills/devloop/` |
| Cursor pointer | `.cursor/skills/lifecycle-loop/` | `.cursor/skills/devloop/` |
| Pack output | `pack/skills/lifecycle-loop/` | `pack/skills/devloop/` |
| Global install | `~/.cursor/skills/lifecycle-loop/` | `~/.cursor/skills/devloop/` |
| Claude global | `~/.claude/skills/lifecycle-loop/` | `~/.claude/skills/devloop/` |
| Skill frontmatter `name:` | `lifecycle-loop` | `devloop` |
| AGENTS.md table label | Lifecycle Loop | Devloop |
| Skill body title | Lifecycle Loop Skill | Devloop Skill |
| User slash commands | `/devloop start\|run\|gate\|status\|classify` | **unchanged** |

### 2.1 Explicitly unchanged

These use "loop" as an **execution mode** or **script name**, not the skill identifier:

- `package.yaml` field `mode: loop | pipeline`
- `scripts/loop-verify.sh`, `.github/workflows/loop-verify.yml`
- Phase skill folder names (`01-requirement`, …)
- Documentation phrases "SDLC loop" when describing the process

## 3. Compatibility

**Clean break** — no `lifecycle-loop` alias stub in the distributable.

**Migration for existing installs:**

1. Pull latest repo and rebuild pack.
2. Run `devloop install --global --upgrade`.
3. Manually remove stale directories if present:
   - `~/.cursor/skills/lifecycle-loop/`
   - `~/.claude/skills/lifecycle-loop/`

No automatic uninstall of old paths in v1.

## 4. Skill discovery (Cursor, Claude Code, Codex)

After `devloop install --global`, agents discover the orchestrator via:

1. **Install path** — `devloop/SKILL.md` under user skills dir
2. **Frontmatter** — `name: devloop`
3. **Description triggers** — lead with `/devloop start`, `/devloop run`, `devloop`, `SDLC orchestrator`

Cursor does not register `/devloop` as a platform built-in slash command; the skill instructs the agent to handle `/devloop <subcommand>` when the user types it. Folder and `name:` alignment makes the skill picker and documentation consistent.

**Project rule** (`templates/cursor/rules/devloop.mdc`) — add explicit line:

```markdown
- Orchestrator skill: `devloop` — user commands: `/devloop start|run|gate|status|classify`
```

## 5. Skill frontmatter (target)

```yaml
---
name: devloop
description: >-
  Develop Loop SDLC orchestrator. Classifies complexity, selects workflow profile,
  invokes phase skills, issues L2 gate decisions, controls loop/pipeline re-entry.
  Use for /devloop start, /devloop run, /devloop gate, /devloop status,
  /devloop classify, devloop, SDLC orchestrator, quality gate.
---
```

## 6. Implementation scope

### 6.1 Git renames

- `.ai/skills/lifecycle-loop/` → `.ai/skills/devloop/`
- `.cursor/skills/lifecycle-loop/` → `.cursor/skills/devloop/`

### 6.2 Scripts and tests

| File | Change |
|------|--------|
| `scripts/build-pack.sh` | Skill map: `devloop:.ai/skills/devloop` |
| `bin/lib/install.sh` | `_SKILLS` array: `devloop` replaces `lifecycle-loop` |
| `bin/lib/doctor.sh` | Check `devloop` instead of `lifecycle-loop` |
| `scripts/test-build-pack.sh` | Assert `pack/skills/devloop/SKILL.md` |
| `scripts/test-devloop-cli.sh` | Assert global install path `devloop/` |

### 6.3 Content references

Replace `lifecycle-loop` with `devloop` in:

- `AGENTS.md`, `README.md`
- Phase skills (text: "invoked by lifecycle-loop" → "invoked by devloop")
- `traceability/SKILL.md` if referenced
- `.ai/skills/devloop/SKILL.md` and `reference.md` (internal cross-refs)
- `.cursor/skills/devloop/SKILL.md` pointer path
- Packaging docs and plans (bulk replace or one-line supersession note on historical plans)

### 6.4 Cursor pointer (dogfooding repo)

```markdown
---
name: devloop
description: >-
  Develop Loop SDLC orchestrator. Source: .ai/skills/devloop/SKILL.md
  Use for /devloop start, /devloop run, /devloop gate, /devloop status, /devloop classify.
---

# Devloop

**Source of truth:** `.ai/skills/devloop/SKILL.md`
```

## 7. Success criteria

1. `pack/skills/devloop/SKILL.md` exists; `pack/skills/lifecycle-loop/` does not.
2. `./scripts/test-build-pack.sh` and `./scripts/test-devloop-cli.sh` pass.
3. `devloop doctor` checks for `devloop` global skill, not `lifecycle-loop`.
4. `AGENTS.md` lists Devloop at `.ai/skills/devloop/SKILL.md` (dogfood path) or skill name `devloop` (consumer template).
5. No remaining `lifecycle-loop` in `.ai/skills/`, `.cursor/skills/`, `bin/`, `scripts/build-pack.sh`, or `AGENTS.md` (docs/plans may retain historical mentions with date prefix only if intentionally archived).

## 8. Out of scope

- Renaming `loop-verify.sh` to `devloop-verify.sh`
- Changing `mode: loop` to `mode: devloop`
- Auto-removal of old `lifecycle-loop` dirs during `devloop install`
- Cursor Marketplace plugin registration

## 9. Implementation handoff

Next step: invoke **writing-plans** skill for a focused rename PR, or implement directly as a single mechanical refactor with test verification.
