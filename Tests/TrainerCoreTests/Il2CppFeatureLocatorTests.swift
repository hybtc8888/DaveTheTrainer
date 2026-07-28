import XCTest
@testable import TrainerCore

final class Il2CppFeatureLocatorTests: XCTestCase {
    func testMetadataAnalyzerFindsKnownOxygenAndAmmoNames() throws {
        let analyzer = Il2CppMetadataAnalyzer()
        let analysis = try analyzer.analyze(
            metadataURL: URL(fileURLWithPath: KnownGameBuild.current.metadataPath),
            targetNames: ["curOxygen", "UpdateOxygen", "Event_OnUseAmmo"]
        )

        XCTAssertEqual(analysis.header.version, 31)
        XCTAssertEqual(analysis.matches["curOxygen"]?.field?.token.isFieldToken, true)
        XCTAssertEqual(analysis.matches["UpdateOxygen"]?.method?.token.isMethodToken, true)
        XCTAssertEqual(analysis.matches["Event_OnUseAmmo"]?.method?.token.isMethodToken, true)
    }

    func testMachOAnalyzerFindsArm64Il2CppRegistrationSymbols() throws {
        let locator = Il2CppStaticFeatureLocator()
        let analyzer = MachOAnalyzer()
        let analysis = try analyzer.analyzeArm64(
            url: locator.gameAssemblyURL(for: KnownGameBuild.current),
            targetSymbols: ["_g_CodeRegistration", "_g_MetadataRegistration", "_g_CodeGenModules"]
        )

        XCTAssertNotNil(analysis.uuid)
        XCTAssertEqual(analysis.symbols["_g_CodeRegistration"]?.isEmpty, false)
        XCTAssertEqual(analysis.symbols["_g_MetadataRegistration"]?.isEmpty, false)
        XCTAssertEqual(analysis.symbols["_g_CodeGenModules"]?.isEmpty, false)
    }

    func testStaticFeatureLocatorMatchesKnownBuildFeatures() throws {
        let report = try Il2CppStaticFeatureLocator().locate(build: KnownGameBuild.current)
        let matched = Dictionary(uniqueKeysWithValues: report.features.map { ($0.featureID, $0.status) })

        XCTAssertEqual(report.metadataVersion, 31)
        XCTAssertEqual(matched["oxygen"], .matched)
        XCTAssertEqual(matched["ammo"], .matched)
        XCTAssertEqual(matched["gold"], .matched)
    }

    func testMachOInspectionFindsManifestBytesAndMethodSymbolCandidate() throws {
        let point = try XCTUnwrap(
            DefaultStaticGamePatches.make()
                .first { $0.id == "god" }?
                .points.first
        )
        let prefix = "_PlayerCharacter_SetHPDamage_m"
        let request = MachOBinaryInspectionRequest(
            symbolPrefixes: [prefix],
            byteReads: [
                MachOByteReadRequest(id: "god.0", rva: point.rva, count: point.expectedBytes.count)
            ],
            symbolByteCount: 32
        )

        let inspection = try MachOAnalyzer().inspectArm64(
            url: Il2CppStaticFeatureLocator().gameAssemblyURL(for: KnownGameBuild.current),
            request: request
        )

        XCTAssertEqual(inspection.uuid, "7BA6FD17-58B4-31CC-A621-45EE26D462F9")
        XCTAssertEqual(inspection.byteReads.first?.result, .bytes(point.expectedBytes))
        XCTAssertTrue(inspection.symbolsByPrefix[prefix]?.contains { $0.symbol.address == point.rva } == true)
    }

    func testCompatibilityReportMatchesInstalledBaselineWithoutPaths() throws {
        let report = try DaveCompatibilityReportGenerator().generate(DaveCompatibilityReportRequest(
            build: KnownGameBuild.current,
            trainer: DaveTrainerReleaseIdentity(version: "test", build: "test", commit: "test"),
            profile: .current
        ))

        XCTAssertTrue(report.context.baseline.matchesDetectedBuild)
        XCTAssertFalse(report.patches.isEmpty)
        let godPoint = try XCTUnwrap(report.patches.first { $0.target.pointID == "god.0" })
        XCTAssertEqual(godPoint.evidence.baseline.expected, godPoint.evidence.observation.bytes)
        let mismatchedPoints = report.patches.filter {
            $0.evidence.baseline.expected != $0.evidence.observation.bytes
        }
        XCTAssertEqual(mismatchedPoints.map(\.target.pointID), [])
        let locatedSymbolCount = report.patches.filter {
            $0.evidence.symbolDiscovery?.candidates.isEmpty == false
        }.count
        XCTAssertGreaterThan(locatedSymbolCount, 50)

        let json = String(decoding: try JSONEncoder().encode(report), as: UTF8.self)
        XCTAssertFalse(json.contains(KnownGameBuild.current.executablePath))
        XCTAssertFalse(json.contains(KnownGameBuild.current.metadataPath))
    }
}

private extension UInt32 {
    var isMethodToken: Bool {
        self & 0xFF00_0000 == 0x0600_0000
    }

    var isFieldToken: Bool {
        self & 0xFF00_0000 == 0x0400_0000
    }
}
