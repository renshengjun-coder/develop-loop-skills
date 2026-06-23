#!/usr/bin/env bash
# scripts/loop-verify.sh — L3 structural verifier (no LLM)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/loop-contract.sh"
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
REQUIRED_PACKAGE_FILES=()

err() { echo "ERROR: $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "WARN: $1"; WARNINGS=$((WARNINGS + 1)); }
EVIDENCE_POLICY=$(contract_policy_path_from_profiles "$PROFILES")
EVIDENCE_POLICY_FILE=""
if [[ -n "$EVIDENCE_POLICY" ]]; then
  EVIDENCE_POLICY_FILE=$(contract_resolve_path "$ROOT" "$EVIDENCE_POLICY")
fi

append_unique_file() {
  local value="$1"
  shift
  local existing
  for existing in "$@"; do
    [[ "$existing" == "$value" ]] && return 1
  done
  return 0
}

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

package_child_ids() {
  awk '
    /^children:/ { in_children=1; next }
    in_children && /^[^[:space:]-]/ { exit }
    in_children && /^[[:space:]]*-/ {
      if (child_id != "") {
        print child_id
      }
      child_id=""
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      if (line ~ /^id:[[:space:]]*/) {
        sub(/^id:[[:space:]]*/, "", line)
        child_id=line
      }
      next
    }
    in_children && /^[[:space:]]+id:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]+id:[[:space:]]*/, "", line)
      child_id=line
      next
    }
    END {
      if (child_id != "") {
        print child_id
      }
    }
  ' "$PKG_DIR/package.yaml"
}

gate_has_binding_prefix() {
  local gate="$1" prefix="$2"
  awk -v prefix="$prefix" '
    /^artifacts_checked:/ { in_section=1; next }
    in_section && /^[a-z_]+:/ { exit }
    in_section && /^  - / {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]+\([^)]*\)[[:space:]]*$/, "", line)
      sub(/@v[0-9]+([.][0-9]+)*[[:space:]]*$/, "", line)
      if (index(line, prefix) == 1) {
        found=1
        exit
      }
    }
    END { exit(found ? 0 : 1) }
  ' "$gate"
}

child_evidence_block_has() {
  local gate="$1" child_id="$2" pattern="$3"
  awk -v child_id="$child_id" -v pattern="$pattern" '
    /^child_evidence:/ { in_section=1; next }
    in_section && /^[a-z_]+:/ { exit(found ? 0 : 1) }
    in_section && $0 == "  - child: " child_id {
      in_child=1
      next
    }
    in_child && /^  - child: / { exit(found ? 0 : 1) }
    in_child && /^[^[:space:]]/ { exit(found ? 0 : 1) }
    in_child && $0 ~ pattern { found=1 }
    END { exit(found ? 0 : 1) }
  ' "$gate"
}

child_evidence_value() {
  local gate="$1" child_id="$2" field="$3"
  awk -v child_id="$child_id" -v field="$field" '
    /^child_evidence:/ { in_section=1; next }
    in_section && /^[a-z_]+:/ { exit }
    in_section && $0 == "  - child: " child_id {
      in_child=1
      next
    }
    in_child && /^  - child: / { exit }
    in_child && /^[^[:space:]]/ { exit }
    in_child && $0 ~ "^    " field ": " {
      line=$0
      sub("^    " field ": ", "", line)
      print line
      exit
    }
  ' "$gate"
}

