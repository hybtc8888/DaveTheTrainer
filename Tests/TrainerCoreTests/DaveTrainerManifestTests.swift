import XCTest
@testable import TrainerCore

final class DaveTrainerManifestTests: XCTestCase {
    func testCurrentManifestRequiresExactBuildWithoutRuntimeScanning() {
        let manifest = DaveTrainerManifest.current

        XCTAssertEqual(manifest.schemaVersion, DaveTrainerManifest.currentSchemaVersion)
        XCTAssertEqual(manifest.gameBuild.bundleID, KnownGameBuild.current.bundleID)
        XCTAssertEqual(manifest.gameBuild.version, KnownGameBuild.current.version)
        XCTAssertEqual(manifest.gameBuild.buildGUID, KnownGameBuild.current.buildGUID)
        XCTAssertFalse(manifest.moduleIdentities.isEmpty)
        XCTAssertFalse(manifest.features.isEmpty)
        XCTAssertTrue(manifest.features.allSatisfy { feature in
            feature.playerRuntimePolicy.allowRuntimeScanning == false
                && feature.playerRuntimePolicy.failureMode == .failLoud
                && feature.playerRuntimePolicy.requiresBuildMatch
        })
    }

    func testV106710ManifestExposesOnlyReportVerifiedFeatures() {
        let manifest = DaveTrainerManifest.v106710
        let supportedFeatureIDs = Set(manifest.features.map(\.id))

        XCTAssertEqual(manifest.gameBuild.version, "v1.0.6.710.mac")
        XCTAssertEqual(manifest.gameBuild.buildGUID, "fd04739b28e64f148c3efcd479a839b8")
        XCTAssertEqual(
            manifest.moduleIdentity(id: DaveTrainerManifest.gameAssemblyModuleID)?.machoUUID,
            "266578BA-B451-313B-8326-CF241BB3FA5F"
        )
        XCTAssertEqual(supportedFeatureIDs, [
            .god,
            .oxygen,
            .ammo,
            .crabTraps,
            .weight,
            .swimSpeed,
            .drones,
            .stamina,
            .wasabi
        ])
        XCTAssertNil(manifest.feature(id: .divingGod))
        XCTAssertNil(manifest.feature(id: .damage))
        XCTAssertNotNil(manifest.feature(id: .swimSpeed))
        XCTAssertNil(manifest.feature(id: .gold))
    }

    func testV106710PatchCatalogKeepsStableEvidenceIDs() {
        let patches = DaveV106710StaticGamePatches.make()
        let points = patches.flatMap(\.points)
        let pointsByID = Dictionary(uniqueKeysWithValues: points.compactMap { point in
            point.targetID.map { ($0, point) }
        })

        XCTAssertEqual(patches.count, 8)
        XCTAssertEqual(points.count, 66)
        XCTAssertEqual(pointsByID.count, points.count)
        XCTAssertEqual(pointsByID["god.0"]?.rva, 0x0B85_378)
        XCTAssertEqual(pointsByID["ammo.5"]?.rva, 0x1B4E_A30)
        XCTAssertEqual(pointsByID["weight.13"]?.rva, 0x20A4_65C)
        XCTAssertEqual(pointsByID["wasabi.0"]?.rva, 0x2152_C68)
        XCTAssertTrue(points.allSatisfy { $0.trampoline == nil })
        XCTAssertTrue(points.allSatisfy { $0.patchBytes.count <= $0.expectedBytes.count })
    }

    func testV106710SpeedPatchUsesOnlyRelocatableReportVerifiedPoints() throws {
        let patch = try DaveV106710StaticGamePatches.makeValuePatch(
            id: "swimSpeed",
            valueText: "7"
        )

        XCTAssertEqual(patch.points.compactMap(\.targetID), [
            "swimSpeed.0",
            "swimSpeed.1",
            "swimSpeed.2",
            "swimSpeed.4",
            "swimSpeed.9",
            "swimSpeed.10"
        ])
        XCTAssertTrue(patch.points.allSatisfy { $0.trampoline == nil })
        XCTAssertTrue(patch.points.allSatisfy { $0.patchBytes.count <= $0.expectedBytes.count })
    }

