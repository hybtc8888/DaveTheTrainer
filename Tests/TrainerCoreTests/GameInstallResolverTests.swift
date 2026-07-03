import XCTest
@testable import TrainerCore

final class GameInstallResolverTests: XCTestCase {
    func testInstalledDaveTheDiverBuildMatchesKnownSignature() throws {
        let resolver = GameInstallResolver()

        let install = try resolver.resolveInstalledGame()

        XCTAssertEqual(install.signature.bundleID, KnownGameBuild.current.bundleID)
        XCTAssertEqual(install.signature.version, KnownGameBuild.current.version)
        XCTAssertEqual(install.signature.buildGUID, KnownGameBuild.current.buildGUID)
        XCTAssertTrue(FileManager.default.fileExists(atPath: install.signature.executablePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: install.signature.metadataPath))
    }
}
