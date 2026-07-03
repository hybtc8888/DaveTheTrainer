import Foundation
import TrainerCore

struct TrainerOperationContext {
    let session: MemorySession
    let gameBuild: GameBuildSignature
}

enum TrainerOperationPayload {
    case staticPatch(patchID: String)
    case staticPatchGroup(patchIDs: [String])
    case valuePatch(patchID: String, valueText: String)
    case runtimeQuantity(resourceID: DaveTrainerFeatureID, valueText: String)
    case inventory(scope: IngredientsInventoryScope, valueText: String)
    case jungleInventory(scope: JungleDLCInventoryScope, valueText: String)
}

struct TrainerOperationRequest {
    let featureID: DaveTrainerFeatureID
    let isEnabled: Bool
    let payload: TrainerOperationPayload
}

private struct ValuePatchOperation {
    let patchID: String
    let valueText: String
    let request: TrainerOperationRequest
    let context: TrainerOperationContext
}

private struct OperationResultDraft {
    let featureID: DaveTrainerFeatureID
    let state: DaveTrainerOperationState
    let targets: [String]
    let message: String
}

protocol RuntimeQuantityIncrementing {
    func clearCachedAddresses()
    func increment(_ request: RuntimeQuantityIncrementRequest, session: RuntimeQuantityMemorySession) throws -> RuntimeQuantityIncrementResult
}

extension RuntimeQuantityIncrementer: RuntimeQuantityIncrementing {}

protocol IngredientsInventoryIncrementing {
    func clearCachedAddresses()
    func increment(_ request: IngredientsInventoryIncrementRequest, session: IngredientsInventoryMemorySession) throws -> IngredientsInventoryIncrementResult
}

extension IngredientsInventoryIncrementer: IngredientsInventoryIncrementing {}

protocol JungleIngredientsInventoryIncrementing {
    func clearCachedAddresses()
    func increment(_ request: JungleIngredientsInventoryIncrementRequest, session: JungleIngredientsInventoryMemorySession) throws -> JungleIngredientsInventoryIncrementResult
}

extension JungleIngredientsInventoryIncrementer: JungleIngredientsInventoryIncrementing {}

final class TrainerOperationService {
    struct Configuration {
        let manifest: DaveTrainerManifest
        let staticPatches: [String: StaticGamePatch]
        let applier: StaticPatchApplying
        let runtimeQuantityIncrementer: RuntimeQuantityIncrementing
        let ingredientsIncrementer: IngredientsInventoryIncrementing
        let jungleIngredientsIncrementer: JungleIngredientsInventoryIncrementing

        static func live() -> Configuration {
            let manifest = DaveTrainerManifest.current
            let patches = DefaultStaticGamePatches.make()
            let moduleResolver = MachOModuleResolver(
                expectedModuleIdentity: manifest.moduleIdentity(id: DaveTrainerManifest.gameAssemblyModuleID)
            )
            return Configuration(
                manifest: manifest,
                staticPatches: Dictionary(uniqueKeysWithValues: patches.map { ($0.id, $0) }),
                applier: StaticPatchEngine(moduleResolver: moduleResolver),
                runtimeQuantityIncrementer: RuntimeQuantityIncrementer(moduleResolver: moduleResolver),
                ingredientsIncrementer: IngredientsInventoryIncrementer(moduleResolver: moduleResolver),
                jungleIngredientsIncrementer: JungleIngredientsInventoryIncrementer(moduleResolver: moduleResolver)
            )
        }
    }

    private let manifest: DaveTrainerManifest
    private let staticPatches: [String: StaticGamePatch]
    private let applier: StaticPatchApplying
    private let runtimeQuantityIncrementer: RuntimeQuantityIncrementing
    private let ingredientsIncrementer: IngredientsInventoryIncrementing
    private let jungleIngredientsIncrementer: JungleIngredientsInventoryIncrementing
    private let transactionEngine: PatchTransactionEngine
    private var activeValuePatches: [String: StaticGamePatch] = [:]

    init(configuration: Configuration = .live()) {
        self.manifest = configuration.manifest
        self.staticPatches = configuration.staticPatches
        self.applier = configuration.applier
        self.runtimeQuantityIncrementer = configuration.runtimeQuantityIncrementer
        self.ingredientsIncrementer = configuration.ingredientsIncrementer
        self.jungleIngredientsIncrementer = configuration.jungleIngredientsIncrementer
        self.transactionEngine = PatchTransactionEngine(applier: configuration.applier)
    }

    func clearRuntimeCaches() {
        runtimeQuantityIncrementer.clearCachedAddresses()
        ingredientsIncrementer.clearCachedAddresses()
        jungleIngredientsIncrementer.clearCachedAddresses()
    }

