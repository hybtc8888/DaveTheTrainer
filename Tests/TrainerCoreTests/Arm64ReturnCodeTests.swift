import XCTest
@testable import TrainerCore

final class Arm64ReturnCodeTests: XCTestCase {
    func testReturnInt32UsesSingleMoveForSmallValue() throws {
        let bytes = try Arm64ReturnCode.returnInt32(999)
        XCTAssertEqual(bytes, [0xE0, 0x7C, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6])
    }

    func testReturnInt32UsesMoveKeepForLargeValue() throws {
        let bytes = try Arm64ReturnCode.returnInt32(9_999_999)
        XCTAssertEqual(bytes, [0xE0, 0xCF, 0x92, 0x52, 0x00, 0x13, 0xA0, 0x72, 0xC0, 0x03, 0x5F, 0xD6])
    }

    func testMoveInt32ToSpecificRegisters() throws {
        XCTAssertEqual(try Arm64ReturnCode.moveInt32ToW1(999), [0xE1, 0x7C, 0x80, 0x52])
        XCTAssertEqual(try Arm64ReturnCode.moveInt32ToW1(999_999), [
            0xE1, 0x47, 0x88, 0x52,
            0xE1, 0x01, 0xA0, 0x72
        ])
        XCTAssertEqual(try Arm64ReturnCode.moveInt32ToW8(999), [0xE8, 0x7C, 0x80, 0x52])
        XCTAssertEqual(try Arm64ReturnCode.moveInt32ToW20(999), [0xF4, 0x7C, 0x80, 0x52])
        XCTAssertEqual(try Arm64ReturnCode.moveInt32ToW21(999), [0xF5, 0x7C, 0x80, 0x52])
        XCTAssertEqual(try Arm64ReturnCode.moveInt32ToW22(999), [0xF6, 0x7C, 0x80, 0x52])
        XCTAssertEqual(try Arm64ReturnCode.moveInt32ToW23(999), [0xF7, 0x7C, 0x80, 0x52])
    }

    func testReturnFloat32MaterializesBitPattern() {
        let bytes = Arm64ReturnCode.returnFloat32(999.0)
        XCTAssertEqual(bytes, [0x08, 0x00, 0x98, 0x52, 0x28, 0x8F, 0xA8, 0x72, 0x00, 0x01, 0x27, 0x1E, 0xC0, 0x03, 0x5F, 0xD6])
    }

    func testReturnThirtyOneFloat32FitsShortGetter() {
        XCTAssertEqual(Arm64ReturnCode.returnThirtyOneFloat32, [0x00, 0xF0, 0x27, 0x1E, 0xC0, 0x03, 0x5F, 0xD6])
    }

