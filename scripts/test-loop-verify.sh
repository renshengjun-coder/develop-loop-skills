#!/usr/bin/env bash
# scripts/test-loop-verify.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/loop-verify.sh"

# Test 1: FEAT-001 demo package passes
output=$("$SCRIPT" FEAT-001 2>&1) || { echo "FAIL: FEAT-001 should pass"; echo "$output"; exit 1; }
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
rm -rf "$ROOT/.ai/packages/TEST-BAD"
echo "PASS: TEST-BAD correctly failed"

# Test 4: FEAT-001 still passes (regression)
output=$("$SCRIPT" FEAT-001 2>&1) || { echo "FAIL: FEAT-001 regression"; exit 1; }

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
echo "result: pass" > "$ROOT/.ai/packages/TEST-NOMATRIX/gates/requirements-1.md"
output=$("$SCRIPT" TEST-NOMATRIX 2>&1) || { echo "FAIL: TEST-NOMATRIX should pass with warning"; exit 1; }
echo "$output" | grep -q "WARN" || { echo "FAIL: TEST-NOMATRIX should warn without matrix"; exit 1; }
if "$SCRIPT" --enforce TEST-NOMATRIX 2>/dev/null; then
  echo "FAIL: --enforce should fail without matrix"; exit 1
fi
rm -rf "$ROOT/.ai/packages/TEST-NOMATRIX" "$ROOT/artifacts/TEST-NOMATRIX"
echo "PASS: enforce flag works"

# Test 6: FEAT-003 passes when present
if [[ -d "$ROOT/.ai/packages/FEAT-003" ]]; then
  output=$("$SCRIPT" FEAT-003 2>&1) || { echo "FAIL: FEAT-003 should pass"; echo "$output"; exit 1; }
  output=$("$SCRIPT" --enforce FEAT-003 2>&1) || { echo "FAIL: FEAT-003 enforce should pass"; echo "$output"; exit 1; }
fi

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
  sed -i '' 's/result: pass/result: fail/' "$ROOT/.ai/packages/TEST-GATEFAIL/gates/requirements-1.md"
else
  sed -i 's/FEAT-001/TEST-GATEFAIL/g' "$ROOT/.ai/packages/TEST-GATEFAIL/package.yaml"
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
rm -rf "$ROOT/.ai/packages/TEST-GATEFAIL" "$ROOT/artifacts/TEST-GATEFAIL" "$ROOT/traceability/TEST-GATEFAIL"
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
  echo "result: pass" > "$ROOT/.ai/packages/TEST-INCOMPLETE/gates/${phase}-1.md"
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
rm -rf "$ROOT/.ai/packages/TEST-INCOMPLETE" "$ROOT/artifacts/TEST-INCOMPLETE" "$ROOT/traceability/TEST-INCOMPLETE"
echo "PASS: profile completeness check works"

echo "All loop-verify tests passed"
