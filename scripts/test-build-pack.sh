#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT/scripts/build-pack.sh"

PACK="$ROOT/pack"
[[ -f "$PACK/VERSION" ]] || { echo "FAIL: pack/VERSION missing"; exit 1; }
[[ -f "$PACK/templates/.ai/config/profiles.yaml" ]] || { echo "FAIL: profiles template missing"; exit 1; }
[[ -f "$PACK/templates/scripts/loop-verify.sh" ]] || { echo "FAIL: loop-verify template missing"; exit 1; }

count=$(find "$PACK/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
[[ "$count" -eq 9 ]] || { echo "FAIL: expected 9 skills, got $count"; exit 1; }

for skill in devloop 01-requirement traceability; do
  [[ -f "$PACK/skills/$skill/SKILL.md" ]] || { echo "FAIL: missing $skill/SKILL.md"; exit 1; }
done

grep -q "/devloop continue <id>" "$PACK/skills/lifecycle-loop/SKILL.md" \
  || { echo "FAIL: lifecycle-loop skill missing continue command"; exit 1; }
grep -q "^run_control:" "$PACK/templates/.ai/packages/_template/package.yaml" \
  || { echo "FAIL: package template missing run_control"; exit 1; }
grep -q "^  state: running" "$PACK/templates/.ai/packages/_template/package.yaml" \
  || { echo "FAIL: package template missing default running state"; exit 1; }
grep -q "/devloop continue <id>" "$PACK/templates/AGENTS.md" \
  || { echo "FAIL: AGENTS template missing continue command"; exit 1; }
grep -Fq "/devloop start|run|continue|gate|status|classify" "$PACK/templates/.cursor/rules/devloop.mdc" \
  || { echo "FAIL: Cursor rule missing continue command"; exit 1; }

echo "PASS: build-pack layout OK"
