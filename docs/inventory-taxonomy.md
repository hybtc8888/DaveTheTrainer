# Dave The Diver Inventory Taxonomy

## Scope

This note documents the inventory and item-count storage planes observed on the
validated baseline `DAVE THE DIVER v1.0.6.675.mac` plus the `In the Jungle` DLC.
Other builds may work only when the relevant feature-level runtime validation
passes.

Evidence sources:

- Local package: `/Applications/DaveTheDiver.app/Contents/Game/DaveTheDiver.app`
- Local metadata: `Contents/Resources/Data/il2cpp_data/Metadata/global-metadata.dat`
- Local native code: `Contents/Frameworks/GameAssembly.dylib`
- Local save samples: `Contents/Resources/Data/StreamingAssets/DevQuickSaves/**/*.sav`
- Official base game page: https://store.steampowered.com/app/1868140/DAVE_THE_DIVER/
- DLC store/news references used for gameplay context: https://store.steampowered.com/news/app/1868140

The exact inventory fields below come from local package inspection, not from public wiki text. Public pages are useful for confirming the base game/DLC context, but they do not expose the memory layout used by the trainer.

Localized item names such as `巨狗脂鲤`, `芫荽`, `香蕉花`, and `鱼露` are present inside Unity Addressables bundle binaries under `StreamingAssets/aa/StandaloneOSX/*.bundle`. They are not exposed as plain JSON/CSV tables in the shipped Mac package. This document therefore treats the storage containers, fields, and ID families as the authoritative trainer taxonomy. A full localized item-name catalog would require a separate Addressables/Unity asset extraction pass and should not be guessed from partial strings.

## Root Causes Fixed

### Main Fish Meat Did Not Change

The recipe UI for main sushi ingredients reads the main save dictionary, not only the runtime ingredient cache.

Observed layout:

- Runtime cache: `IngredientsStorage` dictionary, with `IngredientsData.counts[0]`
- Main save dictionary: `SaveData + 0x100`
- Save entry object: `IngredientsSave`
- Save entry ID: `IngredientsSave + 0x10`
- Save entry count: `IngredientsSave + 0x4C`
- Save dirty flag: `SaveData + 0x29`

The old implementation only updated `IngredientsData.counts[0]`. It could affect some already-open UI paths, but recipe screens still saw stale `IngredientsSave.Count`, which explains why the screenshot showed vegetables/seasonings updated in the DLC recipe while main fish meat still stayed at `5/2`.

The trainer now resolves runtime candidates by `ingredientsID`, matches them against `SaveData.Ingredients`, writes both count planes, and marks the save dirty. If a runtime ingredient ID has no save entry, the trainer throws an explicit error instead of pretending success.

### Artisan Flame Did Not Change In Jungle

`匠人之火` is not a single global value after the DLC.

Observed layout:

- Main value: `PlayerInfoSave.m_ChefFlame`, stored as `ObscuredInt32` at `PlayerInfoSave + 0x38`
- Jungle value: `junglePlayerInfoSave.jungleChefFlame`, stored as plain `Int32`
- Runtime path: `SaveDataJungle + 0xD0 -> holder + 0x14`
- Related Jungle currency: `SaveDataJungle + 0xD0 -> holder + 0x10`

The trainer now updates both the main and Jungle chef-flame fields when pressing the single `增加主线/丛林匠人火焰` option.

## Storage Planes

### Main Player Quantities

Container: `PlayerInfo`

Fields:

- `m_Gold`: main gold
- `m_Bei`: Sea People village currency
- `m_ChefFlame`: main Bancho sushi chef flame

Runtime layout:

- `PlayerInfoSave + 0x10`: gold, `ObscuredInt32`
- `PlayerInfoSave + 0x24`: bei, `ObscuredInt32`
- `PlayerInfoSave + 0x38`: chef flame, `ObscuredInt32`

Trainer support:

- `增加金币`
- `增加鲛人族贝壳`
- `增加主线/丛林匠人火焰`

### Main Sushi Ingredients

Container: `Ingredients`

Fields found in save samples:

- `ingredientsID`
- `level`
- `parentID`
- `count`
- `branchCount`
- `lastGainTime`
- `lastGainGameTime`
- `isNew`
- `placeTagMask`

ID prefixes observed across 288 parsed saves:

- `1021`: main fish/sushi ingredient family
- `1022`: one smaller ingredient family
- `1023`: another main ingredient family
- `1025`: main category family
- `1026`: main category family
- `1027`: main category family

Runtime category values used by the current trainer:

- `0...1`: fish-meat ingredients
- `2`: vegetable ingredients
- `3`: seasoning ingredients
- `4`: upgrade materials

Important distinction:

These are recipe/ingredient counts. `CaughtFish` is a discovery/grade dictionary and is not the fish-meat quantity displayed in recipes.

Trainer support:

- `增加主线全部食材/素材`
- `按鱼肉食材分类增加`
- `按蔬菜食材分类增加`
- `按调味品分类增加`
- `按强化素材分类增加`

### Main Generic Inventory

Container: `InventoryItemSlot`

Fields found in save samples:

- `GUID`
- `index`
- `itemID`
- `totalCount`
- `isNew`

ID prefixes observed across 288 parsed saves:

- `1013`
- `1014`
- `1015`
- `1018`
- `1019`
- `3010`
- `3011`
- `3012`
- `3013`
- `3017`
- `4301`

This is a separate count store from `Ingredients`. It appears to cover generic items, materials, equipment, loot, or special inventory slots depending on `itemID`. It should not be merged into the ingredient incrementer until each prefix is mapped to a safe item group.

