import Foundation
import XCTest
@testable import TrainerCore

final class DaveCompatibilityReportTests: XCTestCase {
    func testReportContainsTargetedEvidenceWithoutPrivatePathsOrFullSymbols() throws {
        let patch = Self.patch()
        let build = Self.reporterBuild()
        let generator = DaveCompatibilityReportGenerator(
            machOInspector: FakeCompatibilityMachOInspector(uuid: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"),
            metadataAnalyzer: FakeCompatibilityMetadataAnalyzer(),
            fileFingerprinter: FakeCompatibilityFileFingerprinter()
        )

        let report = try generator.generate(DaveCompatibilityReportRequest(
            build: build,
            trainer: DaveTrainerReleaseIdentity(version: "0.1.3", build: "4", commit: "abc123"),
            profile: DaveCompatibilityProfile(manifest: .current, patches: [patch])
        ))

        XCTAssertFalse(report.context.baseline.matchesDetectedBuild)
        XCTAssertEqual(report.schemaVersion, "1.1")
        XCTAssertEqual(report.context.detected.build.version, "v1.0.6.710.mac")
        XCTAssertEqual(report.patches.first?.evidence.observation.bytes, "AA BB CC DD EE FF 00 11")
        XCTAssertEqual(report.patches.first?.evidence.symbolDiscovery?.prefix, "_PlayerCharacter_SetHPDamage_m")
        XCTAssertEqual(report.patches.first?.evidence.symbolDiscovery?.candidates.first?.rva, "0xC0FFEE")
        XCTAssertEqual(
            report.patches.first?.evidence.symbolDiscovery?.candidates.first?.matchingExpectedRVAs,
            ["0xC0FFFE"]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(report), as: UTF8.self)
        XCTAssertFalse(json.contains("/Users/reporter"))
        XCTAssertFalse(json.contains("76561198000000000"))
        XCTAssertFalse(json.contains("_PlayerCharacter_SetHPDamage_mPRIVATEHASH"))
        XCTAssertTrue(json.contains("v1.0.6.710.mac"))
    }

    func testRelocatedBaselineMatchesProfileIdentityAndModuleUUID() throws {
        let relocated = GameBuildSignature(
            identity: GameBuildIdentity(
                bundleID: KnownGameBuild.current.bundleID,
                version: KnownGameBuild.current.version,
                buildGUID: KnownGameBuild.current.buildGUID
            ),
            paths: GameBuildPaths(
                executablePath: "/Volumes/Games/DaveTheDiver.app/Contents/MacOS/DAVE THE DIVER",
                metadataPath: "/Volumes/Games/DaveTheDiver.app/Contents/Resources/Data/il2cpp_data/Metadata/global-metadata.dat"
            )
        )
        let uuid = DaveTrainerManifest.current
            .moduleIdentity(id: DaveTrainerManifest.gameAssemblyModuleID)?
            .machoUUID
        let generator = DaveCompatibilityReportGenerator(
            machOInspector: FakeCompatibilityMachOInspector(uuid: uuid),
            metadataAnalyzer: FakeCompatibilityMetadataAnalyzer(),
            fileFingerprinter: FakeCompatibilityFileFingerprinter()
        )

        let report = try generator.generate(DaveCompatibilityReportRequest(
            build: relocated,
            trainer: DaveTrainerReleaseIdentity(version: "0.1.3", build: "4", commit: "abc123"),
            profile: DaveCompatibilityProfile(manifest: .current, patches: [Self.patch()])
        ))

        XCTAssertTrue(report.context.baseline.matchesDetectedBuild)
    }

    func testCurrentProfileIncludesRepresentativeValuePatchEvidence() {
        let patches = DaveCompatibilityProfile.current.patches
        let patchIDs = patches.map(\.id)

        XCTAssertEqual(Set(patchIDs).count, patchIDs.count)
        XCTAssertTrue(Set(["swimSpeed", "gold", "bei", "jungleGold", "materials", "artisan"]).isSubset(of: patchIDs))
        XCTAssertGreaterThan(patches.flatMap(\.points).count, DefaultStaticGamePatches.make().flatMap(\.points).count)
    }

    private static func patch() -> StaticGamePatch {
        StaticGamePatch(
            id: "god",
            title: "God",
            points: [
                StaticPatchPoint(
                    rva: 0xB82130,
                    expectedBytes: [0xFF, 0xC3, 0x01, 0xD1, 0xEB, 0x2B, 0x02, 0x6D],
                    patchBytes: [0xC0, 0x03, 0x5F, 0xD6],
                    note: "PlayerCharacter_SetHPDamage -> ret"
                )
            ]
        )
    }

    private static func reporterBuild() -> GameBuildSignature {
        GameBuildSignature(
            identity: GameBuildIdentity(
                bundleID: KnownGameBuild.current.bundleID,
                version: "v1.0.6.710.mac",
                buildGUID: "reporter-build-guid"
            ),
            paths: GameBuildPaths(
                executablePath: "/Users/reporter/Library/Application Support/Steam/steamapps/common/DAVE THE DIVER/DaveTheDiver.app/Contents/MacOS/DAVE THE DIVER",
                metadataPath: "/Users/reporter/Library/Application Support/Steam/userdata/76561198000000000/global-metadata.dat"
            )
        )
    }
}

private struct FakeCompatibilityMachOInspector: CompatibilityMachOInspecting {
    let uuid: String?

    func inspectArm64(
        url: URL,
        request: MachOBinaryInspectionRequest
    ) throws -> MachOBinaryInspection {
        let reads = request.byteReads.map { read in
            MachOByteReadEvidence(
                request: read,
                result: .bytes([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11])
            )
        }
        let symbol = MachOSymbol(
            name: "_PlayerCharacter_SetHPDamage_mPRIVATEHASH",
            address: 0xC0FFEE,
            type: 0x0E,
            sectionIndex: 1
        )
        var symbolBytes = Array(repeating: UInt8(0x42), count: request.symbolByteCount)
        symbolBytes.replaceSubrange(16..<24, with: [0xFF, 0xC3, 0x01, 0xD1, 0xEB, 0x2B, 0x02, 0x6D])
        let symbolRead = MachOSymbolReadEvidence(
            symbol: symbol,
            result: .bytes(symbolBytes)
        )
        let symbols = Dictionary(uniqueKeysWithValues: request.symbolPrefixes.map { ($0, [symbolRead]) })
        return MachOBinaryInspection(uuid: uuid, byteReads: reads, symbolsByPrefix: symbols)
    }
}

private struct FakeCompatibilityMetadataAnalyzer: CompatibilityMetadataAnalyzing {
    func analyze(metadataURL: URL, targetNames: [String]) throws -> Il2CppMetadataAnalysis {
        let emptyRange = Il2CppMetadataRange(offset: 0, size: 0)
        return Il2CppMetadataAnalysis(
            header: Il2CppMetadataHeader(
                version: 31,
                stringTable: emptyRange,
                methodDefinitions: emptyRange,
                fieldDefinitions: emptyRange
            ),
            matches: [:]
        )
    }
}

private struct FakeCompatibilityFileFingerprinter: CompatibilityFileFingerprinting {
    func fingerprint(url: URL) throws -> DaveCompatibilityFileIdentity {
        DaveCompatibilityFileIdentity(
            name: url.lastPathComponent,
            byteCount: 1024,
            sha256: String(repeating: "a", count: 64)
        )
    }
}
