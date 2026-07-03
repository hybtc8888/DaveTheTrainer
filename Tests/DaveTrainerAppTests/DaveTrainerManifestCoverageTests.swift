import XCTest
import TrainerCore
@testable import DaveTheTrainer

final class DaveTrainerManifestCoverageTests: XCTestCase {
    func testManifestCoversEveryDefaultPlayerOption() {
        let manifestIDs = Set(DaveTrainerManifest.current.features.map(\.id.rawValue))
        let optionIDs = Set(SimpleTrainerOptions.allPlayerOptions.map(\.manifestFeatureID))

        XCTAssertEqual(optionIDs.subtracting(manifestIDs), [])
    }

    func testDefaultPlayerOptionsDoNotUseRuntimeScanningActions() {
        XCTAssertTrue(SimpleTrainerOptions.allPlayerOptions.allSatisfy { option in
            switch option.action {
            case .write, .freeze:
                return false
            case .increment, .incrementInventory, .incrementJungleInventory, .patch, .patchGroup, .valuePatch:
                return true
            case .unavailable:
                return false
            }
        })
    }
}
