import Foundation
import XCTest
@testable import TrainerCore

final class DaveV106756ProfileTests: XCTestCase {
    func testProfileKeepsUnverifiedFeaturesDisabled() throws {
        let manifest = DaveTrainerManifest.v106756
        XCTAssertEqual(manifest.gameBuild.version, "v1.0.6.756.mac")
        XCTAssertEqual(manifest.gameBuild.buildGUID, "1958d94b767741a5a13a2ae0032db743")
        XCTAssertEqual(manifest.moduleIdentity(id: DaveTrainerManifest.gameAssemblyModuleID)?.machoUUID,
                       "698AB592-0DAA-3787-9B22-43683C35F62B")
        XCTAssertEqual(Set(manifest.features.map(\.id)), [
            .god, .oxygen, .ammo, .crabTraps, .weight, .swimSpeed, .drones, .stamina, .wasabi
        ])
        XCTAssertTrue(manifest.features.allSatisfy {
            $0.playerRuntimePolicy.requiresBuildMatch && !$0.playerRuntimePolicy.allowRuntimeScanning
        })
        let patches = DaveV106756StaticGamePatches.make()
        let speed = try DaveV106756StaticGamePatches.makeValuePatch(id: "swimSpeed", valueText: "7")
        XCTAssertEqual(patches.flatMap(\.points).count, 66)
        XCTAssertEqual(speed.points.compactMap(\.targetID), [
            "swimSpeed.0", "swimSpeed.1", "swimSpeed.2", "swimSpeed.4", "swimSpeed.9", "swimSpeed.10"
        ])
        XCTAssertTrue((patches + [speed]).flatMap(\.points).allSatisfy {
            $0.trampoline == nil && $0.patchBytes.count <= $0.expectedBytes.count
        })
        XCTAssertThrowsError(try DaveV106756StaticGamePatches.makeValuePatch(id: "gold", valueText: "999"))
        XCTAssertThrowsError(try DaveV106756StaticGamePatches.makeValuePatch(id: "swimSpeed", valueText: "nan"))
    }

    // Optional read-only integration check. No binaries or diagnostic dumps are committed.
    func testInstalledV106756MatchesEveryReviewedByteWindow() throws {
        guard let path = ProcessInfo.processInfo.environment["DAVE_V106756_APP_PATH"] else {
            throw XCTSkip("Set DAVE_V106756_APP_PATH to the exact local v1.0.6.756 app bundle")
        }
        let app = URL(fileURLWithPath: path)
        let install = try GameInstallResolver().resolve(at: app)
        XCTAssertTrue(install.signature.matchesIdentity(of: KnownGameBuild.v106756))
        let patches = DaveV106756StaticGamePatches.make() + [
            try DaveV106756StaticGamePatches.makeValuePatch(id: "swimSpeed", valueText: "5")
        ]
        let points = patches.flatMap(\.points)
        let inspection = try MachOAnalyzer().inspectArm64(
            url: install.innerAppURL.appendingPathComponent("Contents/Frameworks/GameAssembly.dylib"),
            request: MachOBinaryInspectionRequest(
                symbolPrefixes: [],
                byteReads: points.map {
                    MachOByteReadRequest(id: $0.targetID!, rva: $0.rva, count: $0.expectedBytes.count)
                },
                symbolByteCount: 1
            )
        )
        XCTAssertEqual(inspection.uuid, "698AB592-0DAA-3787-9B22-43683C35F62B")
        XCTAssertEqual(inspection.byteReads.count, 72)
        let expected = Dictionary(uniqueKeysWithValues: points.map { ($0.targetID!, $0.expectedBytes) })
        for evidence in inspection.byteReads {
            guard case .bytes(let bytes) = evidence.result else {
                XCTFail("Unmapped target: \(evidence.request.id)")
                continue
            }
            XCTAssertEqual(bytes, expected[evidence.request.id], evidence.request.id)
        }
    }
}
