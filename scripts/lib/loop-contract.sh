#!/usr/bin/env bash

contract_trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

contract_normalize_scalar() {
  local value
  value=$(contract_trim_whitespace "$1")

  if [[ "$value" =~ ^\".*\"$ || "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi

  contract_trim_whitespace "$value"
}

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
        if (!key_found) {
          exit 2
        }
        if (item_count == 0) {
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
      local when_missing fallback_output fallback_status
      when_missing=$(awk '
        /^compatibility:/ { in_compatibility=1; next }
        in_compatibility && /^[a-z_]+:/ { exit }
        !in_compatibility { next }
        /^  human_readable_evidence:/ { in_hre=1; next }
        in_hre && /^  [a-z_]+:/ { exit }
        !in_hre { next }
        /^    when_missing:/ {
          line=$0
          sub(/^[^:]*:[[:space:]]*/, "", line)
          sub(/[[:space:]]+#.*/, "", line)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
          print line
          exit
        }
      ' "$policy_file")

      when_missing=$(contract_normalize_scalar "$when_missing")

      if [[ "$when_missing" != "fallback" ]]; then
        return 2
      fi

      if fallback_output=$(
        awk '
          BEGIN {
            compatibility_found=0
            hre_found=0
            key_found=0
            item_count=0
          }
          /^compatibility:/ { in_compatibility=1; compatibility_found=1; next }
          in_compatibility && /^[a-z_]+:/ { exit }
          !in_compatibility { next }
          /^  human_readable_evidence:/ { in_hre=1; hre_found=1; next }
          in_hre && /^  [a-z_]+:/ { exit }
          !in_hre { next }
          /^    fallback_required_package_files:/ { key_found=1; in_list=1; next }
          in_list && /^      - / {
            line=$0
            sub(/^[[:space:]]*-[[:space:]]*/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            print line
            item_count++
            next
          }
          END {
            if (!compatibility_found || !hre_found || !key_found || item_count == 0) {
              exit 4
            }
          }
        ' "$policy_file"
      ); then
        fallback_status=0
      else
        fallback_status=$?
      fi

      [[ $fallback_status -eq 0 ]] || return "$fallback_status"
      printf '%s\n' "$fallback_output"
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
    return 0
  fi

  if awk '
    /^compatibility:/ { in_compatibility=1; next }
    in_compatibility && /^[a-z_]+:/ { exit }
    !in_compatibility { next }
    /^  human_readable_evidence:/ { in_hre=1; section_found=1; next }
    in_hre && /^  [a-z_]+:/ { exit }
    END { exit(section_found ? 0 : 1) }
  ' "$policy_file"; then
    printf '%s\n' "invalid compatibility.human_readable_evidence.fallback_required_package_files in configured evidence policy"
    return 0
  fi

  printf '%s\n' "human_readable_evidence.required_package_files missing in configured evidence policy"
}

contract_human_readable_gate_bindings_required() {
  local policy_file="$1"
  local raw_value normalized_value status

  raw_value=$(
    awk '
      /^human_readable_evidence:/ { in_section=1; next }
      in_section && /^[a-z_]+:/ { exit }
      !in_section { next }
      /^  gate_bindings:/ { in_gate_bindings=1; next }
      in_gate_bindings && /^  [a-z_]+:/ { exit }
      !in_gate_bindings { next }
      /^    require_in_artifacts_checked:/ {
        line=$0
        sub(/^[^:]*:[[:space:]]*/, "", line)
        sub(/[[:space:]]+#.*/, "", line)
        print line
        found=1
        exit
      }
      END { exit(found ? 0 : 2) }
    ' "$policy_file"
  )
  status=$?
  if [[ $status -ne 0 ]]; then
    return "$status"
  fi

  normalized_value=$(contract_normalize_scalar "$raw_value")

  case "$normalized_value" in
    true) return 0 ;;
    false) return 1 ;;
    *) return 2 ;;
  esac
}

contract_human_readable_gate_bindings_error() {
  printf '%s\n' "invalid human_readable_evidence.gate_bindings.require_in_artifacts_checked in configured evidence policy"
}

contract_parent_child_release_required() {
  local policy_file="$1"
  local raw_value normalized_value status

  raw_value=$(
    awk '
      /^parent_child_release:/ { in_section=1; next }
      in_section && /^[a-z_]+:/ { exit }
      !in_section { next }
      /^  when_parent_has_children:/ {
        line=$0
        sub(/^[^:]*:[[:space:]]*/, "", line)
        sub(/[[:space:]]+#.*/, "", line)
        print line
        found=1
        exit
      }
      END { exit(found ? 0 : 2) }
    ' "$policy_file"
  )
  status=$?
  if [[ $status -ne 0 ]]; then
    return "$status"
  fi

  normalized_value=$(contract_normalize_scalar "$raw_value")

  case "$normalized_value" in
    require) return 0 ;;
    ignore) return 1 ;;
    *) return 2 ;;
  esac
}

contract_parent_child_release_error() {
  printf '%s\n' "invalid parent_child_release.when_parent_has_children in configured evidence policy"
}

contract_parent_child_required_bindings() {
  local policy_file="$1"
  awk '
    BEGIN {
      section_found=0
      key_found=0
      item_count=0
    }
    /^parent_child_release:/ { in_section=1; section_found=1; next }
    in_section && /^[a-z_]+:/ { exit }
    !in_section { next }
    /^  require_artifacts_checked_bindings:/ { key_found=1; in_list=1; next }
    in_list && /^  [a-z_]+:/ { exit }
    in_list && /^    - / {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      print line
      item_count++
    }
    END {
      if (!section_found || !key_found || item_count == 0) {
        exit 2
      }
    }
  ' "$policy_file"
}

contract_parent_child_required_bindings_error() {
  printf '%s\n' "invalid parent_child_release.require_artifacts_checked_bindings in configured evidence policy"
}

contract_parent_child_child_evidence_section_required() {
  local policy_file="$1"
  local raw_value normalized_value status

  raw_value=$(
    awk '
      /^parent_child_release:/ { in_section=1; next }
      in_section && /^[a-z_]+:/ { exit }
      !in_section { next }
      /^  child_evidence:/ { in_child_evidence=1; next }
      in_child_evidence && /^  [a-z_]+:/ { exit }
      !in_child_evidence { next }
      /^    require_section:/ {
        line=$0
        sub(/^[^:]*:[[:space:]]*/, "", line)
        sub(/[[:space:]]+#.*/, "", line)
        print line
        found=1
        exit
      }
      END { exit(found ? 0 : 2) }
    ' "$policy_file"
  )
  status=$?
  if [[ $status -ne 0 ]]; then
    return "$status"
  fi

  normalized_value=$(contract_normalize_scalar "$raw_value")

  case "$normalized_value" in
    true) return 0 ;;
    false) return 1 ;;
    *) return 2 ;;
  esac
}