    func apply(_ request: TrainerOperationRequest, context: TrainerOperationContext) throws -> DaveTrainerOperationResult {
        if let buildResult = buildGateResult(featureID: request.featureID, gameBuild: context.gameBuild) {
            return buildResult
        }

        guard let feature = manifest.feature(id: request.featureID) else {
            return result(OperationResultDraft(
                featureID: request.featureID,
                state: .targetMismatch,
                targets: [],
                message: "manifest 缺少功能：\(request.featureID.rawValue)。"
            ))
        }

        guard !feature.targets.isEmpty else {
            return result(OperationResultDraft(
                featureID: request.featureID,
                state: .targetMismatch,
                targets: [],
                message: "manifest 功能缺少目标：\(request.featureID.rawValue)。"
            ))
        }

        return try applyValidated(request, context: context, feature: feature)
    }

    func buildGateResult(featureID: DaveTrainerFeatureID, gameBuild: GameBuildSignature) -> DaveTrainerOperationResult? {
        guard gameBuild == manifest.gameBuild else {
            return result(OperationResultDraft(
                featureID: featureID,
                state: .unsupportedBuild,
                targets: [],
                message: "游戏版本不匹配。期望 \(manifest.gameBuild.version) / \(manifest.gameBuild.buildGUID)，实际 \(gameBuild.version) / \(gameBuild.buildGUID)。"
            ))
        }

        return nil
    }

    private func applyValidated(
        _ request: TrainerOperationRequest,
        context: TrainerOperationContext,
        feature: DaveTrainerManifestFeature
    ) throws -> DaveTrainerOperationResult {
        switch request.payload {
        case .staticPatch(let patchID):
            guard feature.kind == .codePatch else {
                return targetMismatchResult(featureID: request.featureID, message: "功能不是静态 patch：\(request.featureID.rawValue)。")
            }
            return applySinglePatch(patchID: patchID, request: request, context: context)
        case .staticPatchGroup(let patchIDs):
            guard feature.kind == .codePatch else {
                return targetMismatchResult(featureID: request.featureID, message: "功能不是静态 patch group：\(request.featureID.rawValue)。")
            }
            return applyPatchGroup(patchIDs: patchIDs, request: request, context: context)
        case .valuePatch(let patchID, let valueText):
            guard feature.kind == .codePatch else {
                return targetMismatchResult(featureID: request.featureID, message: "功能不是静态 value patch：\(request.featureID.rawValue)。")
            }
            return try applyValuePatch(ValuePatchOperation(
                patchID: patchID,
                valueText: valueText,
                request: request,
                context: context
            ))
        case .runtimeQuantity(let resourceID, let valueText):
            return applyRuntimeQuantity(resourceID: resourceID, valueText: valueText, request: request, context: context, feature: feature)
        case .inventory(let scope, let valueText):
            return applyInventory(scope: scope, valueText: valueText, request: request, context: context, feature: feature)
        case .jungleInventory(let scope, let valueText):
            return applyJungleInventory(scope: scope, valueText: valueText, request: request, context: context, feature: feature)
        }
    }

    private func applySinglePatch(
        patchID: String,
        request: TrainerOperationRequest,
        context: TrainerOperationContext
    ) -> DaveTrainerOperationResult {
        do {
            let patch = try requiredStaticPatch(id: patchID)
            return try transactionEngine.apply(PatchTransactionRequest(
                patches: [patch],
                isEnabled: request.isEnabled,
                featureID: request.featureID
            ), session: context.session)
        } catch {
            return failureResult(featureID: request.featureID, targets: [patchID], error: error)
        }
    }

    private func applyPatchGroup(
        patchIDs: [String],
        request: TrainerOperationRequest,
        context: TrainerOperationContext
    ) -> DaveTrainerOperationResult {
        do {
            let patches = try patchIDs.map(requiredStaticPatch)
            return try transactionEngine.apply(PatchTransactionRequest(
                patches: patches,
                isEnabled: request.isEnabled,
                featureID: request.featureID
            ), session: context.session)
        } catch {
            return failureResult(featureID: request.featureID, targets: patchIDs, error: error)
        }
    }

    private func applyValuePatch(_ operation: ValuePatchOperation) throws -> DaveTrainerOperationResult {
        let trimmedOperation = ValuePatchOperation(
            patchID: operation.patchID,
            valueText: operation.valueText.trimmingCharacters(in: .whitespacesAndNewlines),
            request: operation.request,
            context: operation.context
        )
        if operation.request.isEnabled {
            return try enableValuePatch(trimmedOperation)
        }
        return try disableValuePatch(trimmedOperation)
    }

