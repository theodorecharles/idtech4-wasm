#!/usr/bin/env bash
set -euo pipefail

image_repo="${IMAGE_REPO:-local/idtech4-wasm}"
image_tag="${IMAGE_TAG:-dev}"
port="${IDTECH4_TEST_PORT:-18140}"
container="codex-idtech4-http-test"
trap 'docker rm -f "${container}" >/dev/null 2>&1 || true' EXIT

for variant in suite doom3 doom3-mp roe quake4 quake4-mp; do
  if [[ "${variant}" == suite ]]; then
    image="${image_repo}:${image_tag}"
  else
    image="${image_repo}:${variant}-${image_tag}"
  fi
  docker rm -f "${container}" >/dev/null 2>&1 || true
  docker run -d --name "${container}" -p "127.0.0.1:${port}:8088" "${image}" >/dev/null
  for attempt in {1..60}; do
    curl -fsS "http://127.0.0.1:${port}/" >/dev/null 2>&1 && break
    sleep 1
  done
  base_url="http://127.0.0.1:${port}"
  test "$(curl -fsS "${base_url}/wasm-game-framework.json" | node -pe 'JSON.parse(fs.readFileSync(0)).version')" = "0.7.3"
  curl -fsS "${base_url}/" | rg -q 'wasm-game-bootstrap.js'
  curl -fsS "${base_url}/wasm-game.json" | node -e '
    const config = JSON.parse(require("node:fs").readFileSync(0, "utf8"));
    const descriptions = [config.description, ...Object.values(config.variants || {}).flatMap(value => [value.description, value.pwa?.description])].filter(Boolean);
    const forbidden = /\b(owner|registered|files?|storage|cache|provenance|legal|license)\b/i;
    const invalid = descriptions.find(value => forbidden.test(value));
    if (invalid) throw new Error(`normal launcher copy describes setup policy: ${invalid}`);
  '
  test "$(curl -fsS "${base_url}/wasm-game-config.js" | sed -n 's/.*= "\([^"]*\)";.*/\1/p')" = "${variant}"
  test "$(curl -fsSI "${base_url}/" | tr -d '\r' | awk -F': ' 'tolower($1)=="cross-origin-opener-policy" {print $2}')" = "same-origin"
  test "$(curl -fsSI "${base_url}/" | tr -d '\r' | awk -F': ' 'tolower($1)=="cross-origin-embedder-policy" {print $2}')" = "require-corp"
  test "$(curl -fsSI "${base_url}/" | tr -d '\r' | awk -F': ' 'tolower($1)=="x-content-type-options" {print $2}')" = "nosniff"
  test "$(curl -fsS -r 0-3 "${base_url}/dhewm3-base.wasm" | od -An -tx1 | tr -d ' \n')" = "0061736d"
  test "$(curl -fsS -r 0-3 "${base_url}/dhewm3-roe.wasm" | od -An -tx1 | tr -d ' \n')" = "0061736d"
  test "$(curl -fsS -r 0-3 "${base_url}/openQ4-client_wasm32.wasm" | od -An -tx1 | tr -d ' \n')" = "0061736d"
  test "$(curl -fsS -r 0-3 "${base_url}/baseoq4/game-sp_wasm32.wasm" | od -An -tx1 | tr -d ' \n')" = "0061736d"
  test "$(curl -fsS -r 0-3 "${base_url}/baseoq4/game-mp_wasm32.wasm" | od -An -tx1 | tr -d ' \n')" = "0061736d"
  test "$(curl -fsS -r 0-3 "${base_url}/baseoq4/pak0.pk4" | od -An -tx1 | tr -d ' \n')" = "504b0304"
  test "$(curl -fsS -r 0-3 "${base_url}/baseoq4/pak1.pk4" | od -An -tx1 | tr -d ' \n')" = "504b0304"
  test "$(curl -sS -o /dev/null -w '%{http_code}' -X POST "${base_url}/game-adapter.js")" = "405"
  test "$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}/data")" = "404"
  test "$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}/data/base/pak000.pk4")" = "404"
  test "$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}/local-data/base/pak000.pk4")" = "404"
  status="$(curl -fsS "${base_url}/game-data/status")"
  if [[ "${variant}" == suite ]]; then
    test "$(printf '%s' "${status}" | node -pe 'JSON.parse(fs.readFileSync(0)).variantRequired')" = "true"
  else
    test "$(printf '%s' "${status}" | node -pe 'JSON.parse(fs.readFileSync(0)).variant')" = "${variant}"
  fi
  printf '%s OK\n' "${image}"
done
