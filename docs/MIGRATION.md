# Migration and parity

`idtech4-wasm` is a canonical family repository layered above two proven downstream checkpoints. It does not move, delete, or rewrite either working repository:

| Working repository | Local checkpoint | Family input | Status |
| --- | --- | --- | --- |
| `doom3-wasm` | `cc9309051de93e303c384da5e8c285eaf0687c43` | dhewm3 pin + `dhewm3-browser.patch` | Still in development |
| `quake4-wasm` | `77d37eadf5a241db2ae7b2642b5d213bc2ff42d3` | openQ4 pin + `openq4-browser.patch` | Still in development |

The patches are complete binary-capable diffs from each pinned native upstream commit to the corresponding local checkpoint. Generated `.work` trees reproduce those checkpoints without retaining a second large source copy in git. Their origin push URLs are deliberately set to `DISABLED`.

## Contract parity

| Capability | Doom 3 SP/MP + RoE | Quake 4 SP/MP |
| --- | --- | --- |
| Canonical framework 0.7.5 shell | Yes | Yes |
| Downstream-authored HTML/CSS/SW/PWA files | None | None |
| Variant-aware PWA metadata and authentic icon | Yes | Yes |
| Remembered launch-fullscreen preference | Yes | Yes |
| Responsive dynamic canvas and contained native menu pointer mapping | Yes | Yes |
| Worker `OffscreenCanvas` WebGL 2 creation without DOM access | Yes | Yes |
| Exact required-data validation and browser IndexedDB reuse | Yes | Yes |
| `/data` inaccessible by direct HTTP request | Yes | Yes |
| Suite and locked Docker images | Yes | Yes |
| Browser runtime status | Still in development | Still in development |

## Why the working repositories remain

The two existing repositories preserve compact per-engine history and known build evidence while the family pipeline is established. New engine-family changes should land here first as patch-queue updates. A change may be mirrored into a working repository for debugging, but the family lock, patch checksum, staged contract, and migration table must be updated in the same local checkpoint.

No migration step submits changes to dhewm3, openQ4, openQ4-game, or any other upstream.