check_parent_child_release_evidence() {
  local gate="$1"
  local child_id has_children=0
  local latest_gate_ref latest_gate_path

  while IFS= read -r child_id; do
    [[ -n "$child_id" ]] || continue
    has_children=1
    gate_has_section "$gate" "child_evidence" || \
      err "gate child_evidence missing for release ($gate)"
    gate_has_binding "$gate" ".ai/packages/$child_id/package.yaml" || \
      err "release gate missing child package reference for $child_id ($gate)"
    gate_has_binding "$gate" "traceability/$child_id/package-evidence-index.md" || \
      err "release gate missing child evidence index reference for $child_id ($gate)"
    gate_has_binding_prefix "$gate" ".ai/packages/$child_id/gates/" || \
      err "release gate missing child readiness gate reference for $child_id ($gate)"
    child_evidence_block_has "$gate" "$child_id" "^    status: " || \
      err "release gate child_evidence missing status for $child_id ($gate)"
    child_evidence_block_has "$gate" "$child_id" "^    package: \\.ai/packages/$child_id/package\\.yaml$" || \
      err "release gate child_evidence missing package reference for $child_id ($gate)"
    child_evidence_block_has "$gate" "$child_id" "^    latest_gate: \\.ai/packages/$child_id/gates/.+\\.md$" || \
      err "release gate child_evidence missing latest_gate reference for $child_id ($gate)"
    child_evidence_block_has "$gate" "$child_id" "^    evidence_index: traceability/$child_id/package-evidence-index\\.md$" || \
      err "release gate child_evidence missing evidence index reference for $child_id ($gate)"
    latest_gate_ref=$(child_evidence_value "$gate" "$child_id" "latest_gate")
    if [[ -n "$latest_gate_ref" ]]; then
      gate_has_binding "$gate" "$latest_gate_ref" || \
        err "release gate latest_gate is not listed in artifacts_checked for $child_id ($gate)"
      latest_gate_path="$ROOT/$latest_gate_ref"
      [[ -f "$latest_gate_path" ]] || \
        err "release gate latest_gate file missing for $child_id ($latest_gate_ref)"
      if [[ -f "$latest_gate_path" ]]; then
        grep -qE '^result: pass' "$latest_gate_path" || \
          err "release gate latest_gate is not pass for $child_id ($latest_gate_ref)"
      fi
    fi
  done < <(package_child_ids)

  [[ $has_children -eq 0 ]] && return 0
  return 0
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

gate_has_section() {
  local gate="$1" section="$2"
  grep -qE "^${section}:" "$gate"
}

gate_has_binding() {
  local gate="$1" target="$2"
  awk -v target="$target" '
    /^artifacts_checked:/ { in_section=1; next }
    in_section && /^[a-z_]+:/ { exit }
    in_section && /^  - / {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]+\([^)]*\)[[:space:]]*$/, "", line)
      sub(/@v[0-9]+([.][0-9]+)*[[:space:]]*$/, "", line)
      if (line == target) {
        found=1
        exit
      }
    }
    END { exit(found ? 0 : 1) }
  ' "$gate"
}

