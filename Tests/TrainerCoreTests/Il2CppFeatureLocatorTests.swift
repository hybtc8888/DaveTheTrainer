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
}

private extension UInt32 {
    var isMethodToken: Bool {
        self & 0xFF00_0000 == 0x0600_0000
    }

    var isFieldToken: Bool {
        self & 0xFF00_0000 == 0x0400_0000
    }
}
