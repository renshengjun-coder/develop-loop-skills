#!/usr/bin/env bash
# scripts/test-loop-verify.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/loop-verify.sh"
EVIDENCE_POLICY="$ROOT/.ai/contracts/evidence-policy.yaml"
EVIDENCE_POLICY_BAK="$ROOT/.ai/contracts/evidence-policy.yaml.testbak"
EVIDENCE_POLICY_MALFORMED_BAK="$ROOT/.ai/contracts/evidence-policy.yaml.malformedbak"
TEST_PACKAGES=(TEST-BAD TEST-NOMATRIX TEST-NOINDEX TEST-FEAT003 TEST-FEAT003-ATV TEST-FEAT003-PKGBIND TEST-FEAT003-PKGBIND-QUOTED TEST-FEATPARENT TEST-FEATPARENT-CHILD TEST-PARENTCHILD TEST-PARENTCHILD-CHILD TEST-PARENTCHILD-QUOTED TEST-PARENTCHILD-QUOTED-CHILD TEST-PARENTSTATUS TEST-PARENTSTATUS-CHILD TEST-PARENTLATEST TEST-PARENTLATEST-CHILD TEST-PARENTLATEST-STALE TEST-PARENTLATEST-STALE-CHILD TEST-PARENTLATEST-REENTRY TEST-PARENTLATEST-REENTRY-CHILD TEST-PARENTDISABLED TEST-PARENTDISABLED-CHILD TEST-GATEFAIL TEST-INCOMPLETE TEST-BINDING)
TEMP_PACKAGE_INDEXES=()

restore_policy() {
  if [[ -f "$EVIDENCE_POLICY_BAK" ]]; then
    mv "$EVIDENCE_POLICY_BAK" "$EVIDENCE_POLICY"
  fi
  if [[ -f "$EVIDENCE_POLICY_MALFORMED_BAK" ]]; then
    mv "$EVIDENCE_POLICY_MALFORMED_BAK" "$EVIDENCE_POLICY"
  fi
}

write_test_policy() {
  local fixture="$1"
  cat <<'EOF' > "$EVIDENCE_POLICY"
version: 2026-06-23.test
profiles:
  standard:
    phases:
      - requirements
      - design
      - test-plan
      - implementation
      - code-review
      - test-report
      - release
    human_gates:
      - requirements
    max_reentry: 3
    required_artifacts:
      requirements:
        - PRD.md
        - user-stories.md
        - acceptance-criteria.md
        - review-log.md
      design:
        - architecture.md
        - review-log.md
      test-plan:
        - test-strategy.md
        - test-cases.md
        - review-log.md
      implementation:
        - implementation-plan.md
        - changed-files.md
        - coding-log.md
        - review-log.md
      code-review:
        - ai-review.md
        - review-log.md
      test-report:
        - test-execution-summary.md
        - coverage-report.md
        - review-log.md
      release:
        - release-notes.md
        - known-issues.md
        - retro.md
        - review-log.md
  routine:
    phases:
      - requirements
      - implementation
      - code-review
      - test-report
      - release
    human_gates: []
    max_reentry: 2
    required_artifacts:
      requirements:
        - PRD.md
        - user-stories.md
        - acceptance-criteria.md
        - review-log.md
      implementation:
        - implementation-plan.md
        - changed-files.md
        - coding-log.md
        - review-log.md
      code-review:
        - ai-review.md
        - review-log.md
      test-report:
        - test-execution-summary.md
        - coverage-report.md
        - review-log.md
      release:
        - release-notes.md
        - known-issues.md
        - retro.md
        - review-log.md
  high_risk:
    phases:
      - requirements
      - design
      - test-plan
      - implementation
      - code-review
      - test-report
      - release
    human_gates:
      - requirements
      - design
      - test-plan
      - code-review
      - test-report
      - release
    max_reentry: 3
    required_artifacts:
      requirements:
        - PRD.md
        - user-stories.md
        - acceptance-criteria.md
        - review-log.md
      design:
        - architecture.md
        - review-log.md
      test-plan:
        - test-strategy.md
        - test-cases.md
        - review-log.md
      implementation:
        - implementation-plan.md
        - changed-files.md
        - coding-log.md
        - review-log.md
      code-review:
        - ai-review.md
        - security-review.md
        - review-log.md
      test-report:
        - test-execution-summary.md
        - coverage-report.md
        - review-log.md
      release:
        - release-notes.md
        - known-issues.md
        - retro.md
        - review-log.md
EOF

  case "$fixture" in
    malformed_package_files)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
EOF
      ;;
    malformed_gate_bindings)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked:
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children: require
  require_artifacts_checked_bindings:
    - child_package
    - child_latest_gate
    - child_evidence_index
  child_evidence:
    require_section: true
    required_fields:
      - status
      - package
      - latest_gate
      - evidence_index
  latest_gate:
    require_binding: true
    require_pass_result: true
EOF
      ;;
    malformed_parent_child_release)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked: true
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children:
  require_artifacts_checked_bindings:
    - child_package
    - child_latest_gate
    - child_evidence_index
  child_evidence:
    require_section: true
    required_fields:
      - status
      - package
      - latest_gate
      - evidence_index
  latest_gate:
    require_binding: true
    require_pass_result: true
EOF
      ;;
    missing_parent_child_bindings)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked: true
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children: require
  child_evidence:
    require_section: true
    required_fields:
      - status
      - package
      - latest_gate
      - evidence_index
  latest_gate:
    require_binding: true
    require_pass_result: true
EOF
      ;;
    malformed_parent_child_fields)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked: true
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children: require
  require_artifacts_checked_bindings:
    - child_package
    - child_latest_gate
    - child_evidence_index
  child_evidence:
    require_section: true
    required_fields:
  latest_gate:
    require_binding: true
    require_pass_result: true
EOF
      ;;
    quoted_gate_bindings)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked: "true"
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children: require
  require_artifacts_checked_bindings:
    - child_package
    - child_latest_gate
    - child_evidence_index
  child_evidence:
    require_section: true
    required_fields:
      - status
      - package
      - latest_gate
      - evidence_index
  latest_gate:
    require_binding: true
    require_pass_result: true
