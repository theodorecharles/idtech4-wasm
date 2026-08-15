# idtech4-wasm runbook

## Purpose

Maintain one repeatable id Tech 4 browser pipeline for Doom 3 SP/MP, Resurrection of Evil, Quake 4 SP/MP, and Prey (2006) SP. Keep the engine work at this family layer and let `wasm-game-framework` own the page shell, data provisioning, IndexedDB cache, identity/quality/fullscreen preferences, responsive canvas, input-capture lifecycle, PWA generation, service worker, and static container server.

Do not submit anything upstream. All work is local downstream work and all generated source checkouts have a disabled push URL.

## Exact inputs

`source-lock.json` is authoritative. A build must stop if the framework is not version `0.9.1` at commit `68bfbd1dbc0104084c7760e486b7437d4c7bb90e`. It must also stop if a native checkout or patch checksum differs from the lock.

The family repository stores neither complete source forks nor retail content. It reconstructs the browser ports by checking out exact native commits, verifying `patches/SHA256SUMS`, and applying the committed patch queues in `.work/`.

## Build flow

1. `scripts/fetch-sources.sh` creates detached dhewm3, openQ4, openQ4-game, and Prey2006 checkouts and disables their push URLs.
2. `scripts/apply-patches.sh` verifies and applies the three browser patch queues idempotently.
3. `scripts/build-all.sh` invokes the native Emscripten builds using the exact framework checkout.
4. `scripts/stage-site.sh` combines the engine artifacts, source-derived icons/background, exact data manifests, notices, and framework metadata. It asserts that no downstream HTML, CSS, web manifest, or service worker exists.
5. `scripts/build-docker.sh` builds the suite image and six locked variants.
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
| Prey (2006) | Still in development |

Verified browser progress includes PK4 restoration, worker startup, a direct WebGL 2 `OffscreenCanvas` context, filesystem initialization, source game-module loading, declarations, configuration, input bridge, and renderer capability probing. Prey compiles and links 459 native translation units into a WASM module with its gamecode hardlinked. In the last serialized Chrome smoke before the framework 0.9.1 migration, all 13 PK4s loaded, the WebGL 2 context became current, ARB2 reported available, and startup then stopped at `R_ReloadARBPrograms`; a reload reached native main and the first cached PK4 in about eight seconds. The current shared blocker is the desktop fixed-function/ARB program renderer path. Static/native/image/HTTP verification of the 0.9.1 migration does not prove that blocker fixed; a new serialized browser pass is required when the Chrome slot is explicitly granted. Continue by implementing that renderer boundary in native source behind `__EMSCRIPTEN__`; do not fork the framework or add a main-thread DOM workaround.

All browser executables use growable wasm32 memory with an explicit 2 GiB maximum. Doom 3/RoE start at 128 MiB; Quake 4 and Prey start at 256 MiB. Retail PK4 `File`/`Blob` objects and Quake 4's source-derived PK4s mount through `WORKERFS`; they must not be materialized as whole-package `Uint8Array` files in MEMFS.

The static renderer audit reaches the same unresolved boundary in every native tree. Doom 3 and Prey require `GL_ARB_vertex_program` and `GL_ARB_fragment_program`, resolve `glProgramStringARB`, call `R_ARB2_Init`/`R_ReloadARBPrograms_f`, and upload ASCII ARB assembly from `draw_arb2.cpp`. Quake 4's statically linked renderer follows the same ARB upload path even when its optional GL and Vulkan renderer modules are disabled for the Emscripten build. The browser platform seams provide a WebGL 2 ES context and `emscripten_webgl_get_proc_address`, with Emscripten legacy GL emulation enabled; they do not supply a demonstrated GLSL ES replacement for those ARB programs. Therefore the current evidence supports an identified renderer incompatibility, not playability or a renderer fix.

## Browser verification discipline

Browser testing is serialized across the larger WASM workspace. Obtain the coordinator's Chrome slot before opening a test tab, exercise only this family, capture console/runtime evidence, close every tab, and explicitly release the slot. HTTP/container tests do not require the slot.

## Change checklist

- Preserve native builds on non-Emscripten targets.
- Put browser-only native changes behind `__EMSCRIPTEN__` where appropriate.
- Update a patch queue and `patches/SHA256SUMS` together.
- Keep manifest paths, sizes, and digests exact and variant-aware.
- Use source-derived title visual assets.
- Build suite and every locked variant.
- Run static syntax, package integrity, HTTP range, and `/data` isolation tests.
- Use only `Live` or `Still in development` for title status.
- Commit locally in focused checkpoints; do not push or contact upstream.
