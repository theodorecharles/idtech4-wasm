#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_root="${IDTECH4_WORK_ROOT:-${repo_root}/.work}"

"${repo_root}/scripts/fetch-sources.sh"
(cd "${repo_root}/patches" && sha256sum --check SHA256SUMS)

apply_one() {
  local checkout="$1"
  local patch="$2"
  if git -C "${checkout}" apply --reverse --check "${patch}" >/dev/null 2>&1; then
    printf '%s already applied\n' "$(basename "${patch}")"
    return
  fi
  git -C "${checkout}" apply --check "${patch}"
  git -C "${checkout}" apply "${patch}"
  printf 'applied %s\n' "$(basename "${patch}")"
}

apply_one "${work_root}/dhewm3" "${repo_root}/patches/dhewm3-browser.patch"
apply_one "${work_root}/openq4" "${repo_root}/patches/openq4-browser.patch"