EOF
      ;;
    quoted_parent_child_release)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked: true
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children: "require"
  require_artifacts_checked_bindings:
    - child_package
    - child_latest_gate
    - child_evidence_index
  child_evidence:
    require_section: 'true'
    required_fields:
      - status
      - package
      - latest_gate
      - evidence_index
  latest_gate:
    require_binding: "true"
    require_pass_result: 'true'
EOF
      ;;
    compatibility_matrix_only)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  gate_bindings:
    require_in_artifacts_checked: false
compatibility:
  human_readable_evidence:
    when_missing: fallback
    fallback_required_package_files:
      - matrix.md
EOF
      ;;
    quoted_compatibility_matrix_only)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  gate_bindings:
    require_in_artifacts_checked: false
compatibility:
  human_readable_evidence:
    when_missing: "fallback" # comment should be ignored
    fallback_required_package_files:
      - matrix.md
EOF
      ;;
    parent_child_disabled)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked: true
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children: ignore
  require_artifacts_checked_bindings: []
  child_evidence:
    require_section: false
    required_fields: []
  latest_gate:
    require_binding: false
    require_pass_result: false
EOF
      ;;
    *)
      cat <<'EOF' >> "$EVIDENCE_POLICY"
human_readable_evidence:
  required_package_files:
    - matrix.md
    - package-evidence-index.md
  gate_bindings:
    require_in_artifacts_checked: true
compatibility:
  human_readable_evidence:
    when_missing: error
parent_child_release:
  when_parent_has_children: require
  require_artifacts_checked_bindings:
    - child_package
    - child_latest_gate
    - child_evidence_index
  child_evidence:
    require_section: true
    required_fields:
      - status
      - package
      - latest_gate
      - evidence_index
  latest_gate:
    require_binding: true
    require_pass_result: true
EOF
      ;;
  esac
}

ensure_gate_binding() {
  local gate_file="$1" binding="$2"
  python3 - <<'PY' "$gate_file" "$binding"
from pathlib import Path
import sys

path = Path(sys.argv[1])
binding = sys.argv[2]
text = path.read_text()
line = f"  - {binding}\n"
if line in text:
    raise SystemExit(0)
needle = "artifacts_checked:\n"
if needle not in text:
    raise SystemExit(f"missing artifacts_checked section in {path}")
text = text.replace(needle, needle + line, 1)
path.write_text(text)
PY
}

remove_gate_binding() {
  local gate_file="$1" binding="$2"
  python3 - <<'PY' "$gate_file" "$binding"
from pathlib import Path
import sys

path = Path(sys.argv[1])
binding = sys.argv[2]
text = path.read_text()
line = f"  - {binding}\n"
if line not in text:
    raise SystemExit(f"missing expected gate binding to remove: {binding}")
path.write_text(text.replace(line, "", 1))
PY
}

replace_token_in_tree() {
  local old_token="$1" new_token="$2"
  shift 2
  python3 - <<'PY' "$old_token" "$new_token" "$@"
from pathlib import Path
import sys

old_token = sys.argv[1]
new_token = sys.argv[2]
for raw_path in sys.argv[3:]:
    path = Path(raw_path)
    if path.is_dir():
        for child in sorted(p for p in path.rglob("*") if p.is_file()):
            child.write_text(child.read_text().replace(old_token, new_token))
    else:
        path.write_text(path.read_text().replace(old_token, new_token))
PY
}

copy_feat003_fixture() {
  local dest_id="$1"
  local package_dir="$ROOT/.ai/packages/$dest_id"
  local artifacts_dir="$ROOT/artifacts/$dest_id"
  local trace_dir="$ROOT/traceability/$dest_id"

  mkdir -p "$package_dir"
  cp "$ROOT/.ai/packages/FEAT-003/package.yaml" "$package_dir/package.yaml"
  cp "$ROOT/.ai/packages/FEAT-003/classification.yaml" "$package_dir/classification.yaml"
  cp -R "$ROOT/.ai/packages/FEAT-003/gates" "$package_dir/"
  cp -R "$ROOT/artifacts/FEAT-003" "$artifacts_dir"
  mkdir -p "$trace_dir"
  cp "$ROOT/traceability/FEAT-003/matrix.md" "$trace_dir/matrix.md"
  cat > "$trace_dir/package-evidence-index.md" <<EOF
# Package Evidence Index — $dest_id
EOF
  TEMP_PACKAGE_INDEXES+=("$trace_dir/package-evidence-index.md")

  replace_token_in_tree "FEAT-003" "$dest_id" \
    "$package_dir/package.yaml" \
    "$package_dir/classification.yaml" \
    "$package_dir/gates" \
    "$artifacts_dir" \
    "$trace_dir/matrix.md"
}

copy_feat_parent_fixture() {
  local dest_id="$1"
  local package_dir="$ROOT/.ai/packages/$dest_id"
  local artifacts_dir="$ROOT/artifacts/$dest_id"
  local trace_dir="$ROOT/traceability/$dest_id"

  mkdir -p "$package_dir"
  cp "$ROOT/.ai/packages/FEAT-PARENT/package.yaml" "$package_dir/package.yaml"
  cp "$ROOT/.ai/packages/FEAT-PARENT/classification.yaml" "$package_dir/classification.yaml"
  cp -R "$ROOT/.ai/packages/FEAT-PARENT/gates" "$package_dir/"
  cp -R "$ROOT/artifacts/FEAT-PARENT" "$artifacts_dir"
  mkdir -p "$trace_dir"
  cp "$ROOT/traceability/FEAT-PARENT/matrix.md" "$trace_dir/matrix.md"
  cp "$ROOT/traceability/FEAT-PARENT/package-evidence-index.md" "$trace_dir/package-evidence-index.md"

  replace_token_in_tree "FEAT-PARENT" "$dest_id" \
    "$package_dir/package.yaml" \
    "$package_dir/classification.yaml" \
    "$package_dir/gates" \
    "$artifacts_dir" \
    "$trace_dir/matrix.md" \
    "$trace_dir/package-evidence-index.md"
}