    func testImmediateFloat32PatchesUseSingleInstructionWhenSupported() throws {
        XCTAssertEqual(try Arm64ReturnCode.returnImmediateFloat32(2.5), [
            0x00, 0x90, 0x20, 0x1E,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertEqual(try Arm64ReturnCode.returnImmediateFloat32(5.0), [
            0x00, 0x90, 0x22, 0x1E,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertEqual(try Arm64ReturnCode.moveImmediateFloat32ToS0(5.0), [0x00, 0x90, 0x22, 0x1E])
        XCTAssertEqual(try Arm64ReturnCode.moveImmediateFloat32ToS2(5.0), [0x02, 0x90, 0x22, 0x1E])
        XCTAssertEqual(try Arm64ReturnCode.moveImmediateFloat32ToS9(5.0), [0x09, 0x90, 0x22, 0x1E])
    }

    func testLoadFloat32LiteralToS0BranchesOverLiteral() throws {
        XCTAssertEqual(
            try Arm64ReturnCode.loadFloat32LiteralToS0AndBranch(
                value: 5.0,
                patchRVA: 0x0F97664,
                literalRVA: 0x0F97670,
                continueRVA: 0x0F97674
            ),
            [
                0x60, 0x00, 0x00, 0x1C,
                0x03, 0x00, 0x00, 0x14,
                0x1F, 0x20, 0x03, 0xD5,
                0x00, 0x00, 0xA0, 0x40
            ]
        )
    }

    func testLoadFloat32LiteralToS0ReturnsAndDisablesSetter() throws {
        XCTAssertEqual(
            try Arm64ReturnCode.loadFloat32LiteralToS0ReturnAndDisableSetter(
                value: 5.0,
                patchRVA: 0x17A37FC,
                literalRVA: 0x17A3808
            ),
            [
                0x60, 0x00, 0x00, 0x1C,
                0xC0, 0x03, 0x5F, 0xD6,
                0xC0, 0x03, 0x5F, 0xD6,
                0x00, 0x00, 0xA0, 0x40
            ]
        )
    }

    func testRPGDamagePolicyTrampolineCombinesSuperAndIgnoreDamage() throws {
        let request = RPGDamagePolicyTrampolineRequest(
            value: 999_999,
            mode: [.enemySuperDamage, .playerIgnoreDamage],
            addresses: RPGDamagePolicyTrampolineAddresses(
                trampoline: 0x08EA2000,
                resume: 0x18DDD74,
                nullHandler: 0x18DDF0C,
                isEnemy: 0x18E1A58
            )
        )
        let bytes = try Arm64ReturnCode.writeRPGDamagePolicyTrampoline(request)

        XCTAssertEqual(bytes.count, 60)
        XCTAssertEqual(Array(bytes.prefix(4)), [
            0x40, 0x00, 0x00, 0xB5
        ])
        XCTAssertEqual(Array(bytes[8..<16]), [
            0xFC, 0x03, 0x00, 0xAA,
            0xE0, 0x03, 0x14, 0xAA
        ])
        XCTAssertEqual(Array(bytes[24..<32]), try Arm64ReturnCode.moveInt32ToW21(999_999))
        XCTAssertEqual(Array(bytes[36..<40]), try Arm64ReturnCode.moveInt32ToW21(0))
        XCTAssertEqual(Array(bytes[40..<44]), [
            0xE0, 0x03, 0x1C, 0xAA
        ])
        XCTAssertEqual(Array(bytes.suffix(12)), [
            0x03, 0x00, 0x00, 0x00
        ] + Arm64ReturnCode.rpgDamagePolicyTrampolineMarker)
        XCTAssertEqual(
            try Arm64ReturnCode.unconditionalBranch(from: 0x18DDD70, to: 0x08EA2000),
            [0xA4, 0x10, 0xD7, 0x15]
        )
    }

    func testReturnObscuredInt32TailBranchesToGameConstructor() throws {
        let bytes = try Arm64ReturnCode.returnObscuredInt32(99_999, patchRVA: 0x12FD1C0, implicitIntRVA: 0x11DD394)
        XCTAssertEqual(bytes, [0xE0, 0xD3, 0x90, 0x52, 0x20, 0x00, 0xA0, 0x72, 0x73, 0x80, 0xFB, 0x17])
    }

    func testObscuredInt32PropertySetterPatchWritesAndSaves() throws {
        let bytes = try Arm64ReturnCode.writeObscuredInt32PropertyAndSave(
            ObscuredInt32PropertySavePatchRequest(
                value: 999,
                patchRVA: 0x1F3881C,
                fieldOffset: 0x10,
                implicitIntRVA: 0x11DD394,
                getGameSaveRVA: 0x1429234,
                updatePlayerSaveRVA: 0x1870C60,
                raiseNullReferenceRVA: 0x9556E4
            )
        )

        XCTAssertEqual(bytes.count, 76)
        XCTAssertEqual(Array(bytes.prefix(24)), [
            0xFD, 0x7B, 0xBD, 0xA9,
            0xFD, 0x03, 0x00, 0x91,
            0xE0, 0x17, 0x00, 0xF9,
            0xE0, 0x7C, 0x80, 0x52,
            0xE8, 0x43, 0x00, 0x91,
            0xD9, 0x92, 0xCA, 0x97
        ])
        XCTAssertEqual(Array(bytes.suffix(8)), [
            0xA1, 0x73, 0xA8, 0x97,
            0x20, 0x00, 0x20, 0xD4
        ])
    }

    func testIngredientsSetCountPatchFitsOriginalFunction() throws {
        let bytes = try Arm64ReturnCode.writeIngredientsSetCount(
            IngredientsSetCountPatchRequest(
                value: 999,
                patchRVA: 0x20F0130,
                raiseNullReferenceRVA: 0x9556E4,
                raiseIndexOutOfRangeRVA: 0x9556F0
            )
        )

        XCTAssertEqual(bytes.count, 56)
        XCTAssertEqual(Array(bytes.prefix(40)), [
            0x08, 0x14, 0x40, 0xF9,
            0x28, 0x01, 0x00, 0xB4,
            0x09, 0x19, 0x40, 0xB9,
            0x3F, 0x00, 0x09, 0x6B,
            0x02, 0x01, 0x00, 0x54,
            0x08, 0xC9, 0x21, 0x8B,
            0xE2, 0x7C, 0x80, 0x52,
            0x02, 0x21, 0x00, 0xB9,
            0xE0, 0x03, 0x02, 0x2A,
            0xC0, 0x03, 0x5F, 0xD6
        ])
    }

    func testDefaultStaticPatchesIncludeFixedWeightPatch() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let patch = try XCTUnwrap(patches["weight"])
        let cargoBoxMaximumWeight = try XCTUnwrap(patch.points.first { $0.rva == 0x1D95604 })
        let lootBoxGetWeight = try XCTUnwrap(patch.points.first { $0.rva == 0x1EA8368 })
        let lootBoxSetWeight = try XCTUnwrap(patch.points.first { $0.rva == 0x1EA8360 })
        let lootBoxWeightMax = try XCTUnwrap(patch.points.first { $0.rva == 0x1EA8660 })
        let lootBoxOverloadedThreshold = try XCTUnwrap(patch.points.first { $0.rva == 0x1EA86A8 })
        let lootBoxCheckOverloaded = try XCTUnwrap(patch.points.first { $0.rva == 0x1EA80F4 })
        let lootBoxIsOverweight = try XCTUnwrap(patch.points.first { $0.rva == 0x1EA86B8 })
        let overweightThreshold = try XCTUnwrap(patch.points.first { $0.rva == 0x2072528 })

        XCTAssertEqual(patch.points.count, 14)
        XCTAssertEqual(patch.points.first?.rva, 0x1D95604)
        XCTAssertEqual(cargoBoxMaximumWeight.patchBytes, Arm64ReturnCode.returnThirtyOneFloat32)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1D9561C })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1450AF8 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1450B00 })
        XCTAssertEqual(lootBoxGetWeight.patchBytes, Arm64ReturnCode.returnZeroFloat32)
        XCTAssertEqual(lootBoxSetWeight.patchBytes, [0xC0, 0x03, 0x5F, 0xD6])
        XCTAssertEqual(lootBoxWeightMax.patchBytes, Arm64ReturnCode.returnThirtyOneFloat32)
        XCTAssertEqual(lootBoxOverloadedThreshold.patchBytes, Arm64ReturnCode.returnThirtyOneFloat32)
        XCTAssertEqual(lootBoxCheckOverloaded.patchBytes, [
            0x00, 0x00, 0x80, 0x52,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertEqual(lootBoxIsOverweight.patchBytes, [
            0x00, 0x00, 0x80, 0x52,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1EAA1D4 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1EAA960 })
        XCTAssertEqual(overweightThreshold.patchBytes, Arm64ReturnCode.returnFloat32(999.0))
    }

    func testDefaultStaticPatchesCoverGodModeDamageSemantics() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let patch = try XCTUnwrap(patches["god"])
        let onTakeDamage = try XCTUnwrap(patch.points.first { $0.rva == 0x0B7EA14 })
        let isImmuneDamage = try XCTUnwrap(patch.points.first { $0.rva == 0x0B76690 })
        let setHazardHPDamage = try XCTUnwrap(patch.points.first { $0.rva == 0x1B43C20 })
        let cheatNoDie = try XCTUnwrap(patch.points.first { $0.rva == 0x1B400D8 })
        let breathImmuneDamage = try XCTUnwrap(patch.points.first { $0.rva == 0x1B400F8 })
        let insectEnemyDirectDamage = try XCTUnwrap(patch.points.first { $0.rva == 0x0DCC53C })
        let insectEnemyAdvantageDamage = try XCTUnwrap(patch.points.first { $0.rva == 0x0DCC83C })
        let rpgIgnoreDamage = try XCTUnwrap(patch.points.first { $0.rva == 0x18DDD70 })
        let returnTrue = [
            UInt8(0x20), 0x00, 0x80, 0x52,
            0xC0, 0x03, 0x5F, 0xD6
        ]

        XCTAssertEqual(patch.points.count, 10)
        XCTAssertEqual(onTakeDamage.patchBytes, [
            0x00, 0x00, 0x80, 0x52,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertEqual(isImmuneDamage.patchBytes, returnTrue)
        XCTAssertEqual(setHazardHPDamage.patchBytes, [0xC0, 0x03, 0x5F, 0xD6])
        XCTAssertEqual(cheatNoDie.patchBytes, returnTrue)
        XCTAssertEqual(breathImmuneDamage.patchBytes, returnTrue)
        XCTAssertEqual(insectEnemyDirectDamage.patchBytes, try Arm64ReturnCode.moveInt32ToW1(0))
        XCTAssertEqual(insectEnemyAdvantageDamage.patchBytes, try Arm64ReturnCode.moveInt32ToW1(0))
        XCTAssertEqual(rpgIgnoreDamage.expectedBytes, [0xE0, 0x0C, 0x00, 0xB4])
        XCTAssertEqual(rpgIgnoreDamage.patchBytes, [])
        XCTAssertEqual(rpgIgnoreDamage.trampoline?.kind, .rpgDamagePolicyIgnoreDamage)
        XCTAssertEqual(rpgIgnoreDamage.trampoline?.nullHandlerRVA, 0x18DDF0C)
        XCTAssertEqual(rpgIgnoreDamage.trampoline?.helperRVA, 0x18E1A58)
        XCTAssertEqual(rpgIgnoreDamage.trampoline?.codeCaveRVA, 0x940)
        XCTAssertEqual(rpgIgnoreDamage.trampoline?.codeCaveExpectedBytes, Array(repeating: UInt8(0), count: 72))
        XCTAssertNil(patch.points.first { $0.rva == 0x0B77830 })
    }

    func testDefaultStaticPatchesCoverOxygenReadAndDrain() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let patch = try XCTUnwrap(patches["oxygen"])
        let currentOxygen = try XCTUnwrap(patch.points.first { $0.rva == 0x13DBB0C })

        XCTAssertEqual(patch.points.count, 4)
        XCTAssertEqual(currentOxygen.patchBytes, Arm64ReturnCode.returnThirtyOneFloat32)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1B3A044 })
        XCTAssertEqual(patch.points.first { $0.rva == 0x1B438C4 }?.patchBytes, [
            0x00, 0x00, 0x80, 0x52,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertNil(patch.points.first { $0.rva == 0x1B43C20 })
        XCTAssertNil(patch.points.first { $0.rva == 0x1B400D8 })
        XCTAssertNil(patch.points.first { $0.rva == 0x1B400F8 })
    }

    func testDefaultStaticPatchesCoverAmmoConsumptionAndAvailability() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let patch = try XCTUnwrap(patches["ammo"])
        let availability = try XCTUnwrap(patch.points.first { $0.rva == 0x1B35224 })
        let countSecondaryRemain = try XCTUnwrap(patch.points.first { $0.rva == 0x13A0060 })
        let fuelSecondaryRemain = try XCTUnwrap(patch.points.first { $0.rva == 0x13BF134 })
        let gunFireAmmoGate = try XCTUnwrap(patch.points.first { $0.rva == 0x1B28B98 })
        let gunAvailable = try XCTUnwrap(patch.points.first { $0.rva == 0x1B2893C })
        let gunGetAmmo = try XCTUnwrap(patch.points.first { $0.rva == 0x1B293F0 })
        let gunReloadStoredCount = try XCTUnwrap(patch.points.first { $0.rva == 0x1B28504 })
        let gunForceSetCount = try XCTUnwrap(patch.points.first { $0.rva == 0x1B28580 })
        let primaryWeaponUI = try XCTUnwrap(patch.points.first { $0.rva == 0x13407BC })
        let actionSwitchUI = try XCTUnwrap(patch.points.first { $0.rva == 0x1D0B8E4 })

        XCTAssertEqual(patch.points.count, 21)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x0B895E8 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x0B84BF8 })
        XCTAssertEqual(availability.patchBytes, [0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6])
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1B352EC })
        XCTAssertEqual(gunFireAmmoGate.patchBytes, try Arm64ReturnCode.moveInt32ToW8(999))
        XCTAssertNotNil(patch.points.first { $0.rva == 0x1B27FFC })
        XCTAssertEqual(gunAvailable.patchBytes, [0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6])
        XCTAssertEqual(gunGetAmmo.patchBytes, try Arm64ReturnCode.returnInt32(999))
        XCTAssertEqual(gunReloadStoredCount.patchBytes, try Arm64ReturnCode.moveInt32ToW8(999))
        XCTAssertEqual(gunForceSetCount.patchBytes, try Arm64ReturnCode.moveInt32ToW20(999))
        XCTAssertNotNil(patch.points.first { $0.rva == 0x138C3B8 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x138BDD4 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x138BE74 })
        XCTAssertEqual(primaryWeaponUI.patchBytes, try Arm64ReturnCode.moveInt32ToW20(999))
        XCTAssertEqual(actionSwitchUI.patchBytes, try Arm64ReturnCode.moveInt32ToW21(999))
        XCTAssertNotNil(patch.points.first { $0.rva == 0x139A50C })
        XCTAssertEqual(countSecondaryRemain.patchBytes, Arm64ReturnCode.returnFloat32(999.0))
        XCTAssertTrue(countSecondaryRemain.acceptsCompatibleAppliedPatch)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x139FFAC })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x13BD63C })
        XCTAssertEqual(fuelSecondaryRemain.patchBytes, Arm64ReturnCode.returnFloat32(999.0))
        XCTAssertTrue(fuelSecondaryRemain.acceptsCompatibleAppliedPatch)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x13BF0A8 })
    }

    func testDefaultStaticPatchesCoverDroneGetterAndSetter() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let patch = try XCTUnwrap(patches["drones"])
        let subHelperDisplay = try XCTUnwrap(patch.points.first { $0.rva == 0x1D0C0B8 })

        XCTAssertEqual(patch.points.count, 4)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x0B76ECC })
        XCTAssertEqual(subHelperDisplay.patchBytes, try Arm64ReturnCode.moveInt32ToW22(999))
        XCTAssertNotNil(patch.points.first { $0.rva == 0x0B76ED4 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x0B76EDC })
    }

    func testDefaultStaticPatchesCoverCrabTrapGetterSetterAndAvailability() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let patch = try XCTUnwrap(patches["crabTraps"])
        let return999 = try Arm64ReturnCode.returnInt32(999)
        let returnTrue = [
            UInt8(0x20), 0x00, 0x80, 0x52,
            0xC0, 0x03, 0x5F, 0xD6
        ]
        let arm64Return = [UInt8(0xC0), 0x03, 0x5F, 0xD6]

        XCTAssertEqual(patch.points.count, 7)
        XCTAssertEqual(patch.points.first { $0.rva == 0x1418E84 }?.patchBytes, return999)
        XCTAssertEqual(patch.points.first { $0.rva == 0x1418E8C }?.patchBytes, arm64Return)
        XCTAssertEqual(patch.points.first { $0.rva == 0x0B76EEC }?.patchBytes, return999)
        XCTAssertEqual(patch.points.first { $0.rva == 0x0B76EF4 }?.patchBytes, arm64Return)
        XCTAssertEqual(patch.points.first { $0.rva == 0x0B76EFC }?.patchBytes, returnTrue)
        XCTAssertEqual(patch.points.first { $0.rva == 0x144EF4C }?.patchBytes, return999)
        XCTAssertEqual(patch.points.first { $0.rva == 0x144EF54 }?.patchBytes, arm64Return)
    }

    func testDefaultStaticPatchesCoverDamageAndWasabi() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let damage = try XCTUnwrap(patches["damage"])
        let wasabi = try XCTUnwrap(patches["wasabi"])
        let insectDamageBytes = try Arm64ReturnCode.moveInt32ToW1(999_999)
        let nop = [UInt8(0x1F), 0x20, 0x03, 0xD5]

        XCTAssertEqual(damage.points.count, 28)
        for rva in [UInt64(0x1DA39FC), UInt64(0x1DA3C5C), UInt64(0x1DA3DB8)] {
            let point = try XCTUnwrap(damage.points.first { $0.rva == rva })
            XCTAssertEqual(point.patchBytes, point.expectedBytes)
            XCTAssertTrue(point.acceptsCompatibleAppliedPatch)
        }
        let harpoonCollisionDamage = try XCTUnwrap(damage.points.first { $0.rva == 0x1DA55C8 })
        XCTAssertEqual(harpoonCollisionDamage.expectedBytes, [
            0xE0, 0x03, 0x13, 0xAA,
            0x0C, 0xF9, 0xFF, 0x97,
            0xF7, 0x03, 0x00, 0xAA
        ])
        XCTAssertEqual(harpoonCollisionDamage.patchBytes, try Arm64ReturnCode.moveInt32ToW23(999_999) + [
            0x1F, 0x20, 0x03, 0xD5
        ])
        let fishTargetDamage = try XCTUnwrap(damage.points.first { $0.rva == 0x14EAC40 })
        XCTAssertEqual(fishTargetDamage.expectedBytes, [
            0x80, 0x42, 0x00, 0x91,
            0x01, 0x00, 0x80, 0xD2,
            0x28, 0x52, 0x1D, 0x94,
            0xF6, 0x03, 0x00, 0xAA
        ])
        XCTAssertEqual(fishTargetDamage.patchBytes, try Arm64ReturnCode.moveInt32ToW22(999_999) + nop + nop)
        for rva in [UInt64(0x13A3134), UInt64(0x14A8F4C), UInt64(0x15EC7E0), UInt64(0x1722C78), UInt64(0x1722CD0), UInt64(0x1DC4194), UInt64(0x1F0E344), UInt64(0x1F0E478)] {
            XCTAssertEqual(damage.points.first { $0.rva == rva }?.patchBytes, try Arm64ReturnCode.moveInt32ToW0(999_999) + nop)
        }
        for rva in [UInt64(0x13A3204), UInt64(0x13B4358), UInt64(0x1732538), UInt64(0x1F0E718)] {
            XCTAssertEqual(damage.points.first { $0.rva == rva }?.patchBytes, try Arm64ReturnCode.moveInt32ToW20(999_999) + nop + nop)
        }
        XCTAssertEqual(damage.points.first { $0.rva == 0x1C51664 }?.patchBytes, try Arm64ReturnCode.moveInt32ToW1(999_999) + nop + nop)
        XCTAssertEqual(damage.points.first { $0.rva == 0x1C3EB1C }?.patchBytes, try Arm64ReturnCode.moveInt32ToW0(999_999))
        XCTAssertEqual(damage.points.first { $0.rva == 0x1C3EBA0 }?.patchBytes, try Arm64ReturnCode.moveInt32ToW0(999_999))
        XCTAssertNil(damage.points.first { $0.rva == 0x0B7F0E4 || $0.rva == 0x0B7F0EC })
        XCTAssertEqual(damage.points.first { $0.rva == 0x0DCC5C0 }?.patchBytes, insectDamageBytes)
        XCTAssertEqual(damage.points.first { $0.rva == 0x0DCC66C }?.patchBytes, insectDamageBytes)
        XCTAssertEqual(damage.points.first { $0.rva == 0x0DCC734 }?.patchBytes, insectDamageBytes)
        let rpgEnemyOnlyDamage = try XCTUnwrap(damage.points.first { $0.rva == 0x18DDD70 })
        XCTAssertEqual(rpgEnemyOnlyDamage.expectedBytes, [0xE0, 0x0C, 0x00, 0xB4])
        XCTAssertEqual(rpgEnemyOnlyDamage.patchBytes, [])
        XCTAssertEqual(rpgEnemyOnlyDamage.trampoline?.kind, .rpgDamagePolicySuperDamage)
        XCTAssertEqual(rpgEnemyOnlyDamage.trampoline?.nullHandlerRVA, 0x18DDF0C)
        XCTAssertEqual(rpgEnemyOnlyDamage.trampoline?.helperRVA, 0x18E1A58)
        XCTAssertEqual(rpgEnemyOnlyDamage.trampoline?.codeCaveRVA, 0x940)
        XCTAssertEqual(rpgEnemyOnlyDamage.trampoline?.codeCaveExpectedBytes, Array(repeating: UInt8(0), count: 72))
        for rva in [UInt64(0x1C3F4E8), UInt64(0x1C43144), UInt64(0x214BD7C), UInt64(0x18DE9D0)] {
            let point = try XCTUnwrap(damage.points.first { $0.rva == rva })
            XCTAssertEqual(point.patchBytes, point.expectedBytes)
            XCTAssertTrue(point.acceptsCompatibleAppliedPatch)
        }
        XCTAssertEqual(wasabi.points.count, 5)
        XCTAssertNotNil(wasabi.points.first { $0.rva == 0x2120C7C })
        XCTAssertNotNil(wasabi.points.first { $0.rva == 0x210CED8 })
    }

    func testDefaultStaticPatchesCoverStaminaOnly() throws {
        let patches = Dictionary(uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) })
        let stamina = try XCTUnwrap(patches["stamina"])

        XCTAssertEqual(stamina.points.count, 4)
        XCTAssertEqual(stamina.points.first { $0.rva == 0x0FF5E8C }?.patchBytes, try Arm64ReturnCode.returnImmediateFloat32(1.0))
        XCTAssertEqual(stamina.points.first { $0.rva == 0x0FF5E94 }?.patchBytes, [0xC0, 0x03, 0x5F, 0xD6])
        XCTAssertEqual(stamina.points.first { $0.rva == 0x0FF5B50 }?.patchBytes, [
            0x00, 0x00, 0x80, 0x52,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertEqual(stamina.points.first { $0.rva == 0x0FF61E4 }?.patchBytes, [0x20, 0x40, 0x20, 0x1E])
        XCTAssertNil(patches["instantCook"])
    }

    func testValuePatchBuildsGoldPatchFromInputValue() throws {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: "gold", value: 9_999_999)
        let lobbyPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1E45A28 })
        let globalPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x12FD1C0 })
        let savePoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1F38808 })
        let setterPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1F3881C })
        let payablePoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1565F4C })

        XCTAssertEqual(patch.id, "gold")
        XCTAssertEqual(patch.points.count, 10)
        XCTAssertEqual(lobbyPoint.patchBytes, try Arm64ReturnCode.returnInt32(9_999_999))
        XCTAssertEqual(globalPoint.patchBytes, try Arm64ReturnCode.returnObscuredInt32(9_999_999, patchRVA: 0x12FD1C0, implicitIntRVA: 0x11DD394))
        XCTAssertEqual(savePoint.patchBytes, try Arm64ReturnCode.returnObscuredInt32(9_999_999, patchRVA: 0x1F38808, implicitIntRVA: 0x11DD394))
        XCTAssertEqual(setterPoint.patchBytes.count, 80)
        XCTAssertEqual(payablePoint.patchBytes, [0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6])
    }

    func testValuePatchBuildsMaterialsPatchForStorageAndConsumption() throws {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: "materials", value: 999)
        let totalPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F00C4 })
        let getCountPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F00FC })
        let setterPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F0130 })
        let enoughPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F0168 })
        let enoughTotalPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F01A4 })
        let storageCategoryRestorePoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F14DC })

        XCTAssertEqual(patch.id, "materials")
        XCTAssertEqual(patch.title, "设置全部食材/素材数量（全局）")
        XCTAssertEqual(patch.points.count, 9)
        XCTAssertEqual(totalPoint.expectedBytes.count, 48)
        XCTAssertEqual(getCountPoint.expectedBytes.count, 44)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x20F1478 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x191E57C })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x191EDD8 })
        XCTAssertEqual(setterPoint.patchBytes.count, 56)
        XCTAssertEqual(enoughPoint.expectedBytes.count, 52)
        XCTAssertEqual(enoughPoint.patchBytes, [0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6])
        XCTAssertEqual(enoughTotalPoint.expectedBytes.count, 52)
        XCTAssertEqual(storageCategoryRestorePoint.expectedBytes.count, 64)
        XCTAssertEqual(storageCategoryRestorePoint.patchBytes, storageCategoryRestorePoint.expectedBytes)
        XCTAssertTrue(patch.points.allSatisfy { $0.patchBytes.count <= $0.expectedBytes.count })
    }

    func testValuePatchBuildsFishIngredientsCategoryPatch() throws {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: "fishIngredients", value: 999)
        let totalPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F00C4 })
        let storagePoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F14DC })

        XCTAssertEqual(patch.id, "fishIngredients")
        XCTAssertEqual(patch.title, "按鱼肉食材分类设置")
        XCTAssertEqual(patch.points.count, 6)
        XCTAssertNotNil(patch.points.first { $0.rva == 0x20F00FC })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x20F0130 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x20F0168 })
        XCTAssertNotNil(patch.points.first { $0.rva == 0x20F01A4 })
        XCTAssertEqual(totalPoint.patchBytes.count, 44)
        XCTAssertEqual(storagePoint.expectedBytes.count, 64)
        XCTAssertEqual(storagePoint.patchBytes.count, 64)
        XCTAssertEqual(Array(totalPoint.patchBytes.prefix(4)), [0x08, 0x28, 0x40, 0xF9])
        XCTAssertEqual(Array(totalPoint.patchBytes[12..<16]), [0x1F, 0x09, 0x00, 0x71])
        XCTAssertTrue(patch.points.allSatisfy { $0.patchBytes.count <= $0.expectedBytes.count })
    }

    func testValuePatchBuildsSingleIngredientsCategoryPatch() throws {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: "vegetableIngredients", value: 999)
        let totalPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x20F00C4 })

        XCTAssertEqual(patch.id, "vegetableIngredients")
        XCTAssertEqual(patch.points.count, 6)
        XCTAssertEqual(Array(totalPoint.patchBytes[12..<16]), [0x1F, 0x09, 0x00, 0x71])
        XCTAssertEqual(Array(totalPoint.patchBytes[16..<20]), [0xA0, 0x00, 0x00, 0x54])
    }

    func testIngredientsCategoryPatchRejectsValuesThatNeedTwoMoveInstructions() throws {
        XCTAssertThrowsError(try DefaultStaticGamePatches.makeValuePatch(id: "fishIngredients", value: 65_536))
    }

    func testValuePatchBuildsPlayerSpeedOnlyFromText() throws {
        let swim = try DefaultStaticGamePatches.makeValuePatch(id: "swimSpeed", valueText: "2.0")
        let daveMoveValue = try XCTUnwrap(swim.points.first { $0.rva == 0x0FF5E9C })
        let farmMove = try XCTUnwrap(swim.points.first { $0.rva == 0x0F97664 })
        let fishFarmView = try XCTUnwrap(swim.points.first { $0.rva == 0x0F4F390 })
        let fishFarmDash = try XCTUnwrap(swim.points.first { $0.rva == 0x0F4E2E8 })
        let fishFarmWalk = try XCTUnwrap(swim.points.first { $0.rva == 0x0F4E2F0 })
        let jungleStateMachine = try XCTUnwrap(swim.points.first { $0.rva == 0x17A37FC })
        let jungleLobbyMove = try XCTUnwrap(swim.points.first { $0.rva == 0x1799224 })
        let baconMove = try XCTUnwrap(swim.points.first { $0.rva == 0x113D144 })
        let baconChasingLane = try XCTUnwrap(swim.points.first { $0.rva == 0x1146560 })

        XCTAssertEqual(swim.points.count, 13)
        XCTAssertEqual(swim.points.first?.rva, 0x2072778)
        XCTAssertEqual(swim.points.first?.patchBytes, [
            0x08, 0x00, 0x80, 0x52,
            0x08, 0x00, 0xA8, 0x72,
            0x00, 0x01, 0x27, 0x1E,
            0xC0, 0x03, 0x5F, 0xD6
        ])
        XCTAssertNotNil(swim.points.first { $0.rva == 0x0B7D67C })
        XCTAssertEqual(daveMoveValue.patchBytes, swim.points.first?.patchBytes)
        XCTAssertEqual(farmMove.patchBytes, [
            0x60, 0x00, 0x00, 0x1C,
            0x03, 0x00, 0x00, 0x14,
            0x1F, 0x20, 0x03, 0xD5,
            0x00, 0x00, 0x00, 0x40
        ])
        XCTAssertEqual(fishFarmView.patchBytes, swim.points.first?.patchBytes)
        XCTAssertEqual(fishFarmDash.patchBytes, try Arm64ReturnCode.moveImmediateFloat32ToS2(2.0))
        XCTAssertEqual(fishFarmWalk.patchBytes, try Arm64ReturnCode.moveImmediateFloat32ToS2(2.0))
        XCTAssertEqual(jungleStateMachine.patchBytes, [
            0x60, 0x00, 0x00, 0x1C,
            0xC0, 0x03, 0x5F, 0xD6,
            0xC0, 0x03, 0x5F, 0xD6,
            0x00, 0x00, 0x00, 0x40
        ])
        XCTAssertEqual(jungleLobbyMove.patchBytes, try Arm64ReturnCode.moveImmediateFloat32ToS0(2.0))
        XCTAssertEqual(baconMove.patchBytes, try Arm64ReturnCode.moveImmediateFloat32ToS9(2.0))
        XCTAssertEqual(baconChasingLane.patchBytes, try Arm64ReturnCode.returnImmediateFloat32(2.0))
        XCTAssertNotNil(swim.points.first { $0.rva == 0x20A4694 })
        XCTAssertNotNil(swim.points.first { $0.rva == 0x20A4750 })
        XCTAssertThrowsError(try DefaultStaticGamePatches.makeValuePatch(id: "swimSpeed", valueText: "3.3"))
        XCTAssertThrowsError(try DefaultStaticGamePatches.makeValuePatch(id: "gameSpeed", valueText: "3.3"))
    }

    func testValuePatchBuildsBeiPatchForPlayerSave() throws {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: "bei", value: 999)
        let getterPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1F388A0 })
        let setterPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1F388B4 })

        XCTAssertEqual(patch.id, "bei")
        XCTAssertEqual(patch.points.count, 2)
        XCTAssertEqual(getterPoint.patchBytes, try Arm64ReturnCode.returnObscuredInt32(999, patchRVA: 0x1F388A0, implicitIntRVA: 0x11DD394))
        XCTAssertEqual(setterPoint.patchBytes.count, 76)
        XCTAssertEqual(Array(setterPoint.patchBytes[36..<40]), [0x20, 0x41, 0x82, 0x3C])
        XCTAssertEqual(Array(setterPoint.patchBytes[40..<44]), [0x2A, 0x35, 0x00, 0xB9])
    }

    func testValuePatchBuildsJungleGoldPatch() throws {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: "jungleGold", value: 999)
        let getterPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1526360 })

        XCTAssertEqual(patch.id, "jungleGold")
        XCTAssertEqual(patch.points.count, 1)
        XCTAssertEqual(getterPoint.patchBytes, try Arm64ReturnCode.returnInt32(999))
    }

    func testValuePatchBuildsArtisanPatchForPlayerAndJungleSaves() throws {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: "artisan", value: 999)
        let getterPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1F38938 })
        let setterPoint = try XCTUnwrap(patch.points.first { $0.rva == 0x1F3894C })

        XCTAssertEqual(patch.points.count, 3)
        XCTAssertEqual(getterPoint.patchBytes, try Arm64ReturnCode.returnObscuredInt32(999, patchRVA: 0x1F38938, implicitIntRVA: 0x11DD394))
        XCTAssertEqual(setterPoint.patchBytes.count, 76)
        XCTAssertEqual(Array(setterPoint.patchBytes[36..<40]), [0x20, 0x81, 0x83, 0x3C])
        XCTAssertEqual(Array(setterPoint.patchBytes[40..<44]), [0x2A, 0x49, 0x00, 0xB9])
        XCTAssertNotNil(patch.points.first { $0.rva == 0x15264FC })
    }
}
