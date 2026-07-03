import XCTest
@testable import TrainerCore

final class SaveBackupServiceTests: XCTestCase {
    func testDefaultSaveDirectoryDoesNotHardcodeDeveloperHome() {
        let service = SaveBackupService(environment: [:])
        let fixedSteamAccountPattern = #"/SteamSData/[0-9]+"#

        XCTAssertNil(service.defaultSaveDirectory.path.range(of: fixedSteamAccountPattern, options: .regularExpression))
        XCTAssertTrue(service.defaultSaveDirectory.path.contains("Application Support/com.nexon.dave/SteamSData"))
    }

    func testSaveBackupServiceUsesInjectedSaveDirectory() {
        let directory = URL(fileURLWithPath: "/tmp/dave-save-fixture", isDirectory: true)
        let service = SaveBackupService(defaultSaveDirectory: directory, environment: [:])

        XCTAssertEqual(service.defaultSaveDirectory, directory)
    }

    func testSaveBackupServiceUsesEnvironmentOverride() {
        let directory = "/tmp/dave-save-env"
        let service = SaveBackupService(environment: [SaveBackupService.saveDirectoryEnvironmentKey: directory])

        XCTAssertEqual(service.defaultSaveDirectory.path, directory)
    }
}
