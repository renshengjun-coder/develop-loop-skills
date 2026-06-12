#!/usr/bin/env bash
# bin/lib/install.sh
set -euo pipefail

_SKILLS=(
  lifecycle-loop 01-requirement 02-design 03-test-plan
  04-implementation 05-code-review 06-test-report 07-release-retro
  traceability
)

devloop_cmd_install() {
  local global=0 upgrade=0
  local runtimes="cursor,claude,codex"
  local root pack mode uh
  local -a runtime_list

  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  # shellcheck source=bin/lib/common.sh
  source "$root/bin/lib/common.sh"
  # shellcheck source=bin/lib/merge-agents.sh
  source "$root/bin/lib/merge-agents.sh"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global) global=1; shift ;;
      --upgrade) upgrade=1; shift ;;
      --runtimes) runtimes="$2"; shift 2 ;;
      *) echo "ERROR: unknown install flag $1" >&2; exit 1 ;;
    esac
  done

  [[ "$global" -eq 1 ]] || {
    echo "Usage: devloop install --global [--upgrade] [--runtimes cursor,claude,codex]" >&2
    exit 1
  }

  pack="$(devloop_pack_dir)"
  mode="skip"
  [[ "$upgrade" -eq 1 ]] && mode="force"

  IFS=',' read -r -a runtime_list <<< "$runtimes"
  uh="$(devloop_user_home)"

  for rt in "${runtime_list[@]}"; do
    case "$rt" in
      cursor)
        for skill in "${_SKILLS[@]}"; do
          dest="$uh/.cursor/skills/$skill"
          mkdir -p "$dest"
          cp "$pack/skills/$skill/SKILL.md" "$dest/SKILL.md"
          [[ -f "$pack/skills/$skill/reference.md" ]] && cp "$pack/skills/$skill/reference.md" "$dest/reference.md"
          echo "installed cursor:$skill"
        done
        ;;
      claude)
        for skill in "${_SKILLS[@]}"; do
          dest="$uh/.claude/skills/$skill"
          mkdir -p "$dest"
          cp "$pack/skills/$skill/SKILL.md" "$dest/SKILL.md"
          [[ -f "$pack/skills/$skill/reference.md" ]] && cp "$pack/skills/$skill/reference.md" "$dest/reference.md"
          echo "installed claude:$skill"
        done
        ;;
      codex)
        codex_agents="$uh/.codex/AGENTS.md"
        mkdir -p "$(dirname "$codex_agents")"
        devloop_merge_agents_md "$pack/templates/AGENTS.md" "$codex_agents" "$mode"
        echo "installed codex:AGENTS.md block"
        ;;
      *)
        echo "WARN: unknown runtime $rt (skipped)"
        ;;
    esac
  done

  echo "devloop global install complete (v$(devloop_version))"
}
