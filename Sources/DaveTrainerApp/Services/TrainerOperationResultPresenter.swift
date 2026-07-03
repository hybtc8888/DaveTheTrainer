import Foundation
import TrainerCore

struct TrainerOperationResultPresentation: Equatable {
    let featureID: DaveTrainerFeatureID
    let state: DaveTrainerOperationState
    let targetIDs: [String]
    let message: String
    let isError: Bool

    var logMessage: String {
        let targets = targetIDs.isEmpty ? "none" : targetIDs.joined(separator: ",")
        return "[\(state.rawValue)] \(featureID.rawValue) targets=\(targets): \(message)"
    }
}

enum TrainerOperationResultPresenter {
    static func presentation(for result: DaveTrainerOperationResult) -> TrainerOperationResultPresentation {
        TrainerOperationResultPresentation(
            featureID: result.featureID,
            state: result.state,
            targetIDs: result.targetIDs,
            message: result.message,
            isError: !result.isMemoryApplied
        )
    }
}
