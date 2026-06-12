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

[[ -f "$DEVLOOP_HOME/.cursor/skills/lifecycle-loop/SKILL.md" ]] \
  || { echo "FAIL: cursor lifecycle-loop not installed"; exit 1; }
[[ -f "$DEVLOOP_HOME/.codex/AGENTS.md" ]] \
  || { echo "FAIL: codex AGENTS.md not installed"; exit 1; }

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
grep -q "DEVLOOP:BEGIN" "$PROJ/AGENTS.md" \
  || { echo "FAIL: AGENTS.md missing devloop block"; exit 1; }

out=$(cd "$PROJ" && "$ROOT/bin/devloop" init 2>&1)
echo "$out" | grep -q "skip" || { echo "FAIL: second init should skip files"; echo "$out"; exit 1; }

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
