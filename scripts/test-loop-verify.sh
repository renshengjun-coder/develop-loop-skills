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

echo "All loop-verify tests passed"
