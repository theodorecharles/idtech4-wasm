# idtech4-wasm runbook

## Purpose

Maintain one repeatable, retail-free id Tech 4 browser pipeline for Doom 3 SP/MP, Resurrection of Evil, and Quake 4 SP/MP. Keep the engine work at this family layer and let `wasm-game-framework` own the page shell, data provisioning, IndexedDB cache, identity/quality/fullscreen preferences, responsive canvas, input-capture lifecycle, PWA generation, service worker, and static container server.

Do not submit anything upstream. All work is local downstream work and all generated source checkouts have a disabled push URL.

## Exact inputs

`source-lock.json` is authoritative. A build must stop if the framework is not version `0.7.0` at commit `536d919ef6e6cd171aa826812db9f888ffbf04a3`. It must also stop if a native checkout or patch checksum differs from the lock.

The family repository stores neither complete source forks nor retail content. It reconstructs the browser ports by checking out exact native commits, verifying `patches/SHA256SUMS`, and applying the committed patch queues in `.work/`.

## Build flow

1. `scripts/fetch-sources.sh` creates detached dhewm3, openQ4, and openQ4-game checkouts and disables their push URLs.
2. `scripts/apply-patches.sh` verifies and applies the two browser patch queues idempotently.
3. `scripts/build-all.sh` invokes the native Emscripten builds using the exact framework checkout.
4. `scripts/stage-site.sh` combines the engine artifacts, authentic source-licensed icons/background, exact owner-data manifests, licenses, and framework metadata. It asserts that no downstream HTML, CSS, web manifest, or service worker exists.
5. `scripts/build-docker.sh` builds the suite image and five locked variants.
6. `scripts/test-http.sh` checks all images, framework metadata, canonical bootstrap, WASM and PK4 range responses, and the `/data` denial contract.

## Data and security contract

Retail files exist only in the operator's `/data` volume and the user's browser cache. The static site contains no retail PK4. The server exposes validated file endpoints used by the framework, while `/data` and all descendants return 404. Do not add a static mount, symlink, copy, or image build context that can expose that volume.

The exact owner-file sizes and SHA-256 values live in the generated `wasm-game-data.json`. Variants share namespaces so SP and MP do not redownload identical files. Optional Quake 4 patch PK4s remain optional. RoE includes both its expansion files and the exact Doom 3 base set.

## Quake 4 source packages

The openQ4 build must create both source-derived packages under `baseoq4`:

| Package | Bytes | MD5 |
| --- | ---: | --- |
| `pak0.pk4` | 4,285,437 | `17550cb028326cdf1cee440bc5d73d74` |
| `pak1.pk4` | 641,646,791 | `c3434e1d28bebdc367d6e50f3b1fda3a` |

`pak1.pk4` supplies the SDK-derived runtime game content required by openQ4. Never weaken or bypass the engine's package validation. Build, staging, Docker, and HTTP checks must fail if either package is absent or corrupt.

## Runtime boundary

| Variant | Status |
| --- | --- |
| Doom 3 | Still in development |
| Doom 3 multiplayer | Still in development |
| Resurrection of Evil | Still in development |
| Quake 4 | Still in development |
| Quake 4 multiplayer | Still in development |

Verified browser progress includes owner PK4 restoration, worker startup, a direct WebGL 2 `OffscreenCanvas` context, filesystem initialization, source game-module loading, declarations, configuration, input bridge, and renderer capability probing. The current shared blocker is the desktop OpenGL/ARB program renderer path. Continue by implementing that renderer boundary in native source behind `__EMSCRIPTEN__`; do not fork the framework or add a main-thread DOM workaround.

## Browser verification discipline

Browser testing is serialized across the larger WASM workspace. Obtain the coordinator's Chrome slot before opening a test tab, exercise only this family, capture console/runtime evidence, close every tab, and explicitly release the slot. HTTP/container tests do not require the slot.

## Change checklist

- Preserve native builds on non-Emscripten targets.
- Put browser-only native changes behind `__EMSCRIPTEN__` where appropriate.
- Update a patch queue and `patches/SHA256SUMS` together.
- Keep manifest paths, sizes, and digests exact and variant-aware.
- Use only source-licensed authentic visual assets.
- Build suite and every locked variant.
- Run static syntax, package integrity, HTTP range, and `/data` isolation tests.
- Use only `Live` or `Still in development` for title status.
- Commit locally in focused checkpoints; do not push or contact upstream.