contract_parent_child_child_evidence_section_error() {
  printf '%s\n' "invalid parent_child_release.child_evidence.require_section in configured evidence policy"
}

contract_parent_child_latest_gate_binding_required() {
  local policy_file="$1"
  local raw_value normalized_value status

  raw_value=$(
    awk '
      /^parent_child_release:/ { in_section=1; next }
      in_section && /^[a-z_]+:/ { exit }
      !in_section { next }
      /^  latest_gate:/ { in_latest_gate=1; next }
      in_latest_gate && /^  [a-z_]+:/ { exit }
      !in_latest_gate { next }
      /^    require_binding:/ {
        line=$0
        sub(/^[^:]*:[[:space:]]*/, "", line)
        sub(/[[:space:]]+#.*/, "", line)
        print line
        found=1
        exit
      }
      END { exit(found ? 0 : 2) }
    ' "$policy_file"
  )
  status=$?
  if [[ $status -ne 0 ]]; then
    return "$status"
  fi

  normalized_value=$(contract_normalize_scalar "$raw_value")

  case "$normalized_value" in
    true) return 0 ;;
    false) return 1 ;;
    *) return 2 ;;
  esac
}

contract_parent_child_latest_gate_binding_error() {
  printf '%s\n' "invalid parent_child_release.latest_gate.require_binding in configured evidence policy"
}

contract_parent_child_latest_gate_pass_required() {
  local policy_file="$1"
  local raw_value normalized_value status

  raw_value=$(
    awk '
      /^parent_child_release:/ { in_section=1; next }
      in_section && /^[a-z_]+:/ { exit }
      !in_section { next }
      /^  latest_gate:/ { in_latest_gate=1; next }
      in_latest_gate && /^  [a-z_]+:/ { exit }
      !in_latest_gate { next }
      /^    require_pass_result:/ {
        line=$0
        sub(/^[^:]*:[[:space:]]*/, "", line)
        sub(/[[:space:]]+#.*/, "", line)
        print line
        found=1
        exit
      }
      END { exit(found ? 0 : 2) }
    ' "$policy_file"
  )
  status=$?
  if [[ $status -ne 0 ]]; then
    return "$status"
  fi

  normalized_value=$(contract_normalize_scalar "$raw_value")

  case "$normalized_value" in
    true) return 0 ;;
    false) return 1 ;;
    *) return 2 ;;
  esac
}

contract_parent_child_latest_gate_pass_error() {
  printf '%s\n' "invalid parent_child_release.latest_gate.require_pass_result in configured evidence policy"
}

contract_parent_child_required_fields() {
  local policy_file="$1"
  awk '
    BEGIN {
      section_found=0
      child_evidence_found=0
      key_found=0
      item_count=0
    }
    /^parent_child_release:/ { in_section=1; section_found=1; next }
    in_section && /^[a-z_]+:/ { exit }
    !in_section { next }
    /^  child_evidence:/ { in_child_evidence=1; child_evidence_found=1; next }
    in_child_evidence && /^  [a-z_]+:/ { exit }
    !in_child_evidence { next }
    /^    required_fields:/ { key_found=1; in_list=1; next }
    in_list && /^    [a-z_]+:/ { exit }
    in_list && /^      - / {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      print line
      item_count++
    }
    END {
      if (!section_found || !child_evidence_found || !key_found || item_count == 0) {
        exit 2
      }
    }
  ' "$policy_file"
}

contract_parent_child_required_fields_error() {
  printf '%s\n' "invalid parent_child_release.child_evidence.required_fields in configured evidence policy"
}
