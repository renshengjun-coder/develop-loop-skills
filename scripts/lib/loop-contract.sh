#!/usr/bin/env bash

contract_policy_path_from_profiles() {
  local profiles_file="$1"

  awk '
    /^contract:/ { in_contract=1; next }
    in_contract && /^[a-z_]+:/ { exit }
    in_contract && /^[[:space:]]*evidence_policy:[[:space:]]*/ {
      line=$0
      sub(/^[^:]*:[[:space:]]*/, "", line)
      sub(/[[:space:]]+#.*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

      if (line ~ /^".*"$/ || line ~ /^'\''.*'\''$/) {
        print substr(line, 2, length(line) - 2)
      } else {
        print line
      }
      exit
    }
  ' "$profiles_file"
}

contract_resolve_path() {
  local root="$1"
  local path="$2"

  [[ -n "$path" ]] || return 1

  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$root/$path"
  fi
}

contract_required_phase_files() {
  local policy_file="$1"
  local profile="$2"
  local phase="$3"

  awk -v profile="$profile" -v phase="$phase" '
    /^profiles:/ { in_profiles=1; next }
    in_profiles && /^  [a-z_]+:/ {
      current_profile=$1
      sub(/:$/, "", current_profile)
      in_profile=(current_profile == profile)
      in_required=0
      in_phase=0
      next
    }
    !in_profile { next }
    /^    required_artifacts:/ { in_required=1; next }
    in_required && /^    [a-z_]+:/ { in_required=0; in_phase=0 }
    !in_required { next }
    /^      [a-z0-9-]+:/ {
      current_phase=$1
      sub(/:$/, "", current_phase)
      in_phase=(current_phase == phase)
      next
    }
    in_phase && /^        - / {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      print line
    }
  ' "$policy_file"
}

contract_required_package_files() {
  local policy_file="$1"
  local output=""
  local status=0

  if output=$(
    awk '
      BEGIN {
        section_found=0
        key_found=0
        item_count=0
      }
      /^human_readable_evidence:/ {
        section_found=1
        in_section=1
        next
      }
      in_section && /^[a-z_]+:/ {
        in_section=0
      }
      !in_section { next }
      /^  required_package_files:/ {
        key_found=1
        in_list=1
        next
      }
      in_list && /^    - / {
        line=$0
        sub(/^[[:space:]]*-[[:space:]]*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        print line
        item_count++
        next
      }
      END {
        if (!section_found) {
          exit 2
        }
        if (!key_found || item_count == 0) {
          exit 3
        }
      }
    ' "$policy_file"
  ); then
    status=0
  else
    status=$?
  fi

  case "$status" in
    0)
      printf '%s\n' "$output"
      ;;
    2)
      printf '%s\n' "matrix.md"
      printf '%s\n' "package-evidence-index.md"
      ;;
    *)
      return 1
      ;;
  esac
}

contract_required_package_files_error() {
  local policy_file="$1"

  if awk '
    /^human_readable_evidence:/ { section_found=1 }
    END { exit(section_found ? 0 : 1) }
  ' "$policy_file"; then
    printf '%s\n' "invalid human_readable_evidence.required_package_files in configured evidence policy"
  fi
}
