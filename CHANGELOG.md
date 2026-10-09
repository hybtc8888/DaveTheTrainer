# Changelog

## Unreleased

- Distinguish hardened-target signing denial from missing administrator elevation, sign trainer bundles with the debugging-tool entitlement, and provide an explicit opt-in script for an independent debug game copy.

- Add an exact all-control profile for `v1.0.6.756.mac`, bound to its build GUID and arm64 GameAssembly UUID.
- Enable all 22 controls with 101 byte-verified code targets, enemy-specific damage policies, complete active speed targets, and a reviewed version-specific runtime resource layout.
- Add build-routing, resource-layout, damage-policy and rejection tests plus an optional read-only local binary check. Gameplay effects remain unverified.

## v0.1.5 - 2026-08-02

- Expand the exact `v1.0.6.710.mac` profile from 59 to 72 byte-verified targets across nine features.
- Add a partial `.710` player-speed patch with six position-independent targets found in the reporter's v0.1.4 compatibility report.
- Complete the reported ammo, drone, and stamina target groups with five additional ammo points, the drone UI count point, and the stamina-drain point.
- Inject value-patch factories per game build so `.710` speed changes cannot accidentally reuse `.675` RVAs.
- Expand compatibility report schema `1.2` to use 3072-byte symbol windows, explicit damage-method mappings, RPG trampoline code-cave evidence, and resource helper/singleton diagnostics.
- Keep damage and runtime currency/inventory controls disabled on `.710` where the report does not yet prove the complete write path.

## v0.1.4 - 2026-07-30

- Add an exact, report-derived partial profile for `v1.0.6.710.mac`, bound to its build GUID and GameAssembly arm64 UUID.
- Enable 59 byte-verified targets across god mode, oxygen, ammo, crab traps, weight, drones, stamina, and wasabi; keep every unproven feature explicitly disabled.
- Route player operations through the matching per-build manifest and module resolver instead of one global baseline profile.
- Preserve stable target IDs when a newer build supports only a reviewed subset of an older multi-point patch.
- Show per-feature compatibility limits in the player UI and allow preparation/attach for a known partial profile.
- Expand compatibility report schema `1.1` to inspect 1024-byte symbol windows, emit exact matching candidate RVAs, and include representative speed, currency, material, and artisan targets.
- Clear enabled toggle and value-patch state when a process session is replaced.

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
