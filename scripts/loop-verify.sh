#!/usr/bin/env bash
# scripts/loop-verify.sh — L3 structural verifier (no LLM)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENFORCE=0
PKG_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enforce) ENFORCE=1; shift ;;
    -*) echo "ERROR: unknown flag $1"; exit 1 ;;
    *) PKG_ID="$1"; shift ;;
  esac
done

[[ -n "$PKG_ID" ]] || { echo "Usage: loop-verify.sh [--enforce] <package_id>"; exit 1; }

PKG_DIR="$ROOT/.ai/packages/$PKG_ID"
ART_DIR="$ROOT/artifacts/$PKG_ID"
TRACE_MATRIX="$ROOT/traceability/$PKG_ID/matrix.md"
PROFILES="$ROOT/.ai/config/profiles.yaml"
ERRORS=0
WARNINGS=0

err() { echo "ERROR: $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN: $1"; WARNINGS=$((WARNINGS + 1)); }

phase_to_dir() {
  case "$1" in
    requirements) echo "01-requirements" ;;
    design) echo "02-design" ;;
    test-plan) echo "03-test-plan" ;;
    implementation) echo "04-implementation" ;;
    code-review) echo "05-code-review" ;;
    test-report) echo "06-test-report" ;;
    release) echo "07-release-retro" ;;
    *) echo "" ;;
  esac
}

profile_phases() {
  local profile="$1"
  awk -v p="$profile" '
    $0 ~ "^" p ":" { found=1; next }
    found && /^[a-z_]+:/ { exit }
    found && /phases:/ {
      line=$0
      sub(/.*\[/, "", line)
      sub(/\].*/, "", line)
      gsub(/ /, "", line)
      n=split(line, a, /,/)
      for (i=1; i<=n; i++) if (a[i] != "") print a[i]
      exit
    }
  ' "$PROFILES"
}

phase_in_human_gates() {
  local profile="$1" phase="$2"
  local line
  line=$(awk -v p="$profile" '
    $0 ~ "^" p ":" { found=1; next }
    found && /^[a-z_]+:/ { exit }
    found && /human_gates:/ { print; exit }
  ' "$PROFILES")
  [[ "$line" == *"$phase"* ]]
}

latest_gate_file() {
  local phase="$1"
  local gates=() f
  shopt -s nullglob
  for f in "$PKG_DIR/gates/${phase}-"*.md; do
    gates+=("$f")
  done
  shopt -u nullglob
  ((${#gates[@]})) || return 1
  printf '%s\n' "${gates[@]}" | sort -V | tail -1
}

check_gate_pass() {
  local phase="$1"
  local gate
  gate=$(latest_gate_file "$phase")
  [[ -n "$gate" ]] || { err "no gate file for phase $phase"; return; }
  grep -qE '^result: pass' "$gate" || err "latest gate for $phase is not pass ($gate)"
}

required_files_for_phase() {
  local profile="$1" phase="$2"
  case "$profile:$phase" in
    standard:requirements|routine:requirements|high_risk:requirements)
      echo "PRD.md user-stories.md acceptance-criteria.md review-log.md" ;;
    standard:design|high_risk:design)
      echo "architecture.md review-log.md" ;;
    standard:test-plan|high_risk:test-plan)
      echo "test-strategy.md test-cases.md review-log.md" ;;
    standard:implementation|routine:implementation|high_risk:implementation)
      echo "implementation-plan.md changed-files.md coding-log.md review-log.md" ;;
    standard:code-review|routine:code-review|high_risk:code-review)
      echo "ai-review.md review-log.md" ;;
    standard:test-report|routine:test-report|high_risk:test-report)
      echo "test-execution-summary.md coverage-report.md review-log.md" ;;
    standard:release|routine:release|high_risk:release)
      echo "release-notes.md known-issues.md retro.md review-log.md" ;;
    *) echo "" ;;
  esac
}

check_human_gate() {
  local profile="$1" phase="$2" phase_dir="$3"
  phase_in_human_gates "$profile" "$phase" || return 0
  case "$phase" in
    requirements)
      grep -q 'status: approved' "$phase_dir/PRD.md" 2>/dev/null || \
        err "$phase human gate: PRD not approved" ;;
    design)
      grep -qE 'status: (approved|reviewed)' "$phase_dir/architecture.md" 2>/dev/null || \
        err "$phase human gate: architecture not approved/reviewed" ;;
    test-plan)
      grep -qE 'status: (approved|reviewed)' "$phase_dir/test-cases.md" 2>/dev/null || \
        err "$phase human gate: test-cases not approved/reviewed" ;;
    code-review|test-report|release)
      [[ -f "$phase_dir/approval.md" ]] || \
        err "$phase human gate: approval.md missing" ;;
  esac
}

[[ -f "$PKG_DIR/package.yaml" ]] || { err "missing package.yaml"; echo "FAIL ($ERRORS errors)"; exit 1; }
[[ -f "$PKG_DIR/classification.yaml" ]] || err "missing classification.yaml"

PROFILE=$(grep -E '^profile:' "$PKG_DIR/package.yaml" | awk '{print $2}')
[[ -n "$PROFILE" ]] || err "package.yaml missing profile"

PKG_STATUS=$(grep -E '^status:' "$PKG_DIR/package.yaml" | awk '{print $2}')

ARCHIVED_PHASES=$(awk '
  /^  [a-z-]+:$/ { phase=$1; gsub(/:/,"",phase) }
  /status: archived/ { if (phase != "") print phase }
' "$PKG_DIR/package.yaml")

for phase in $ARCHIVED_PHASES; do
  dir=$(phase_to_dir "$phase")
  [[ -n "$dir" ]] || { err "unknown phase: $phase"; continue; }
  PHASE_DIR="$ART_DIR/$dir"
  [[ -d "$PHASE_DIR" ]] || { err "missing artifacts/$PKG_ID/$dir"; continue; }
  [[ -f "$PHASE_DIR/review-log.md" ]] || err "missing review-log in $dir"

  required=$(required_files_for_phase "$PROFILE" "$phase")
  for f in $required; do
    [[ -f "$PHASE_DIR/$f" ]] || err "missing $dir/$f"
  done

  if [[ "$PROFILE" == "high_risk" && "$phase" == "code-review" ]]; then
    [[ -f "$PHASE_DIR/security-review.md" ]] || err "missing code-review/security-review.md (high_risk)"
  fi

  check_human_gate "$PROFILE" "$phase" "$PHASE_DIR"
  check_gate_pass "$phase"
done

if [[ "$PKG_STATUS" == "ready_for_release" ]]; then
  while IFS= read -r profile_phase; do
    [[ -n "$profile_phase" ]] || continue
    echo "$ARCHIVED_PHASES" | grep -qx "$profile_phase" || \
      err "profile phase $profile_phase not archived (ready_for_release requires full profile)"
  done < <(profile_phases "$PROFILE")
fi

if [[ ! -f "$TRACE_MATRIX" ]]; then
  if [[ "$ENFORCE" -eq 1 ]]; then
    err "missing traceability/$PKG_ID/matrix.md (enforce mode)"
  else
    warn "missing traceability/$PKG_ID/matrix.md"
  fi
fi

if [[ $ERRORS -gt 0 ]]; then
  echo "FAIL ($ERRORS errors, $WARNINGS warnings)"
  exit 1
fi
echo "PASS ($WARNINGS warnings)"
exit 0
