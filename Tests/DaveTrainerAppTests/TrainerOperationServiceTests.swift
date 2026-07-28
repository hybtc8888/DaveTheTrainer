import XCTest
import TrainerCore
@testable import DaveTheTrainer

final class TrainerOperationServiceTests: XCTestCase {
    func testUnknownBuildStaticPatchReturnsUnsupportedWithoutWritingMemory() throws {
        let applier = RecordingTrainerOperationApplier()
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .god, isEnabled: true, payload: .staticPatch(patchID: "god")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: Self.unsupportedBuild)
        )

        XCTAssertEqual(result.state, .unsupportedBuild)
        XCTAssertTrue(result.message.contains("导出兼容报告"))
        XCTAssertTrue(applier.preflightRequests.isEmpty)
        XCTAssertTrue(applier.requests.isEmpty)
    }

    func testUnknownManifestFeatureReturnsTargetMismatchWithoutWritingMemory() throws {
        let applier = RecordingTrainerOperationApplier()
        let manifest = DaveTrainerManifest(schemaVersion: "1.0", gameBuild: KnownGameBuild.current, features: [])
        let service = TrainerOperationService(configuration: .test(manifest: manifest, applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .god, isEnabled: true, payload: .staticPatch(patchID: "god")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .targetMismatch)
        XCTAssertTrue(applier.requests.isEmpty)
    }

    func testStaticPatchOutsideManifestFeatureReturnsTargetMismatchWithoutWritingMemory() throws {
        let applier = RecordingTrainerOperationApplier()
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .god, isEnabled: true, payload: .staticPatch(patchID: "oxygen")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .targetMismatch)
        XCTAssertTrue(applier.preflightRequests.isEmpty)
        XCTAssertTrue(applier.requests.isEmpty)
    }

    func testPatchGroupOutsideManifestFeatureReturnsTargetMismatchWithoutWritingMemory() throws {
        let applier = RecordingTrainerOperationApplier()
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(
                featureID: .divingGod,
                isEnabled: true,
                payload: .staticPatchGroup(patchIDs: ["god", "oxygen", "swimSpeed"])
            ),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .targetMismatch)
        XCTAssertTrue(applier.preflightRequests.isEmpty)
        XCTAssertTrue(applier.requests.isEmpty)
    }

    func testValuePatchOutsideManifestFeatureReturnsTargetMismatchWithoutWritingMemory() throws {
        let applier = RecordingTrainerOperationApplier()
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .god, isEnabled: true, payload: .valuePatch(patchID: "swimSpeed", valueText: "6")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .targetMismatch)
        XCTAssertTrue(applier.preflightRequests.isEmpty)
        XCTAssertTrue(applier.requests.isEmpty)
    }

    func testPatchGroupFailureRollsBackAndReturnsWriteFailedResult() throws {
        let applier = RecordingTrainerOperationApplier(failingPatchID: "oxygen.0", failingEnabledState: true)
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(
                featureID: .divingGod,
                isEnabled: true,
                payload: .staticPatchGroup(patchIDs: ["god", "oxygen", "ammo"])
            ),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .writeFailed)
        XCTAssertFalse(result.isMemoryApplied)
        XCTAssertEqual(applier.requests.map(\.patch.id), ["god.0", "oxygen.0", "god.0"])
        XCTAssertEqual(applier.requests.map(\.isEnabled), [true, true, false])
    }

    func testPatchGroupSuccessReturnsBytesAppliedResult() throws {
        let applier = RecordingTrainerOperationApplier()
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(
                featureID: .divingGod,
                isEnabled: true,
                payload: .staticPatchGroup(patchIDs: ["god", "oxygen"])
            ),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .bytesApplied)
        XCTAssertEqual(result.targetIDs, ["god.0", "oxygen.0"])
        XCTAssertTrue(result.isMemoryApplied)
    }

    func testPatchGroupPreflightTargetMismatchReturnsTargetMismatchResult() throws {
        let applier = RecordingTrainerOperationApplier(
            preflightError: TrainerError.targetMismatch("forced target mismatch")
        )
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(
                featureID: .divingGod,
                isEnabled: true,
                payload: .staticPatchGroup(patchIDs: ["god", "oxygen"])
            ),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .targetMismatch)
        XCTAssertFalse(result.isMemoryApplied)
        XCTAssertEqual(applier.requests.map(\.patch.id), [])
    }

    func testSinglePatchVerifyFailureReturnsVerifyFailedResult() throws {
        let applier = RecordingTrainerOperationApplier(
            failingPatchID: "god.0",
            failingEnabledState: true,
            applyError: TrainerError.verifyFailed("forced verify failure")
        )
        let service = TrainerOperationService(configuration: .test(applier: applier))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .god, isEnabled: true, payload: .staticPatch(patchID: "god")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .verifyFailed)
        XCTAssertFalse(result.isMemoryApplied)
    }

    func testSinglePatchFailureRollsBackPreviouslyAppliedPatchPoint() throws {
        let applier = RecordingTrainerOperationApplier(failingPatchID: "multiGod.1", failingEnabledState: true)
        let service = TrainerOperationService(configuration: .test(
            manifest: Self.manifest(featureID: .god, patchID: "multiGod"),
            applier: applier
        ))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .god, isEnabled: true, payload: .staticPatch(patchID: "multiGod")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .writeFailed)
        XCTAssertFalse(result.isMemoryApplied)
        XCTAssertEqual(applier.requests.map(\.patch.id), ["multiGod.0", "multiGod.1", "multiGod.0"])
        XCTAssertEqual(applier.requests.map(\.isEnabled), [true, true, false])
    }

    func testGoldIncrementUsesManifestCapabilityAndReturnsBehaviorVerified() throws {
        let runtimeIncrementer = RecordingRuntimeQuantityIncrementer(result: RuntimeQuantityIncrementResult(updatedAddressCount: 1))
        let service = TrainerOperationService(configuration: .test(
            applier: RecordingTrainerOperationApplier(),
            runtimeQuantityIncrementer: runtimeIncrementer
        ))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .gold, isEnabled: true, payload: .runtimeQuantity(resourceID: .gold, valueText: "99")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .behaviorVerified)
        XCTAssertEqual(result.targetIDs, ["gold"])
        XCTAssertEqual(runtimeIncrementer.requests, [RuntimeQuantityIncrementRequest(featureID: "gold", delta: 99)])
    }

    func testUnknownBuildRuntimeResourceReturnsUnsupportedWithoutWritingMemory() throws {
        let runtimeIncrementer = RecordingRuntimeQuantityIncrementer(result: RuntimeQuantityIncrementResult(updatedAddressCount: 1))
        let service = TrainerOperationService(configuration: .test(
            applier: RecordingTrainerOperationApplier(),
            runtimeQuantityIncrementer: runtimeIncrementer
        ))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .gold, isEnabled: true, payload: .runtimeQuantity(resourceID: .gold, valueText: "99")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: Self.unsupportedBuild)
        )

        XCTAssertEqual(result.state, .unsupportedBuild)
        XCTAssertTrue(runtimeIncrementer.requests.isEmpty)
    }

    func testResourceWithoutManifestCapabilityReturnsTargetMismatch() throws {
        let runtimeIncrementer = RecordingRuntimeQuantityIncrementer(result: RuntimeQuantityIncrementResult(updatedAddressCount: 1))
        let manifest = DaveTrainerManifest(
            schemaVersion: "1.0",
            gameBuild: KnownGameBuild.current,
            features: [
                DaveTrainerManifestFeature(id: .gold, title: "Gold", kind: .inventoryResource, targets: [])
            ]
        )
        let service = TrainerOperationService(configuration: .test(
            manifest: manifest,
            applier: RecordingTrainerOperationApplier(),
            runtimeQuantityIncrementer: runtimeIncrementer
        ))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .gold, isEnabled: true, payload: .runtimeQuantity(resourceID: .gold, valueText: "99")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .targetMismatch)
        XCTAssertEqual(runtimeIncrementer.requests, [])
    }

    func testRuntimeResourceVerifyFailureReturnsVerifyFailedResult() throws {
        let runtimeIncrementer = RecordingRuntimeQuantityIncrementer(error: TrainerError.verifyFailed("forced verify failure"))
        let service = TrainerOperationService(configuration: .test(
            applier: RecordingTrainerOperationApplier(),
            runtimeQuantityIncrementer: runtimeIncrementer
        ))
        let result = try service.apply(
            TrainerOperationRequest(featureID: .gold, isEnabled: true, payload: .runtimeQuantity(resourceID: .gold, valueText: "99")),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .verifyFailed)
        XCTAssertFalse(result.isMemoryApplied)
    }

    func testSeaPeopleVillageItemsUseVillageOnlyJungleScope() throws {
        let jungleIncrementer = RecordingJungleIngredientsInventoryIncrementer(
            result: JungleIngredientsInventoryIncrementResult(updatedItemCount: 2)
        )
        let service = TrainerOperationService(configuration: .test(
            applier: RecordingTrainerOperationApplier(),
            jungleIngredientsIncrementer: jungleIncrementer
        ))
        let result = try service.apply(
            TrainerOperationRequest(
                featureID: .seaPeopleVillageItems,
                isEnabled: true,
                payload: .jungleInventory(scope: .villageItems, valueText: "99")
            ),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .behaviorVerified)
        XCTAssertEqual(result.targetIDs, ["seaPeopleVillageItems"])
        XCTAssertEqual(jungleIncrementer.requests, [
            JungleIngredientsInventoryIncrementRequest(delta: 99, scope: .villageItems)
        ])
    }

    func testJungleInventoryFeatureScopeMismatchReturnsTargetMismatch() throws {
        let jungleIncrementer = RecordingJungleIngredientsInventoryIncrementer(
            result: JungleIngredientsInventoryIncrementResult(updatedItemCount: 2)
        )
        let service = TrainerOperationService(configuration: .test(
            applier: RecordingTrainerOperationApplier(),
            jungleIngredientsIncrementer: jungleIncrementer
        ))
        let result = try service.apply(
            TrainerOperationRequest(
                featureID: .jungleIngredients,
                isEnabled: true,
                payload: .jungleInventory(scope: .villageItems, valueText: "99")
            ),
            context: TrainerOperationContext(session: Self.session(), gameBuild: KnownGameBuild.current)
        )

        XCTAssertEqual(result.state, .targetMismatch)
        XCTAssertEqual(jungleIncrementer.requests, [])
    }

    private static var unsupportedBuild: GameBuildSignature {
        GameBuildSignature(
            identity: GameBuildIdentity(
                bundleID: KnownGameBuild.current.bundleID,
                version: "unsupported",
                buildGUID: "unsupported-build"
            ),
            paths: GameBuildPaths(
                executablePath: KnownGameBuild.current.executablePath,
                metadataPath: KnownGameBuild.current.metadataPath
            )
        )
    }

    private static func session() -> MemorySession {
        MachMemoryAccess().currentProcessSession()
    }
}

