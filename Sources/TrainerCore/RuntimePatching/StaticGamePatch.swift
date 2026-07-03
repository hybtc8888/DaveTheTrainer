import Foundation

public enum StaticPatchTrampolineKind: String, Codable, Sendable {
    case rpgEnemyOnlySuperDamage
    case rpgDamagePolicySuperDamage
    case rpgDamagePolicyIgnoreDamage
}

public struct StaticPatchTrampoline: Equatable, Codable, Sendable {
    public let kind: StaticPatchTrampolineKind
    public let value: Int64
    public let resumeRVA: UInt64
    public let nullHandlerRVA: UInt64
    public let helperRVA: UInt64
    public let codeCaveRVA: UInt64?
    public let codeCaveExpectedBytes: [UInt8]?

    public init(
        kind: StaticPatchTrampolineKind,
        value: Int64,
        resumeRVA: UInt64,
        nullHandlerRVA: UInt64,
        helperRVA: UInt64,
        codeCaveRVA: UInt64? = nil,
        codeCaveExpectedBytes: [UInt8]? = nil
    ) {
        self.kind = kind
        self.value = value
        self.resumeRVA = resumeRVA
        self.nullHandlerRVA = nullHandlerRVA
        self.helperRVA = helperRVA
        self.codeCaveRVA = codeCaveRVA
        self.codeCaveExpectedBytes = codeCaveExpectedBytes
    }
}

public struct StaticPatchPoint: Equatable, Codable, Sendable {
    public let rva: UInt64
    public let expectedBytes: [UInt8]
    public let patchBytes: [UInt8]
    public let note: String
    public let acceptsLegacyIntReturnPatch: Bool
    public let acceptsCompatibleAppliedPatch: Bool
    public let trampoline: StaticPatchTrampoline?

    public init(
        rva: UInt64,
        expectedBytes: [UInt8],
        patchBytes: [UInt8],
        note: String,
        acceptsLegacyIntReturnPatch: Bool = false,
        acceptsCompatibleAppliedPatch: Bool = false,
        trampoline: StaticPatchTrampoline? = nil
    ) {
        self.rva = rva
        self.expectedBytes = expectedBytes
        self.patchBytes = patchBytes
        self.note = note
        self.acceptsLegacyIntReturnPatch = acceptsLegacyIntReturnPatch
        self.acceptsCompatibleAppliedPatch = acceptsCompatibleAppliedPatch
        self.trampoline = trampoline
    }
}

public struct StaticGamePatch: Equatable, Codable, Sendable {
    public let id: String
    public let title: String
    public let points: [StaticPatchPoint]

    public init(id: String, title: String, points: [StaticPatchPoint]) {
        self.id = id
        self.title = title
        self.points = points
    }
}

public enum DefaultStaticGamePatches {
    private static let globalGetTotalGoldRVA = UInt64(0x12FD1C0)
    private static let globalDecreaseTotalGoldRVA = UInt64(0x12FFCE4)
    private static let lobbyGoldGetCurrentZoneGoldRVA = UInt64(0x1E45A28)
    private static let playerInfoSaveGetGoldRVA = UInt64(0x1F38808)
    private static let playerInfoSaveSetGoldRVA = UInt64(0x1F3881C)
    private static let playerInfoSaveGetBeiRVA = UInt64(0x1F388A0)
    private static let playerInfoSaveSetBeiRVA = UInt64(0x1F388B4)
    private static let playerInfoSaveGetChefFlameRVA = UInt64(0x1F38938)
    private static let playerInfoSaveSetChefFlameRVA = UInt64(0x1F3894C)
    private static let obscuredIntFromIntRVA = UInt64(0x11DD394)
    private static let saveSystemGetGameSaveRVA = UInt64(0x1429234)
    private static let saveDataUpdatePlayerSaveRVA = UInt64(0x1870C60)
    private static let raiseNullReferenceRVA = UInt64(0x9556E4)
    private static let raiseIndexOutOfRangeRVA = UInt64(0x9556F0)
    private static let playerInfoSaveGoldFieldOffset = UInt32(0x10)
    private static let playerInfoSaveBeiFieldOffset = UInt32(0x24)
    private static let playerInfoSaveChefFlameFieldOffset = UInt32(0x38)
    private static let jungleCommonIsPayableRVA = UInt64(0x1565F4C)
    private static let jungleCommonGetPayableResultRVA = UInt64(0x15660A0)
    private static let jungleCommonPayPlayerResourceListRVA = UInt64(0x1566200)
    private static let jungleCommonPayPlayerResourceSingleRVA = UInt64(0x1566690)
    private static let weaponInfoPanelPayGoldRVA = UInt64(0x1368460)
    private static let ingredientsDataTotalCountRVA = UInt64(0x20F00C4)
    private static let ingredientsDataGetCountRVA = UInt64(0x20F00FC)
    private static let ingredientsDataSetCountRVA = UInt64(0x20F0130)
    private static let ingredientsDataIsEnoughRVA = UInt64(0x20F0168)
    private static let ingredientsDataIsEnoughTotalRVA = UInt64(0x20F01A4)
    private static let ingredientsStorageGetCountRVA = UInt64(0x20F1478)
    private static let ingredientsStorageGetCountCategoryPatchRVA = UInt64(0x20F14DC)
    private static let cookingConsumeIngredientsRVA = UInt64(0x191E57C)
    private static let cookingConsumeIngredientsOverloadRVA = UInt64(0x191EDD8)
    private static let playerCharacterDetermineMoveSpeedRVA = UInt64(0x0B7D67C)
    private static let playerMovePropertyGetMoveSpeedRVA = UInt64(0x2072778)
    private static let daveMoveValueGetSpeedMultiplierRVA = UInt64(0x0FF5E9C)
    private static let farmPlayerPresenterMoveSpeedMultiplierRVA = UInt64(0x0F97664)
    private static let farmPlayerPresenterMoveSpeedLiteralRVA = UInt64(0x0F97670)
    private static let farmPlayerPresenterMoveSpeedContinueRVA = UInt64(0x0F97674)
    private static let fishFarmPlayerViewGetDaveSpeedRVA = UInt64(0x0F4F390)
    private static let fishFarmPlayerPresenterDashSpeedRVA = UInt64(0x0F4E2E8)
    private static let fishFarmPlayerPresenterWalkSpeedRVA = UInt64(0x0F4E2F0)
    private static let jVillageLobbyMoveCustomizedSpeedRVA = UInt64(0x1799224)
    private static let jVillageStateMachineGetCustomizedSpeedRateRVA = UInt64(0x17A37FC)
    private static let jVillageStateMachineCustomizedSpeedLiteralRVA = UInt64(0x17A3808)
    private static let baconStoryPlayerMoveSpeedRVA = UInt64(0x113D144)
    private static let baconStoryChasingLaneGetMoveSpeedRVA = UInt64(0x1146560)
    private static let legacyFishSpeedEnterMultiplierRVA = UInt64(0x20A4694)
    private static let legacyFishSpeedUpdateMultiplierRVA = UInt64(0x20A4750)
    private static let playerCharacterOnTakeDamageRVA = UInt64(0x0B7EA14)
    private static let playerCharacterGetIsImmuneDamageRVA = UInt64(0x0B76690)
    private static let playerCharacterIsDroneAvailableRVA = UInt64(0x0B76EDC)
    private static let playerBreathHandlerChangeOxygenValueRVA = UInt64(0x1B3A044)
    private static let playerBreathHandlerSetHazardHPDamageRVA = UInt64(0x1B43C20)
    private static let playerBreathHandlerGetIsOxygenDepletingRVA = UInt64(0x1B438C4)
    private static let playerBreathHandlerGetCheatNoDieRVA = UInt64(0x1B400D8)
    private static let playerBreathHandlerGetImmuneDamageRVA = UInt64(0x1B400F8)
    private static let primaryWeaponDecreaseRemainCountRVA = UInt64(0x138C3B8)
    private static let primaryWeaponGetCanUseRVA = UInt64(0x138BDD4)
    private static let primaryWeaponGetRemainBombCountRVA = UInt64(0x138BE74)
    private static let gunWeaponHandlerDecreaseBulletRVA = UInt64(0x1B27FFC)
    private static let gunWeaponHandlerFireWeaponAmmoGateRVA = UInt64(0x1B28B98)
    private static let gunWeaponHandlerReloadBulletFinalCountRVA = UInt64(0x1B28504)
    private static let gunWeaponHandlerForceSetBulletCountValueMoveRVA = UInt64(0x1B28580)
    private static let gunWeaponHandlerIsAvailableRVA = UInt64(0x1B2893C)
    private static let gunWeaponHandlerGetAmmoRVA = UInt64(0x1B293F0)
    private static let countSecondaryWeaponDecreaseFireCountRVA = UInt64(0x139A50C)
    private static let countSecondaryWeaponGetRemainedFireCountRVA = UInt64(0x13A0060)
    private static let countSecondaryWeaponGetCanUseRVA = UInt64(0x139FFAC)
    private static let fuelSecondaryWeaponDecreaseFuelRVA = UInt64(0x13BD63C)
    private static let fuelSecondaryWeaponGetRemainedFireCountRVA = UInt64(0x13BF134)
    private static let fuelSecondaryWeaponGetCanUseRVA = UInt64(0x13BF0A8)
    private static let ammoHandlerUseInstanceSubHelperRVA = UInt64(0x1B352EC)
    private static let weaponManagerSetPrimaryWeaponRemainCountValueMoveRVA = UInt64(0x13407BC)
    private static let actionSwitchUISetBulletCountValueMoveRVA = UInt64(0x1D0B8E4)
    private static let actionSwitchUISetSubHelperDataCountMoveRVA = UInt64(0x1D0C0B8)
    private static let subEquipmentGetTrapCountRVA = UInt64(0x1418E84)
    private static let subEquipmentSetTrapCountRVA = UInt64(0x1418E8C)
    private static let playerCharacterAvailableCrabTrapCountRVA = UInt64(0x0B76EEC)
    private static let playerCharacterSetAvailableCrabTrapCountRVA = UInt64(0x0B76EF4)
    private static let playerCharacterIsCrabTrapAvailableRVA = UInt64(0x0B76EFC)
    private static let savePlayerDataAvailableCrabTrapRVA = UInt64(0x144EF4C)
    private static let savePlayerDataSetAvailableCrabTrapRVA = UInt64(0x144EF54)
    private static let cargoBoxGetMaximumWeightRVA = UInt64(0x1D95604)
    private static let playerInstalledCargoBoxDataGetWeightRVA = UInt64(0x1450AF8)
    private static let playerInstalledCargoBoxDataSetWeightRVA = UInt64(0x1450B00)
    private static let lootBoxSetWeightRVA = UInt64(0x1EA8360)
    private static let lootBoxGetWeightRVA = UInt64(0x1EA8368)
    private static let lootBoxGetWeightMaxRVA = UInt64(0x1EA8660)
    private static let lootBoxCheckOverloadedStateRVA = UInt64(0x1EA80F4)
    private static let lootBoxGetOverloadedThresholdRVA = UInt64(0x1EA86A8)
    private static let lootBoxGetIsOverweightStateRVA = UInt64(0x1EA86B8)
    private static let lootBoxRefreshWeightRVA = UInt64(0x1EAA1D4)
    private static let lootBoxRefreshOverweightRVA = UInt64(0x1EAA960)
    private static let overweightPropertyGetOverloadedThresholdRVA = UInt64(0x2072528)
    private static let retiredHarpoonProjectileGetBuffedProjectileDamageRVA = UInt64(0x1DA39FC)
    private static let retiredHarpoonProjectileGetProjectileDamageRVA = UInt64(0x1DA3C5C)
    private static let retiredHarpoonProjectileGetGlobalProjectileDamageRVA = UInt64(0x1DA3DB8)
    private static let harpoonProjectileCollisionDamageValueRVA = UInt64(0x1DA55C8)
    private static let pirateRopeDamageRVA = UInt64(0x13A3134)
    private static let pirateRopePopupDamageRVA = UInt64(0x13A3204)
    private static let johnWatsonDamageRVA = UInt64(0x13B4358)
    private static let wreckDamageRVA = UInt64(0x14A8F4C)
    private static let fishAISystemDamageRVA = UInt64(0x14EAC40)
    private static let mxmtoonDamageGateRVA = UInt64(0x15EC7E0)
    private static let pirateBaseDamageGateRVA = UInt64(0x1722C78)
    private static let pirateBaseDamageRVA = UInt64(0x1722CD0)
    private static let npcPlayerCharacterDamageRVA = UInt64(0x1732538)
    private static let damageableEventDamageRVA = UInt64(0x1C3EB1C)
    private static let damageableLastDamageRVA = UInt64(0x1C3EBA0)
    private static let rockBlockerDamageRVA = UInt64(0x1C51664)
    private static let giantSquidDamageGateRVA = UInt64(0x1DC4194)
    private static let wolffishDamageGateRVA = UInt64(0x1F0E344)
    private static let wolffishDamageScaleRVA = UInt64(0x1F0E478)
    private static let wolffishFinalDamageRVA = UInt64(0x1F0E718)
    private static let insectBattlePlayerDirectDamageRVA = UInt64(0x0DCC5C0)
    private static let insectBattlePlayerDamageDifferenceRVA = UInt64(0x0DCC66C)
    private static let insectBattlePlayerCounterDamageDifferenceRVA = UInt64(0x0DCC734)
    private static let insectBattleEnemyDirectDamageRVA = UInt64(0x0DCC53C)
    private static let insectBattleEnemyDamageDifferenceRVA = UInt64(0x0DCC83C)
    private static let legacyAttackDataGetBuffedDamageRVA = UInt64(0x1C3F4E8)
    private static let legacyDamagerSetDamageValueRVA = UInt64(0x1C43144)
    private static let legacyExtensionIDamagerGetBuffedDamageRVA = UInt64(0x214BD7C)
    private static let legacyJungleRPGDamageResultScaleRVA = UInt64(0x18DE9D0)
    private static let rpgDealDamageEnemyOnlyHookRVA = UInt64(0x18DDD70)
    private static let rpgDealDamageEnemyOnlyResumeRVA = UInt64(0x18DDD74)
    private static let rpgDealDamageNullHandlerRVA = UInt64(0x18DDF0C)
    private static let rpgDamageTrampolineCodeCaveRVA = UInt64(0x940)
    private static let battleUtilsIsEnemyRVA = UInt64(0x18E1A58)
    private static let operationDataNowWasabiCountRVA = UInt64(0x2120C7C)
    private static let operationDataIsAvailableWasabiRVA = UInt64(0x2120E90)
    private static let operationDataUsingWasabiInCookingRVA = UInt64(0x210CED8)
    private static let wasabiGratersGetNowCountRVA = UInt64(0x21207E4)
    private static let wasabiGratersRemainRateRVA = UInt64(0x2120AD8)
    private static let saveDataJungleGetJungleGoldRVA = UInt64(0x1526360)
    private static let saveDataJungleGetChiefFlameRVA = UInt64(0x15264FC)
    private static let daveMoveValueGetIsStaminaZeroPenaltyRVA = UInt64(0x0FF5B50)
    private static let daveMoveValueGetStaminaRVA = UInt64(0x0FF5E8C)
    private static let daveMoveValueSetStaminaRVA = UInt64(0x0FF5E94)
    private static let daveMoveValueConsumeStaminaArithmeticRVA = UInt64(0x0FF61E4)
    private static let superDamageValue = Int64(999_999)
    private static let unlimitedAmmoCount = Int64(999)
    private static let unlimitedDroneDisplayCount = Int64(999)
    private static let unlimitedOverweightThreshold = Float(999.0)
    private static let unlimitedWasabiCount = Int64(999)

