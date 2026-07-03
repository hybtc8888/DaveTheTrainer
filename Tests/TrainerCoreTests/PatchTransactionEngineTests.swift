import XCTest
@testable import TrainerCore

final class PatchTransactionEngineTests: XCTestCase {
    func testTransactionPreflightsAllPatchesBeforeWritingAnyTarget() throws {
        let applier = RecordingPatchApplier(failingEnabledState: true)
        let engine = PatchTransactionEngine(applier: applier)
        let session = MachMemoryAccess().currentProcessSession()

        _ = try engine.apply(PatchTransactionRequest(
            patches: [Self.patch(id: "god", pointCount: 2), Self.patch(id: "oxygen")],
            isEnabled: true,
            featureID: .divingGod
        ), session: session)

        XCTAssertEqual(applier.events, [
            "preflight:god.0:true",
            "preflight:god.1:true",
            "preflight:oxygen.0:true",
            "apply:god.0:true",
            "apply:god.1:true",
            "apply:oxygen.0:true"
        ])
    }

    func testTransactionDoesNotWriteWhenLaterPreflightFails() throws {
        let applier = RecordingPatchApplier(failingPreflightPatchID: "oxygen.0", failingEnabledState: true)
        let engine = PatchTransactionEngine(applier: applier)
        let session = MachMemoryAccess().currentProcessSession()

        XCTAssertThrowsError(try engine.apply(PatchTransactionRequest(
            patches: [Self.patch(id: "god"), Self.patch(id: "oxygen"), Self.patch(id: "ammo")],
            isEnabled: true,
            featureID: .divingGod
        ), session: session))

        XCTAssertEqual(applier.preflightRequests.map(\.patch.id), ["god.0", "oxygen.0"])
        XCTAssertEqual(applier.requests.map(\.patch.id), [])
    }

    func testTransactionRollsBackPreviouslyEnabledPatchesWhenLaterPatchFails() throws {
        let applier = RecordingPatchApplier(failingPatchID: "oxygen.0", failingEnabledState: true)
        let engine = PatchTransactionEngine(applier: applier)
        let session = MachMemoryAccess().currentProcessSession()

        XCTAssertThrowsError(try engine.apply(PatchTransactionRequest(
            patches: [Self.patch(id: "god"), Self.patch(id: "oxygen"), Self.patch(id: "ammo")],
            isEnabled: true,
            featureID: .divingGod
        ), session: session))

        XCTAssertEqual(applier.requests.map(\.patch.id), ["god.0", "oxygen.0", "god.0"])
        XCTAssertEqual(applier.requests.map(\.isEnabled), [true, true, false])
    }

    func testTransactionDisablesPreviouslyEnabledPatchesWhenRestoreFails() throws {
        let applier = RecordingPatchApplier(failingPatchID: "oxygen.0", failingEnabledState: false)
        let engine = PatchTransactionEngine(applier: applier)
        let session = MachMemoryAccess().currentProcessSession()

        XCTAssertThrowsError(try engine.apply(PatchTransactionRequest(
            patches: [Self.patch(id: "god"), Self.patch(id: "oxygen")],
            isEnabled: false,
            featureID: .divingGod
        ), session: session))

        XCTAssertEqual(applier.requests.map(\.patch.id), ["god.0", "oxygen.0", "god.0"])
        XCTAssertEqual(applier.requests.map(\.isEnabled), [false, false, true])
    }

    func testTransactionResultReportsPatchPointIDs() throws {
        let applier = RecordingPatchApplier(failingEnabledState: true)
        let engine = PatchTransactionEngine(applier: applier)
        let session = MachMemoryAccess().currentProcessSession()

        let result = try engine.apply(PatchTransactionRequest(
            patches: [Self.patch(id: "god", pointCount: 2), Self.patch(id: "oxygen")],
            isEnabled: true,
            featureID: .divingGod
        ), session: session)

        XCTAssertEqual(result.targetIDs, ["god.0", "god.1", "oxygen.0"])
    }

    func testRollbackFailureIsExposedAndNeverCountsAsApplied() throws {
        let applier = RecordingPatchApplier(failingApplications: ["oxygen.0:true", "god.0:false"])
        let engine = PatchTransactionEngine(applier: applier)
        let session = MachMemoryAccess().currentProcessSession()
        var thrownError: Error?

        XCTAssertThrowsError(try engine.apply(PatchTransactionRequest(
            patches: [Self.patch(id: "god"), Self.patch(id: "oxygen")],
            isEnabled: true,
            featureID: .divingGod
        ), session: session)) { error in
            thrownError = error
        }

        XCTAssertEqual(applier.requests.map(Self.applicationKey), ["god.0:true", "oxygen.0:true", "god.0:false"])
        XCTAssertTrue(thrownError?.localizedDescription.contains("rollback also failed") == true)
    }

    private static func applicationKey(_ request: StaticPatchApplyRequest) -> String {
        "\(request.patch.id):\(request.isEnabled)"
    }

    private static func patch(id: String, pointCount: Int = 1) -> StaticGamePatch {
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
}

private final class RecordingPatchApplier: StaticPatchApplying {
    private let failingPatchID: String?
    private let failingPreflightPatchID: String?
    private let failingEnabledState: Bool
    private let failingApplications: Set<String>
    private(set) var preflightRequests: [StaticPatchApplyRequest] = []
    private(set) var requests: [StaticPatchApplyRequest] = []
    private(set) var events: [String] = []

    init(failingPatchID: String? = nil, failingPreflightPatchID: String? = nil, failingEnabledState: Bool) {
        self.failingPatchID = failingPatchID
        self.failingPreflightPatchID = failingPreflightPatchID
        self.failingEnabledState = failingEnabledState
        self.failingApplications = []
    }

    init(failingApplications: Set<String>) {
        self.failingPatchID = nil
        self.failingPreflightPatchID = nil
        self.failingEnabledState = true
        self.failingApplications = failingApplications
    }

    func preflight(_ request: StaticPatchApplyRequest, session: MemorySession) throws {
        preflightRequests.append(request)
        events.append("preflight:\(request.patch.id):\(request.isEnabled)")
        guard request.patch.id == failingPreflightPatchID, request.isEnabled == failingEnabledState else {
            return
        }
        throw TrainerError.memoryWriteFailed("forced preflight failure")
    }

    func apply(_ request: StaticPatchApplyRequest, session: MemorySession) throws {
        requests.append(request)
        events.append("apply:\(request.patch.id):\(request.isEnabled)")
        if failingApplications.contains("\(request.patch.id):\(request.isEnabled)") {
            throw TrainerError.memoryWriteFailed("forced failure")
        }

        guard request.patch.id == failingPatchID, request.isEnabled == failingEnabledState else {
            return
        }
        throw TrainerError.memoryWriteFailed("forced failure")
    }
}