private final class RecordingTrainerOperationApplier: StaticPatchApplying {
    private let failingPatchID: String?
    private let failingEnabledState: Bool?
    private let preflightError: Error?
    private let applyError: Error?
    private(set) var preflightRequests: [StaticPatchApplyRequest] = []
    private(set) var requests: [StaticPatchApplyRequest] = []

    init(
        failingPatchID: String? = nil,
        failingEnabledState: Bool? = nil,
        preflightError: Error? = nil,
        applyError: Error? = nil
    ) {
        self.failingPatchID = failingPatchID
        self.failingEnabledState = failingEnabledState
        self.preflightError = preflightError
        self.applyError = applyError
    }

    func preflight(_ request: StaticPatchApplyRequest, session: MemorySession) throws {
        preflightRequests.append(request)
        if let preflightError {
            throw preflightError
        }
    }

    func apply(_ request: StaticPatchApplyRequest, session: MemorySession) throws {
        requests.append(request)
        guard request.patch.id == failingPatchID, request.isEnabled == failingEnabledState else {
            return
        }
        throw applyError ?? TrainerError.memoryWriteFailed("forced failure")
    }
}

private extension TrainerOperationService.Configuration {
    static func test(
        manifest: DaveTrainerManifest = .current,
        applier: StaticPatchApplying,
        runtimeQuantityIncrementer: RuntimeQuantityIncrementing = RecordingRuntimeQuantityIncrementer(),
        ingredientsIncrementer: IngredientsInventoryIncrementing = RecordingIngredientsInventoryIncrementer(),
        jungleIngredientsIncrementer: JungleIngredientsInventoryIncrementing = RecordingJungleIngredientsInventoryIncrementer()
    ) -> TrainerOperationService.Configuration {
        TrainerOperationService.Configuration(
            manifest: manifest,
            staticPatches: TrainerOperationServiceTests.testPatches,
            applier: applier,
            runtimeQuantityIncrementer: runtimeQuantityIncrementer,
            ingredientsIncrementer: ingredientsIncrementer,
            jungleIngredientsIncrementer: jungleIngredientsIncrementer
        )
    }
}