    func testCurrentManifestDeclaresGameAssemblyModuleIdentity() throws {
        let module = try XCTUnwrap(DaveTrainerManifest.current.moduleIdentity(id: DaveTrainerManifest.gameAssemblyModuleID))

        XCTAssertEqual(module.id, DaveTrainerManifest.gameAssemblyModuleID)
        XCTAssertEqual(module.moduleName, "GameAssembly.dylib")
        XCTAssertEqual(module.architecture, "arm64")
        XCTAssertEqual(module.machoUUID, "7BA6FD17-58B4-31CC-A621-45EE26D462F9")
        XCTAssertEqual(module.pathMatchPolicy, "image-name")
    }

    func testKnownBaselineIdentityDoesNotDependOnInstallLocation() {
        let relocatedBuild = GameBuildSignature(
            identity: GameBuildIdentity(
                bundleID: KnownGameBuild.current.bundleID,
                version: KnownGameBuild.current.version,
                buildGUID: KnownGameBuild.current.buildGUID
            ),
            paths: GameBuildPaths(
                executablePath: "/Custom/SteamLibrary/DaveTheDiver.app/Contents/MacOS/DAVE THE DIVER",
                metadataPath: "/Custom/SteamLibrary/DaveTheDiver.app/Contents/Resources/Data/il2cpp_data/Metadata/global-metadata.dat"
            )
        )

        XCTAssertNotEqual(relocatedBuild, KnownGameBuild.current)
        XCTAssertTrue(relocatedBuild.isKnownBaseline)
    }

    func testStaticPatchManifestEntriesExposeExpectedPatchAndRestoreBytes() throws {
        let manifest = DaveTrainerManifest.current
        let staticFeatures = manifest.features.filter { $0.kind == .codePatch }

        XCTAssertFalse(staticFeatures.isEmpty)
        for feature in staticFeatures {
            XCTAssertFalse(feature.targets.isEmpty, "Missing targets for \(feature.id.rawValue)")
            for target in feature.targets {
                guard case .patchPoint(let point) = target else {
                    XCTFail("Expected patch point target for \(feature.id.rawValue)")
                    continue
                }
                XCTAssertEqual(point.moduleID, DaveTrainerManifest.gameAssemblyModuleID)
                XCTAssertFalse(point.expectedBytes.isEmpty, "Missing expected bytes for \(point.id)")
                XCTAssertFalse(point.restoreBytes.isEmpty, "Missing restore bytes for \(point.id)")
                XCTAssertEqual(point.restoreBytes, point.expectedBytes)
                XCTAssertTrue(point.patchBytes.isEmpty == point.usesTrampoline || !point.patchBytes.isEmpty)
            }
        }
    }

    func testResourceCapabilitiesDocumentRuntimeAndSavePlanes() throws {
        let manifest = DaveTrainerManifest.current
        let requiredIDs: Set<DaveTrainerFeatureID> = [
            .gold,
            .bei,
            .jungleGold,
            .artisan,
            .ingredients,
            .jungleIngredients,
            .seaPeopleVillageItems
        ]

        for featureID in requiredIDs {
            let feature = try XCTUnwrap(manifest.feature(id: featureID))
            guard case .inventoryResource = feature.kind else {
                XCTFail("Expected resource feature for \(featureID.rawValue)")
                continue
            }
            let capabilities = feature.targets.compactMap { target -> DaveResourceCapability? in
                if case .resourceCapability(let capability) = target {
                    return capability
                }
                return nil
            }
            XCTAssertFalse(capabilities.isEmpty, "Missing capability for \(featureID.rawValue)")
            XCTAssertTrue(capabilities.allSatisfy { !$0.runtimePlane.isEmpty && !$0.savePlane.isEmpty })
        }
    }

    func testSeaPeopleVillageCapabilityIsManifestBacked() throws {
        let feature = try XCTUnwrap(DaveTrainerManifest.current.feature(id: .seaPeopleVillageItems))

        XCTAssertEqual(feature.kind, .inventoryResource)
        XCTAssertFalse(feature.playerRuntimePolicy.allowRuntimeScanning)

        let capability = try XCTUnwrap(feature.targets.compactMap { target -> DaveResourceCapability? in
            if case .resourceCapability(let capability) = target {
                return capability
            }
            return nil
        }.first)
        XCTAssertEqual(capability.id, "seaPeopleVillageItems")
        XCTAssertEqual(capability.runtimePlane, "SaveDataJungle.IvenData")
        XCTAssertEqual(capability.savePlane, "SaveDataJungle.IvenData")
        XCTAssertFalse(capability.canCreateEntries)
        XCTAssertTrue(capability.modifiesExistingEntries)
    }
}
