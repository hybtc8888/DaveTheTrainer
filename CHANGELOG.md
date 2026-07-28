# Changelog

## Unreleased

## v0.1.3 - 2026-07-28

- Reject unknown game builds before any player memory write instead of applying stale baseline RVAs.
- Require the exact manifest build identity and GameAssembly arm64 UUID for player operations while keeping installation paths relocatable.
- Add an explicit, local-only compatibility report export for unsupported builds.
- Include targeted manifest bytes, method-symbol candidate RVAs, build GUID, Mach-O UUID, metadata version, file sizes, and SHA-256 fingerprints in reports.
- Exclude absolute paths and full extracted symbol names from exported reports.
- Replace ASLR-dependent AOB errors with patch notes, RVAs, and expected/observed bytes.

## v0.1.2 - 2026-07-28

- Resolve the game bundle from the running executable instead of requiring `/Applications/DaveTheDiver.app`.
- Support Steam custom libraries, relocated installs, and standalone Unity app bundles.
- Validate the bundle executable, bundle id, IL2CPP metadata, and GameAssembly before attach.
- Reject ambiguous same-name processes and clear stale attach sessions when the target changes.
- Distinguish `Game Not Running` from `Install Not Resolved` in the player UI.
- Embed package version, build number, git commit, and build date in release metadata.
- Verify release ZIPs outside File Provider-backed workspaces to prevent metadata races.
- Generate a portable SHA-256 file that can be verified beside the downloaded ZIP.
- Update CI checkout to the current Node.js runtime.

## v0.1.1 - 2026-07-04

- Added adaptive, feature-level validation for game builds outside the verified baseline.
- Added manifest-backed operation results for player features.
- Added transactional static patch groups.
- Added GameAssembly module identity binding.
- Added Sea People / jungle village existing item support.
- Moved release policy toward public artifact checks.

## v0.1.0 - 2026-07-04

- Published the first public GitHub release package.
- Added English and Chinese README documentation.
- Documented release zip installation, Gatekeeper behavior, and exact build support.
- Added repository logo presentation in README files.
- Verified extracted release zip app signatures during packaging.
