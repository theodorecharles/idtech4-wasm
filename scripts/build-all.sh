#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_root="${IDTECH4_WORK_ROOT:-${repo_root}/.work}"
framework_dir="${WASM_GAME_FRAMEWORK_DIR:-${work_root}/wasm-game-framework}"
jobs="${JOBS:-4}"
meson="$("${repo_root}/scripts/ensure-build-tools.sh")"

"${repo_root}/scripts/apply-patches.sh"

test "$(node -p "require('${framework_dir}/package.json').version")" = "0.7.3"
test "$(git -C "${framework_dir}" rev-parse HEAD)" = "be0b81301c5f12f09e445a3bc765b7709603265e"

D3WASM_FRAMEWORK_DIR="${framework_dir}" JOBS="${jobs}" \
  "${work_root}/dhewm3/scripts/build-web.sh"
Q4WASM_FRAMEWORK_DIR="${framework_dir}" \
OPENQ4_GAMELIBS_REPO="${work_root}/openq4-game" \
OPENQ4_MESON="${meson}" \
JOBS="${jobs}" \
  "${work_root}/openq4/scripts/build-web.sh"

"${repo_root}/scripts/stage-site.sh"