check_gate_structure() {
  local profile="$1" phase="$2" phase_dir="$3" gate="$4"
  shift 4
  local dir required_file artifact_path package_file

  dir=$(basename "$phase_dir")
  grep -qE "^profile: ${profile}$" "$gate" || \
    err "gate profile mismatch for $phase ($gate)"
  grep -qE '^mode: [a-z_]+' "$gate" || \
    err "gate mode missing for $phase ($gate)"
  grep -qE '^reentry: [0-9]+' "$gate" || \
    err "gate reentry missing for $phase ($gate)"
  grep -qE '^next: ' "$gate" || \
    err "gate next missing for $phase ($gate)"
  gate_has_section "$gate" "artifacts_checked" || \
    err "gate artifacts_checked missing for $phase ($gate)"
  gate_has_section "$gate" "checklist" || \
    err "gate checklist missing for $phase ($gate)"

  for required_file in "$@"; do
    artifact_path="artifacts/$PKG_ID/$dir/$required_file"
    gate_has_binding "$gate" "$artifact_path" || \
      err "gate artifacts_checked missing binding for $phase artifact $required_file ($gate)"
  done

  for package_file in "${REQUIRED_PACKAGE_FILES[@]-}"; do
    artifact_path="traceability/$PKG_ID/$package_file"
    gate_has_binding "$gate" "$artifact_path" || \
      err "gate artifacts_checked missing package evidence binding for $phase artifact $package_file ($gate)"
  done
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
[[ -n "$EVIDENCE_POLICY" ]] || err "profiles.yaml missing contract.evidence_policy"
[[ -n "$EVIDENCE_POLICY" && -f "$EVIDENCE_POLICY_FILE" ]] || \
  err "missing configured evidence policy ($EVIDENCE_POLICY)"

PROFILE=$(grep -E '^profile:' "$PKG_DIR/package.yaml" | awk '{print $2}')
[[ -n "$PROFILE" ]] || err "package.yaml missing profile"

if [[ $ERRORS -gt 0 ]]; then
  echo "FAIL ($ERRORS errors, $WARNINGS warnings)"
  exit 1
fi

PKG_STATUS=$(grep -E '^status:' "$PKG_DIR/package.yaml" | awk '{print $2}')

package_files_output=""
required_package_count=0
if ! package_files_output=$(contract_required_package_files "$EVIDENCE_POLICY_FILE"); then
  err "$(contract_required_package_files_error "$EVIDENCE_POLICY_FILE")"
else
  while IFS= read -r package_file; do
    [[ -n "$package_file" ]] || continue
    REQUIRED_PACKAGE_FILES+=("$package_file")
    required_package_count=$((required_package_count + 1))
  done <<< "$package_files_output"

  if [[ $required_package_count -eq 0 ]]; then
    err "no required package evidence files configured"
  fi
fi

if [[ $ERRORS -gt 0 ]]; then
  echo "FAIL ($ERRORS errors, $WARNINGS warnings)"
  exit 1
fi

ARCHIVED_PHASES=$(awk '
  /^  [a-z-]+:$/ { phase=$1; gsub(/:/,"",phase) }
  /status: archived/ { if (phase != "") print phase }
' "$PKG_DIR/package.yaml")

for phase in $ARCHIVED_PHASES; do
  dir=$(phase_to_dir "$phase")
  [[ -n "$dir" ]] || { err "unknown phase: $phase"; continue; }
  PHASE_DIR="$ART_DIR/$dir"
  gate=""
  required_files=()
  [[ -d "$PHASE_DIR" ]] || { err "missing artifacts/$PKG_ID/$dir"; continue; }
  required_count=0
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if append_unique_file "$f" "${required_files[@]-}"; then
      required_files+=("$f")
    fi
  done < <(contract_required_phase_files "$EVIDENCE_POLICY_FILE" "$PROFILE" "$phase")
  for f in "${required_files[@]-}"; do
    required_count=$((required_count + 1))
    [[ -f "$PHASE_DIR/$f" ]] || err "missing $dir/$f"
  done
  if [[ $required_count -eq 0 ]]; then
    err "no required artifacts configured for profile=$PROFILE phase=$phase"
    continue
  fi

  check_human_gate "$PROFILE" "$phase" "$PHASE_DIR"
  gate=$(latest_gate_file "$phase")
  if [[ -z "$gate" ]]; then
    err "no gate file for phase $phase"
    continue
  fi
  grep -qE '^result: pass' "$gate" || err "latest gate for $phase is not pass ($gate)"
  check_gate_structure "$PROFILE" "$phase" "$PHASE_DIR" "$gate" "${required_files[@]}"
  if [[ "$phase" == "release" ]]; then
    check_parent_child_release_evidence "$gate"
  fi
done

if [[ "$PKG_STATUS" == "ready_for_release" ]]; then
  while IFS= read -r profile_phase; do
    [[ -n "$profile_phase" ]] || continue
    echo "$ARCHIVED_PHASES" | grep -qx "$profile_phase" || \
      err "profile phase $profile_phase not archived (ready_for_release requires full profile)"
  done < <(profile_phases "$PROFILE")
fi

for package_file in "${REQUIRED_PACKAGE_FILES[@]-}"; do
  if [[ ! -f "$ROOT/traceability/$PKG_ID/$package_file" ]]; then
    if [[ "$ENFORCE" -eq 1 ]]; then
      err "missing traceability/$PKG_ID/$package_file (enforce mode)"
    else
      warn "missing traceability/$PKG_ID/$package_file"
    fi
  fi
done

if [[ $ERRORS -gt 0 ]]; then
  echo "FAIL ($ERRORS errors, $WARNINGS warnings)"
  exit 1
fi
echo "PASS ($WARNINGS warnings)"
exit 0