    public static func make() -> [StaticGamePatch] {
        [
            StaticGamePatch(
                id: "god",
                title: "无敌/忽略伤害",
                points: [
                    StaticPatchPoint(
                        rva: 0x0B82130,
                        expectedBytes: [0xFF, 0xC3, 0x01, 0xD1, 0xEB, 0x2B, 0x02, 0x6D],
                        patchBytes: arm64Return,
                        note: "PlayerCharacter_SetHPDamage -> ret"
                    ),
                    StaticPatchPoint(
                        rva: 0x0B823BC,
                        expectedBytes: [0xFF, 0xC3, 0x01, 0xD1, 0xEB, 0x2B, 0x02, 0x6D],
                        patchBytes: arm64Return,
                        note: "PlayerCharacter_SetHPDamageQTE -> ret"
                    ),
                    StaticPatchPoint(
                        rva: playerCharacterOnTakeDamageRVA,
                        expectedBytes: playerCharacterOnTakeDamageExpectedBytes,
                        patchBytes: arm64ReturnFalseBool,
                        note: "PlayerCharacter_OnTakeDamage -> false"
                    ),
                    StaticPatchPoint(
                        rva: playerCharacterGetIsImmuneDamageRVA,
                        expectedBytes: playerCharacterGetIsImmuneDamageExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "PlayerCharacter_get_IsImmuneDamage -> true"
                    ),
                    StaticPatchPoint(
                        rva: playerBreathHandlerSetHazardHPDamageRVA,
                        expectedBytes: playerBreathHandlerSetHazardHPDamageExpectedBytes,
                        patchBytes: arm64Return,
                        note: "PlayerBreathHandler_SetHazardHPDamage -> ret"
                    ),
                    StaticPatchPoint(
                        rva: playerBreathHandlerGetCheatNoDieRVA,
                        expectedBytes: playerBreathHandlerGetCheatNoDieExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "PlayerBreathHandler_get_Cheat_NoDie -> true"
                    ),
                    StaticPatchPoint(
                        rva: playerBreathHandlerGetImmuneDamageRVA,
                        expectedBytes: playerBreathHandlerGetImmuneDamageExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "PlayerBreathHandler_get_ImmuneDamage -> true"
                    ),
                    StaticPatchPoint(
                        rva: insectBattleEnemyDirectDamageRVA,
                        expectedBytes: insectBattleEnemyDirectDamageExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW1(0),
                        note: "InsectBattle enemy direct damage -> player zero damage"
                    ),
                    StaticPatchPoint(
                        rva: insectBattleEnemyDamageDifferenceRVA,
                        expectedBytes: insectBattleEnemyDamageDifferenceExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW1(0),
                        note: "InsectBattle enemy damage advantage -> player zero damage"
                    ),
                    StaticPatchPoint(
                        rva: rpgDealDamageEnemyOnlyHookRVA,
                        expectedBytes: rpgDealDamageEnemyOnlyHookExpectedBytes,
                        patchBytes: [],
                        note: "RPG DealDamage target non-Enemy -> player zero damage",
                        trampoline: StaticPatchTrampoline(
                            kind: .rpgDamagePolicyIgnoreDamage,
                            value: superDamageValue,
                            resumeRVA: rpgDealDamageEnemyOnlyResumeRVA,
                            nullHandlerRVA: rpgDealDamageNullHandlerRVA,
                            helperRVA: battleUtilsIsEnemyRVA,
                            codeCaveRVA: rpgDamageTrampolineCodeCaveRVA,
                            codeCaveExpectedBytes: rpgDamageTrampolineCodeCaveExpectedBytes
                        )
                    )
                ]
            ),
            StaticGamePatch(
                id: "oxygen",
                title: "无限氧气",
                points: [
                    StaticPatchPoint(
                        rva: 0x13D8E78,
                        expectedBytes: [0x01, 0x28, 0x41, 0xBD, 0x20, 0x20, 0x20, 0x1E],
                        patchBytes: arm64Return,
                        note: "DavePlayer_ReduceOxygen -> ret"
                    ),
                    StaticPatchPoint(
                        rva: 0x13DBB0C,
                        expectedBytes: [0x00, 0x28, 0x41, 0xBD, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: Arm64ReturnCode.returnThirtyOneFloat32,
                        note: "DavePlayer_get_CurOxygen -> 31.0"
                    ),
                    StaticPatchPoint(
                        rva: playerBreathHandlerChangeOxygenValueRVA,
                        expectedBytes: playerBreathHandlerChangeOxygenValueExpectedBytes,
                        patchBytes: arm64Return,
                        note: "PlayerBreathHandler_ChangeOxygenValue -> ret"
                    ),
                    StaticPatchPoint(
                        rva: playerBreathHandlerGetIsOxygenDepletingRVA,
                        expectedBytes: playerBreathHandlerGetIsOxygenDepletingExpectedBytes,
                        patchBytes: arm64ReturnFalseBool,
                        note: "PlayerBreathHandler_get_IsOxygenDepleting -> false"
                    )
                ]
            ),
            StaticGamePatch(
                id: "ammo",
                title: "无限弹药/鱼叉资源",
                points: [
                    StaticPatchPoint(
                        rva: 0x0B895E8,
                        expectedBytes: [0xF4, 0x4F, 0xBE, 0xA9, 0xFD, 0x7B, 0x01, 0xA9],
                        patchBytes: arm64Return,
                        note: "PlayerCharacter_Event_OnUseAmmo -> ret"
                    ),
                    StaticPatchPoint(
                        rva: 0x0B84BF8,
                        expectedBytes: [0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9],
                        patchBytes: arm64Return,
                        note: "PlayerCharacter_Event_OnLoseHarpoonProjectile -> ret"
                    ),
                    StaticPatchPoint(
                        rva: 0x1B35224,
                        expectedBytes: [0xF4, 0x4F, 0xBE, 0xA9, 0xFD, 0x7B, 0x01, 0xA9],
                        patchBytes: arm64ReturnTrueBool,
                        note: "AmmoHandler_IsAvailable -> true"
                    ),
                    StaticPatchPoint(
                        rva: ammoHandlerUseInstanceSubHelperRVA,
                        expectedBytes: ammoHandlerUseInstanceSubHelperExpectedBytes,
                        patchBytes: arm64Return,
                        note: "AmmoHandler_UseInstanceSubHelper -> ret"
                    ),
                    StaticPatchPoint(
                        rva: gunWeaponHandlerFireWeaponAmmoGateRVA,
                        expectedBytes: gunWeaponHandlerFireWeaponAmmoGateExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW8(unlimitedAmmoCount),
                        note: "GunWeaponHandler_FireWeapon ammo gate -> 999"
                    ),
                    StaticPatchPoint(
                        rva: gunWeaponHandlerDecreaseBulletRVA,
                        expectedBytes: gunWeaponHandlerDecreaseBulletExpectedBytes,
                        patchBytes: arm64Return,
                        note: "GunWeaponHandler_DecreaseBullet -> ret"
                    ),
                    StaticPatchPoint(
                        rva: gunWeaponHandlerIsAvailableRVA,
                        expectedBytes: gunWeaponHandlerIsAvailableExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "GunWeaponHandler_IsAvailable -> true"
                    ),
                    StaticPatchPoint(
                        rva: gunWeaponHandlerGetAmmoRVA,
                        expectedBytes: gunWeaponHandlerGetAmmoExpectedBytes,
                        patchBytes: arm64Return999Int32,
                        note: "GunWeaponHandler_GetAmmo -> 999"
                    ),
                    StaticPatchPoint(
                        rva: gunWeaponHandlerReloadBulletFinalCountRVA,
                        expectedBytes: gunWeaponHandlerReloadBulletFinalCountExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW8(unlimitedAmmoCount),
                        note: "GunWeaponHandler_ReloadBullet stored count -> 999"
                    ),
                    StaticPatchPoint(
                        rva: gunWeaponHandlerForceSetBulletCountValueMoveRVA,
                        expectedBytes: gunWeaponHandlerForceSetBulletCountValueMoveExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW20(unlimitedAmmoCount),
                        note: "GunWeaponHandler_ForceSetBulletCount real count -> 999"
                    ),
                    StaticPatchPoint(
                        rva: primaryWeaponDecreaseRemainCountRVA,
                        expectedBytes: primaryWeaponDecreaseRemainCountExpectedBytes,
                        patchBytes: arm64Return,
                        note: "PrimaryWeaponController_DecreaseRemainCount -> ret"
                    ),
                    StaticPatchPoint(
                        rva: primaryWeaponGetCanUseRVA,
                        expectedBytes: obscuredIntCanUseExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "PrimaryWeaponController_get_canUse -> true"
                    ),
                    StaticPatchPoint(
                        rva: primaryWeaponGetRemainBombCountRVA,
                        expectedBytes: obscuredIntCanUseExpectedBytes,
                        patchBytes: arm64Return999Int32,
                        note: "PrimaryWeaponController_get_remainBombCount -> 999"
                    ),
                    StaticPatchPoint(
                        rva: weaponManagerSetPrimaryWeaponRemainCountValueMoveRVA,
                        expectedBytes: weaponManagerSetPrimaryWeaponRemainCountValueMoveExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW20(unlimitedAmmoCount),
                        note: "WeaponManager_SetPrimaryWeaponRemainCount count -> 999"
                    ),
                    StaticPatchPoint(
                        rva: actionSwitchUISetBulletCountValueMoveRVA,
                        expectedBytes: actionSwitchUISetBulletCountValueMoveExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW21(unlimitedAmmoCount),
                        note: "ActionSwitchUI_SetBulletCount count -> 999"
                    ),
                    StaticPatchPoint(
                        rva: countSecondaryWeaponDecreaseFireCountRVA,
                        expectedBytes: secondaryWeaponDecreaseExpectedBytes,
                        patchBytes: arm64Return,
                        note: "CountSecondaryWeaponController_DecreaseFireCount -> ret"
                    ),
                    StaticPatchPoint(
                        rva: countSecondaryWeaponGetCanUseRVA,
                        expectedBytes: obscuredIntCanUseExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "CountSecondaryWeaponController_get_canUse -> true"
                    ),
                    StaticPatchPoint(
                        rva: countSecondaryWeaponGetRemainedFireCountRVA,
                        expectedBytes: secondaryWeaponGetRemainedFireCountExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnFloat32(Float(unlimitedAmmoCount)),
                        note: "CountSecondaryWeaponController_GetRemainedFireCount -> 999.0",
                        acceptsCompatibleAppliedPatch: true
                    ),
                    StaticPatchPoint(
                        rva: fuelSecondaryWeaponDecreaseFuelRVA,
                        expectedBytes: secondaryWeaponDecreaseExpectedBytes,
                        patchBytes: arm64Return,
                        note: "FuelSecondaryWeaponController_DecreaseFuel -> ret"
                    ),
                    StaticPatchPoint(
                        rva: fuelSecondaryWeaponGetCanUseRVA,
                        expectedBytes: obscuredIntCanUseExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "FuelSecondaryWeaponController_get_canUse -> true"
                    ),
                    StaticPatchPoint(
                        rva: fuelSecondaryWeaponGetRemainedFireCountRVA,
                        expectedBytes: secondaryWeaponGetRemainedFireCountExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnFloat32(Float(unlimitedAmmoCount)),
                        note: "FuelSecondaryWeaponController_GetRemainedFireCount -> 999.0",
                        acceptsCompatibleAppliedPatch: true
                    )
                ]
            ),
            StaticGamePatch(
                id: "crabTraps",
                title: "无限鱼笼",
                points: [
                    StaticPatchPoint(
                        rva: subEquipmentGetTrapCountRVA,
                        expectedBytes: subEquipmentGetTrapCountExpectedBytes,
                        patchBytes: arm64Return999Int32,
                        note: "SubEquipment_get_TrapCount -> 999"
                    ),
                    StaticPatchPoint(
                        rva: subEquipmentSetTrapCountRVA,
                        expectedBytes: subEquipmentSetTrapCountExpectedBytes,
                        patchBytes: arm64Return,
                        note: "SubEquipment_set_TrapCount -> ret"
                    ),
                    StaticPatchPoint(
                        rva: playerCharacterAvailableCrabTrapCountRVA,
                        expectedBytes: playerCharacterAvailableCrabTrapCountExpectedBytes,
                        patchBytes: arm64Return999Int32,
                        note: "PlayerCharacter_get_AvailableCrabTrapCount -> 999"
                    ),
                    StaticPatchPoint(
                        rva: playerCharacterSetAvailableCrabTrapCountRVA,
                        expectedBytes: playerCharacterSetAvailableCrabTrapCountExpectedBytes,
                        patchBytes: arm64Return,
                        note: "PlayerCharacter_set_AvailableCrabTrapCount -> ret"
                    ),
                    StaticPatchPoint(
                        rva: playerCharacterIsCrabTrapAvailableRVA,
                        expectedBytes: playerCharacterIsCrabTrapAvailableExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "PlayerCharacter_get_IsCrabTrapAvailable -> true"
                    ),
                    StaticPatchPoint(
                        rva: savePlayerDataAvailableCrabTrapRVA,
                        expectedBytes: savePlayerDataAvailableCrabTrapExpectedBytes,
                        patchBytes: arm64Return999Int32,
                        note: "SavePlayerData_get_AvailableCrabTrap -> 999"
                    ),
                    StaticPatchPoint(
                        rva: savePlayerDataSetAvailableCrabTrapRVA,
                        expectedBytes: savePlayerDataSetAvailableCrabTrapExpectedBytes,
                        patchBytes: arm64Return,
                        note: "SavePlayerData_set_AvailableCrabTrap -> ret"
                    )
                ]
            ),
            StaticGamePatch(
                id: "drones",
                title: "无限无人机",
                points: [
                    StaticPatchPoint(
                        rva: 0x0B76ECC,
                        expectedBytes: [0x00, 0xD0, 0x41, 0xB9, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: arm64Return999Int32,
                        note: "PlayerCharacter_get_AvailableLiftDroneCount -> 999"
                    ),
                    StaticPatchPoint(
                        rva: actionSwitchUISetSubHelperDataCountMoveRVA,
                        expectedBytes: actionSwitchUISetSubHelperDataCountMoveExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW22(unlimitedDroneDisplayCount),
                        note: "ActionSwitchUI_SetSubHelperData count -> 999"
                    ),
                    StaticPatchPoint(
                        rva: 0x0B76ED4,
                        expectedBytes: [0x01, 0xD0, 0x01, 0xB9, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: arm64Return,
                        note: "PlayerCharacter_set_AvailableLiftDroneCount -> ret"
                    ),
                    StaticPatchPoint(
                        rva: playerCharacterIsDroneAvailableRVA,
                        expectedBytes: playerCharacterIsDroneAvailableExpectedBytes,
                        patchBytes: arm64ReturnTrueBool,
                        note: "PlayerCharacter_get_IsDroneAvailable -> true"
                    )
                ]
            ),
            StaticGamePatch(
                id: "weight",
                title: "无限负重",
                points: [
                    StaticPatchPoint(
                        rva: cargoBoxGetMaximumWeightRVA,
                        expectedBytes: cargoBoxGetMaximumWeightExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnThirtyOneFloat32,
                        note: "CargoBox_get_MaximumWeight -> 31.0"
                    ),
                    StaticPatchPoint(
                        rva: 0x1D95614,
                        expectedBytes: [0x00, 0x3C, 0x40, 0xBD, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: Arm64ReturnCode.returnZeroFloat32,
                        note: "CargoBox_get_Weight -> 0.0"
                    ),
                    StaticPatchPoint(
                        rva: 0x1D9561C,
                        expectedBytes: [0x00, 0x3C, 0x00, 0xBD, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: arm64Return,
                        note: "CargoBox_set_Weight -> ret"
                    ),
                    StaticPatchPoint(
                        rva: playerInstalledCargoBoxDataGetWeightRVA,
                        expectedBytes: playerInstalledCargoBoxDataGetWeightExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnZeroFloat32,
                        note: "PlayerInstalledCargoBoxData_get_Weight -> 0.0"
                    ),
                    StaticPatchPoint(
                        rva: playerInstalledCargoBoxDataSetWeightRVA,
                        expectedBytes: playerInstalledCargoBoxDataSetWeightExpectedBytes,
                        patchBytes: arm64Return,
                        note: "PlayerInstalledCargoBoxData_set_Weight -> ret"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxGetWeightRVA,
                        expectedBytes: lootBoxGetWeightExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnZeroFloat32,
                        note: "LootBox_get_weight -> 0.0"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxSetWeightRVA,
                        expectedBytes: lootBoxSetWeightExpectedBytes,
                        patchBytes: arm64Return,
                        note: "LootBox_set_weight -> ret"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxGetWeightMaxRVA,
                        expectedBytes: lootBoxGetWeightMaxExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnThirtyOneFloat32,
                        note: "LootBox_get_weightMax -> 31.0"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxGetOverloadedThresholdRVA,
                        expectedBytes: lootBoxGetOverloadedThresholdExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnThirtyOneFloat32,
                        note: "LootBox_get_overloadedThreshold -> 31.0"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxCheckOverloadedStateRVA,
                        expectedBytes: lootBoxCheckOverloadedStateExpectedBytes,
                        patchBytes: arm64ReturnFalseBool,
                        note: "LootBox_CheckOverloadedState -> false"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxGetIsOverweightStateRVA,
                        expectedBytes: lootBoxGetIsOverweightStateExpectedBytes,
                        patchBytes: arm64ReturnFalseBool,
                        note: "LootBox_get_isOverweightState -> false"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxRefreshWeightRVA,
                        expectedBytes: lootBoxRefreshWeightExpectedBytes,
                        patchBytes: arm64Return,
                        note: "LootBox_RefreshWeight -> ret"
                    ),
                    StaticPatchPoint(
                        rva: lootBoxRefreshOverweightRVA,
                        expectedBytes: lootBoxRefreshOverweightExpectedBytes,
                        patchBytes: arm64Return,
                        note: "LootBox_RefreshOverweight -> ret"
                    ),
                    StaticPatchPoint(
                        rva: overweightPropertyGetOverloadedThresholdRVA,
                        expectedBytes: overweightPropertyGetOverloadedThresholdExpectedBytes,
                        patchBytes: Arm64ReturnCode.returnFloat32(unlimitedOverweightThreshold),
                        note: "OverweightProperty_get_OverloadedThreshold -> 999.0"
                    )
                ]
            ),
            StaticGamePatch(
                id: "damage",
                title: "超级伤害/一击必杀",
                points: [
                    StaticPatchPoint(
                        rva: retiredHarpoonProjectileGetBuffedProjectileDamageRVA,
                        expectedBytes: retiredHarpoonProjectileGetBuffedProjectileDamageExpectedBytes,
                        patchBytes: retiredHarpoonProjectileGetBuffedProjectileDamageExpectedBytes,
                        note: "Restore retired unscoped HarpoonProjectile buffed damage patch",
                        acceptsCompatibleAppliedPatch: true
                    ),
                    StaticPatchPoint(
                        rva: retiredHarpoonProjectileGetProjectileDamageRVA,
                        expectedBytes: retiredHarpoonProjectileGetProjectileDamageExpectedBytes,
                        patchBytes: retiredHarpoonProjectileGetProjectileDamageExpectedBytes,
                        note: "Restore retired unscoped HarpoonProjectile damage patch",
                        acceptsCompatibleAppliedPatch: true
                    ),
                    StaticPatchPoint(
                        rva: retiredHarpoonProjectileGetGlobalProjectileDamageRVA,
                        expectedBytes: retiredHarpoonProjectileGetProjectileDamageExpectedBytes,
                        patchBytes: retiredHarpoonProjectileGetProjectileDamageExpectedBytes,
                        note: "Restore retired unscoped HarpoonProjectile global damage patch",
                        acceptsCompatibleAppliedPatch: true
                    ),
                    StaticPatchPoint(
                        rva: harpoonProjectileCollisionDamageValueRVA,
                        expectedBytes: harpoonProjectileCollisionDamageValueExpectedBytes,
                        patchBytes: harpoonProjectileCollisionSuperDamagePatchBytes,
                        note: "HarpoonProjectile collision damage branch -> super damage after capture/net paths"
                    ),
                ] + divingTargetDamagePatchPoints + [
                    StaticPatchPoint(
                        rva: insectBattlePlayerDirectDamageRVA,
                        expectedBytes: insectBattlePlayerDirectDamageExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW1(superDamageValue),
                        note: "InsectBattle player direct damage -> enemy super damage"
                    ),
                    StaticPatchPoint(
                        rva: insectBattlePlayerDamageDifferenceRVA,
                        expectedBytes: insectBattlePlayerDamageDifferenceExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW1(superDamageValue),
                        note: "InsectBattle player damage advantage -> enemy super damage"
                    ),
                    StaticPatchPoint(
                        rva: insectBattlePlayerCounterDamageDifferenceRVA,
                        expectedBytes: insectBattlePlayerDamageDifferenceExpectedBytes,
                        patchBytes: try! Arm64ReturnCode.moveInt32ToW1(superDamageValue),
                        note: "InsectBattle player counter advantage -> enemy super damage"
                    ),
                    StaticPatchPoint(
                        rva: rpgDealDamageEnemyOnlyHookRVA,
                        expectedBytes: rpgDealDamageEnemyOnlyHookExpectedBytes,
                        patchBytes: [],
                        note: "RPG DealDamage target Enemy -> super damage, non-Enemy unchanged",
                        trampoline: StaticPatchTrampoline(
                            kind: .rpgDamagePolicySuperDamage,
                            value: superDamageValue,
                            resumeRVA: rpgDealDamageEnemyOnlyResumeRVA,
                            nullHandlerRVA: rpgDealDamageNullHandlerRVA,
                            helperRVA: battleUtilsIsEnemyRVA,
                            codeCaveRVA: rpgDamageTrampolineCodeCaveRVA,
                            codeCaveExpectedBytes: rpgDamageTrampolineCodeCaveExpectedBytes
                        )
                    ),
                    StaticPatchPoint(
                        rva: legacyAttackDataGetBuffedDamageRVA,
                        expectedBytes: legacyAttackDataGetBuffedDamageExpectedBytes,
                        patchBytes: legacyAttackDataGetBuffedDamageExpectedBytes,
                        note: "Restore retired shared AttackData damage patch from older trainer builds",
                        acceptsCompatibleAppliedPatch: true
                    ),
                    StaticPatchPoint(
                        rva: legacyDamagerSetDamageValueRVA,
                        expectedBytes: legacyDamagerSetDamageValueExpectedBytes,
                        patchBytes: legacyDamagerSetDamageValueExpectedBytes,
                        note: "Restore retired shared Damager damage setter patch from older trainer builds",
                        acceptsCompatibleAppliedPatch: true
                    ),
                    StaticPatchPoint(
                        rva: legacyExtensionIDamagerGetBuffedDamageRVA,
                        expectedBytes: legacyExtensionIDamagerGetBuffedDamageExpectedBytes,
                        patchBytes: legacyExtensionIDamagerGetBuffedDamageExpectedBytes,
                        note: "Restore retired shared ExtensionIDamager damage patch from older trainer builds",
                        acceptsCompatibleAppliedPatch: true
                    ),
                    StaticPatchPoint(
                        rva: legacyJungleRPGDamageResultScaleRVA,
                        expectedBytes: legacyJungleRPGDamageResultScaleExpectedBytes,
                        patchBytes: legacyJungleRPGDamageResultScaleExpectedBytes,
                        note: "Restore retired shared Jungle RPG damage scale patch from older trainer builds",
                        acceptsCompatibleAppliedPatch: true
                    )
                ]
            ),
            StaticGamePatch(
                id: "stamina",
                title: "无限体力",
                points: [
                    StaticPatchPoint(
                        rva: daveMoveValueGetStaminaRVA,
                        expectedBytes: [0x00, 0x40, 0x40, 0xBD, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: try! Arm64ReturnCode.returnImmediateFloat32(1.0),
                        note: "DaveMoveValue_get_stamina -> 1.0"
                    ),
                    StaticPatchPoint(
                        rva: daveMoveValueSetStaminaRVA,
                        expectedBytes: [0x00, 0x40, 0x00, 0xBD, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: arm64Return,
                        note: "DaveMoveValue_set_stamina -> ret"
                    ),
                    StaticPatchPoint(
                        rva: daveMoveValueGetIsStaminaZeroPenaltyRVA,
                        expectedBytes: [
                            0x00, 0x60, 0x40, 0xBD,
                            0x08, 0x20, 0x20, 0x1E,
                            0xE0, 0xD7, 0x9F, 0x1A,
                            0xC0, 0x03, 0x5F, 0xD6
                        ],
                        patchBytes: arm64ReturnFalseBool,
                        note: "DaveMoveValue_get_IsStaminaZeroPenalty -> false"
                    ),
                    StaticPatchPoint(
                        rva: daveMoveValueConsumeStaminaArithmeticRVA,
                        expectedBytes: arm64FsubS0S1S0,
                        patchBytes: arm64FmovS0S1,
                        note: "DaveMoveValue_Update stamina drain -> keep current stamina"
                    )
                ]
            ),
            StaticGamePatch(
                id: "wasabi",
                title: "无限芥末",
                points: [
                    StaticPatchPoint(
                        rva: operationDataNowWasabiCountRVA,
                        expectedBytes: operationDataNowWasabiCountExpectedBytes,
                        patchBytes: arm64Return999Int32,
                        note: "OperationData_NowWasabiCount -> 999"
                    ),
                    StaticPatchPoint(
                        rva: operationDataIsAvailableWasabiRVA,
                        expectedBytes: [
                            0xF4, 0x4F, 0xBE, 0xA9,
                            0xFD, 0x7B, 0x01, 0xA9
                        ],
                        patchBytes: arm64ReturnTrueBool,
                        note: "OperationData_IsAvailableWasabi -> true"
                    ),
                    StaticPatchPoint(
                        rva: operationDataUsingWasabiInCookingRVA,
                        expectedBytes: [
                            0xF6, 0x57, 0xBD, 0xA9,
                            0xF4, 0x4F, 0x01, 0xA9
                        ],
                        patchBytes: arm64Return,
                        note: "OperationData_UsingWasabiInCooking -> ret"
                    ),
                    StaticPatchPoint(
                        rva: wasabiGratersGetNowCountRVA,
                        expectedBytes: [0x00, 0x10, 0x40, 0xB9, 0xC0, 0x03, 0x5F, 0xD6],
                        patchBytes: arm64Return999Int32,
                        note: "WasabiGratersData_get_NowCount -> 999"
                    ),
                    StaticPatchPoint(
                        rva: wasabiGratersRemainRateRVA,
                        expectedBytes: [
                            0xF6, 0x57, 0xBD, 0xA9,
                            0xF4, 0x4F, 0x01, 0xA9
                        ],
                        patchBytes: try! Arm64ReturnCode.returnImmediateFloat32(1.0),
                        note: "WasabiGratersData_RemainWasabiRate -> 1.0"
                    )
                ]
            )
        ]
    }

    public static func makeValuePatch(id: String, value: Int64) throws -> StaticGamePatch {
        switch id {
        case "gold":
            return try makeGoldPatch(value: value)
        case "bei":
            return try makeBeiPatch(value: value)
        case "jungleGold":
            return try makeJungleGoldPatch(value: value)
        case "materials":
            return try makeMaterialsPatch(value: value)
        case "fishIngredients", "vegetableIngredients", "seasoningIngredients", "upgradeMaterials":
            return try makeIngredientsCategoryPatch(id: id, value: value)
        case "artisan":
            return try makeArtisanPatch(value: value)
        default:
            throw TrainerError.invalidInput("未知固定数值 patch：\(id)")
        }
    }

    public static func makeValuePatch(id: String, valueText: String) throws -> StaticGamePatch {
        switch id {
        case "gold", "bei", "jungleGold", "materials", "fishIngredients", "vegetableIngredients", "seasoningIngredients", "upgradeMaterials", "artisan":
            return try makeValuePatch(id: id, value: parseNonNegativeInt64(valueText))
        case "swimSpeed":
            return try makeSwimSpeedPatch(value: parsePositiveFloat(valueText))
        default:
            throw TrainerError.invalidInput("未知固定数值 patch：\(id)")
        }
    }

    private static func parseNonNegativeInt64(_ text: String) throws -> Int64 {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int64(trimmed), value >= 0 else {
            throw TrainerError.invalidInput("固定数值 patch 只接受非负整数：\(text)")
        }
        return value
    }

    private static func parsePositiveFloat(_ text: String) throws -> Float {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Float(trimmed), value.isFinite, value > 0 else {
            throw TrainerError.invalidInput("倍率 patch 只接受正的有限数字：\(text)")
        }
        return value
    }

    private static func makeSwimSpeedPatch(value: Float) throws -> StaticGamePatch {
        let patchBytes = Arm64ReturnCode.returnFloat32(value)
        let immediateS0PatchBytes = try Arm64ReturnCode.moveImmediateFloat32ToS0(value)
        let immediateS2PatchBytes = try Arm64ReturnCode.moveImmediateFloat32ToS2(value)
        let immediateS9PatchBytes = try Arm64ReturnCode.moveImmediateFloat32ToS9(value)
        let farmPatchBytes = try Arm64ReturnCode.loadFloat32LiteralToS0AndBranch(
            value: value,
            patchRVA: farmPlayerPresenterMoveSpeedMultiplierRVA,
            literalRVA: farmPlayerPresenterMoveSpeedLiteralRVA,
            continueRVA: farmPlayerPresenterMoveSpeedContinueRVA
        )
        let jVillageStateMachinePatchBytes = try Arm64ReturnCode.loadFloat32LiteralToS0ReturnAndDisableSetter(
            value: value,
            patchRVA: jVillageStateMachineGetCustomizedSpeedRateRVA,
            literalRVA: jVillageStateMachineCustomizedSpeedLiteralRVA
        )
        return StaticGamePatch(
            id: "swimSpeed",
            title: "设置玩家移动速度",
            points: [
                StaticPatchPoint(
                    rva: playerMovePropertyGetMoveSpeedRVA,
                    expectedBytes: playerMovePropertyGetMoveSpeedExpectedBytes,
                    patchBytes: patchBytes,
                    note: "PlayerMoveProperty_GetMoveSpeed -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: playerCharacterDetermineMoveSpeedRVA,
                    expectedBytes: playerCharacterDetermineMoveSpeedExpectedBytes,
                    patchBytes: patchBytes,
                    note: "PlayerCharacter_DetermineMoveSpeed -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: daveMoveValueGetSpeedMultiplierRVA,
                    expectedBytes: daveMoveValueGetSpeedMultiplierExpectedBytes,
                    patchBytes: patchBytes,
                    note: "DaveMoveValue_get_speedMultiplier -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: farmPlayerPresenterMoveSpeedMultiplierRVA,
                    expectedBytes: farmPlayerPresenterMoveSpeedMultiplierExpectedBytes,
                    patchBytes: farmPatchBytes,
                    note: "FarmPlayerPresenter_ProcessMove speed multiplier -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: fishFarmPlayerViewGetDaveSpeedRVA,
                    expectedBytes: fishFarmPlayerViewGetDaveSpeedExpectedBytes,
                    patchBytes: patchBytes,
                    note: "FishFarmPlayerView_get_DaveSpeed -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: fishFarmPlayerPresenterDashSpeedRVA,
                    expectedBytes: fishFarmPlayerPresenterDashSpeedExpectedBytes,
                    patchBytes: immediateS2PatchBytes,
                    note: "FishFarmPlayerPresenter_ProcessMove dash speed -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: fishFarmPlayerPresenterWalkSpeedRVA,
                    expectedBytes: fishFarmPlayerPresenterWalkSpeedExpectedBytes,
                    patchBytes: immediateS2PatchBytes,
                    note: "FishFarmPlayerPresenter_ProcessMove walk speed -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: jVillageStateMachineGetCustomizedSpeedRateRVA,
                    expectedBytes: jVillageStateMachineCustomizedSpeedExpectedBytes,
                    patchBytes: jVillageStateMachinePatchBytes,
                    note: "JVillageStateMachine speed getter/setter -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: jVillageLobbyMoveCustomizedSpeedRVA,
                    expectedBytes: jVillageLobbyMoveCustomizedSpeedExpectedBytes,
                    patchBytes: immediateS0PatchBytes,
                    note: "JVillageLobbyMove speed rate -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: baconStoryPlayerMoveSpeedRVA,
                    expectedBytes: baconStoryPlayerMoveSpeedExpectedBytes,
                    patchBytes: immediateS9PatchBytes,
                    note: "BaconStoryPlayerControllerBacon_OnMove speed -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: baconStoryChasingLaneGetMoveSpeedRVA,
                    expectedBytes: baconStoryChasingLaneGetMoveSpeedExpectedBytes,
                    patchBytes: try Arm64ReturnCode.returnImmediateFloat32(value),
                    note: "BaconStoryChasingLane_get_MoveSpeed -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: legacyFishSpeedEnterMultiplierRVA,
                    expectedBytes: legacyFishSpeedMultiplierExpectedBytes,
                    patchBytes: legacyFishSpeedMultiplierExpectedBytes,
                    note: "Restore legacy fish-speed patch point from older trainer builds",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: legacyFishSpeedUpdateMultiplierRVA,
                    expectedBytes: legacyFishSpeedMultiplierExpectedBytes,
                    patchBytes: legacyFishSpeedMultiplierExpectedBytes,
                    note: "Restore legacy fish-speed update patch point from older trainer builds",
                    acceptsCompatibleAppliedPatch: true
                )
            ]
        )
    }

    private static func makeGoldPatch(value: Int64) throws -> StaticGamePatch {
        let intPatchBytes = try Arm64ReturnCode.returnInt32(value)
        return StaticGamePatch(
            id: "gold",
            title: "设置金币",
            points: [
                StaticPatchPoint(
                    rva: lobbyGoldGetCurrentZoneGoldRVA,
                    expectedBytes: [
                        0xFF, 0xC3, 0x01, 0xD1,
                        0xF6, 0x57, 0x04, 0xA9,
                        0xF4, 0x4F, 0x05, 0xA9
                    ],
                    patchBytes: intPatchBytes,
                    note: "LobbyGoldInfoPanelUI_GetCurrentZoneGold -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: globalGetTotalGoldRVA,
                    expectedBytes: [
                        0x09, 0x10, 0x40, 0xF9,
                        0xC9, 0x00, 0x00, 0xB4,
                        0x20, 0x05, 0xC0, 0x3D
                    ],
                    patchBytes: try Arm64ReturnCode.returnObscuredInt32(
                        value,
                        patchRVA: globalGetTotalGoldRVA,
                        implicitIntRVA: obscuredIntFromIntRVA
                    ),
                    note: "Global_get_totalGold -> ObscuredInt input value",
                    acceptsLegacyIntReturnPatch: true,
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: playerInfoSaveGetGoldRVA,
                    expectedBytes: [
                        0x00, 0x04, 0xC0, 0x3D,
                        0x00, 0x01, 0x80, 0x3D,
                        0x09, 0x20, 0x40, 0xB9
                    ],
                    patchBytes: try Arm64ReturnCode.returnObscuredInt32(
                        value,
                        patchRVA: playerInfoSaveGetGoldRVA,
                        implicitIntRVA: obscuredIntFromIntRVA
                    ),
                    note: "PlayerInfoSave_get_gold -> ObscuredInt input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: playerInfoSaveSetGoldRVA,
                    expectedBytes: playerInfoSaveSetGoldExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeObscuredInt32PropertyAndSave(
                        ObscuredInt32PropertySavePatchRequest(
                            value: value,
                            patchRVA: playerInfoSaveSetGoldRVA,
                            fieldOffset: playerInfoSaveGoldFieldOffset,
                            implicitIntRVA: obscuredIntFromIntRVA,
                            getGameSaveRVA: saveSystemGetGameSaveRVA,
                            updatePlayerSaveRVA: saveDataUpdatePlayerSaveRVA,
                            raiseNullReferenceRVA: raiseNullReferenceRVA
                        )
                    ),
                    note: "PlayerInfoSave_set_gold -> write ObscuredInt input value and save",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: globalDecreaseTotalGoldRVA,
                    expectedBytes: [
                        0xFF, 0x03, 0x02, 0xD1,
                        0xF8, 0x5F, 0x04, 0xA9
                    ],
                    patchBytes: arm64Return,
                    note: "Global_DecreaseTotalGold -> ret"
                ),
                StaticPatchPoint(
                    rva: weaponInfoPanelPayGoldRVA,
                    expectedBytes: [
                        0xFF, 0x83, 0x01, 0xD1,
                        0xF6, 0x57, 0x03, 0xA9
                    ],
                    patchBytes: arm64Return,
                    note: "WeaponInfoPanel_PayGold -> ret"
                ),
                StaticPatchPoint(
                    rva: jungleCommonIsPayableRVA,
                    expectedBytes: [
                        0xF8, 0x5F, 0xBC, 0xA9,
                        0xF6, 0x57, 0x01, 0xA9
                    ],
                    patchBytes: arm64ReturnTrueBool,
                    note: "JungleCommonDefine_IsPayable -> true"
                ),
                StaticPatchPoint(
                    rva: jungleCommonGetPayableResultRVA,
                    expectedBytes: [
                        0xFA, 0x67, 0xBB, 0xA9,
                        0xF8, 0x5F, 0x01, 0xA9
                    ],
                    patchBytes: try Arm64ReturnCode.returnInt32(0),
                    note: "JungleCommonDefine_GetPayableResult -> success"
                ),
                StaticPatchPoint(
                    rva: jungleCommonPayPlayerResourceListRVA,
                    expectedBytes: [
                        0xFF, 0xC3, 0x01, 0xD1,
                        0xFA, 0x67, 0x02, 0xA9
                    ],
                    patchBytes: arm64ReturnTrueBool,
                    note: "JungleCommonDefine_PayPlayerResource(list) -> true without spending"
                ),
                StaticPatchPoint(
                    rva: jungleCommonPayPlayerResourceSingleRVA,
                    expectedBytes: [
                        0xF6, 0x57, 0xBD, 0xA9,
                        0xF4, 0x4F, 0x01, 0xA9
                    ],
                    patchBytes: arm64ReturnTrueBool,
                    note: "JungleCommonDefine_PayPlayerResource(single) -> true without spending"
                )
            ]
        )
    }

    private static func makeBeiPatch(value: Int64) throws -> StaticGamePatch {
        StaticGamePatch(
            id: "bei",
            title: "设置鲛人族贝壳",
            points: [
                StaticPatchPoint(
                    rva: playerInfoSaveGetBeiRVA,
                    expectedBytes: playerInfoSaveGetBeiExpectedBytes,
                    patchBytes: try Arm64ReturnCode.returnObscuredInt32(
                        value,
                        patchRVA: playerInfoSaveGetBeiRVA,
                        implicitIntRVA: obscuredIntFromIntRVA
                    ),
                    note: "PlayerInfoSave_get_bei -> ObscuredInt input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: playerInfoSaveSetBeiRVA,
                    expectedBytes: playerInfoSaveSetBeiExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeObscuredInt32PropertyAndSave(
                        ObscuredInt32PropertySavePatchRequest(
                            value: value,
                            patchRVA: playerInfoSaveSetBeiRVA,
                            fieldOffset: playerInfoSaveBeiFieldOffset,
                            implicitIntRVA: obscuredIntFromIntRVA,
                            getGameSaveRVA: saveSystemGetGameSaveRVA,
                            updatePlayerSaveRVA: saveDataUpdatePlayerSaveRVA,
                            raiseNullReferenceRVA: raiseNullReferenceRVA
                        )
                    ),
                    note: "PlayerInfoSave_set_bei -> write ObscuredInt input value and save",
                    acceptsCompatibleAppliedPatch: true
                )
            ]
        )
    }

    private static func makeJungleGoldPatch(value: Int64) throws -> StaticGamePatch {
        StaticGamePatch(
            id: "jungleGold",
            title: "设置丛林货币",
            points: [
                StaticPatchPoint(
                    rva: saveDataJungleGetJungleGoldRVA,
                    expectedBytes: saveDataJungleGetJungleGoldExpectedBytes,
                    patchBytes: try Arm64ReturnCode.returnInt32(value),
                    note: "SaveDataJungle_GetJungleGold -> input value",
                    acceptsCompatibleAppliedPatch: true
                )
            ]
        )
    }

    private static func makeMaterialsPatch(value: Int64) throws -> StaticGamePatch {
        let patchBytes = try Arm64ReturnCode.returnInt32(value)
        return StaticGamePatch(
            id: "materials",
            title: "设置全部食材/素材数量（全局）",
            points: [
                StaticPatchPoint(
                    rva: ingredientsDataTotalCountRVA,
                    expectedBytes: ingredientsDataTotalCountFullExpectedBytes,
                    patchBytes: patchBytes,
                    note: "IngredientsData_TotalCount -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataGetCountRVA,
                    expectedBytes: ingredientsDataGetCountExpectedBytes,
                    patchBytes: patchBytes,
                    note: "IngredientsData_GetCount -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsStorageGetCountRVA,
                    expectedBytes: [0xFF, 0x03, 0x01, 0xD1, 0xF6, 0x57, 0x01, 0xA9, 0xF4, 0x4F, 0x02, 0xA9],
                    patchBytes: patchBytes,
                    note: "IngredientsStorage_GetIngredientsCount -> input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataSetCountRVA,
                    expectedBytes: ingredientsDataSetCountExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeIngredientsSetCount(
                        IngredientsSetCountPatchRequest(
                            value: value,
                            patchRVA: ingredientsDataSetCountRVA,
                            raiseNullReferenceRVA: raiseNullReferenceRVA,
                            raiseIndexOutOfRangeRVA: raiseIndexOutOfRangeRVA
                        )
                    ),
                    note: "IngredientsData_SetCount -> store input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataIsEnoughRVA,
                    expectedBytes: ingredientsDataIsEnoughExpectedBytes,
                    patchBytes: arm64ReturnTrueBool,
                    note: "IngredientsData_IsEnough -> true",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataIsEnoughTotalRVA,
                    expectedBytes: ingredientsDataIsEnoughTotalExpectedBytes,
                    patchBytes: arm64ReturnTrueBool,
                    note: "IngredientsData_IsEnoughTotal -> true",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsStorageGetCountCategoryPatchRVA,
                    expectedBytes: ingredientsStorageGetCountCategoryExpectedBytes,
                    patchBytes: ingredientsStorageGetCountCategoryExpectedBytes,
                    note: "IngredientsStorage_GetIngredientsCount category site -> restore original",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: cookingConsumeIngredientsRVA,
                    expectedBytes: [
                        0xFF, 0xC3, 0x01, 0xD1,
                        0xFA, 0x67, 0x02, 0xA9
                    ],
                    patchBytes: arm64Return,
                    note: "CookingSystem_ConsumeIngredients -> ret"
                ),
                StaticPatchPoint(
                    rva: cookingConsumeIngredientsOverloadRVA,
                    expectedBytes: [
                        0xFF, 0x43, 0x02, 0xD1,
                        0xFC, 0x6F, 0x03, 0xA9
                    ],
                    patchBytes: arm64Return,
                    note: "CookingSystem_ConsumeIngredients(overload) -> ret"
                )
            ]
        )
    }

    private struct IngredientsCategoryPatchDefinition {
        let title: String
        let matcher: IngredientsTypeMatcher
    }

    private static func makeIngredientsCategoryPatch(id: String, value: Int64) throws -> StaticGamePatch {
        let definition = try ingredientsCategoryPatchDefinition(id: id)
        let totalRequest = IngredientsCategoryPatchRequest(
            value: value,
            matcher: definition.matcher,
            patchRVA: ingredientsDataTotalCountRVA
        )
        let getCountRequest = IngredientsCategoryPatchRequest(
            value: value,
            matcher: definition.matcher,
            patchRVA: ingredientsDataGetCountRVA
        )
        let setCountRequest = IngredientsCategoryPatchRequest(
            value: value,
            matcher: definition.matcher,
            patchRVA: ingredientsDataSetCountRVA
        )
        let isEnoughRequest = IngredientsCategoryPatchRequest(
            value: value,
            matcher: definition.matcher,
            patchRVA: ingredientsDataIsEnoughRVA
        )
        let isEnoughTotalRequest = IngredientsCategoryPatchRequest(
            value: value,
            matcher: definition.matcher,
            patchRVA: ingredientsDataIsEnoughTotalRVA
        )
        let storageCountRequest = IngredientsCategoryPatchRequest(
            value: value,
            matcher: definition.matcher,
            patchRVA: ingredientsStorageGetCountCategoryPatchRVA
        )

        return StaticGamePatch(
            id: id,
            title: definition.title,
            points: [
                StaticPatchPoint(
                    rva: ingredientsDataTotalCountRVA,
                    expectedBytes: ingredientsDataTotalCountExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeIngredientsCategoryTotalCount(totalRequest),
                    note: "IngredientsData_TotalCount -> category input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataGetCountRVA,
                    expectedBytes: ingredientsDataGetCountExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeIngredientsCategoryGetCount(getCountRequest),
                    note: "IngredientsData_GetCount -> category input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataSetCountRVA,
                    expectedBytes: ingredientsDataSetCountExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeIngredientsCategorySetCount(setCountRequest),
                    note: "IngredientsData_SetCount -> category input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataIsEnoughRVA,
                    expectedBytes: ingredientsDataIsEnoughExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeIngredientsCategoryIsEnough(isEnoughRequest),
                    note: "IngredientsData_IsEnough -> category true",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsDataIsEnoughTotalRVA,
                    expectedBytes: ingredientsDataIsEnoughTotalExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeIngredientsCategoryIsEnoughTotal(isEnoughTotalRequest),
                    note: "IngredientsData_IsEnoughTotal -> category true",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: ingredientsStorageGetCountCategoryPatchRVA,
                    expectedBytes: ingredientsStorageGetCountCategoryExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeIngredientsStorageCategoryGetCount(storageCountRequest),
                    note: "IngredientsStorage_GetIngredientsCount -> category input value",
                    acceptsCompatibleAppliedPatch: true
                )
            ]
        )
    }

    private static func ingredientsCategoryPatchDefinition(id: String) throws -> IngredientsCategoryPatchDefinition {
        switch id {
        case "fishIngredients":
            return IngredientsCategoryPatchDefinition(title: "按鱼肉食材分类设置", matcher: .lessThan(2))
        case "vegetableIngredients":
            return IngredientsCategoryPatchDefinition(title: "按蔬菜食材分类设置", matcher: .equals(2))
        case "seasoningIngredients":
            return IngredientsCategoryPatchDefinition(title: "按调味品分类设置", matcher: .equals(3))
        case "upgradeMaterials":
            return IngredientsCategoryPatchDefinition(title: "按强化素材分类设置", matcher: .equals(4))
        default:
            throw TrainerError.invalidInput("未知分类食材 patch：\(id)")
        }
    }

    private static func makeArtisanPatch(value: Int64) throws -> StaticGamePatch {
        return StaticGamePatch(
            id: "artisan",
            title: "设置匠人火焰",
            points: [
                StaticPatchPoint(
                    rva: playerInfoSaveGetChefFlameRVA,
                    expectedBytes: [
                        0x00, 0x80, 0xC3, 0x3C,
                        0x00, 0x01, 0x80, 0x3D,
                        0x09, 0x48, 0x40, 0xB9
                    ],
                    patchBytes: try Arm64ReturnCode.returnObscuredInt32(
                        value,
                        patchRVA: playerInfoSaveGetChefFlameRVA,
                        implicitIntRVA: obscuredIntFromIntRVA
                    ),
                    note: "PlayerInfoSave_get_ChefFlame -> ObscuredInt input value",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: playerInfoSaveSetChefFlameRVA,
                    expectedBytes: playerInfoSaveSetChefFlameExpectedBytes,
                    patchBytes: try Arm64ReturnCode.writeObscuredInt32PropertyAndSave(
                        ObscuredInt32PropertySavePatchRequest(
                            value: value,
                            patchRVA: playerInfoSaveSetChefFlameRVA,
                            fieldOffset: playerInfoSaveChefFlameFieldOffset,
                            implicitIntRVA: obscuredIntFromIntRVA,
                            getGameSaveRVA: saveSystemGetGameSaveRVA,
                            updatePlayerSaveRVA: saveDataUpdatePlayerSaveRVA,
                            raiseNullReferenceRVA: raiseNullReferenceRVA
                        )
                    ),
                    note: "PlayerInfoSave_set_ChefFlame -> write ObscuredInt input value and save",
                    acceptsCompatibleAppliedPatch: true
                ),
                StaticPatchPoint(
                    rva: saveDataJungleGetChiefFlameRVA,
                    expectedBytes: [
                        0x08, 0x68, 0x40, 0xF9,
                        0x68, 0x00, 0x00, 0xB4
                    ],
                    patchBytes: try Arm64ReturnCode.returnInt32(value),
                    note: "SaveDataJungle_GetJungleChiefFlame -> input value",
                    acceptsCompatibleAppliedPatch: true
                )
            ]
        )
    }

    private static let arm64Return: [UInt8] = [0xC0, 0x03, 0x5F, 0xD6]
    private static let arm64ReturnFalseBool: [UInt8] = [0x00, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6]
    private static let arm64ReturnTrueBool: [UInt8] = [0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6]
    private static let arm64Return999Int32: [UInt8] = [0xE0, 0x7C, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6]
    private static let arm64FsubS0S1S0: [UInt8] = [0x20, 0x38, 0x20, 0x1E]
    private static let arm64FmovS0S1: [UInt8] = [0x20, 0x40, 0x20, 0x1E]
    private static let arm64Nop: [UInt8] = [0x1F, 0x20, 0x03, 0xD5]
    private static let rpgDamageTrampolineCodeCaveExpectedBytes = Array(repeating: UInt8(0), count: 72)
    private static var divingTargetDamagePatchPoints: [StaticPatchPoint] {
        [
            StaticPatchPoint(
                rva: pirateRopeDamageRVA,
                expectedBytes: pirateRopeDamageExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "PirateRopeChainController target damage -> super damage"
            ),
            StaticPatchPoint(
                rva: pirateRopePopupDamageRVA,
                expectedBytes: pirateRopePopupDamageExpectedBytes,
                patchBytes: targetDamageW20Window16PatchBytes,
                note: "PirateRopeChainController popup damage -> super damage"
            ),
            StaticPatchPoint(
                rva: johnWatsonDamageRVA,
                expectedBytes: johnWatsonDamageExpectedBytes,
                patchBytes: targetDamageW20Window16PatchBytes,
                note: "NPCPlayer_JohnWatson target damage -> super damage"
            ),
            StaticPatchPoint(
                rva: wreckDamageRVA,
                expectedBytes: wreckDamageExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "WreckController target damage -> super damage"
            ),
            StaticPatchPoint(
                rva: fishAISystemDamageRVA,
                expectedBytes: fishAISystemDamageExpectedBytes,
                patchBytes: targetDamageW22Window16PatchBytes,
                note: "FishAISystem target damage -> super damage for knife and normal weapons"
            ),
            StaticPatchPoint(
                rva: mxmtoonDamageGateRVA,
                expectedBytes: mxmtoonDamageGateExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "NPC_Mxmtoon damage gate -> super damage"
            ),
            StaticPatchPoint(
                rva: pirateBaseDamageGateRVA,
                expectedBytes: pirateBaseDamageGateExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "NPCPlayer_PirateBase damage gate -> super damage"
            ),
            StaticPatchPoint(
                rva: pirateBaseDamageRVA,
                expectedBytes: pirateBaseDamageExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "NPCPlayer_PirateBase target damage -> super damage"
            ),
            StaticPatchPoint(
                rva: npcPlayerCharacterDamageRVA,
                expectedBytes: npcPlayerCharacterDamageExpectedBytes,
                patchBytes: targetDamageW20Window16PatchBytes,
                note: "NPCPlayerCharacter target damage -> super damage"
            ),
            StaticPatchPoint(
                rva: damageableEventDamageRVA,
                expectedBytes: damageableEventDamageExpectedBytes,
                patchBytes: targetDamageW0Window8PatchBytes,
                note: "Damageable_TakeDamage event damage -> super damage"
            ),
            StaticPatchPoint(
                rva: damageableLastDamageRVA,
                expectedBytes: damageableLastDamageExpectedBytes,
                patchBytes: targetDamageW0Window8PatchBytes,
                note: "Damageable_TakeDamage last damage -> super damage"
            ),
            StaticPatchPoint(
                rva: rockBlockerDamageRVA,
                expectedBytes: rockBlockerDamageExpectedBytes,
                patchBytes: targetDamageW1Window16PatchBytes,
                note: "RockBlocker target damage -> super damage"
            ),
            StaticPatchPoint(
                rva: giantSquidDamageGateRVA,
                expectedBytes: giantSquidDamageGateExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "BossGiantSquid damage gate -> super damage"
            ),
            StaticPatchPoint(
                rva: wolffishDamageGateRVA,
                expectedBytes: wolffishDamageGateExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "BossWolffish damage gate -> super damage"
            ),
            StaticPatchPoint(
                rva: wolffishDamageScaleRVA,
                expectedBytes: wolffishDamageScaleExpectedBytes,
                patchBytes: targetDamageW0Window12PatchBytes,
                note: "BossWolffish scaled damage -> super damage"
            ),
            StaticPatchPoint(
                rva: wolffishFinalDamageRVA,
                expectedBytes: wolffishFinalDamageExpectedBytes,
                patchBytes: targetDamageW20Window16PatchBytes,
                note: "BossWolffish final damage -> super damage"
            )
        ]
    }

    private static var harpoonProjectileCollisionSuperDamagePatchBytes: [UInt8] {
        (try! Arm64ReturnCode.moveInt32ToW23(superDamageValue)) + arm64Nop
    }
    private static var targetDamageW0Window8PatchBytes: [UInt8] {
        try! Arm64ReturnCode.moveInt32ToW0(superDamageValue)
    }
    private static var targetDamageW0Window12PatchBytes: [UInt8] {
        (try! Arm64ReturnCode.moveInt32ToW0(superDamageValue)) + arm64Nop
    }
    private static var targetDamageW1Window16PatchBytes: [UInt8] {
        (try! Arm64ReturnCode.moveInt32ToW1(superDamageValue)) + arm64Nop + arm64Nop
    }
    private static var targetDamageW20Window16PatchBytes: [UInt8] {
        (try! Arm64ReturnCode.moveInt32ToW20(superDamageValue)) + arm64Nop + arm64Nop
    }
    private static var targetDamageW22Window16PatchBytes: [UInt8] {
        (try! Arm64ReturnCode.moveInt32ToW22(superDamageValue)) + arm64Nop + arm64Nop
    }
    private static let playerCharacterOnTakeDamageExpectedBytes: [UInt8] = [
        0xFF, 0x03, 0x07, 0xD1,
        0xED, 0x33, 0x14, 0x6D
    ]
    private static let playerCharacterGetIsImmuneDamageExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9,
        0xF4, 0x4F, 0x01, 0xA9
    ]
    private static let playerCharacterIsDroneAvailableExpectedBytes: [UInt8] = [
        0x08, 0xD0, 0x41, 0xB9,
        0x1F, 0x01, 0x00, 0x71
    ]
    private static let playerBreathHandlerChangeOxygenValueExpectedBytes: [UInt8] = [
        0xFF, 0x03, 0x03, 0xD1,
        0xE9, 0x23, 0x08, 0x6D
    ]
    private static let playerBreathHandlerSetHazardHPDamageExpectedBytes: [UInt8] = [
        0x00, 0x80, 0x00, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let playerBreathHandlerGetIsOxygenDepletingExpectedBytes: [UInt8] = [
        0x08, 0xB0, 0x42, 0x39,
        0x1F, 0x05, 0x00, 0x71
    ]
    private static let playerBreathHandlerGetCheatNoDieExpectedBytes: [UInt8] = [
        0x00, 0x64, 0x43, 0x39,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let playerBreathHandlerGetImmuneDamageExpectedBytes: [UInt8] = [
        0x00, 0x6C, 0x43, 0x39,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let primaryWeaponDecreaseRemainCountExpectedBytes: [UInt8] = [
        0xFF, 0x43, 0x02, 0xD1,
        0xF6, 0x57, 0x06, 0xA9
    ]
    private static let secondaryWeaponDecreaseExpectedBytes: [UInt8] = [
        0xFF, 0x83, 0x02, 0xD1,
        0xE9, 0x23, 0x06, 0x6D
    ]
    private static let obscuredIntCanUseExpectedBytes: [UInt8] = [
        0xFF, 0xC3, 0x01, 0xD1,
        0xF6, 0x57, 0x04, 0xA9
    ]
    private static let secondaryWeaponGetRemainedFireCountExpectedBytes: [UInt8] = [
        0xFF, 0xC3, 0x01, 0xD1,
        0xF6, 0x57, 0x04, 0xA9,
        0xF4, 0x4F, 0x05, 0xA9,
        0xFD, 0x7B, 0x06, 0xA9
    ]
    private static let ammoHandlerUseInstanceSubHelperExpectedBytes: [UInt8] = [
        0xF8, 0x5F, 0xBC, 0xA9,
        0xF6, 0x57, 0x01, 0xA9
    ]
    private static let gunWeaponHandlerDecreaseBulletExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9,
        0xF4, 0x4F, 0x01, 0xA9
    ]
    private static let gunWeaponHandlerFireWeaponAmmoGateExpectedBytes: [UInt8] = [
        0x68, 0x7E, 0x40, 0xB9
    ]
    private static let gunWeaponHandlerReloadBulletFinalCountExpectedBytes: [UInt8] = [
        0x28, 0xB1, 0x88, 0x1A
    ]
    private static let gunWeaponHandlerForceSetBulletCountValueMoveExpectedBytes: [UInt8] = [
        0xF4, 0x03, 0x01, 0xAA
    ]
    private static let gunWeaponHandlerIsAvailableExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9,
        0xF4, 0x4F, 0x01, 0xA9
    ]
    private static let gunWeaponHandlerGetAmmoExpectedBytes: [UInt8] = [
        0x00, 0x7C, 0x40, 0xB9,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let weaponManagerSetPrimaryWeaponRemainCountValueMoveExpectedBytes: [UInt8] = [
        0xF4, 0x03, 0x01, 0xAA
    ]
    private static let actionSwitchUISetBulletCountValueMoveExpectedBytes: [UInt8] = [
        0xF5, 0x03, 0x01, 0xAA
    ]
    private static let actionSwitchUISetSubHelperDataCountMoveExpectedBytes: [UInt8] = [
        0xF6, 0x03, 0x02, 0xAA
    ]
    private static let subEquipmentGetTrapCountExpectedBytes: [UInt8] = [
        0x00, 0x5C, 0x40, 0xB9,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let subEquipmentSetTrapCountExpectedBytes: [UInt8] = [
        0x01, 0x5C, 0x00, 0xB9,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let playerCharacterAvailableCrabTrapCountExpectedBytes: [UInt8] = [
        0x00, 0xD4, 0x41, 0xB9,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let playerCharacterSetAvailableCrabTrapCountExpectedBytes: [UInt8] = [
        0x01, 0xD4, 0x01, 0xB9,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let playerCharacterIsCrabTrapAvailableExpectedBytes: [UInt8] = [
        0x08, 0xD4, 0x41, 0xB9,
        0x1F, 0x01, 0x00, 0x71
    ]
    private static let savePlayerDataAvailableCrabTrapExpectedBytes: [UInt8] = [
        0x00, 0x9C, 0x40, 0xB9,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let savePlayerDataSetAvailableCrabTrapExpectedBytes: [UInt8] = [
        0x01, 0x9C, 0x00, 0xB9,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let playerInstalledCargoBoxDataGetWeightExpectedBytes: [UInt8] = [
        0x00, 0x48, 0x40, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let playerInstalledCargoBoxDataSetWeightExpectedBytes: [UInt8] = [
        0x00, 0x48, 0x00, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let cargoBoxGetMaximumWeightExpectedBytes: [UInt8] = [
        0x00, 0x38, 0x40, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let lootBoxSetWeightExpectedBytes: [UInt8] = [
        0x00, 0x2C, 0x00, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let lootBoxGetWeightExpectedBytes: [UInt8] = [
        0x00, 0x2C, 0x40, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let lootBoxGetWeightMaxExpectedBytes: [UInt8] = [
        0x00, 0x18, 0x40, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let lootBoxGetOverloadedThresholdExpectedBytes: [UInt8] = [
        0x00, 0x40, 0x40, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let lootBoxCheckOverloadedStateExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9,
        0xF4, 0x4F, 0x01, 0xA9
    ]
    private static let lootBoxGetIsOverweightStateExpectedBytes: [UInt8] = [
        0x08, 0x28, 0x40, 0xB9,
        0x1F, 0x05, 0x00, 0x31,
        0xE0, 0x07, 0x9F, 0x1A,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let lootBoxRefreshWeightExpectedBytes: [UInt8] = [
        0xFF, 0x43, 0x03, 0xD1,
        0xE9, 0x23, 0x07, 0x6D
    ]
    private static let lootBoxRefreshOverweightExpectedBytes: [UInt8] = [
        0xE9, 0x23, 0xBB, 0x6D,
        0xF8, 0x5F, 0x01, 0xA9
    ]
    private static let overweightPropertyGetOverloadedThresholdExpectedBytes: [UInt8] = [
        0xF4, 0x4F, 0xBE, 0xA9,
        0xFD, 0x7B, 0x01, 0xA9,
        0xFD, 0x43, 0x00, 0x91,
        0x33, 0xE4, 0x03, 0xD0
    ]
    private static let retiredHarpoonProjectileGetBuffedProjectileDamageExpectedBytes: [UInt8] = [
        0xFF, 0x43, 0x01, 0xD1,
        0xE9, 0x23, 0x01, 0x6D,
        0xF6, 0x57, 0x02, 0xA9
    ]
    private static let retiredHarpoonProjectileGetProjectileDamageExpectedBytes: [UInt8] = [
        0xF4, 0x4F, 0xBE, 0xA9,
        0xFD, 0x7B, 0x01, 0xA9,
        0xFD, 0x43, 0x00, 0x91
    ]
    private static let harpoonProjectileCollisionDamageValueExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x13, 0xAA,
        0x0C, 0xF9, 0xFF, 0x97,
        0xF7, 0x03, 0x00, 0xAA
    ]
    private static let pirateRopeDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0xEB, 0x70, 0x22, 0x94
    ]
    private static let pirateRopePopupDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0xB7, 0x70, 0x22, 0x94,
        0xF4, 0x03, 0x00, 0xAA
    ]
    private static let johnWatsonDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x15, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x62, 0x2C, 0x22, 0x94,
        0xF4, 0x03, 0x00, 0xAA
    ]
    private static let wreckDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x65, 0x59, 0x1E, 0x94
    ]
    private static let fishAISystemDamageExpectedBytes: [UInt8] = [
        0x80, 0x42, 0x00, 0x91,
        0x01, 0x00, 0x80, 0xD2,
        0x28, 0x52, 0x1D, 0x94,
        0xF6, 0x03, 0x00, 0xAA
    ]
    private static let mxmtoonDamageGateExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x15, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x40, 0x4B, 0x19, 0x94
    ]
    private static let pirateBaseDamageGateExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x01, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x1A, 0x72, 0x14, 0x94
    ]
    private static let pirateBaseDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x04, 0x72, 0x14, 0x94
    ]
    private static let npcPlayerCharacterDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x01, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0xEA, 0x33, 0x14, 0x94,
        0xF4, 0x03, 0x00, 0xAA
    ]
    private static let damageableEventDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x13, 0xAA,
        0x72, 0x02, 0x00, 0x94
    ]
    private static let damageableLastDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x13, 0xAA,
        0x51, 0x02, 0x00, 0x94
    ]
    private static let rockBlockerDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x00, 0x91,
        0x01, 0x00, 0x80, 0xD2,
        0x9F, 0xB7, 0xFF, 0x97,
        0xE1, 0x03, 0x00, 0xAA
    ]
    private static let giantSquidDamageGateExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0xD3, 0xEC, 0xF9, 0x97
    ]
    private static let wolffishDamageGateExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x67, 0xC4, 0xF4, 0x97
    ]
    private static let wolffishDamageScaleExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x1A, 0xC4, 0xF4, 0x97
    ]
    private static let wolffishFinalDamageExpectedBytes: [UInt8] = [
        0xE0, 0x03, 0x14, 0xAA,
        0x01, 0x00, 0x80, 0xD2,
        0x72, 0xC3, 0xF4, 0x97,
        0xF4, 0x03, 0x00, 0xAA
    ]
    private static let insectBattlePlayerDirectDamageExpectedBytes: [UInt8] = [
        0x01, 0x3D, 0x40, 0xB9,
        0x02, 0x00, 0x80, 0xD2
    ]
    private static let insectBattlePlayerDamageDifferenceExpectedBytes: [UInt8] = [
        0x5F, 0x03, 0x00, 0x71,
        0x41, 0x57, 0x9A, 0x5A
    ]
    private static let insectBattleEnemyDirectDamageExpectedBytes: [UInt8] = [
        0x01, 0x3D, 0x40, 0xB9
    ]
    private static let insectBattleEnemyDamageDifferenceExpectedBytes: [UInt8] = [
        0xE1, 0x03, 0x00, 0xAA
    ]
    private static let legacyAttackDataGetBuffedDamageExpectedBytes: [UInt8] = [
        0xFF, 0x83, 0x01, 0xD1,
        0xE9, 0x23, 0x01, 0x6D,
        0xF8, 0x5F, 0x02, 0xA9,
        0xF6, 0x57, 0x03, 0xA9
    ]
    private static let legacyDamagerSetDamageValueExpectedBytes: [UInt8] = [
        0x08, 0x00, 0x38, 0x1E,
        0x09, 0xF0, 0xAF, 0x52,
        0x21, 0x01, 0x27, 0x1E,
        0x00, 0x20, 0x21, 0x1E,
        0x09, 0x00, 0xB0, 0x52,
        0x28, 0x01, 0x88, 0x1A,
        0x08, 0x78, 0x00, 0xB9,
        0x28, 0x00, 0x80, 0x52,
        0x08, 0x80, 0x01, 0x39,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let legacyExtensionIDamagerGetBuffedDamageExpectedBytes: [UInt8] = [
        0xFF, 0x43, 0x01, 0xD1,
        0xF8, 0x5F, 0x01, 0xA9,
        0xF6, 0x57, 0x02, 0xA9,
        0xF4, 0x4F, 0x03, 0xA9
    ]
    private static let legacyJungleRPGDamageResultScaleExpectedBytes: [UInt8] = [
        0x60, 0x3A, 0x40, 0xBD
    ]
    private static let rpgDealDamageEnemyOnlyHookExpectedBytes: [UInt8] = [
        0xE0, 0x0C, 0x00, 0xB4
    ]
    private static let legacyFishSpeedMultiplierExpectedBytes: [UInt8] = [0x61, 0x26, 0x40, 0xBD]
    private static let playerMovePropertyGetMoveSpeedExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9,
        0xFD, 0x7B, 0x02, 0xA9, 0xFD, 0x83, 0x00, 0x91
    ]
    private static let playerCharacterDetermineMoveSpeedExpectedBytes: [UInt8] = [
        0xE9, 0x23, 0xBD, 0x6D, 0xF4, 0x4F, 0x01, 0xA9,
        0xFD, 0x7B, 0x02, 0xA9, 0xFD, 0x83, 0x00, 0x91
    ]
    private static let daveMoveValueGetSpeedMultiplierExpectedBytes: [UInt8] = [
        0xFD, 0x7B, 0xBF, 0xA9,
        0xFD, 0x03, 0x00, 0x91,
        0x08, 0x28, 0x80, 0xB9,
        0x1F, 0x05, 0x00, 0x31
    ]
    private static let farmPlayerPresenterMoveSpeedMultiplierExpectedBytes: [UInt8] = [
        0x00, 0x10, 0x2E, 0x1E,
        0x1F, 0x05, 0x00, 0x71,
        0x41, 0x00, 0x00, 0x54,
        0x80, 0x32, 0x40, 0xBD
    ]
    private static let fishFarmPlayerViewGetDaveSpeedExpectedBytes: [UInt8] = [
        0x08, 0x2C, 0x40, 0xF9,
        0x08, 0x01, 0x00, 0xB4,
        0x08, 0xF5, 0x40, 0x39,
        0x88, 0x00, 0x00, 0x36
    ]
    private static let fishFarmPlayerPresenterDashSpeedExpectedBytes: [UInt8] = [
        0x22, 0x08, 0x22, 0x1E
    ]
    private static let fishFarmPlayerPresenterWalkSpeedExpectedBytes: [UInt8] = [
        0x02, 0x28, 0x40, 0xBD
    ]
    private static let jVillageStateMachineCustomizedSpeedExpectedBytes: [UInt8] = [
        0x00, 0x7C, 0x40, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6,
        0x00, 0x7C, 0x00, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let jVillageLobbyMoveCustomizedSpeedExpectedBytes: [UInt8] = [
        0x60, 0x6E, 0x40, 0xBD
    ]
    private static let baconStoryPlayerMoveSpeedExpectedBytes: [UInt8] = [
        0x69, 0x62, 0x40, 0xBD
    ]
    private static let baconStoryChasingLaneGetMoveSpeedExpectedBytes: [UInt8] = [
        0x00, 0x30, 0x40, 0xBD,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let operationDataNowWasabiCountExpectedBytes: [UInt8] = [
        0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91,
        0x08, 0x08, 0x40, 0xF9, 0x48, 0x01, 0x00, 0xB4,
        0x09, 0x19, 0x40, 0xB9, 0x3F, 0x00, 0x09, 0x6B,
        0x02, 0x01, 0x00, 0x54, 0x08, 0xCD, 0x21, 0x8B,
        0x08, 0x11, 0x40, 0xF9, 0x88, 0x00, 0x00, 0xB4,
        0x00, 0x11, 0x40, 0xB9, 0xFD, 0x7B, 0xC1, 0xA8,
        0xC0, 0x03, 0x5F, 0xD6, 0x8D, 0xD2, 0xA0, 0x97,
        0x8F, 0xD2, 0xA0, 0x97, 0x00, 0x20, 0x40, 0xB9
    ]
    private static let playerInfoSaveSetGoldExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9,
        0xFD, 0x7B, 0x02, 0xA9, 0xFD, 0x83, 0x00, 0x91,
        0xF4, 0x03, 0x01, 0xAA, 0xF3, 0x03, 0x00, 0xAA,
        0xF6, 0xED, 0x03, 0xF0, 0xC8, 0x6E, 0x52, 0x39,
        0x35, 0xCA, 0x03, 0xD0, 0xB5, 0xC2, 0x33, 0x91,
        0xC8, 0x00, 0x00, 0x37, 0x20, 0xCA, 0x03, 0xD0,
        0x00, 0xC0, 0x33, 0x91, 0xEE, 0x72, 0xA8, 0x97,
        0x28, 0x00, 0x80, 0x52, 0xC8, 0x6E, 0x12, 0x39,
        0x80, 0x02, 0xC0, 0x3D, 0x88, 0x12, 0x40, 0xB9,
        0x68, 0x22, 0x00, 0xB9, 0x60, 0x06, 0x80, 0x3D,
        0xA0, 0x02, 0x40, 0xF9, 0x08, 0xE4, 0x40, 0xB9,
        0x48, 0x00, 0x00, 0x35, 0x4C, 0x73, 0xA8, 0x97,
        0x00, 0x00, 0x80, 0xD2, 0x6D, 0xC2, 0xD3, 0x97,
        0xC0, 0x00, 0x00, 0xB4, 0x01, 0x00, 0x80, 0xD2,
        0xFD, 0x7B, 0x42, 0xA9, 0xF4, 0x4F, 0x41, 0xA9,
        0xF6, 0x57, 0xC3, 0xA8, 0xF2, 0xE0, 0xE4, 0x17
    ]
    private static let playerInfoSaveGetBeiExpectedBytes: [UInt8] = [
        0x00, 0x40, 0xC2, 0x3C,
        0x00, 0x01, 0x80, 0x3D,
        0x09, 0x34, 0x40, 0xB9
    ]
    private static let playerInfoSaveSetBeiExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9,
        0xFD, 0x7B, 0x02, 0xA9, 0xFD, 0x83, 0x00, 0x91,
        0xF4, 0x03, 0x01, 0xAA, 0xF3, 0x03, 0x00, 0xAA,
        0xF6, 0xED, 0x03, 0xF0, 0xC8, 0x72, 0x52, 0x39,
        0x35, 0xCA, 0x03, 0xD0, 0xB5, 0xC2, 0x33, 0x91,
        0xC8, 0x00, 0x00, 0x37, 0x20, 0xCA, 0x03, 0xD0,
        0x00, 0xC0, 0x33, 0x91, 0xC8, 0x72, 0xA8, 0x97,
        0x28, 0x00, 0x80, 0x52, 0xC8, 0x72, 0x12, 0x39,
        0x80, 0x02, 0xC0, 0x3D, 0x88, 0x12, 0x40, 0xB9,
        0x68, 0x36, 0x00, 0xB9, 0x60, 0x42, 0x82, 0x3C,
        0xA0, 0x02, 0x40, 0xF9, 0x08, 0xE4, 0x40, 0xB9,
        0x48, 0x00, 0x00, 0x35, 0x26, 0x73, 0xA8, 0x97,
        0x00, 0x00, 0x80, 0xD2, 0x47, 0xC2, 0xD3, 0x97,
        0xC0, 0x00, 0x00, 0xB4, 0x01, 0x00, 0x80, 0xD2,
        0xFD, 0x7B, 0x42, 0xA9, 0xF4, 0x4F, 0x41, 0xA9,
        0xF6, 0x57, 0xC3, 0xA8, 0xCC, 0xE0, 0xE4, 0x17
    ]
    private static let playerInfoSaveSetChefFlameExpectedBytes: [UInt8] = [
        0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9,
        0xFD, 0x7B, 0x02, 0xA9, 0xFD, 0x83, 0x00, 0x91,
        0xF4, 0x03, 0x01, 0xAA, 0xF3, 0x03, 0x00, 0xAA,
        0xF6, 0xED, 0x03, 0xF0, 0xC8, 0x76, 0x52, 0x39,
        0x35, 0xCA, 0x03, 0xD0, 0xB5, 0xC2, 0x33, 0x91,
        0xC8, 0x00, 0x00, 0x37, 0x20, 0xCA, 0x03, 0xD0,
        0x00, 0xC0, 0x33, 0x91, 0xA2, 0x72, 0xA8, 0x97,
        0x28, 0x00, 0x80, 0x52, 0xC8, 0x76, 0x12, 0x39,
        0x80, 0x02, 0xC0, 0x3D, 0x88, 0x12, 0x40, 0xB9,
        0x68, 0x4A, 0x00, 0xB9, 0x60, 0x82, 0x83, 0x3C,
        0xA0, 0x02, 0x40, 0xF9, 0x08, 0xE4, 0x40, 0xB9,
        0x48, 0x00, 0x00, 0x35, 0x00, 0x73, 0xA8, 0x97,
        0x00, 0x00, 0x80, 0xD2, 0x21, 0xC2, 0xD3, 0x97,
        0xC0, 0x00, 0x00, 0xB4, 0x01, 0x00, 0x80, 0xD2,
        0xFD, 0x7B, 0x42, 0xA9, 0xF4, 0x4F, 0x41, 0xA9,
        0xF6, 0x57, 0xC3, 0xA8, 0xA6, 0xE0, 0xE4, 0x17
    ]
    private static let ingredientsDataTotalCountExpectedBytes: [UInt8] = [
        0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91,
        0x08, 0x14, 0x40, 0xF9, 0x48, 0x01, 0x00, 0xB4,
        0x09, 0x19, 0x40, 0xB9, 0x3F, 0x05, 0x00, 0x71,
        0xC0, 0x00, 0x00, 0x54, 0xA9, 0x00, 0x00, 0x34,
        0x09, 0x21, 0x44, 0x29, 0x00, 0x01, 0x09, 0x0B,
        0xFD, 0x7B, 0xC1, 0xA8
    ]
    private static let ingredientsDataTotalCountFullExpectedBytes: [UInt8] = ingredientsDataTotalCountExpectedBytes + [
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let ingredientsDataGetCountExpectedBytes: [UInt8] = [
        0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91,
        0x08, 0x14, 0x40, 0xF9, 0x08, 0x01, 0x00, 0xB4,
        0x09, 0x19, 0x40, 0xB9, 0x3F, 0x00, 0x09, 0x6B,
        0xC2, 0x00, 0x00, 0x54, 0x08, 0xC9, 0x21, 0x8B,
        0x00, 0x21, 0x40, 0xB9, 0xFD, 0x7B, 0xC1, 0xA8,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let ingredientsDataSetCountExpectedBytes: [UInt8] = [
        0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91,
        0x08, 0x14, 0x40, 0xF9, 0x28, 0x01, 0x00, 0xB4,
        0x09, 0x19, 0x40, 0xB9, 0x3F, 0x00, 0x09, 0x6B,
        0xE2, 0x00, 0x00, 0x54, 0x08, 0xC9, 0x21, 0x8B,
        0x02, 0x21, 0x00, 0xB9, 0xE0, 0x03, 0x02, 0xAA,
        0xFD, 0x7B, 0xC1, 0xA8, 0xC0, 0x03, 0x5F, 0xD6,
        0x61, 0x95, 0xA1, 0x97, 0x63, 0x95, 0xA1, 0x97
    ]
    private static let ingredientsDataIsEnoughExpectedBytes: [UInt8] = [
        0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91,
        0x08, 0x14, 0x40, 0xF9, 0x48, 0x01, 0x00, 0xB4,
        0x09, 0x19, 0x40, 0xB9, 0x3F, 0x00, 0x09, 0x6B,
        0x02, 0x01, 0x00, 0x54, 0x08, 0xC9, 0x21, 0x8B,
        0x08, 0x21, 0x40, 0xB9, 0x1F, 0x01, 0x02, 0x6B,
        0xE0, 0xB7, 0x9F, 0x1A, 0xFD, 0x7B, 0xC1, 0xA8,
        0xC0, 0x03, 0x5F, 0xD6
    ]
    private static let ingredientsDataIsEnoughTotalExpectedBytes: [UInt8] = [
        0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91,
        0x08, 0x14, 0x40, 0xF9, 0x88, 0x01, 0x00, 0xB4,
        0x09, 0x19, 0x40, 0xB9, 0x3F, 0x05, 0x00, 0x71,
        0x00, 0x01, 0x00, 0x54, 0xE9, 0x00, 0x00, 0x34,
        0x09, 0x21, 0x44, 0x29, 0x08, 0x01, 0x09, 0x0B,
        0x1F, 0x01, 0x01, 0x6B, 0xE0, 0xB7, 0x9F, 0x1A,
        0xFD, 0x7B, 0xC1, 0xA8
    ]
    private static let ingredientsStorageGetCountCategoryExpectedBytes: [UInt8] = [
        0xE8, 0x07, 0x40, 0xF9, 0xC8, 0x01, 0x00, 0xB4,
        0x08, 0x15, 0x40, 0xF9, 0x88, 0x01, 0x00, 0xB4,
        0x09, 0x19, 0x40, 0xB9, 0x3F, 0x05, 0x00, 0x71,
        0x40, 0x01, 0x00, 0x54, 0x29, 0x01, 0x00, 0x34,
        0x09, 0x21, 0x44, 0x29, 0x00, 0x01, 0x09, 0x0B,
        0xFD, 0x7B, 0x43, 0xA9, 0xF4, 0x4F, 0x42, 0xA9,
        0xF6, 0x57, 0x41, 0xA9, 0xFF, 0x03, 0x01, 0x91,
        0xC0, 0x03, 0x5F, 0xD6, 0x73, 0x90, 0xA1, 0x97
    ]
    private static let saveDataJungleGetJungleGoldExpectedBytes: [UInt8] = [
        0x08, 0x68, 0x40, 0xF9,
        0x68, 0x00, 0x00, 0xB4,
        0x00, 0x11, 0x40, 0xB9
    ]
}
