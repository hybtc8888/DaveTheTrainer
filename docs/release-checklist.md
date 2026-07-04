# Release Checklist

## Build

- Build public packages with `script/build_and_run.sh --release-package`.
- Use `swift build -c release`.
- Set `DAVE_TRAINER_SIGN_IDENTITY` for release packages.
- Set `DAVE_TRAINER_BUNDLE_ID` only when intentionally overriding the public bundle id.

## Artifact

- Verify the `.app` has `Contents/MacOS/DaveTheTrainer`.
- Verify `Info.plist` has version, build, bundle id, and manifest schema.
- Verify `codesign --verify --deep --strict`.
- Verify zip contents do not contain `._*` or `.DS_Store`.
- Test the zipped app, not only the local build folder.

## Player Scenarios

- Game not running.
- Permission denied.
- Permission granted.
- Unknown game build with feature-level validation failure.
- Supported build with a reversible patch.
- Inventory operation with missing entry.
- Uninstall path.

## Repository Boundary

- Do not publish local reverse-engineering fixtures.
- Do not publish local agent config.
- Do not publish logs, dSYM bundles, or build artifacts.
