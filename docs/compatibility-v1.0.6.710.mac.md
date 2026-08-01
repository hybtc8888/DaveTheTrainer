# v1.0.6.710.mac Compatibility Evidence

This profile was derived from the v0.1.3 and v0.1.4 compatibility reports attached to
[GitHub issue #2](https://github.com/Empress7211/DaveTheTrainer/issues/2#issuecomment-5126767138).
It is a reviewed partial profile, not a claim that every trainer feature is
portable to this game build.

## Build Identity

| Field | Value |
| --- | --- |
| Bundle ID | `com.nexon.dave` |
| Version | `v1.0.6.710.mac` |
| Build GUID | `fd04739b28e64f148c3efcd479a839b8` |
| GameAssembly arm64 UUID | `266578BA-B451-313B-8326-CF241BB3FA5F` |
| GameAssembly SHA-256 | `75465aa10888880fc73626b56cf99b23afc39863fdfd623635d6e777dab78f33` |
| IL2CPP metadata version | `31` |
| IL2CPP metadata SHA-256 | `33158ff01871d0358f0c89b9b2746cfe0d022590ef5000b3a11da38a2215666f` |

## Reviewed Coverage

The latest report contained 135 baseline and representative value-patch points.
The `.710` profile includes 72 points for which the reports supplied exact target
evidence:

| Feature | Included points | Baseline points | Notes |
| --- | ---: | ---: | --- |
| God mode | 7 | 10 | Core player and breath-handler methods; insect battle and RPG internals remain excluded |
| Oxygen | 4 | 4 | Complete reported group |
| Ammo | 21 | 21 | Complete reported group |
| Crab traps | 7 | 7 | Complete reported group |
| Weight | 14 | 14 | Complete reported group |
| Player speed | 6 | 13 | Main, fish-farm, and Bacon Story methods with position-independent patch bytes; unmatched internal branch/literal points remain excluded |
| Drones | 4 | 4 | Complete reported group |
| Stamina | 4 | 4 | Complete reported group |
| Wasabi | 5 | 5 | Complete reported group |

No target was relocated using a global offset. Seventy targets contain the
baseline expected byte sequence at the reported method-symbol candidate RVA.
Two reviewed exceptions are explicit:

- `weight.13` has the same method prologue except for an `ADRP` immediate changed
  by the linker; the profile uses the exact `.710` bytes from the report.
- `wasabi.0` was reported with only the first 32 method bytes; the profile narrows
  the expected-byte window to those 32 observed bytes. Its patch changes only
  the first 8 bytes.

Every write still requires the exact build identity, exact GameAssembly UUID,
and per-point expected-byte preflight. A mismatch fails before memory is
modified. Multi-point operations preflight all targets and roll back a partial
write.

## Validation Status

The maintainer does not have this game build locally. The profile therefore has
strong binary-location evidence but still needs reporter confirmation of each
gameplay path. The app reports `bytesApplied` after readback; it does not report
`behaviorVerified` for these code patches.

All other `.710` features remain disabled until a report provides enough exact
evidence. Compatibility report schema 1.2 reads 3072-byte method windows, maps
damage targets to explicit method prefixes, records the RPG trampoline code cave,
and captures resource helper/singleton candidates. These diagnostics are intended
to cover later targets without adding runtime scanning or guessed writes to the
player path.
