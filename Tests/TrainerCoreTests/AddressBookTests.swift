import XCTest
@testable import TrainerCore

final class AddressBookTests: XCTestCase {
    func testAddressBookRejectsMismatchedBuild() throws {
        let expected = KnownGameBuild.current
        let actual = GameBuildSignature(
            identity: GameBuildIdentity(
                bundleID: expected.bundleID,
                version: "different",
                buildGUID: expected.buildGUID
            ),
            paths: GameBuildPaths(
                executablePath: expected.executablePath,
                metadataPath: expected.metadataPath
            )
        )
        let book = AddressBook(build: actual, entries: [:])

        XCTAssertThrowsError(try book.entry(for: "gold", expectedBuild: expected)) { error in
            XCTAssertTrue(error.localizedDescription.contains("游戏版本不匹配"))
        }
    }

    func testAddressBookReturnsEntryForCurrentBuild() throws {
        let details = AddressEntryDetails(address: 0x1234, valueKind: .int64, note: "test")
        let entry = AddressEntry(featureID: "gold", details: details)
        let book = AddressBook(build: KnownGameBuild.current, entries: ["gold": entry])

        XCTAssertEqual(try book.entry(for: "gold", expectedBuild: KnownGameBuild.current), entry)
    }
}
