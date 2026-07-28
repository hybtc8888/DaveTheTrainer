# Release Checklist

## Build

- Build public packages with `script/build_and_run.sh --release-package`.
- Use `swift build -c release`.
- Set `DAVE_TRAINER_SIGN_IDENTITY` for release packages.
- Set `DAVE_TRAINER_BUNDLE_ID` only when intentionally overriding the public bundle id.

## Artifact

- Verify the `.app` has `Contents/MacOS/DaveTheTrainer`.
- Verify `Info.plist` has version, build, git commit, build date, bundle id, and manifest schema.
- Verify `codesign --verify --deep --strict`.
- Verify zip contents do not contain `._*` or `.DS_Store`.
- Test the zipped app from a temporary directory outside File Provider-backed workspaces.
- Verify the `.sha256` asset references only the ZIP file name, not a local build path.

## Player Scenarios

- Game not running.
- Permission denied.
- Permission granted.
- Unknown game build rejected before player memory writes.
- Compatibility report export with no absolute paths or full symbol names.
- Supported build with a reversible patch.
- Inventory operation with missing entry.
- Uninstall path.

## Repository Boundary

- Do not publish local reverse-engineering fixtures.
- Do not publish local agent config.
- Do not publish logs, dSYM bundles, or build artifacts.
