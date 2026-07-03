# DaveTheTrainer Resource Capabilities

This document records player-facing resource operations that are backed by `DaveTrainerManifest`.

## Rules

- Player buttons use manifest feature IDs and exact object paths or patch points.
- Player buttons must not trigger global memory scanning.
- Missing runtime roots, save entries, or eligible item entries must fail loudly.
- Existing-entry operations do not create new inventory entries, unlock recipes, or mutate discovery records.

## Sea People / Jungle Village Items

Manifest feature: `seaPeopleVillageItems`

UI title: `增加鲛人村/丛林村庄物品（已有）`

Storage plane:

- Runtime plane: `SaveDataJungle.IvenData`
- Save plane: `SaveDataJungle.IvenData`
- Container offset: `SaveDataJungle + 0x150`
- Entry type: jungle inventory slot save object
- Item ID field: object offset `0x10`
- Quantity field: object offset `0x14`

Policy:

- `allowRuntimeScanning`: `false`
- `canCreateEntries`: `false`
- `modifiesExistingEntries`: `true`
- Missing `IvenData` dictionary or no eligible entries: fail loud.
- Battle insect entries with prefix `410103` are skipped and never counted as a successful write target.

Scenario check:

- Pressing the player button increments existing non-insect `IvenData` entries.
- Existing `JungleIngredientsSave` entries remain unchanged for this feature.
- Insect entries remain unchanged.
- Readback must match the requested final quantity before the operation returns `behaviorVerified`.