private final class RecordingRuntimeQuantityIncrementer: RuntimeQuantityIncrementing {
    private let result: RuntimeQuantityIncrementResult
    private let error: Error?
    private(set) var requests: [RuntimeQuantityIncrementRequest] = []
    private(set) var clearCallCount = 0

    init(
        result: RuntimeQuantityIncrementResult = RuntimeQuantityIncrementResult(updatedAddressCount: 0),
        error: Error? = nil
    ) {
        self.result = result
        self.error = error
    }

    func clearCachedAddresses() {
        clearCallCount += 1
    }

    func increment(
        _ request: RuntimeQuantityIncrementRequest,
        session: RuntimeQuantityMemorySession
    ) throws -> RuntimeQuantityIncrementResult {
        requests.append(request)
        if let error {
            throw error
        }
        return result
    }
}

private final class RecordingIngredientsInventoryIncrementer: IngredientsInventoryIncrementing {
    private let result: IngredientsInventoryIncrementResult
    private let error: Error?
    private(set) var requests: [IngredientsInventoryIncrementRequest] = []
    private(set) var clearCallCount = 0

    init(
        result: IngredientsInventoryIncrementResult = IngredientsInventoryIncrementResult(updatedItemCount: 0),
        error: Error? = nil
    ) {
        self.result = result
        self.error = error
    }