    private func enableValuePatch(_ operation: ValuePatchOperation) throws -> DaveTrainerOperationResult {
        let patch = try DefaultStaticGamePatches.makeValuePatch(id: operation.patchID, valueText: operation.valueText)
        do {
            try restoreConflictingValuePatches(for: operation.patchID, session: operation.context.session)
            if let previousPatch = activeValuePatches[operation.patchID], previousPatch != patch {
                try applier.apply(StaticPatchApplyRequest(patch: previousPatch, isEnabled: false), session: operation.context.session)
            }
            try applier.apply(StaticPatchApplyRequest(patch: patch, isEnabled: true), session: operation.context.session)
            activeValuePatches[operation.patchID] = patch
            return result(OperationResultDraft(
                featureID: operation.request.featureID,
                state: .bytesApplied,
                targets: [patch.id],
                message: "已应用：\(patch.title) = \(operation.valueText)"
            ))
        } catch {
            return failureResult(featureID: operation.request.featureID, targets: [operation.patchID], error: error)
        }
    }

    private func disableValuePatch(_ operation: ValuePatchOperation) throws -> DaveTrainerOperationResult {
        let patch = try activeValuePatches[operation.patchID] ?? DefaultStaticGamePatches.makeValuePatch(id: operation.patchID, valueText: operation.valueText)
        do {
            try applier.apply(StaticPatchApplyRequest(patch: patch, isEnabled: false), session: operation.context.session)
            activeValuePatches[operation.patchID] = nil
            return result(OperationResultDraft(
                featureID: operation.request.featureID,
                state: .bytesApplied,
                targets: [patch.id],
                message: "已恢复：\(patch.title)"
            ))
        } catch {
            return failureResult(featureID: operation.request.featureID, targets: [operation.patchID], error: error)
        }
    }

    private func applyRuntimeQuantity(
        resourceID: DaveTrainerFeatureID,
        valueText: String,
        request: TrainerOperationRequest,
        context: TrainerOperationContext,
        feature: DaveTrainerManifestFeature
    ) -> DaveTrainerOperationResult {
        do {
            let capability = try resourceCapability(feature: feature, expectedID: resourceID.rawValue)
            guard request.featureID == resourceID else {
                throw TrainerError.targetMismatch("请求功能 \(request.featureID.rawValue) 与资源 \(resourceID.rawValue) 不一致。")
            }
            let delta = try Self.parseIncrementDelta(valueText)
            let incrementResult = try runtimeQuantityIncrementer.increment(
                RuntimeQuantityIncrementRequest(featureID: resourceID.rawValue, delta: delta),
                session: context.session
            )
            return resourceSuccessResult(
                featureID: request.featureID,
                capability: capability,
                message: "已验证调整 \(feature.title)：\(Self.formatDelta(delta))，更新 \(incrementResult.updatedAddressCount) 处运行时数量。"
            )
        } catch {
            return failureResult(featureID: request.featureID, targets: [resourceID.rawValue], error: error)
        }
    }

    private func applyInventory(
        scope: IngredientsInventoryScope,
        valueText: String,
        request: TrainerOperationRequest,
        context: TrainerOperationContext,
        feature: DaveTrainerManifestFeature
    ) -> DaveTrainerOperationResult {
        let expectedFeatureID = scope.daveTrainerFeatureID
        do {
            let capability = try resourceCapability(feature: feature, expectedID: expectedFeatureID.rawValue)
            guard request.featureID == expectedFeatureID else {
                throw TrainerError.targetMismatch("请求功能 \(request.featureID.rawValue) 与库存范围 \(expectedFeatureID.rawValue) 不一致。")
            }
            let delta = try Self.parseIncrementDelta(valueText)
            let incrementResult = try ingredientsIncrementer.increment(
                IngredientsInventoryIncrementRequest(scope: scope, delta: delta),
                session: context.session
            )
            return resourceSuccessResult(
                featureID: request.featureID,
                capability: capability,
                message: "已验证调整 \(feature.title)：\(Self.formatDelta(delta))，更新 \(incrementResult.updatedItemCount) 项。"
            )
        } catch {
            return failureResult(featureID: request.featureID, targets: [expectedFeatureID.rawValue], error: error)
        }
    }

    private func applyJungleInventory(
        scope: JungleDLCInventoryScope,
        valueText: String,
        request: TrainerOperationRequest,
        context: TrainerOperationContext,
        feature: DaveTrainerManifestFeature
    ) -> DaveTrainerOperationResult {
        let expectedFeatureID = scope.daveTrainerFeatureID
        do {
            let capability = try resourceCapability(feature: feature, expectedID: expectedFeatureID.rawValue)
            guard request.featureID == expectedFeatureID else {
                throw TrainerError.targetMismatch("请求功能 \(request.featureID.rawValue) 与丛林库存范围 \(expectedFeatureID.rawValue) 不一致。")
            }
            let delta = try Self.parseIncrementDelta(valueText)
            let incrementResult = try jungleIngredientsIncrementer.increment(
                JungleIngredientsInventoryIncrementRequest(delta: delta, scope: scope),
                session: context.session
            )
            return resourceSuccessResult(
                featureID: request.featureID,
                capability: capability,
                message: "已验证调整 \(feature.title)：\(Self.formatDelta(delta))，更新 \(incrementResult.updatedItemCount) 项。"
            )
        } catch {
            return failureResult(featureID: request.featureID, targets: [expectedFeatureID.rawValue], error: error)
        }
    }