copy_feat_child_fixture() {
  local dest_id="$1"
  local package_dir="$ROOT/.ai/packages/$dest_id"
  local artifacts_dir="$ROOT/artifacts/$dest_id"
  local trace_dir="$ROOT/traceability/$dest_id"

  mkdir -p "$package_dir"
  cp "$ROOT/.ai/packages/FEAT-CHILD/package.yaml" "$package_dir/package.yaml"
  cp "$ROOT/.ai/packages/FEAT-CHILD/classification.yaml" "$package_dir/classification.yaml"
  cp -R "$ROOT/.ai/packages/FEAT-CHILD/gates" "$package_dir/"
  cp -R "$ROOT/artifacts/FEAT-CHILD" "$artifacts_dir"
  mkdir -p "$trace_dir"
  cp "$ROOT/traceability/FEAT-CHILD/matrix.md" "$trace_dir/matrix.md"
  cp "$ROOT/traceability/FEAT-CHILD/package-evidence-index.md" "$trace_dir/package-evidence-index.md"

  replace_token_in_tree "FEAT-CHILD" "$dest_id" \
    "$package_dir/package.yaml" \
    "$package_dir/classification.yaml" \
    "$package_dir/gates" \
    "$artifacts_dir" \
    "$trace_dir/matrix.md" \
    "$trace_dir/package-evidence-index.md"
}

retarget_parent_child_references() {
  local parent_id="$1" child_id="$2"
  replace_token_in_tree "FEAT-CHILD" "$child_id" \
    "$ROOT/.ai/packages/$parent_id/package.yaml" \
    "$ROOT/.ai/packages/$parent_id/gates" \
    "$ROOT/traceability/$parent_id/package-evidence-index.md"
}

cleanup_fixtures() {
  local pkg
  restore_policy
  for pkg in "${TEMP_PACKAGE_INDEXES[@]-}"; do
    rm -f "$pkg"
  done
  for pkg in "${TEST_PACKAGES[@]}"; do
    rm -rf "$ROOT/.ai/packages/$pkg" "$ROOT/artifacts/$pkg" "$ROOT/traceability/$pkg"
  done
}

cleanup_fixtures
trap cleanup_fixtures EXIT

# Test 0: verifier fails when the configured evidence policy is missing
[[ -f "$EVIDENCE_POLICY" ]] || {
  echo "FAIL: missing .ai/contracts/evidence-policy.yaml"
  exit 1
}
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_BAK"
if output=$("$SCRIPT" FEAT-003 2>&1); then
  echo "FAIL: FEAT-003 verifier should fail when .ai/contracts/evidence-policy.yaml is missing"
  exit 1
fi
echo "$output" | grep -q "missing configured evidence policy" || {
  echo "FAIL: expected missing evidence policy error"
  echo "$output"
  exit 1
}
restore_policy
output=$("$SCRIPT" FEAT-003 2>&1) || {
  echo "FAIL: FEAT-003 should pass once evidence policy is restored"
  echo "$output"
  exit 1
}
echo "$output" | grep -q "PASS" || { echo "FAIL: expected PASS after restoring evidence policy"; exit 1; }

# Test 0b: malformed required_package_files must fail instead of using compatibility fallback
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy malformed_package_files
if output=$("$SCRIPT" FEAT-003 2>&1); then
  echo "FAIL: FEAT-003 should fail when required_package_files is malformed"
  exit 1
fi
echo "$output" | grep -q "invalid human_readable_evidence.required_package_files" || {
  echo "FAIL: expected malformed required_package_files error"
  echo "$output"
  exit 1
}
restore_policy
output=$("$SCRIPT" FEAT-003 2>&1) || {
  echo "FAIL: FEAT-003 should pass once malformed policy is restored"
  echo "$output"
  exit 1
}
echo "$output" | grep -q "PASS" || { echo "FAIL: expected PASS after restoring malformed policy"; exit 1; }

# Test 0c: malformed gate_bindings must fail closed instead of disabling package evidence binding checks
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy malformed_gate_bindings
if output=$("$SCRIPT" FEAT-003 2>&1); then
  echo "FAIL: FEAT-003 should fail when gate_bindings policy is malformed"
  exit 1
fi
echo "$output" | grep -q "invalid human_readable_evidence.gate_bindings.require_in_artifacts_checked" || {
  echo "FAIL: expected malformed gate_bindings error"
  echo "$output"
  exit 1
}
restore_policy

# Test 0d: malformed parent_child_release must fail closed instead of disabling child evidence enforcement
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy malformed_parent_child_release
if output=$("$SCRIPT" FEAT-PARENT 2>&1); then
  echo "FAIL: FEAT-PARENT should fail when parent_child_release policy is malformed"
  exit 1
fi
echo "$output" | grep -q "invalid parent_child_release.when_parent_has_children" || {
  echo "FAIL: expected malformed parent_child_release error"
  echo "$output"
  exit 1
}
restore_policy

# Test 0e: missing parent_child_release require_artifacts_checked_bindings must fail closed
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy missing_parent_child_bindings
if output=$("$SCRIPT" FEAT-PARENT 2>&1); then
  echo "FAIL: FEAT-PARENT should fail when parent_child_release bindings policy is missing"
  exit 1
fi
echo "$output" | grep -q "invalid parent_child_release.require_artifacts_checked_bindings" || {
  echo "FAIL: expected missing parent_child_release bindings error"
  echo "$output"
  exit 1
}
restore_policy

# Test 0f: malformed parent_child_release child_evidence.required_fields must fail closed
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy malformed_parent_child_fields
if output=$("$SCRIPT" FEAT-PARENT 2>&1); then
  echo "FAIL: FEAT-PARENT should fail when parent_child_release child fields policy is malformed"
  exit 1
fi
echo "$output" | grep -q "invalid parent_child_release.child_evidence.required_fields" || {
  echo "FAIL: expected malformed parent_child_release child fields error"
  echo "$output"
  exit 1
}
restore_policy

# Test 1: FEAT-003 demo package passes
output=$("$SCRIPT" FEAT-003 2>&1) || { echo "FAIL: FEAT-003 should pass"; echo "$output"; exit 1; }
echo "$output" | grep -q "PASS" || { echo "FAIL: expected PASS"; exit 1; }

# Test 2: missing package fails
if "$SCRIPT" NONEXISTENT 2>/dev/null; then
  echo "FAIL: NONEXISTENT should fail"; exit 1
fi
echo "PASS: NONEXISTENT correctly failed"

# Test 3: package missing review-log fails
mkdir -p "$ROOT/.ai/packages/TEST-BAD/gates"
cp "$ROOT/.ai/packages/FEAT-001/package.yaml" "$ROOT/.ai/packages/TEST-BAD/package.yaml"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/FEAT-001/TEST-BAD/g' "$ROOT/.ai/packages/TEST-BAD/package.yaml"
else
  sed -i 's/FEAT-001/TEST-BAD/g' "$ROOT/.ai/packages/TEST-BAD/package.yaml"