    func clearCachedAddresses() {
        clearCallCount += 1
    }

    func increment(
        _ request: IngredientsInventoryIncrementRequest,
        session: IngredientsInventoryMemorySession
    ) throws -> IngredientsInventoryIncrementResult {
        requests.append(request)
        if let error {
            throw error
        }
        return result
    }
}

private final class RecordingJungleIngredientsInventoryIncrementer: JungleIngredientsInventoryIncrementing {
    private let result: JungleIngredientsInventoryIncrementResult
    private let error: Error?
    private(set) var requests: [JungleIngredientsInventoryIncrementRequest] = []
    private(set) var clearCallCount = 0

    init(
        result: JungleIngredientsInventoryIncrementResult = JungleIngredientsInventoryIncrementResult(updatedItemCount: 0),
        error: Error? = nil
    ) {
        self.result = result
        self.error = error
    }

    func clearCachedAddresses() {
        clearCallCount += 1
    }

    func increment(
        _ request: JungleIngredientsInventoryIncrementRequest,
        session: JungleIngredientsInventoryMemorySession
    ) throws -> JungleIngredientsInventoryIncrementResult {
        requests.append(request)
        if let error {
            throw error
        }
        return result
    }
}

private extension TrainerOperationServiceTests {
    static let testPatches: [String: StaticGamePatch] = [
        "god": patch(id: "god"),
        "multiGod": patch(id: "multiGod", pointCount: 2),
        "oxygen": patch(id: "oxygen"),
        "ammo": patch(id: "ammo"),
        "swimSpeed": patch(id: "swimSpeed")
    ]

    static func patch(id: String, pointCount: Int = 1) -> StaticGamePatch {
        StaticGamePatch(
            id: id,
            title: id,
            points: (0..<pointCount).map { index in
                StaticPatchPoint(
                    rva: 0x1000 + UInt64(index * 4),
                    expectedBytes: [0x01, 0x02, 0x03, 0x04],
                    patchBytes: [0x05, 0x06, 0x07, 0x08],
                    note: id
                )
            }
        )
    }

    static func manifest(featureID: DaveTrainerFeatureID, patchID: String) -> DaveTrainerManifest {
        DaveTrainerManifest(
            schemaVersion: DaveTrainerManifest.currentSchemaVersion,
            gameBuild: KnownGameBuild.current,
            features: [
                DaveTrainerManifestFeature(
                    id: featureID,
                    title: featureID.rawValue,
                    kind: .codePatch,
                    targets: patchTargets(patchID: patchID)
                )
            ]
        )
    }

    static func patchTargets(patchID: String) -> [DaveTrainerManifestTarget] {
        guard let patch = testPatches[patchID] else {
            return []
        }
        return patch.points.enumerated().map { index, point in
            DaveTrainerManifestTarget.patchPoint(DaveManifestPatchPoint(
                id: "\(patchID).\(index)",
                moduleID: DaveTrainerManifest.gameAssemblyModuleID,
                point: point
            ))
        }
    }
}
