# v1.0.6.710.mac Compatibility Evidence

This profile was derived from the v0.1.3 compatibility report attached to
[GitHub issue #2](https://github.com/Empress7211/DaveTheTrainer/issues/2#issuecomment-5115490874).
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

The report contained 97 baseline patch points. The `.710` profile includes 59
points for which the report supplied exact target evidence:

| Feature | Included points | Baseline points | Notes |
| --- | ---: | ---: | --- |
| God mode | 7 | 10 | Core player and breath-handler methods; insect battle and RPG internals remain excluded |
| Oxygen | 4 | 4 | Complete reported group |
| Ammo | 16 | 21 | Public/core methods only; unlocated internal gates remain excluded |
| Crab traps | 7 | 7 | Complete reported group |
| Weight | 14 | 14 | Complete reported group |
| Drones | 3 | 4 | Internal UI count point remains excluded |
| Stamina | 3 | 4 | Internal drain arithmetic point remains excluded |
| Wasabi | 5 | 5 | Complete reported group |

No target was relocated using a global offset. Fifty-seven targets contain the
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
evidence. Compatibility report schema 1.1 expands symbol samples and emits exact
candidate matches so later reports can cover those targets without adding
runtime scanning or guessed writes to the player path.
