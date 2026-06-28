#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export DEVLOOP_HOME="$TMP/home"
export DEVLOOP_YES=1
mkdir -p "$DEVLOOP_HOME"

"$ROOT/scripts/build-pack.sh"

"$ROOT/bin/devloop" install --global --runtimes cursor,codex

[[ -f "$DEVLOOP_HOME/.cursor/skills/devloop/SKILL.md" ]] \
  || { echo "FAIL: cursor devloop not installed"; exit 1; }
[[ -f "$DEVLOOP_HOME/.codex/AGENTS.md" ]] \
  || { echo "FAIL: codex AGENTS.md not installed"; exit 1; }
[[ ! -e "$DEVLOOP_HOME/.cursor/skills/lifecycle-loop" ]] \
  || { echo "FAIL: legacy lifecycle-loop skill should not be installed"; exit 1; }
grep -q "/devloop continue <id>" "$DEVLOOP_HOME/.cursor/skills/devloop/SKILL.md" \
  || { echo "FAIL: installed devloop skill missing continue command"; exit 1; }
grep -q "do \\*\\*not\\*\\* start the next phase" "$DEVLOOP_HOME/.cursor/skills/devloop/SKILL.md" \
  || { echo "FAIL: installed devloop skill missing hard-stop checkpoint wording"; exit 1; }
grep -q "/devloop continue <id>" "$DEVLOOP_HOME/.codex/AGENTS.md" \
  || { echo "FAIL: installed codex AGENTS missing continue command"; exit 1; }

PROJ="$TMP/myproject"
mkdir -p "$PROJ"
(
  cd "$PROJ"
  "$ROOT/bin/devloop" init --with-ci
)

[[ -f "$PROJ/.ai/config/profiles.yaml" ]] \
  || { echo "FAIL: profiles.yaml missing"; exit 1; }
[[ -f "$PROJ/scripts/loop-verify.sh" ]] \
  || { echo "FAIL: loop-verify.sh missing"; exit 1; }
[[ -f "$PROJ/.github/workflows/loop-verify.yml" ]] \
  || { echo "FAIL: workflow missing"; exit 1; }
[[ -f "$PROJ/.ai/packages/_template/package.yaml" ]] \
  || { echo "FAIL: package template missing"; exit 1; }
grep -q "^run_control:" "$PROJ/.ai/packages/_template/package.yaml" \
  || { echo "FAIL: initialized package template missing run_control"; exit 1; }
grep -q "^  state: running" "$PROJ/.ai/packages/_template/package.yaml" \
  || { echo "FAIL: initialized package template missing default running state"; exit 1; }
grep -q "DEVLOOP:BEGIN" "$PROJ/AGENTS.md" \
  || { echo "FAIL: AGENTS.md missing devloop block"; exit 1; }
grep -q "/devloop continue <id>" "$PROJ/AGENTS.md" \
  || { echo "FAIL: AGENTS.md missing continue command"; exit 1; }
grep -Fq "/devloop start|run|continue|gate|status|classify" "$PROJ/.cursor/rules/devloop.mdc" \
  || { echo "FAIL: Cursor rule missing continue command"; exit 1; }

out=$(cd "$PROJ" && "$ROOT/bin/devloop" init 2>&1)
echo "$out" | grep -q "skip" || { echo "FAIL: second init should skip files"; echo "$out"; exit 1; }

cat > "$PROJ/.cursor/rules/devloop.mdc" <<'EOF'
---
description: Use Develop Loop SDLC skills and /devloop commands for change packages
globs:
alwaysApply: true
---

# Develop Loop

- Orchestrator: `/devloop start|run|gate|status|classify`
- Read project `AGENTS.md` for state paths (`.ai/packages/`, `artifacts/`, `traceability/`)
- Phase skills are installed globally; follow archived design and acceptance criteria in `artifacts/<id>/`
EOF
echo "# Upgrade Test" > "$PROJ/AGENTS.md"
(
  cd "$PROJ"
  "$ROOT/bin/devloop" init --upgrade
)
grep -Fq "/devloop start|run|continue|gate|status|classify" "$PROJ/.cursor/rules/devloop.mdc" \
  || { echo "FAIL: init --upgrade should refresh stale Cursor rule"; exit 1; }

mkdir -p "$DEVLOOP_HOME/.cursor/skills/lifecycle-loop" "$DEVLOOP_HOME/.claude/skills/lifecycle-loop"
echo "legacy" > "$DEVLOOP_HOME/.cursor/skills/lifecycle-loop/SKILL.md"
echo "legacy" > "$DEVLOOP_HOME/.claude/skills/lifecycle-loop/SKILL.md"
mkdir -p "$DEVLOOP_HOME/.codex"
cat > "$DEVLOOP_HOME/.codex/AGENTS.md" <<'EOF'
# Personal Notes

<!-- DEVLOOP:BEGIN -->
# Develop Loop

AI-native SDLC skills for this project. Skills are installed globally via `devloop install --global`.

## Commands

Orchestrator slash command: **`/devloop`**

| Command | Description |
|---------|-------------|
| `/devloop start <id>` | Create package, classify, select profile |
| `/devloop run <id>` | E2E orchestration (loop mode) |
| `/devloop gate <id> <phase>` | L2 gate check for one phase |
| `/devloop status <id>` | Package status and blockers |
| `/devloop classify <id>` | Re-run complexity classification |

<!-- DEVLOOP:END -->
EOF
"$ROOT/bin/devloop" install --global --upgrade --runtimes cursor,claude
[[ ! -e "$DEVLOOP_HOME/.cursor/skills/lifecycle-loop" ]] \
  || { echo "FAIL: install --upgrade should remove legacy cursor lifecycle-loop"; exit 1; }
[[ ! -e "$DEVLOOP_HOME/.claude/skills/lifecycle-loop" ]] \
  || { echo "FAIL: install --upgrade should remove legacy claude lifecycle-loop"; exit 1; }
"$ROOT/bin/devloop" install --global --upgrade --runtimes codex
grep -q "^# Personal Notes$" "$DEVLOOP_HOME/.codex/AGENTS.md" \
  || { echo "FAIL: codex upgrade should preserve existing AGENTS content"; exit 1; }
grep -q "/devloop continue <id>" "$DEVLOOP_HOME/.codex/AGENTS.md" \
  || { echo "FAIL: codex upgrade should refresh devloop block with continue command"; exit 1; }
grep -Fq 'waits for `/devloop continue <id>` before any later phase starts' "$DEVLOOP_HOME/.codex/AGENTS.md" \
  || { echo "FAIL: codex upgrade should refresh run command description"; exit 1; }

echo "# My App" > "$PROJ/AGENTS.md"
(
  cd "$PROJ"
  "$ROOT/bin/devloop" init
)
grep -q "My App" "$PROJ/AGENTS.md" || { echo "FAIL: existing AGENTS content lost"; exit 1; }
grep -q "DEVLOOP:BEGIN" "$PROJ/AGENTS.md" || { echo "FAIL: devloop block not merged"; exit 1; }

(
  cd "$PROJ"
  "$ROOT/bin/devloop" doctor
)

echo "PASS: devloop CLI integration tests"
