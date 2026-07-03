import Foundation

public enum DaveTrainerOperationState: String, Codable, Sendable {
    case unsupportedBuild
    case targetMismatch
    case writeFailed
    case verifyFailed
    case bytesApplied
    case behaviorVerified
}

public struct DaveTrainerOperationResult: Equatable, Codable, Sendable {
    public let featureID: DaveTrainerFeatureID
    public let state: DaveTrainerOperationState
    public let targetIDs: [String]
    public let message: String

    public init(
        featureID: DaveTrainerFeatureID,
        state: DaveTrainerOperationState,
        targetIDs: [String],
        message: String
    ) {
        self.featureID = featureID
        self.state = state
        self.targetIDs = targetIDs
        self.message = message
    }

    public var isMemoryApplied: Bool {
        switch state {
        case .bytesApplied, .behaviorVerified:
            return true
        case .unsupportedBuild, .targetMismatch, .writeFailed, .verifyFailed:
            return false
        }
    }

    public var isBehaviorVerified: Bool {
        state == .behaviorVerified
    }
}
