#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_root="${IDTECH4_WORK_ROOT:-${repo_root}/.work}"
framework_dir="${WASM_GAME_FRAMEWORK_DIR:-${work_root}/wasm-game-framework}"
doom_web="${work_root}/dhewm3/build/web"
quake_web="${work_root}/openq4/build/web"
site="${repo_root}/build/site"

test "$(node -p "require('${framework_dir}/package.json').version")" = "0.7.1"
test "$(git -C "${framework_dir}" rev-parse HEAD)" = "9359fb186399d0c608cbcd063f7e6fd03eb7c210"
for required in \
  "${doom_web}/dhewm3-base.js" "${doom_web}/dhewm3-base.wasm" \
  "${doom_web}/dhewm3-roe.js" "${doom_web}/dhewm3-roe.wasm" \
  "${quake_web}/openQ4-client_wasm32.js" "${quake_web}/openQ4-client_wasm32.wasm" \
  "${quake_web}/baseoq4/game-sp_wasm32.wasm" "${quake_web}/baseoq4/game-mp_wasm32.wasm" \
  "${quake_web}/baseoq4/pak0.pk4" "${quake_web}/baseoq4/pak1.pk4"; do
  test -s "${required}" || { echo "Missing ${required}; run scripts/build-all.sh first." >&2; exit 1; }
done

case "${site}" in
  "${repo_root}/build/site") ;;
  *) echo "Unsafe generated site path: ${site}" >&2; exit 1 ;;
esac
rm -rf -- "${site}"
mkdir -p "${site}/baseoq4"

install -m 0644 "${repo_root}/site/wasm-game.json" "${site}/wasm-game.json"
install -m 0644 "${repo_root}/site/game-adapter.js" "${site}/game-adapter.js"

for artifact in d3-worker.js dhewm3-base.js dhewm3-base.wasm dhewm3-roe.js dhewm3-roe.wasm doom3.ico doom3-pwa.svg roe.png; do
  install -m 0644 "${doom_web}/${artifact}" "${site}/${artifact}"
done
for artifact in q4-worker.js openQ4-client_wasm32.js openQ4-client_wasm32.wasm quake4.ico quake4-pwa.svg quake4-background.png; do
  install -m 0644 "${quake_web}/${artifact}" "${site}/${artifact}"
done
for artifact in game-sp_wasm32.wasm game-mp_wasm32.wasm mod.json pak0.pk4 pak1.pk4; do
  install -m 0644 "${quake_web}/baseoq4/${artifact}" "${site}/baseoq4/${artifact}"
done

node "${repo_root}/scripts/merge-data-manifests.mjs" \
  "${doom_web}/wasm-game-data.json" \
  "${quake_web}/wasm-game-data.json" \
  "${site}/wasm-game-data.json"

install -m 0644 "${work_root}/dhewm3/COPYING.txt" "${site}/DHEWM3-COPYING.txt"
install -m 0644 "${work_root}/openq4/docs/QUAKE4-SDK-EULA.rtf" "${site}/QUAKE4-SDK-EULA.rtf"
install -m 0644 "${work_root}/openq4/docs/REDISTRIBUTION.md" "${site}/QUAKE4-REDISTRIBUTION.md"
install -m 0644 "${repo_root}/site/IDTECH4-NOTICES.txt" "${site}/IDTECH4-NOTICES.txt"

metadata_dir="$(mktemp -d -t idtech4-framework.XXXXXX)"
trap 'rm -rf -- "${metadata_dir}"' EXIT
"${framework_dir}/scripts/install-browser-package.sh" "${metadata_dir}" copy >/dev/null
install -m 0644 "${metadata_dir}/wasm-game-framework.json" "${site}/wasm-game-framework.json"

node --check "${site}/game-adapter.js"
node --check "${site}/d3-worker.js"
node --check "${site}/q4-worker.js"
node --check "${site}/dhewm3-base.js"
node --check "${site}/dhewm3-roe.js"
node --check "${site}/openQ4-client_wasm32.js"
node -e 'for (const path of process.argv.slice(1)) JSON.parse(fs.readFileSync(path, "utf8"))' \
  "${site}/wasm-game.json" "${site}/wasm-game-data.json" "${site}/baseoq4/mod.json"
for wasm in \
  "${site}/dhewm3-base.wasm" "${site}/dhewm3-roe.wasm" \
  "${site}/openQ4-client_wasm32.wasm" \
  "${site}/baseoq4/game-sp_wasm32.wasm" "${site}/baseoq4/game-mp_wasm32.wasm"; do
  test "$(od -An -tx1 -N4 "${wasm}" | tr -d ' \n')" = "0061736d"
done
test "$(md5sum "${site}/baseoq4/pak0.pk4" | awk '{print $1}')" = "17550cb028326cdf1cee440bc5d73d74"
test "$(md5sum "${site}/baseoq4/pak1.pk4" | awk '{print $1}')" = "c3434e1d28bebdc367d6e50f3b1fda3a"
test "$(stat -c '%s' "${site}/baseoq4/pak0.pk4")" = "4285437"
test "$(stat -c '%s' "${site}/baseoq4/pak1.pk4")" = "641646791"
unzip -tqq "${site}/baseoq4/pak0.pk4"
unzip -tqq "${site}/baseoq4/pak1.pk4"
test ! -e "${site}/index.html"
test ! -e "${site}/app.webmanifest"
test ! -e "${site}/service-worker.js"

expected_files="$(cat <<'EOF'
DHEWM3-COPYING.txt
IDTECH4-NOTICES.txt
QUAKE4-REDISTRIBUTION.md
QUAKE4-SDK-EULA.rtf
baseoq4/game-mp_wasm32.wasm
baseoq4/game-sp_wasm32.wasm
baseoq4/mod.json
baseoq4/pak0.pk4
baseoq4/pak1.pk4
d3-worker.js
dhewm3-base.js
dhewm3-base.wasm
dhewm3-roe.js
dhewm3-roe.wasm
doom3-pwa.svg
doom3.ico
game-adapter.js
openQ4-client_wasm32.js
openQ4-client_wasm32.wasm
q4-worker.js
quake4-background.png
quake4-pwa.svg
quake4.ico
roe.png
wasm-game-data.json
wasm-game-framework.json
wasm-game.json
EOF
)"
actual_files="$(find "${site}" -type f -printf '%P\n' | sort)"
test "${actual_files}" = "${expected_files}"

printf 'Staged retail-free id Tech 4 family site at %s\n' "${site}"
