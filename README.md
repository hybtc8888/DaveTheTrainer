# DaveTheTrainer

DaveTheTrainer is a native macOS trainer for `DAVE THE DIVER`, built as a
SwiftPM and SwiftUI app with a manifest-backed safety model.

It is intentionally not a general memory scanner. Player-facing actions are
bound to a known game build, a known Mach-O module, reviewed patch points, and
documented runtime object paths. Unsupported builds fail before attach or write
work begins.

> This project is not affiliated with, endorsed by, or sponsored by MINTROCKET,
> Nexon, or the creators of `DAVE THE DIVER`.

## Project Status

| Area | Status |
| --- | --- |
| Platform | macOS |
| App type | Native SwiftUI app |
| Package manager | Swift Package Manager |
| Supported game build | `v1.0.6.675.mac` |
| Target module | `GameAssembly.dylib` |
| Manifest schema | `1.0` |
| Test coverage | XCTest coverage for manifest policy, patch transactions, runtime incrementers, release scripts, and player path contracts |
| License | MIT |

## Compatibility Boundary

Compatibility is exact, not best-effort. This repository currently supports
`v1.0.6.675.mac` only. If Steam or another distributor updates your installed
game to a newer Mac build, that newer build is unsupported until a matching
manifest is reviewed, tested, and released.

The app is expected to reject unsupported builds before attach or write work
starts. Do not treat visual similarity between game versions as compatibility.

## What It Can Do

DaveTheTrainer focuses on safe, repeatable player operations for the supported
build:

- Diving patches: god mode, oxygen, ammo, crab traps, weight, damage, drones,
  and swim speed.
- Currency operations: gold, Bei, jungle gold, and artisan flame.
- Inventory operations: main ingredients, category ingredients, Jungle DLC
  existing inventory, and Sea People / jungle village existing items.
- Sushi bar patches: stamina and wasabi.

Inventory features only modify existing entries unless the manifest explicitly
documents creation support. Missing roots, missing entries, verification
failures, and unsupported builds are reported as failures instead of being
silently ignored.

## Design Principles

- Manifest first: player buttons map to reviewed manifest feature IDs.
- Exact build binding: the app validates the supported game build and module
  identity before memory writes.
- No silent fallback: failures surface as explicit errors, logs, or test
  failures.
- Transactional patching: multi-point patch groups preflight targets and roll
  back when a later write fails.
- Readback verification: runtime quantity writes must prove that the requested
  value changed.
- Public boundary: extracted game binaries, memory dumps, save fixtures, logs,
  and signing material are not part of this repository.

## Requirements

- macOS 14 or newer.
- Xcode command line tools with Swift 5.9 or newer.
- A local macOS installation of `DAVE THE DIVER` build `v1.0.6.675.mac`.
- Permission to attach to the running game process when using trainer actions.

## Build From Source

```bash
git clone https://github.com/Empress7211/DaveTheTrainer.git
cd DaveTheTrainer
swift test
./script/build_and_run.sh
```

`script/build_and_run.sh` builds the SwiftPM executable, stages a real
`DaveTheTrainer.app` bundle, signs it, copies the latest app to
`${DAVE_TRAINER_LOCAL_APP_DIR:-$HOME/Applications}`, mirrors the artifact under
`dist/`, creates `dist/DaveTheTrainer.zip`, and launches the app.

To choose a different local app destination:

```bash
DAVE_TRAINER_LOCAL_APP_DIR="$HOME/Desktop/DaveTheTrainerBuild" ./script/build_and_run.sh
```

Useful script modes:

| Command | Purpose |
| --- | --- |
| `./script/build_and_run.sh` | Build, package, and launch the app |
| `./script/build_and_run.sh --verify` | Build, package, launch, verify signing, and confirm the process starts |
| `./script/build_and_run.sh --package` | Build and print the local `.app` path |
| `./script/build_and_run.sh --release-package` | Produce a release zip with release build settings |
| `./script/build_and_run.sh --logs` | Launch and stream unified logs for the app process |
| `./script/build_and_run.sh --telemetry` | Launch and stream app subsystem logs |

Release packages require an explicit signing identity:

```bash
DAVE_TRAINER_SIGN_IDENTITY="Developer ID Application: Example (TEAMID)" \
  ./script/build_and_run.sh --release-package
```

## Using The App

1. Start the supported macOS build of `DAVE THE DIVER`.
2. Launch `DaveTheTrainer`.
3. Use the one-click trainer controls for the supported feature set.
4. If macOS asks for administrator authorization, review the prompt and allow
   it only for the trainer attach/read/write operation.

The app should fail loudly when the game is missing, the build is unsupported,
the target module does not match the manifest, permission is denied, or readback
verification fails.

## Permissions And Privacy

DaveTheTrainer modifies a running local game process. macOS can require
administrator authorization for task access and process memory writes.

The app does not upload telemetry, memory dumps, save files, API keys, crash
logs, or diagnostics. Local diagnostics are for troubleshooting only. Public
bug reports should redact home directory paths, raw memory addresses, save
paths, Steam account directories, unrelated process details, extracted symbols,
and memory dumps.

See [Permissions And Privacy](docs/permissions-and-privacy.md) for the detailed
policy.

## Repository Layout

```text
Sources/
  DaveTrainerApp/      SwiftUI app, stores, views, and presentation logic
  TrainerCore/         Manifest, patching, scanning, runtime, and save services
  MachMemory/          C bridge for Mach task memory access
Tests/
  DaveTrainerAppTests/ Player path, release script, and app service contracts
  TrainerCoreTests/    Core patching, manifest, scanner, and runtime tests
docs/                  Public policy, release, and capability notes
script/                Build, release, and legacy admin helper scripts
Assets/                App icon assets
```

## Development Workflow

Run the full test suite before publishing changes:

```bash
swift test
```

GitHub Actions runs the public suite and explicitly skips tests that require a
local `DAVE THE DIVER` installation or extracted proprietary game files:

```bash
swift test \
  --skip GameInstallResolverTests \
  --skip Il2CppFeatureLocatorTests \
  --skip MachOModuleResolverTests
```

Feature changes should follow the manifest-first workflow:

1. Document the target feature in `DaveTrainerManifest`.
2. Add tests for unsupported build, target mismatch, write failure, verify
   failure, and success.
3. Implement the smallest exact patch point or runtime object path.
4. Keep game-specific addresses and offsets in this project.
5. Keep development discovery code behind explicit diagnostics.

Do not add mock success paths, broad compatibility guesses, runtime scanning
fallbacks, or player buttons that rely on unreviewed discovery output.

## Documentation

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Release Checklist](docs/release-checklist.md)
- [Resource Capabilities](docs/resource-capabilities.md)
- [Inventory Taxonomy](docs/inventory-taxonomy.md)
- [Development Fixtures](docs/development-fixtures.md)

## Security

Please report security issues privately to the maintainer before public
disclosure. See [Security](SECURITY.md) for the project scope.

## License

DaveTheTrainer is released under the [MIT License](LICENSE).