fi
cp "$ROOT/.ai/packages/FEAT-001/classification.yaml" "$ROOT/.ai/packages/TEST-BAD/"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/FEAT-001/TEST-BAD/g' "$ROOT/.ai/packages/TEST-BAD/classification.yaml"
else
  sed -i 's/FEAT-001/TEST-BAD/g' "$ROOT/.ai/packages/TEST-BAD/classification.yaml"
fi
if "$SCRIPT" TEST-BAD 2>/dev/null; then
  echo "FAIL: TEST-BAD should fail without artifacts"; exit 1
fi
echo "PASS: TEST-BAD correctly failed"

# Test 4: FEAT-003 still passes (regression)
output=$("$SCRIPT" FEAT-003 2>&1) || { echo "FAIL: FEAT-003 regression"; exit 1; }

# Test 5: --enforce turns matrix warning into failure
mkdir -p "$ROOT/.ai/packages/TEST-NOMATRIX/gates"
cat > "$ROOT/.ai/packages/TEST-NOMATRIX/package.yaml" <<'EOF'
id: TEST-NOMATRIX
owner: test
profile: routine
mode: loop
status: in_progress
phases:
  requirements:
    status: archived
    artifact_version: v1
children: []
EOF
echo "package_id: TEST-NOMATRIX" > "$ROOT/.ai/packages/TEST-NOMATRIX/classification.yaml"
mkdir -p "$ROOT/artifacts/TEST-NOMATRIX/01-requirements"
for f in PRD.md user-stories.md acceptance-criteria.md review-log.md; do
  echo "status: approved" > "$ROOT/artifacts/TEST-NOMATRIX/01-requirements/$f"
done
cat > "$ROOT/.ai/packages/TEST-NOMATRIX/gates/requirements-1.md" <<'EOF'
# Gate: requirements (attempt 1)

result: pass
profile: routine
mode: loop

artifacts_checked:
  - artifacts/TEST-NOMATRIX/01-requirements/PRD.md (v1)
  - artifacts/TEST-NOMATRIX/01-requirements/user-stories.md (v1)
  - artifacts/TEST-NOMATRIX/01-requirements/acceptance-criteria.md (v1)
  - artifacts/TEST-NOMATRIX/01-requirements/review-log.md
  - traceability/TEST-NOMATRIX/matrix.md
  - traceability/TEST-NOMATRIX/package-evidence-index.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile

findings: []
reentry: 0
next: implementation
EOF
output=$("$SCRIPT" TEST-NOMATRIX 2>&1) || { echo "FAIL: TEST-NOMATRIX should pass with warning"; exit 1; }
echo "$output" | grep -q "WARN" || { echo "FAIL: TEST-NOMATRIX should warn without matrix"; exit 1; }
if "$SCRIPT" --enforce TEST-NOMATRIX 2>/dev/null; then
  echo "FAIL: --enforce should fail without matrix"; exit 1
fi
echo "PASS: enforce flag works"

# Test 5b: --enforce requires package evidence index when matrix is present
mkdir -p "$ROOT/.ai/packages/TEST-NOINDEX/gates"
cat > "$ROOT/.ai/packages/TEST-NOINDEX/package.yaml" <<'EOF'
id: TEST-NOINDEX
owner: test
profile: routine
mode: loop
status: in_progress
phases:
  requirements:
    status: archived
    artifact_version: v1
children: []
EOF
echo "package_id: TEST-NOINDEX" > "$ROOT/.ai/packages/TEST-NOINDEX/classification.yaml"
mkdir -p "$ROOT/artifacts/TEST-NOINDEX/01-requirements"
for f in PRD.md user-stories.md acceptance-criteria.md review-log.md; do
  echo "status: approved" > "$ROOT/artifacts/TEST-NOINDEX/01-requirements/$f"
done
cat > "$ROOT/.ai/packages/TEST-NOINDEX/gates/requirements-1.md" <<'EOF'
# Gate: requirements (attempt 1)

result: pass
profile: routine
mode: loop

artifacts_checked:
  - artifacts/TEST-NOINDEX/01-requirements/PRD.md (v1)
  - artifacts/TEST-NOINDEX/01-requirements/user-stories.md (v1)
  - artifacts/TEST-NOINDEX/01-requirements/acceptance-criteria.md (v1)
  - artifacts/TEST-NOINDEX/01-requirements/review-log.md
  - traceability/TEST-NOINDEX/matrix.md
  - traceability/TEST-NOINDEX/package-evidence-index.md

checklist:
  - [x] L1 self-review complete, no blocking failures
  - [x] Required artifacts exist for profile

findings: []
reentry: 0
next: implementation
EOF
mkdir -p "$ROOT/traceability/TEST-NOINDEX"
cat > "$ROOT/traceability/TEST-NOINDEX/matrix.md" <<'EOF'
# Traceability Matrix — TEST-NOINDEX
EOF
if output=$("$SCRIPT" --enforce TEST-NOINDEX 2>&1); then
  echo "FAIL: --enforce should fail without package-evidence-index"; exit 1
fi
echo "$output" | grep -q "missing traceability/TEST-NOINDEX/package-evidence-index.md (enforce mode)" || {
  echo "FAIL: expected missing package-evidence-index error"
  echo "$output"
  exit 1
}
echo "PASS: package evidence index enforce check works"

# Test 5c: compatibility fallback required package files come from policy, not verifier defaults
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy compatibility_matrix_only
output=$("$SCRIPT" --enforce TEST-NOINDEX 2>&1) || {
  echo "FAIL: TEST-NOINDEX enforce should pass when compatibility fallback requires only matrix.md"
  echo "$output"
  exit 1
}
echo "$output" | grep -q "PASS" || {
  echo "FAIL: expected PASS when policy compatibility fallback omits package-evidence-index"
  echo "$output"
  exit 1
}
restore_policy

# Test 5d: quoted/commented compatibility when_missing fallback still activates policy fallback files
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy quoted_compatibility_matrix_only
output=$("$SCRIPT" --enforce TEST-NOINDEX 2>&1) || {
  echo "FAIL: TEST-NOINDEX enforce should pass when quoted/commented compatibility fallback requires only matrix.md"
  echo "$output"
  exit 1
}
echo "$output" | grep -q "PASS" || {
  echo "FAIL: expected PASS when quoted/commented when_missing parses as fallback"
  echo "$output"
  exit 1
}
restore_policy

