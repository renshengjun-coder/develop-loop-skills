#!/usr/bin/env bash
# bin/lib/init.sh
set -euo pipefail

devloop_cmd_init() {
  local with_ci=0 upgrade=0 force=0
  local mode="skip"
  local root pack proj tpl

  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  # shellcheck source=bin/lib/common.sh
  source "$root/bin/lib/common.sh"
  # shellcheck source=bin/lib/merge-agents.sh
  source "$root/bin/lib/merge-agents.sh"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --with-ci) with_ci=1; shift ;;
      --upgrade) upgrade=1; shift ;;
      --force) force=1; shift ;;
      *) echo "ERROR: unknown init flag $1" >&2; exit 1 ;;
    esac
  done

  if [[ "$force" -eq 1 ]]; then
    if ! devloop_confirm "Overwrite devloop template files in this project?"; then
      echo "Aborted."
      exit 1
    fi
    mode="force"
  elif [[ "$upgrade" -eq 1 ]]; then
    mode="upgrade"
  else
    mode="skip"
  fi

  pack="$(devloop_pack_dir)"
  proj="$(pwd)"
  tpl="$pack/templates"

  devloop_copy_tree_file "$tpl/.ai/config/profiles.yaml" "$proj/.ai/config/profiles.yaml" "$mode"
  devloop_copy_tree_file "$tpl/.ai/packages/_template/package.yaml" "$proj/.ai/packages/_template/package.yaml" "$mode"
  devloop_copy_tree_file "$tpl/.ai/packages/_template/classification.yaml" "$proj/.ai/packages/_template/classification.yaml" "$mode"
  devloop_copy_tree_file "$tpl/scripts/loop-verify.sh" "$proj/scripts/loop-verify.sh" "$mode"
  devloop_copy_tree_file "$tpl/scripts/test-loop-verify.sh" "$proj/scripts/test-loop-verify.sh" "$mode"
  chmod +x "$proj/scripts/loop-verify.sh" "$proj/scripts/test-loop-verify.sh" 2>/dev/null || true

  devloop_merge_agents_md "$tpl/AGENTS.md" "$proj/AGENTS.md" "$mode"

  if [[ ! -f "$proj/artifacts/.gitkeep" ]]; then
    mkdir -p "$proj/artifacts"
    touch "$proj/artifacts/.gitkeep"
    echo "created $proj/artifacts/.gitkeep"
  else
    echo "skip  $proj/artifacts/.gitkeep"
  fi

  if [[ ! -f "$proj/traceability/.gitkeep" ]]; then
    mkdir -p "$proj/traceability"
    touch "$proj/traceability/.gitkeep"
    echo "created $proj/traceability/.gitkeep"
  else
    echo "skip  $proj/traceability/.gitkeep"
  fi

  devloop_copy_tree_file "$tpl/.devloop-version" "$proj/.devloop-version" "$mode"
  devloop_copy_tree_file "$tpl/.cursor/rules/devloop.mdc" "$proj/.cursor/rules/devloop.mdc" "$mode"

  if [[ "$with_ci" -eq 1 ]]; then
    devloop_copy_tree_file "$tpl/.github/workflows/loop-verify.yml" "$proj/.github/workflows/loop-verify.yml" "$mode"
  fi

  echo "devloop init complete (template v$(devloop_version))"
}