    private func resourceCapability(feature: DaveTrainerManifestFeature, expectedID: String) throws -> DaveResourceCapability {
        guard feature.kind == .inventoryResource || feature.kind == .runtimeValue else {
            throw TrainerError.targetMismatch("功能不是资源 capability：\(feature.id.rawValue)。")
        }
        guard let capability = feature.targets.compactMap(Self.resourceCapabilityTarget).first else {
            throw TrainerError.targetMismatch("manifest 缺少资源 capability：\(feature.id.rawValue)。")
        }
        guard capability.id == expectedID else {
            throw TrainerError.targetMismatch("资源 capability 不匹配。期望 \(expectedID)，实际 \(capability.id)。")
        }
        return capability
    }

    private static func resourceCapabilityTarget(_ target: DaveTrainerManifestTarget) -> DaveResourceCapability? {
        if case .resourceCapability(let capability) = target {
            return capability
        }
        return nil
    }

    private func resourceSuccessResult(
        featureID: DaveTrainerFeatureID,
        capability: DaveResourceCapability,
        message: String
    ) -> DaveTrainerOperationResult {
        result(OperationResultDraft(
            featureID: featureID,
            state: .behaviorVerified,
            targets: [capability.id],
            message: message
        ))
    }

    private func restoreConflictingValuePatches(for patchID: String, session: MemorySession) throws {
        guard Self.inventoryValuePatchGroup.contains(patchID) else {
            return
        }

        for conflictingID in Self.inventoryValuePatchGroup where conflictingID != patchID && activeValuePatches[conflictingID] != nil {
            guard let activePatch = activeValuePatches[conflictingID] else {
                throw TrainerError.invalidInput("库存 patch 状态不一致：\(conflictingID) 已标记开启，但缺少可恢复的活动补丁。")
            }

            try applier.apply(StaticPatchApplyRequest(patch: activePatch, isEnabled: false), session: session)
            activeValuePatches[conflictingID] = nil
        }
    }

    private func requiredStaticPatch(id: String) throws -> StaticGamePatch {
        guard let patch = staticPatches[id] else {
            throw TrainerError.invalidInput("未知静态 patch：\(id)")
        }
        return patch
    }

    private func failureResult(
        featureID: DaveTrainerFeatureID,
        targets: [String],
        error: Error
    ) -> DaveTrainerOperationResult {
        let state: DaveTrainerOperationState
        if case TrainerError.targetMismatch = error {
            state = .targetMismatch
        } else if case TrainerError.verifyFailed = error {
            state = .verifyFailed
        } else {
            state = .writeFailed
        }

        return result(OperationResultDraft(
            featureID: featureID,
            state: state,
            targets: targets,
            message: error.localizedDescription
        ))
    }

    private func targetMismatchResult(featureID: DaveTrainerFeatureID, message: String) -> DaveTrainerOperationResult {
        result(OperationResultDraft(
            featureID: featureID,
            state: .targetMismatch,
            targets: [],
            message: message
        ))
    }

    private func result(_ draft: OperationResultDraft) -> DaveTrainerOperationResult {
        DaveTrainerOperationResult(
            featureID: draft.featureID,
            state: draft.state,
            targetIDs: draft.targets,
            message: draft.message
        )
    }

    private static func parseIncrementDelta(_ text: String) throws -> Int64 {
        let trimmedValue = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let delta = Int64(trimmedValue) else {
            throw TrainerError.invalidInput("调整数量必须是整数。")
        }
        return delta
    }

    private static func formatDelta(_ delta: Int64) -> String {
        delta >= 0 ? "+\(delta)" : String(delta)
    }

    private static let inventoryValuePatchGroup: Set<String> = [
        "materials",
        "fishIngredients",
        "vegetableIngredients",
        "seasoningIngredients",
        "upgradeMaterials"
    ]
}

private extension IngredientsInventoryScope {
    var daveTrainerFeatureID: DaveTrainerFeatureID {
        switch self {
        case .all:
            return .ingredients
        case .fish:
            return .fishIngredients
        case .vegetable:
            return .vegetableIngredients
        case .seasoning:
            return .seasoningIngredients
        case .upgrade:
            return .upgradeMaterials
        }
    }
}

private extension JungleDLCInventoryScope {
    var daveTrainerFeatureID: DaveTrainerFeatureID {
        switch self {
        case .ingredientsAndVillageItems, .ingredients:
            return .jungleIngredients
        case .villageItems:
            return .seaPeopleVillageItems
        }
    }
}