Trainer support:

- Not yet exposed as a separate safe option.

### Fish Discovery And Grade

Container: `CaughtFish`

Fields found in save samples:

- `fishID`
- `grade`
- `isNew`

ID prefixes observed:

- `2010`
- `2012`
- `2013`
- `2014`

This records fish discovery/quality state, not ingredient quantity. Changing it is not equivalent to adding fish meat.

Trainer support:

- Not exposed as an inventory count option.

### Sea People Village Inventory

Container: `MermanVillInventory`

Fields found in save samples:

- `mvInvenItemID`
- `count`

ID prefix observed:

- `1111`

Trainer support:

- Currency `m_Bei` is supported.
- Village item counts are not yet exposed as a separate safe option.

### Harvested And Production Buckets

Containers observed in local metadata:

- `HarvestedIngredients`
- `HarvestedBonusIngredients`
- `HarvestedEggboxIngredients`
- `HarvestedEggboxBonusIngredients`
- `FishFarm`
- `FishCard`

These are production, discovery, or session-result buckets rather than the primary persistent item count store used by recipe inventory. They should be treated separately from the direct count incrementers.

Trainer support:

- Not exposed as direct inventory count options.

## Jungle DLC Storage Planes

### Jungle Player Quantities

Container: `JDLCContents.junglePlayerInfoSave`

Fields found in save samples:

- `jungleGold`
- `jungleChefFlame`
- `bestDivingTime`
- `bestReachedDepth`
- `bestCatchFish`
- `bestGetGatheringItem`
- `totalDivingCount`
- `dailyDivingCount`
- `baconResearchLevel`
- `baconLabRerollCount`
- `junglesubHelper1SlotItemID`
- `junglesubHelper2SlotItemID`
- `totalDivingCountFromSecondDay`

Trainer support:

- `增加丛林货币`
- `增加主线/丛林匠人火焰`

### Jungle Recipe Ingredients

Container: `JDLCContents.jungleIngredientsSave`

Fields found in save samples:

- `ingredientID`
- `count`
- `isNew`
- `level`
- `parentID`
- `lastGainTime`
- `lastGainGameTime`

ID prefix observed:

- `4102`

This is the DLC recipe ingredient store used by Bancho Grill and Jungle food systems. It includes more than only vegetables and seasonings; DLC fish/food ingredients also appear here.

Trainer support:

- `增加丛林DLC食材/素材（已有）`

### Jungle Village Inventory

Container: `JDLCContents.JungleVilInven`

Fields found in save samples:

- `itemID`
- `count`
- `isNew`
- `lastGainTime`
- `lastGainGameTime`

ID prefixes observed:

- `4101`
- `4102`

This is a DLC village inventory store. It overlaps the `4102` ID family but is not the same container as `jungleIngredientsSave`, so it must be handled as a separate store.

Important exclusion:

- `410103xx` entries overlap with `jungleBattleInsectSave` and `jungleInsectCodexSave`.
- Those entries are Jungle insects/beetles and must not be bulk-incremented by the inventory feature.
- The runtime incrementer skips `410103xx` inside `JungleVilInven` to avoid corrupting the beetle inventory display/cap behavior.

Trainer support:

- Non-insect existing `JungleVilInven` entries are included by `增加丛林DLC食材/素材（已有）`.
- Beetle/insect entries are intentionally excluded.

### Jungle Equipment And Tools

Containers found in save samples or metadata:

- `jungleGatheringToolSave`
- `jungleEquipSlotSave`
- `Jungle Equipment`
- `Jungle RPG Equipment`

Fields found in save samples:

- `equippedPickaxeTID`
- `equippedAxeTID`
- `equippedFishingRodTID`
- `equippedFishingLineTID`
- `gunSlotItemID`
- `gunSlotGuid`

These represent equipped tools or equipment slots, not additive inventory counts.

Trainer support:

- Not exposed as direct count options.

### Jungle RPG And Progression

Containers found:

- `userJungleRPGData`
- `SaveDataJungleDungeon`
- `jungleInsectCodexSave`
- `JungleCookingStudySave`
- `JungleSushiBarMenuSlotSaveData`
- `jungleGrillRecipeUnlockSave`
- `JungleDispatchSave`
- `JungleSushiBarSave`
- `jungleVillageMerchantSave`
- `jungleVillagerSaveDictionary`
- `jungleVillageWeatherForecast`

Metadata category names observed:

- `Jungle Item`
- `Jungle Equipment`
- `Jungle RPG Equipment`
- `Jungle Furniture`
- `Jungle NPC Shop`
- `Jungle Insect Codex`
- `Jungle Weather`
- `Jungle Achievement Log`
- `Sushi Bar Ingredients`

These categories include unlocks, progression, codex entries, furniture, NPC shops, weather, RPG state, and menu slots. They are not all safe to increment with one generic item-count operation.

Trainer support:

- Not exposed as bulk count options.

## Implementation Rule For Inventory Features

Every inventory feature should specify all of these before writing memory:

- The owning container, such as `Ingredients`, `InventoryItemSlot`, `jungleIngredientsSave`, or `JungleVilInven`
- The item ID field, such as `ingredientsID`, `itemID`, `fishID`, or `ingredientID`
- The quantity field, such as `count` or `totalCount`
- Whether the field is plain `Int32`, `ObscuredInt32`, an array element, or an object reference
- Whether a runtime cache must be updated in addition to the persistent save object
- Whether a dirty flag must be set

The current safe model is to fail loudly if a runtime object cannot be matched to its persistent save entry. This avoids the previous silent-success case where UI cache changed but the real recipe inventory did not.