# Test 6: copied FEAT-003 fixture passes when required contract bindings are present
if [[ -d "$ROOT/.ai/packages/FEAT-003" ]]; then
  copy_feat003_fixture TEST-FEAT003
  ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003/gates/implementation-1.md" "artifacts/TEST-FEAT003/04-implementation/coding-log.md"
  ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003/gates/release-1.md" "artifacts/TEST-FEAT003/07-release-retro/retro.md"
  output=$("$SCRIPT" TEST-FEAT003 2>&1) || { echo "FAIL: TEST-FEAT003 should pass"; echo "$output"; exit 1; }
  output=$("$SCRIPT" --enforce TEST-FEAT003 2>&1) || { echo "FAIL: TEST-FEAT003 enforce should pass"; echo "$output"; exit 1; }
fi

# Test 6a: gate bindings accept @v1 artifact suffixes
copy_feat003_fixture TEST-FEAT003-ATV
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-ATV/gates/implementation-1.md" "artifacts/TEST-FEAT003-ATV/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-ATV/gates/release-1.md" "artifacts/TEST-FEAT003-ATV/07-release-retro/retro.md"
replace_token_in_tree " (v1)" "@v1" "$ROOT/.ai/packages/TEST-FEAT003-ATV/gates"
output=$("$SCRIPT" TEST-FEAT003-ATV 2>&1) || {
  echo "FAIL: TEST-FEAT003-ATV should pass with @v1 gate bindings"
  echo "$output"
  exit 1
}
echo "PASS: @v1 gate binding syntax works"

# Test 6aa: baseline verifier requires package evidence bindings in gate artifacts_checked
copy_feat003_fixture TEST-FEAT003-PKGBIND
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND/gates/implementation-1.md" "artifacts/TEST-FEAT003-PKGBIND/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND/gates/release-1.md" "artifacts/TEST-FEAT003-PKGBIND/07-release-retro/retro.md"
remove_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND/gates/requirements-1.md" "traceability/TEST-FEAT003-PKGBIND/matrix.md"
remove_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND/gates/requirements-1.md" "traceability/TEST-FEAT003-PKGBIND/package-evidence-index.md"
if "$SCRIPT" TEST-FEAT003-PKGBIND 2>/dev/null; then
  echo "FAIL: TEST-FEAT003-PKGBIND should fail without package evidence gate bindings"
  exit 1
fi
echo "PASS: package evidence gate binding check works"

# Test 6ab: quoted gate_bindings true still enforces package evidence gate bindings
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy quoted_gate_bindings
copy_feat003_fixture TEST-FEAT003-PKGBIND-QUOTED
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND-QUOTED/gates/implementation-1.md" "artifacts/TEST-FEAT003-PKGBIND-QUOTED/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND-QUOTED/gates/release-1.md" "artifacts/TEST-FEAT003-PKGBIND-QUOTED/07-release-retro/retro.md"
remove_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND-QUOTED/gates/requirements-1.md" "traceability/TEST-FEAT003-PKGBIND-QUOTED/matrix.md"
remove_gate_binding "$ROOT/.ai/packages/TEST-FEAT003-PKGBIND-QUOTED/gates/requirements-1.md" "traceability/TEST-FEAT003-PKGBIND-QUOTED/package-evidence-index.md"
if "$SCRIPT" TEST-FEAT003-PKGBIND-QUOTED 2>/dev/null; then
  echo "FAIL: TEST-FEAT003-PKGBIND-QUOTED should fail when quoted gate_bindings still requires package evidence gate bindings"
  exit 1
fi
restore_policy
echo "PASS: quoted gate_bindings syntax works"

# Test 6b: incomplete gate artifact bindings fail verification
copy_feat003_fixture TEST-BINDING
ensure_gate_binding "$ROOT/.ai/packages/TEST-BINDING/gates/implementation-1.md" "artifacts/TEST-BINDING/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-BINDING/gates/release-1.md" "artifacts/TEST-BINDING/07-release-retro/retro.md"
remove_gate_binding "$ROOT/.ai/packages/TEST-BINDING/gates/code-review-1.md" "artifacts/TEST-BINDING/05-code-review/review-log.md (v1)"
if "$SCRIPT" TEST-BINDING 2>/dev/null; then
  echo "FAIL: TEST-BINDING should fail on incomplete gate bindings"; exit 1
fi
echo "PASS: gate artifact binding check works"

# Test 6c: parent release evidence must reference child evidence and readiness
copy_feat_parent_fixture TEST-FEATPARENT
copy_feat_child_fixture TEST-FEATPARENT-CHILD
retarget_parent_child_references TEST-FEATPARENT TEST-FEATPARENT-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEATPARENT/gates/implementation-1.md" "artifacts/TEST-FEATPARENT/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEATPARENT/gates/release-1.md" "artifacts/TEST-FEATPARENT/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-FEATPARENT/gates/release-1.md" "artifacts/TEST-FEATPARENT/07-release-retro/retro.md"
output=$("$SCRIPT" TEST-FEATPARENT 2>&1) || { echo "FAIL: TEST-FEATPARENT should pass"; echo "$output"; exit 1; }

copy_feat_parent_fixture TEST-PARENTCHILD
copy_feat_child_fixture TEST-PARENTCHILD-CHILD
retarget_parent_child_references TEST-PARENTCHILD TEST-PARENTCHILD-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTCHILD/gates/implementation-1.md" "artifacts/TEST-PARENTCHILD/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTCHILD/gates/release-1.md" "artifacts/TEST-PARENTCHILD/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTCHILD/gates/release-1.md" "artifacts/TEST-PARENTCHILD/07-release-retro/retro.md"
python3 - <<'PY' "$ROOT/.ai/packages/TEST-PARENTCHILD/gates/release-1.md" "TEST-PARENTCHILD-CHILD"
from pathlib import Path
import sys

