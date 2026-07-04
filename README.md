# DaveTheTrainer

<p align="center">
  <img src="Assets/AppIcon/DaveTheTrainerIcon.png" width="144" alt="DaveTheTrainer app icon">
</p>

<p align="center">
  Manifest-backed macOS trainer for <code>DAVE THE DIVER</code>.
</p>

<p align="center">
  <a href="README.zh-CN.md">Chinese README</a> ·
  <a href="https://github.com/Empress7211/DaveTheTrainer/releases/latest">Download latest release</a>
</p>

DaveTheTrainer is a native macOS trainer for `DAVE THE DIVER`, built as a
SwiftPM and SwiftUI app with a manifest-backed safety model.

It is intentionally not a general memory scanner. Player-facing actions are
bound to reviewed manifest feature IDs, a validated Mach-O module shape,
reviewed patch points, and documented runtime object paths. The known game
build is a validated baseline profile, not a global compatibility kill switch.

> This project is not affiliated with, endorsed by, or sponsored by MINTROCKET,
> Nexon, or the creators of `DAVE THE DIVER`.

## Project Status

| Area | Status |
| --- | --- |
| Platform | macOS |
| App type | Native SwiftUI app |
| Package manager | Swift Package Manager |
| Validated baseline build | `v1.0.6.675.mac` |
| Target module | `GameAssembly.dylib` |
| Manifest schema | `1.0` |
| Test coverage | XCTest coverage for manifest policy, patch transactions, runtime incrementers, release scripts, and player path contracts |
| License | MIT |

## Download

Prebuilt app zips are published on
[GitHub Releases](https://github.com/Empress7211/DaveTheTrainer/releases).

Current release artifacts are ad-hoc signed and not Apple-notarized. macOS may
show an unidentified-developer warning on first launch. Review the source and
release notes before running the app.

Install from a release zip:

1. Download `DaveTheTrainer-v0.1.0-macOS.zip` from the latest release.
2. Unzip it.
3. Move `DaveTheTrainer.app` to `/Applications` or `$HOME/Applications`.
4. Start the supported macOS build of `DAVE THE DIVER`.
5. Open `DaveTheTrainer.app`.

If Gatekeeper blocks the first launch, use Finder's right-click `Open` flow. If
you intentionally trust the downloaded artifact after reviewing it, you can also
remove quarantine:

```bash
xattr -dr com.apple.quarantine /Applications/DaveTheTrainer.app
```

## Compatibility Boundary

Compatibility is feature-level and validation-gated. This repository's fully
validated baseline is `v1.0.6.675.mac`; Steam or distributor updates may still
work for individual features when their own locator, target validation, write,
and readback checks pass.

Game version, build GUID, Mach-O UUID, and metadata details are profile signals.
They help choose and diagnose feature locators, but they do not reject the
entire app by themselves. A feature that cannot locate or verify its target
fails explicitly and does not mark itself successful.

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
documents creation support. Missing roots, missing entries, target mismatches,
and verification failures are reported as failures instead of being silently
ignored.

## Design Principles

- Manifest first: player buttons map to reviewed manifest feature IDs.
- Feature-level compatibility: unknown builds may be attempted, but each
  feature must validate the module, target bytes or object path, and readback
  before reporting success.
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
- A local macOS IL2CPP installation of `DAVE THE DIVER`; `v1.0.6.675.mac` is
  the validated baseline profile.
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

1. Start the macOS build of `DAVE THE DIVER`.
2. Launch `DaveTheTrainer`.
3. Confirm that the app detects the game process and build fingerprint.
4. Apply only the one-click trainer operation you intend to use.
5. If macOS asks for administrator authorization, review the prompt and allow
   it only for the trainer attach/read/write operation.

The app should fail loudly when the game is missing, the target module does not
match the required shape, a feature target cannot be validated, permission is
denied, or readback verification fails.

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
2. Add tests for unknown-build feature validation, target mismatch, write
   failure, verify failure, and success.
3. Implement the smallest validated patch point or runtime object path.
4. Keep game-specific addresses and offsets in this project.
5. Keep development discovery code behind explicit diagnostics.

Do not add mock success paths, unverified compatibility guesses, unbounded
runtime scanning fallbacks, or player buttons that rely on unreviewed discovery
output.

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
