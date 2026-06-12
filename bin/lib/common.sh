#!/usr/bin/env bash
# bin/lib/common.sh — shared helpers for devloop CLI
set -euo pipefail

devloop_root() {
  if [[ -n "${DEVLOOP_PKG_ROOT:-}" ]]; then
    echo "$DEVLOOP_PKG_ROOT"
    return 0
  fi
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

devloop_pack_dir() {
  local root
  root="$(devloop_root)"
  if [[ -d "$root/pack/skills" ]]; then
    echo "$root/pack"
    return 0
  fi
  echo "ERROR: pack/ not found. Run: $root/scripts/build-pack.sh" >&2
  return 1
}

devloop_version() {
  local pack
  pack="$(devloop_pack_dir)"
  tr -d '[:space:]' < "$pack/VERSION"
}

devloop_user_home() {
  if [[ -n "${DEVLOOP_HOME:-}" ]]; then
    echo "$DEVLOOP_HOME"
    return 0
  fi
  echo "$HOME"
}

devloop_copy_file() {
  local src="$1" dest="$2" mode="${3:-skip}"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    case "$mode" in
      skip) echo "skip  $dest"; return 0 ;;
      upgrade|force) cp "$src" "$dest"; echo "updated $dest"; return 0 ;;
      *) echo "ERROR: unknown mode $mode" >&2; return 1 ;;
    esac
  fi
  cp "$src" "$dest"
  echo "created $dest"
}

devloop_copy_tree_file() {
  local src="$1" dest="$2" mode="${3:-skip}"
  devloop_copy_file "$src" "$dest" "$mode"
}

devloop_confirm() {
  local msg="$1"
  if [[ "${DEVLOOP_YES:-}" == "1" ]]; then
    return 0
  fi
  read -r -p "$msg [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}