path = Path(sys.argv[1])
child_id = sys.argv[2]
text = path.read_text()
text = text.replace(f"  - .ai/packages/{child_id}/package.yaml\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/requirements-1.md\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/design-1.md\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/test-plan-1.md\n", "", 1)
text = text.replace(f"  - traceability/{child_id}/package-evidence-index.md\n", "", 1)
lines = []
skip = False
for line in text.splitlines(keepends=True):
    if line.startswith("child_evidence:"):
        skip = True
        continue
    if skip and not line.startswith("  "):
        skip = False
    if skip:
        continue
    lines.append(line)
path.write_text("".join(lines))
PY
if "$SCRIPT" TEST-PARENTCHILD 2>/dev/null; then
  echo "FAIL: TEST-PARENTCHILD should fail without child evidence references"; exit 1
fi
echo "PASS: parent-child release evidence check works"

# Test 6cc: quoted parent_child_release scalars still enforce child evidence requirements
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy quoted_parent_child_release
copy_feat_parent_fixture TEST-PARENTCHILD-QUOTED
copy_feat_child_fixture TEST-PARENTCHILD-QUOTED-CHILD
retarget_parent_child_references TEST-PARENTCHILD-QUOTED TEST-PARENTCHILD-QUOTED-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTCHILD-QUOTED/gates/implementation-1.md" "artifacts/TEST-PARENTCHILD-QUOTED/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTCHILD-QUOTED/gates/release-1.md" "artifacts/TEST-PARENTCHILD-QUOTED/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTCHILD-QUOTED/gates/release-1.md" "artifacts/TEST-PARENTCHILD-QUOTED/07-release-retro/retro.md"
python3 - <<'PY' "$ROOT/.ai/packages/TEST-PARENTCHILD-QUOTED/gates/release-1.md" "TEST-PARENTCHILD-QUOTED-CHILD"
from pathlib import Path
import sys

path = Path(sys.argv[1])
child_id = sys.argv[2]
text = path.read_text()
text = text.replace(f"  - .ai/packages/{child_id}/package.yaml\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/requirements-1.md\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/design-1.md\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/test-plan-1.md\n", "", 1)
text = text.replace(f"  - traceability/{child_id}/package-evidence-index.md\n", "", 1)
lines = []
skip = False
for line in text.splitlines(keepends=True):
    if line.startswith("child_evidence:"):
        skip = True
        continue
    if skip and not line.startswith("  "):
        skip = False
    if skip:
        continue
    lines.append(line)
path.write_text("".join(lines))
PY
if "$SCRIPT" TEST-PARENTCHILD-QUOTED 2>/dev/null; then
  echo "FAIL: TEST-PARENTCHILD-QUOTED should fail when quoted parent_child_release values still require child evidence"
  exit 1
fi
restore_policy
echo "PASS: quoted parent_child_release syntax works"

copy_feat_parent_fixture TEST-PARENTSTATUS
copy_feat_child_fixture TEST-PARENTSTATUS-CHILD
retarget_parent_child_references TEST-PARENTSTATUS TEST-PARENTSTATUS-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTSTATUS/gates/implementation-1.md" "artifacts/TEST-PARENTSTATUS/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTSTATUS/gates/release-1.md" "artifacts/TEST-PARENTSTATUS/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTSTATUS/gates/release-1.md" "artifacts/TEST-PARENTSTATUS/07-release-retro/retro.md"
python3 - <<'PY' "$ROOT/.ai/packages/TEST-PARENTSTATUS/gates/release-1.md" "TEST-PARENTSTATUS-CHILD"
from pathlib import Path
import sys

path = Path(sys.argv[1])
child_id = sys.argv[2]
text = path.read_text().replace(
    "    status: ready_for_merge\n",
    "    status: ready_for_release\n",
    1,
)
path.write_text(text)
PY
if "$SCRIPT" TEST-PARENTSTATUS 2>/dev/null; then
  echo "FAIL: TEST-PARENTSTATUS should fail when child_evidence.status disagrees with the child manifest"
  exit 1
fi
echo "PASS: parent child status consistency check works"

copy_feat_parent_fixture TEST-PARENTLATEST
copy_feat_child_fixture TEST-PARENTLATEST-CHILD
retarget_parent_child_references TEST-PARENTLATEST TEST-PARENTLATEST-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST/gates/implementation-1.md" "artifacts/TEST-PARENTLATEST/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST/gates/release-1.md" "artifacts/TEST-PARENTLATEST/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST/gates/release-1.md" "artifacts/TEST-PARENTLATEST/07-release-retro/retro.md"
python3 - <<'PY' "$ROOT/.ai/packages/TEST-PARENTLATEST/gates/release-1.md" "TEST-PARENTLATEST-CHILD"
from pathlib import Path
import sys

path = Path(sys.argv[1])
child_id = sys.argv[2]
text = path.read_text().replace(
    f"    latest_gate: .ai/packages/{child_id}/gates/test-plan-1.md\n",
    f"    latest_gate: .ai/packages/{child_id}/gates/release-9.md\n",
    1,
)
path.write_text(text)
PY
if "$SCRIPT" TEST-PARENTLATEST 2>/dev/null; then
  echo "FAIL: TEST-PARENTLATEST should fail when latest_gate is not referenced in artifacts_checked"; exit 1
fi
echo "PASS: parent latest_gate consistency check works"

copy_feat_parent_fixture TEST-PARENTLATEST-STALE
copy_feat_child_fixture TEST-PARENTLATEST-STALE-CHILD
retarget_parent_child_references TEST-PARENTLATEST-STALE TEST-PARENTLATEST-STALE-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST-STALE/gates/implementation-1.md" "artifacts/TEST-PARENTLATEST-STALE/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST-STALE/gates/release-1.md" "artifacts/TEST-PARENTLATEST-STALE/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST-STALE/gates/release-1.md" "artifacts/TEST-PARENTLATEST-STALE/07-release-retro/retro.md"
cp "$ROOT/.ai/packages/TEST-PARENTLATEST-STALE-CHILD/gates/test-plan-1.md" \
  "$ROOT/.ai/packages/TEST-PARENTLATEST-STALE-CHILD/gates/implementation-1.md"
python3 - <<'PY' "$ROOT/.ai/packages/TEST-PARENTLATEST-STALE-CHILD/gates/implementation-1.md" "TEST-PARENTLATEST-STALE-CHILD"
from pathlib import Path
import sys

