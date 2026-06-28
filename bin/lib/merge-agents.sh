#!/usr/bin/env bash
# bin/lib/merge-agents.sh — merge Develop Loop block into AGENTS.md
set -euo pipefail

DEVLOOP_AGENTS_BEGIN="<!-- DEVLOOP:BEGIN -->"
DEVLOOP_AGENTS_END="<!-- DEVLOOP:END -->"

devloop_merge_agents_md() {
  local template="$1" target="$2" mode="${3:-skip}"
  local block wrapped tmp repl_file
  block="$(cat "$template")"
  wrapped="${DEVLOOP_AGENTS_BEGIN}
${block}
${DEVLOOP_AGENTS_END}"

  if [[ ! -f "$target" ]]; then
    printf '%s\n' "$wrapped" > "$target"
    echo "created $target"
    return 0
  fi

  if grep -q "$DEVLOOP_AGENTS_BEGIN" "$target"; then
    if [[ "$mode" == "skip" ]]; then
      echo "skip  $target (devloop block present)"
      return 0
    fi
    tmp="$(mktemp)"
    repl_file="$(mktemp)"
    printf '%s\n' "$wrapped" > "$repl_file"
    awk -v begin="$DEVLOOP_AGENTS_BEGIN" -v end="$DEVLOOP_AGENTS_END" -v repl_file="$repl_file" '
      function emit_replacement(line) {
        while ((getline line < repl_file) > 0) {
          print line
        }
        close(repl_file)
      }
      BEGIN { inblock=0 }
      $0 == begin { inblock=1; emit_replacement(); next }
      inblock && $0 == end { inblock=0; next }
      !inblock { print }
    ' "$target" > "$tmp"
    rm -f "$repl_file"
    mv "$tmp" "$target"
    echo "updated $target (replaced devloop block)"
    return 0
  fi

  printf '\n%s\n' "$wrapped" >> "$target"
  echo "appended devloop block to $target"
}
