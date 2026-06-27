#!/usr/bin/env bash
# scripts/build-pack.sh — assemble pack/skills and pack/templates for distribution
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACK="$ROOT/pack"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"

declare -a SKILL_MAP=(
  "devloop:.ai/skills/devloop"
  "01-requirement:.ai/skills/phases/01-requirement"
  "02-design:.ai/skills/phases/02-design"
  "03-test-plan:.ai/skills/phases/03-test-plan"
  "04-implementation:.ai/skills/phases/04-implementation"
  "05-code-review:.ai/skills/phases/05-code-review"
  "06-test-report:.ai/skills/phases/06-test-report"
  "07-release-retro:.ai/skills/phases/07-release-retro"
  "traceability:.ai/skills/traceability"
)

rm -rf "$PACK"
mkdir -p "$PACK/skills" "$PACK/templates"

echo "$VERSION" > "$PACK/VERSION"

for entry in "${SKILL_MAP[@]}"; do
  name="${entry%%:*}"
  src_rel="${entry#*:}"
  src="$ROOT/$src_rel"
  dest="$PACK/skills/$name"
  [[ -d "$src" ]] || { echo "ERROR: missing skill source $src"; exit 1; }
  mkdir -p "$dest"
  cp "$src/SKILL.md" "$dest/SKILL.md"
  [[ -f "$src/reference.md" ]] && cp "$src/reference.md" "$dest/reference.md"
  if grep -q 'Source of truth:' "$dest/SKILL.md" 2>/dev/null; then
    echo "ERROR: $dest/SKILL.md still looks like a pointer stub"
    exit 1
  fi
done

mkdir -p "$PACK/templates/.ai/config"
mkdir -p "$PACK/templates/.ai/packages/_template"
mkdir -p "$PACK/templates/scripts"
mkdir -p "$PACK/templates/artifacts"
mkdir -p "$PACK/templates/traceability"
mkdir -p "$PACK/templates/.github/workflows"
mkdir -p "$PACK/templates/.cursor/rules"

cp "$ROOT/.ai/config/profiles.yaml" "$PACK/templates/.ai/config/profiles.yaml"
cp "$ROOT/.ai/packages/_template/package.yaml" "$PACK/templates/.ai/packages/_template/package.yaml"
cp "$ROOT/.ai/packages/_template/classification.yaml" "$PACK/templates/.ai/packages/_template/classification.yaml"
cp "$ROOT/scripts/loop-verify.sh" "$PACK/templates/scripts/loop-verify.sh"
cp "$ROOT/scripts/test-loop-verify.sh" "$PACK/templates/scripts/test-loop-verify.sh"
cp "$ROOT/templates/AGENTS.md" "$PACK/templates/AGENTS.md"
cp "$ROOT/templates/cursor/rules/devloop.mdc" "$PACK/templates/.cursor/rules/devloop.mdc"
cp "$ROOT/.github/workflows/loop-verify.yml" "$PACK/templates/.github/workflows/loop-verify.yml"
touch "$PACK/templates/artifacts/.gitkeep"
touch "$PACK/templates/traceability/.gitkeep"
cp "$ROOT/VERSION" "$PACK/templates/.devloop-version"

echo "Built pack v$VERSION at $PACK"
echo "Skills: $(find "$PACK/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