path = Path(sys.argv[1])
child_id = sys.argv[2]
text = path.read_text()
text = text.replace("# Gate: test-plan (attempt 1)", "# Gate: implementation (attempt 1)", 1)
text = text.replace(f"artifacts/{child_id}/03-test-plan/", f"artifacts/{child_id}/04-implementation/")
path.write_text(text)
PY
if "$SCRIPT" TEST-PARENTLATEST-STALE 2>/dev/null; then
  :
else
  echo "FAIL: TEST-PARENTLATEST-STALE should pass when a later-phase pass gate exists on disk but the child manifest is still archived at test-plan"
  exit 1
fi
echo "PASS: parent latest_gate archived phase wins over stale later pass gates"

copy_feat_parent_fixture TEST-PARENTLATEST-REENTRY
copy_feat_child_fixture TEST-PARENTLATEST-REENTRY-CHILD
retarget_parent_child_references TEST-PARENTLATEST-REENTRY TEST-PARENTLATEST-REENTRY-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY/gates/implementation-1.md" "artifacts/TEST-PARENTLATEST-REENTRY/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY/gates/release-1.md" "artifacts/TEST-PARENTLATEST-REENTRY/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY/gates/release-1.md" "artifacts/TEST-PARENTLATEST-REENTRY/07-release-retro/retro.md"
cp "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY-CHILD/gates/test-plan-1.md" \
  "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY-CHILD/gates/implementation-1.md"
python3 - <<'PY' \
  "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY-CHILD/gates/implementation-1.md" \
  "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY-CHILD/package.yaml" \
  "$ROOT/.ai/packages/TEST-PARENTLATEST-REENTRY/gates/release-1.md" \
  "TEST-PARENTLATEST-REENTRY-CHILD"
from pathlib import Path
import sys

gate_path = Path(sys.argv[1])
package_path = Path(sys.argv[2])
parent_gate_path = Path(sys.argv[3])
child_id = sys.argv[4]

gate_text = gate_path.read_text()
gate_text = gate_text.replace("# Gate: test-plan (attempt 1)", "# Gate: implementation (attempt 1)", 1)
gate_text = gate_text.replace(f"artifacts/{child_id}/03-test-plan/", f"artifacts/{child_id}/04-implementation/")
gate_path.write_text(gate_text)

package_text = package_path.read_text()
package_text = package_text.replace("status: ready_for_merge\n", "status: in_progress\n", 1)
package_text = package_text.replace(
    "  test-plan:\n    status: archived\n    artifact_version: v1\nchildren: []\n",
    "  test-plan:\n    status: archived\n    artifact_version: v1\n  implementation:\n    status: in_progress\nchildren: []\n",
    1,
)
package_path.write_text(package_text)

parent_gate_text = parent_gate_path.read_text()
parent_gate_text = parent_gate_text.replace(
    f"  - .ai/packages/{child_id}/gates/test-plan-1.md\n",
    f"  - .ai/packages/{child_id}/gates/implementation-1.md\n",
    1,
)
parent_gate_text = parent_gate_text.replace(
    f"    latest_gate: .ai/packages/{child_id}/gates/test-plan-1.md\n",
    f"    latest_gate: .ai/packages/{child_id}/gates/implementation-1.md\n",
    1,
)
parent_gate_path.write_text(parent_gate_text)
PY
if "$SCRIPT" TEST-PARENTLATEST-REENTRY 2>/dev/null; then
  echo "FAIL: TEST-PARENTLATEST-REENTRY should fail when latest_gate points to a stale retained pass gate beyond the child's current archived phase"
  exit 1
fi
echo "PASS: parent latest_gate archived-phase check works"

# Test 6d: parent-child release enforcement is controlled by policy
mv "$EVIDENCE_POLICY" "$EVIDENCE_POLICY_MALFORMED_BAK"
write_test_policy parent_child_disabled
copy_feat_parent_fixture TEST-PARENTDISABLED
copy_feat_child_fixture TEST-PARENTDISABLED-CHILD
retarget_parent_child_references TEST-PARENTDISABLED TEST-PARENTDISABLED-CHILD
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTDISABLED/gates/implementation-1.md" "artifacts/TEST-PARENTDISABLED/04-implementation/coding-log.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTDISABLED/gates/release-1.md" "artifacts/TEST-PARENTDISABLED/07-release-retro/known-issues.md"
ensure_gate_binding "$ROOT/.ai/packages/TEST-PARENTDISABLED/gates/release-1.md" "artifacts/TEST-PARENTDISABLED/07-release-retro/retro.md"
python3 - <<'PY' "$ROOT/.ai/packages/TEST-PARENTDISABLED/gates/release-1.md" "TEST-PARENTDISABLED-CHILD"
from pathlib import Path
import sys

path = Path(sys.argv[1])
child_id = sys.argv[2]
text = path.read_text()
text = text.replace(f"  - .ai/packages/{child_id}/package.yaml\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/requirements-1.md\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/design-1.md\n", "", 1)
text = text.replace(f"  - .ai/packages/{child_id}/gates/test-plan-1.md\n", "", 1)
text = text.replace(f"  - traceability/{child_id}/package-evidence-index.md\n", "", 1)
lines = []
skip = False
for line in text.splitlines(keepends=True):
    if line.startswith("child_evidence:"):
        skip = True
        continue
    if skip and not line.startswith("  "):
        skip = False
    if skip:
        continue
    lines.append(line)
path.write_text("".join(lines))
PY
output=$("$SCRIPT" TEST-PARENTDISABLED 2>&1) || {
  echo "FAIL: TEST-PARENTDISABLED should pass when parent-child release enforcement is disabled by policy"
  echo "$output"
  exit 1
}
echo "$output" | grep -q "PASS" || {
  echo "FAIL: expected PASS when policy disables parent-child release enforcement"
  echo "$output"
  exit 1
}
restore_policy

# Test 7: failed gate result fails verification
mkdir -p "$ROOT/.ai/packages/TEST-GATEFAIL/gates"
cp "$ROOT/.ai/packages/FEAT-001/package.yaml" "$ROOT/.ai/packages/TEST-GATEFAIL/package.yaml"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/.ai/packages/TEST-GATEFAIL/package.yaml"
else
  sed -i 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/.ai/packages/TEST-GATEFAIL/package.yaml"
