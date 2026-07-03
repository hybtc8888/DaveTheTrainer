import Foundation

public protocol StaticPatchApplying {
    func preflight(_ request: StaticPatchApplyRequest, session: MemorySession) throws
    func apply(_ request: StaticPatchApplyRequest, session: MemorySession) throws
}

extension StaticPatchEngine: StaticPatchApplying {}

public struct PatchTransactionRequest: Sendable {
    public let patches: [StaticGamePatch]
    public let isEnabled: Bool
    public let featureID: DaveTrainerFeatureID

    public init(patches: [StaticGamePatch], isEnabled: Bool, featureID: DaveTrainerFeatureID) {
        self.patches = patches
        self.isEnabled = isEnabled
        self.featureID = featureID
    }
}

public final class PatchTransactionEngine {
    private let applier: StaticPatchApplying

    public init(applier: StaticPatchApplying = StaticPatchEngine()) {
        self.applier = applier
    }

    @discardableResult
    public func apply(_ request: PatchTransactionRequest, session: MemorySession) throws -> DaveTrainerOperationResult {
        guard !request.patches.isEmpty else {
            throw TrainerError.invalidInput("Patch transaction cannot be empty.")
        }

        let targetPatches = Self.patchPointPatches(for: request.patches)
        guard !targetPatches.isEmpty else {
            throw TrainerError.invalidInput("Patch transaction cannot contain patches without points.")
        }

        for patch in targetPatches {
            try applier.preflight(StaticPatchApplyRequest(patch: patch, isEnabled: request.isEnabled), session: session)
        }

        var applied: [StaticGamePatch] = []
        do {
            for patch in targetPatches {
                try applier.apply(StaticPatchApplyRequest(patch: patch, isEnabled: request.isEnabled), session: session)
                applied.append(patch)
            }
        } catch {
            try rollback(RollbackContext(
                patches: Array(applied.reversed()),
                request: request,
                session: session,
                originalError: error
            ))
            throw error
        }

        return DaveTrainerOperationResult(
            featureID: request.featureID,
            state: .bytesApplied,
            targetIDs: targetPatches.map(\.id),
            message: request.isEnabled ? "Patch transaction applied." : "Patch transaction restored."
        )
    }

    private static func patchPointPatches(for patches: [StaticGamePatch]) -> [StaticGamePatch] {
        patches.flatMap { patch in
            patch.points.enumerated().map { index, point in
                StaticGamePatch(
                    id: "\(patch.id).\(index)",
                    title: "\(patch.title) #\(index)",
                    points: [point]
                )
            }
        }
    }

    private func rollback(_ context: RollbackContext) throws {
        var rollbackFailures: [String] = []
        for patch in context.patches {
            do {
                try applier.apply(StaticPatchApplyRequest(patch: patch, isEnabled: !context.request.isEnabled), session: context.session)
            } catch {
                rollbackFailures.append("\(patch.id): \(error.localizedDescription)")
            }
        }

        guard rollbackFailures.isEmpty else {
            throw TrainerError.memoryWriteFailed(
                "Patch transaction for \(context.request.featureID.rawValue) failed and rollback also failed: \(rollbackFailures.joined(separator: "; ")). Original error: \(context.originalError.localizedDescription)"
            )
        }
    }
}

private struct RollbackContext {
    let patches: [StaticGamePatch]
    let request: PatchTransactionRequest
    let session: MemorySession
    let originalError: Error
}
