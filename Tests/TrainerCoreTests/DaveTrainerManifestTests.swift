import XCTest
@testable import TrainerCore

final class DaveTrainerManifestTests: XCTestCase {
    func testCurrentManifestUsesKnownDaveBuildAndDisablesPlayerRuntimeScanning() {
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

    func testCurrentManifestDeclaresGameAssemblyModuleIdentity() throws {
        let module = try XCTUnwrap(DaveTrainerManifest.current.moduleIdentity(id: DaveTrainerManifest.gameAssemblyModuleID))

        XCTAssertEqual(module.id, DaveTrainerManifest.gameAssemblyModuleID)
        XCTAssertEqual(module.moduleName, "GameAssembly.dylib")
        XCTAssertEqual(module.architecture, "arm64")
        XCTAssertEqual(module.machoUUID, "7BA6FD17-58B4-31CC-A621-45EE26D462F9")
        XCTAssertEqual(module.pathMatchPolicy, "image-name")
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
