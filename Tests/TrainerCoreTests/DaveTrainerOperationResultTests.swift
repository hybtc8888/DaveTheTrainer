import XCTest
@testable import TrainerCore

final class DaveTrainerOperationResultTests: XCTestCase {
    func testOperationResultSeparatesBytesAppliedFromBehaviorVerified() {
        let bytesApplied = DaveTrainerOperationResult(
            featureID: .damage,
            state: .bytesApplied,
            targetIDs: ["damage.fish-ai"],
            message: "bytes"
        )
        let behaviorVerified = DaveTrainerOperationResult(
            featureID: .damage,
            state: .behaviorVerified,
            targetIDs: ["damage.fish-ai"],
            message: "verified"
        )

        XCTAssertTrue(bytesApplied.isMemoryApplied)
        XCTAssertFalse(bytesApplied.isBehaviorVerified)
        XCTAssertTrue(behaviorVerified.isMemoryApplied)
        XCTAssertTrue(behaviorVerified.isBehaviorVerified)
    }

    func testOperationResultFailuresAreNotSuccessfulWrites() {
        let failures: [DaveTrainerOperationState] = [
            .unsupportedBuild,
            .targetMismatch,
            .writeFailed,
            .verifyFailed
        ]

        for state in failures {
            let result = DaveTrainerOperationResult(
                featureID: .oxygen,
                state: state,
                targetIDs: [],
                message: state.rawValue
            )
            XCTAssertFalse(result.isMemoryApplied, "\(state.rawValue) must not count as applied")
            XCTAssertFalse(result.isBehaviorVerified, "\(state.rawValue) must not count as verified")
        }
    }
}
