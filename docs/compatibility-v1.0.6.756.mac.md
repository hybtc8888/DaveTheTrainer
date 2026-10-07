# v1.0.6.756.mac Compatibility Evidence

This exact partial profile was reviewed against a local macOS installation on
2026-10-07. It retains the same nine feature groups and position-independent
subset reviewed for `.710`, with independently located `.756` RVAs.
It does not declare full compatibility or verified gameplay behavior.

## Build Identity

| Field | Value |
| --- | --- |
| Bundle ID | `com.nexon.dave` |
| Version | `v1.0.6.756.mac` |
| Build GUID | `1958d94b767741a5a13a2ae0032db743` |
| GameAssembly arm64 UUID | `698AB592-0DAA-3787-9B22-43683C35F62B` |
| GameAssembly SHA-256 | `0a608e833f8df5ff22323f9712879e5dea6aac43327f622767e234d4714f4b82` |
| IL2CPP metadata version | `31` |
| IL2CPP metadata SHA-256 | `04b3ba2460dec827579c3668cf46408ffc353184a0947008319220eb6fbf56ed` |

## Reviewed Coverage

| Feature | Included points | Baseline points |
| --- | ---: | ---: |
| God mode | 7 | 10 |
| Oxygen | 4 | 4 |
| Ammo | 21 | 21 |
| Crab traps | 7 | 7 |
| Weight | 14 | 14 |
| Player speed | 6 | 13 |
| Drones | 4 | 4 |
| Stamina | 4 | 4 |
| Wasabi | 5 | 5 |

The schema 1.2 compatibility exporter supplied targeted method candidates.
Each of the 70 unchanged expected-byte sequences was matched uniquely within
its named method, bounded by the next distinct symbol address from the arm64
symbol table. Matches elsewhere in the exporter's 3072-byte windows were
excluded. No global offset was used. All 72 final expected-byte windows were
then read directly from the local arm64 image using the final profile. The
optional integration test reproduces this read-only check.
The curated RVAs and stable target IDs are in
`Sources/TrainerCore/RuntimePatching/DaveV106756StaticGamePatches.swift`.

Two explicit expected-byte adjustments are reviewed:

- `weight.13` at `0x210BBAC`: the first 12 bytes match the baseline. The fourth
  instruction remains `ADRP x19`; only its linker-dependent page immediate
  changes. The profile records the exact 16-byte `.756` prologue, ending in
  `13 E6 03 D0`. The replacement is a position-independent float return.
- `wasabi.0` at `0x21D4F50`: the first 52 bytes match the baseline, through its
  first `RET`. The original 64-byte window includes relocated `BL` instructions
  and does not match in full. The profile checks the unchanged 52-byte prefix;
  its integer-return replacement changes only the first 8 bytes.

The god profile excludes insect-battle and RPG internals. Speed covers the
reviewed main-player, fish-farm getter, and Bacon Story targets only; internal
branch/literal patches and legacy fish-speed restore points remain excluded.
Damage, combined Diving God mode, currency, inventory, and artisan flame stay
disabled because the complete player write paths have not been validated.

## Validation and Reproduction

The runtime continues to require exact bundle ID, version, build GUID, module
arm64 UUID, expected-byte preflight, transactional writes, and readback.
A wrong build or UUID cannot fall back to baseline addresses.

Run the public tests plus the optional **read-only** local byte-window check:

```bash
DAVE_V106756_APP_PATH="/path/to/DaveTheDiver.app" swift test \
  --skip InstalledGameIntegrationTests \
  --skip Il2CppFeatureLocatorTests \
  --skip MachOModuleResolverTests
```

The three excluded suites require the old `.675` installation or proprietary
fixtures. Without the environment variable, the new local integration test
skips; all portable profile and routing tests still run. Game binaries,
symbol-table dumps, compatibility reports, and saves are not committed.

No live process memory was modified during validation. Test coverage and local
binary verification establish target locations and guarded routing; actual
in-game effects still need confirmation. Successful readback is `bytesApplied`,
not `behaviorVerified`.
