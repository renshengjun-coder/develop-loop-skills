#!/usr/bin/env bash
# scripts/loop-verify.sh — L3 structural verifier (no LLM)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_ID="${1:?Usage: loop-verify.sh <package_id>}"
PKG_DIR="$ROOT/.ai/packages/$PKG_ID"
ART_DIR="$ROOT/artifacts/$PKG_ID"
TRACE_MATRIX="$ROOT/traceability/$PKG_ID/matrix.md"
PROFILES="$ROOT/.ai/config/profiles.yaml"
ERRORS=0
WARNINGS=0

err() { echo "ERROR: $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN: $1"; WARNINGS=$((WARNINGS + 1)); }

[[ -f "$PKG_DIR/package.yaml" ]] || { err "missing package.yaml"; echo "FAIL ($ERRORS errors)"; exit 1; }
[[ -f "$PKG_DIR/classification.yaml" ]] || err "missing classification.yaml"

PROFILE=$(grep -E '^profile:' "$PKG_DIR/package.yaml" | awk '{print $2}')
[[ -n "$PROFILE" ]] || err "package.yaml missing profile"

ARCHIVED_PHASES=$(awk '
  /^  [a-z-]+:$/ { phase=$1; gsub(/:/,"",phase) }
  /status: archived/ { if (phase != "") print phase }
' "$PKG_DIR/package.yaml")

for phase in $ARCHIVED_PHASES; do
  case "$phase" in
    requirements) dir="01-requirements" ;;
    design) dir="02-design" ;;
    test-plan) dir="03-test-plan" ;;
    *) err "unknown phase: $phase"; continue ;;
  esac
  PHASE_DIR="$ART_DIR/$dir"
  [[ -d "$PHASE_DIR" ]] || { err "missing artifacts/$PKG_ID/$dir"; continue; }
  [[ -f "$PHASE_DIR/review-log.md" ]] || err "missing review-log in $dir"
  case "$phase" in
    requirements)
      for f in PRD.md user-stories.md acceptance-criteria.md; do
        [[ -f "$PHASE_DIR/$f" ]] || err "missing $dir/$f"
      done
      if grep -q 'human_gates:.*requirements' "$PROFILES" 2>/dev/null; then
        grep -q 'status: approved' "$PHASE_DIR/PRD.md" 2>/dev/null || err "requirements human gate: PRD not approved"
      fi
      ;;
    design)
      [[ -f "$PHASE_DIR/architecture.md" ]] || err "missing design/architecture.md"
      ;;
    test-plan)
      [[ -f "$PHASE_DIR/test-strategy.md" ]] || err "missing test-plan/test-strategy.md"
      [[ -f "$PHASE_DIR/test-cases.md" ]] || err "missing test-plan/test-cases.md"
      ;;
  esac
  GATE_COUNT=$(find "$PKG_DIR/gates" -name "${phase}-*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ "$GATE_COUNT" -ge 1 ]] || err "no gate file for phase $phase"
done

[[ -f "$TRACE_MATRIX" ]] || warn "missing traceability/$PKG_ID/matrix.md"

if [[ $ERRORS -gt 0 ]]; then
  echo "FAIL ($ERRORS errors, $WARNINGS warnings)"
  exit 1
fi
echo "PASS ($WARNINGS warnings)"
exit 0
