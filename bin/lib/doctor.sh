#!/usr/bin/env bash
# bin/lib/doctor.sh
set -euo pipefail

_SKILLS=(lifecycle-loop 01-requirement traceability)

devloop_cmd_doctor() {
  local root uh errors=0 pv cv
  local -a required

  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  # shellcheck source=bin/lib/common.sh
  source "$root/bin/lib/common.sh"
  uh="$(devloop_user_home)"

  echo "== devloop doctor =="

  for skill in "${_SKILLS[@]}"; do
    if [[ -f "$uh/.cursor/skills/$skill/SKILL.md" ]]; then
      echo "ok    cursor skill $skill"
    else
      echo "MISS  cursor skill $skill (run: devloop install --global)"
      errors=$((errors + 1))
    fi
  done

  required=(
    .ai/config/profiles.yaml
    .ai/packages/_template/package.yaml
    scripts/loop-verify.sh
    AGENTS.md
    artifacts/.gitkeep
    traceability/.gitkeep
    .devloop-version
  )

  for f in "${required[@]}"; do
    if [[ -f "$f" ]]; then
      echo "ok    project $f"
    else
      echo "MISS  project $f (run: devloop init)"
      errors=$((errors + 1))
    fi
  done

  if [[ -x scripts/loop-verify.sh ]]; then
    echo "ok    scripts/loop-verify.sh executable"
  else
    echo "MISS  scripts/loop-verify.sh not executable"
    errors=$((errors + 1))
  fi

  if [[ -f .devloop-version ]]; then
    pv="$(tr -d '[:space:]' < .devloop-version)"
    cv="$(devloop_version)"
    if [[ "$pv" != "$cv" ]]; then
      echo "WARN  project .devloop-version ($pv) != package ($cv); run: devloop init --upgrade"
    else
      echo "ok    version $pv"
    fi
  fi

  if [[ "$errors" -gt 0 ]]; then
    echo "FAIL: $errors issue(s)"
    exit 1
  fi
  echo "PASS: devloop doctor"
}