fi
cp -R "$ROOT/.ai/packages/FEAT-001/gates" "$ROOT/.ai/packages/TEST-GATEFAIL/"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/.ai/packages/TEST-GATEFAIL/package.yaml"
  find "$ROOT/.ai/packages/TEST-GATEFAIL/gates" -type f -exec sed -i '' 's/FEAT-001/TEST-GATEFAIL/g' {} +
  sed -i '' 's/result: pass/result: fail/' "$ROOT/.ai/packages/TEST-GATEFAIL/gates/requirements-1.md"
else
  sed -i 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/.ai/packages/TEST-GATEFAIL/package.yaml"
  find "$ROOT/.ai/packages/TEST-GATEFAIL/gates" -type f -exec sed -i 's/FEAT-001/TEST-GATEFAIL/g' {} +
  sed -i 's/result: pass/result: fail/' "$ROOT/.ai/packages/TEST-GATEFAIL/gates/requirements-1.md"
fi
cp -R "$ROOT/artifacts/FEAT-001" "$ROOT/artifacts/TEST-GATEFAIL"
if [[ "$(uname)" == "Darwin" ]]; then
  find "$ROOT/artifacts/TEST-GATEFAIL" -type f -exec sed -i '' 's/FEAT-001/TEST-GATEFAIL/g' {} +
else
  find "$ROOT/artifacts/TEST-GATEFAIL" -type f -exec sed -i 's/FEAT-001/TEST-GATEFAIL/g' {} +
fi
cp "$ROOT/.ai/packages/FEAT-001/classification.yaml" "$ROOT/.ai/packages/TEST-GATEFAIL/"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/.ai/packages/TEST-GATEFAIL/classification.yaml"
else
  sed -i 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/.ai/packages/TEST-GATEFAIL/classification.yaml"
fi
mkdir -p "$ROOT/traceability/TEST-GATEFAIL"
cp "$ROOT/traceability/FEAT-001/matrix.md" "$ROOT/traceability/TEST-GATEFAIL/matrix.md"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/traceability/TEST-GATEFAIL/matrix.md"
else
  sed -i 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/traceability/TEST-GATEFAIL/matrix.md"
fi
if "$SCRIPT" TEST-GATEFAIL 2>/dev/null; then
  echo "FAIL: TEST-GATEFAIL should fail on gate result fail"; exit 1
fi
echo "PASS: gate result check works"

# Test 8: ready_for_release requires all profile phases archived
mkdir -p "$ROOT/.ai/packages/TEST-INCOMPLETE/gates"
cat > "$ROOT/.ai/packages/TEST-INCOMPLETE/package.yaml" <<'EOF'
id: TEST-INCOMPLETE
owner: test
profile: standard
mode: loop
status: ready_for_release
phases:
  requirements:
    status: archived
    artifact_version: v1
  design:
    status: archived
    artifact_version: v1
  test-plan:
    status: archived
    artifact_version: v1
children: []
EOF
echo "package_id: TEST-INCOMPLETE" > "$ROOT/.ai/packages/TEST-INCOMPLETE/classification.yaml"
for phase in requirements design test-plan; do
  case "$phase" in
    requirements)
      phase_dir="01-requirements"
      artifacts="PRD.md user-stories.md acceptance-criteria.md review-log.md"
      next_phase="design"
      ;;
    design)
      phase_dir="02-design"
      artifacts="architecture.md review-log.md"
      next_phase="test-plan"
      ;;
    test-plan)
      phase_dir="03-test-plan"
      artifacts="test-strategy.md test-cases.md review-log.md"
      next_phase="ready_for_merge"
      ;;
  esac
  {
    echo "# Gate: $phase (attempt 1)"
    echo
    echo "result: pass"
    echo "profile: standard"
    echo "mode: loop"
    echo
    echo "artifacts_checked:"
    for artifact in $artifacts; do
      echo "  - artifacts/TEST-INCOMPLETE/$phase_dir/$artifact (v1)"
    done
    echo
    echo "checklist:"
    echo "  - [x] L1 self-review complete, no blocking failures"
    echo "  - [x] Required artifacts exist for profile"
    echo
    echo "findings: []"
    echo "reentry: 0"
    echo "next: $next_phase"
  } > "$ROOT/.ai/packages/TEST-INCOMPLETE/gates/${phase}-1.md"
done
cp -R "$ROOT/artifacts/FEAT-001" "$ROOT/artifacts/TEST-INCOMPLETE"
if [[ "$(uname)" == "Darwin" ]]; then
  find "$ROOT/artifacts/TEST-INCOMPLETE" -type f -exec sed -i '' 's/FEAT-001/TEST-INCOMPLETE/g' {} +
else
  find "$ROOT/artifacts/TEST-INCOMPLETE" -type f -exec sed -i 's/FEAT-001/TEST-INCOMPLETE/g' {} +
fi
mkdir -p "$ROOT/traceability/TEST-INCOMPLETE"
cp "$ROOT/traceability/FEAT-001/matrix.md" "$ROOT/traceability/TEST-INCOMPLETE/matrix.md"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/FEAT-001/TEST-INCOMPLETE/g' "$ROOT/traceability/TEST-INCOMPLETE/matrix.md"
else
  sed -i 's/FEAT-001/TEST-INCOMPLETE/g' "$ROOT/traceability/TEST-INCOMPLETE/matrix.md"
fi
if "$SCRIPT" TEST-INCOMPLETE 2>/dev/null; then
  echo "FAIL: TEST-INCOMPLETE should fail (ready_for_release with 3/7 phases)"; exit 1
fi
echo "PASS: profile completeness check works"

# Full-regression check: committed demo evidence indexes must remain present
[[ -f "$ROOT/traceability/FEAT-001/package-evidence-index.md" ]] || {
  echo "FAIL: missing committed package evidence index for FEAT-001"; exit 1
}
[[ -f "$ROOT/traceability/FEAT-003/package-evidence-index.md" ]] || {
  echo "FAIL: missing committed package evidence index for FEAT-003"; exit 1
}
[[ -f "$ROOT/traceability/FEAT-PARENT/package-evidence-index.md" ]] || {
  echo "FAIL: missing committed package evidence index for FEAT-PARENT"; exit 1
}
[[ -f "$ROOT/traceability/FEAT-CHILD/package-evidence-index.md" ]] || {
  echo "FAIL: missing committed package evidence index for FEAT-CHILD"; exit 1
}
echo "PASS: committed package evidence indexes exist for FEAT-001, FEAT-003, FEAT-PARENT, and FEAT-CHILD"

echo "All loop-verify tests passed"
