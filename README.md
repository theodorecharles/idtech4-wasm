# idtech4-wasm

`idtech4-wasm` is the engine-family workspace for running Doom 3, Doom 3 multiplayer, Resurrection of Evil, Quake 4, and Quake 4 multiplayer in a browser. It builds the native source ports with Emscripten, presents every title through `wasm-game-framework`, and produces one suite image plus five game-locked images.

No game data is committed or copied into an image. The container serves the required files from its private `/data` volume through the framework's validated data endpoint; the browser verifies them against exact manifests and stores them in IndexedDB for later launches. Direct HTTP access to `/data` is denied.

## Status

| Title | Status |
| --- | --- |
| Doom 3 single-player | Still in development |
| Doom 3 multiplayer | Still in development |
| Resurrection of Evil | Still in development |
| Quake 4 single-player | Still in development |
| Quake 4 multiplayer | Still in development |

Both native engines compile to WebAssembly, their source-derived runtime modules are staged, required data is validated and restored in the browser, and WebGL 2 context creation succeeds in an `OffscreenCanvas` worker. The remaining renderer boundary is the desktop OpenGL/ARB program path used by both engines; it needs a WebGL 2-compatible implementation before gameplay is expected.

## Repository model

The large native trees are reproducible inputs rather than vendored copies:

- `source-lock.json` pins dhewm3, openQ4, openQ4-game, and `wasm-game-framework` to exact commits.
- `patches/` contains the complete downstream browser changes generated from those native bases.
- `scripts/fetch-sources.sh` creates detached, push-disabled checkouts in `.work/`.
- `scripts/apply-patches.sh` verifies patch hashes before applying them.
- `scripts/build-all.sh` builds both engines and stages one canonical family site.

The existing `doom3-wasm` and `quake4-wasm` repositories remain independent working checkpoints. See [docs/MIGRATION.md](docs/MIGRATION.md).

## Build

Activate an Emscripten SDK that provides `emcc`, `em++`, and `embuilder`. The build fetches the exact framework and native revisions into ignored `.work/` checkouts and creates a pinned Meson 1.8.3 environment under `.work/build-tools`. Set `WASM_GAME_FRAMEWORK_DIR` only when intentionally validating an already pinned checkout.

Build the family site and all images:

```bash
JOBS=8 ./scripts/build-all.sh
IMAGE_REPO=local/idtech4-wasm IMAGE_TAG=dev ./scripts/build-docker.sh
IMAGE_REPO=local/idtech4-wasm IMAGE_TAG=dev ./scripts/test-http.sh
```

Image names are:

- `local/idtech4-wasm:dev` — selectable suite
- `local/idtech4-wasm:doom3-dev`
- `local/idtech4-wasm:doom3-mp-dev`
- `local/idtech4-wasm:roe-dev`
- `local/idtech4-wasm:quake4-dev`
- `local/idtech4-wasm:quake4-mp-dev`

Override `IMAGE_REPO` and `IMAGE_TAG` for another local registry. These scripts do not push images.

## Run and provide game data

Create a host directory and mount it at `/data`:

```bash
mkdir -p ./data/base ./data/d3xp ./data/q4base
docker run --rm -p 8088:8088 -v "$PWD/data:/data" local/idtech4-wasm:dev
```

Copy the required files into:

- `/data/base`: Doom 3 `pak000.pk4` through `pak008.pk4`
- `/data/d3xp`: Resurrection of Evil `pak000.pk4` and `pak001.pk4`
- `/data/q4base`: Quake 4 PK4s listed by the launcher's exact manifest

Open `http://localhost:8088`. A locked image skips the suite choice but uses the same volume layout and browser cache. The framework can also accept uploads into the container data volume when a required file is absent; after valid files are installed, that upload interface disappears.

## Source inputs

Doom 3 uses the pinned native dhewm3 source. Quake 4 uses pinned openQ4 engine and openQ4-game source, including source-derived `baseoq4/pak0.pk4` and `pak1.pk4`. Those two packages are asserted by exact size, MD5, ZIP integrity, and HTTP range tests.

The source trees retain their required notices. Quake 4 SDK terms are staged beside the browser runtime. This project does not contact or submit work upstream.
