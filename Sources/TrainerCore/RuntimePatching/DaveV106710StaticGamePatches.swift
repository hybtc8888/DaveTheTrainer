import Foundation

public enum DaveV106710StaticGamePatches {
    private struct VerifiedPoint {
        let targetID: String
        let rva: UInt64
        let expectedBytes: [UInt8]?

        init(targetID: String, rva: UInt64, expectedBytes: [UInt8]? = nil) {
            self.targetID = targetID
            self.rva = rva
            self.expectedBytes = expectedBytes
        }
    }

    private static let supportedPatchIDs = [
        "god",
        "oxygen",
        "ammo",
        "crabTraps",
        "weight",
        "drones",
        "stamina",
        "wasabi"
    ]

    // Curated from the v0.1.3 and v0.1.4 compatibility reports attached to GitHub issue #2.
    private static let staticVerifiedPoints = [
        VerifiedPoint(targetID: "god.0", rva: 0x0B85_378),
        VerifiedPoint(targetID: "god.1", rva: 0x0B85_604),
        VerifiedPoint(targetID: "god.2", rva: 0x0B81_C68),
        VerifiedPoint(targetID: "god.3", rva: 0x0B79_8E4),
        VerifiedPoint(targetID: "god.4", rva: 0x1B6A_7C4),
        VerifiedPoint(targetID: "god.5", rva: 0x1B66_C7C),
        VerifiedPoint(targetID: "god.6", rva: 0x1B66_C9C),
        VerifiedPoint(targetID: "oxygen.0", rva: 0x13F2_AD0),
        VerifiedPoint(targetID: "oxygen.1", rva: 0x13F5_78C),
        VerifiedPoint(targetID: "oxygen.2", rva: 0x1B60_BE8),
        VerifiedPoint(targetID: "oxygen.3", rva: 0x1B6A_468),
        VerifiedPoint(targetID: "ammo.0", rva: 0x0B8C_978),
        VerifiedPoint(targetID: "ammo.1", rva: 0x0B87_F70),
        VerifiedPoint(targetID: "ammo.2", rva: 0x1B5B_D78),
        VerifiedPoint(targetID: "ammo.3", rva: 0x1B5B_E40),
        VerifiedPoint(targetID: "ammo.4", rva: 0x1B4F_5CC),
        VerifiedPoint(targetID: "ammo.5", rva: 0x1B4E_A30),
        VerifiedPoint(targetID: "ammo.6", rva: 0x1B4F_370),
        VerifiedPoint(targetID: "ammo.7", rva: 0x1B4F_E24),
        VerifiedPoint(targetID: "ammo.8", rva: 0x1B4E_F38),
        VerifiedPoint(targetID: "ammo.9", rva: 0x1B4E_FB4),
        VerifiedPoint(targetID: "ammo.10", rva: 0x13C0_9B8),
        VerifiedPoint(targetID: "ammo.11", rva: 0x13C0_3D4),
        VerifiedPoint(targetID: "ammo.12", rva: 0x13C0_474),
        VerifiedPoint(targetID: "ammo.13", rva: 0x1355_968),
        VerifiedPoint(targetID: "ammo.14", rva: 0x1D32_F10),
        VerifiedPoint(targetID: "ammo.15", rva: 0x13CE_B0C),
        VerifiedPoint(targetID: "ammo.16", rva: 0x13D4_5AC),
        VerifiedPoint(targetID: "ammo.17", rva: 0x13D4_660),
        VerifiedPoint(targetID: "ammo.18", rva: 0x13D7_280),
        VerifiedPoint(targetID: "ammo.19", rva: 0x13D8_CEC),
        VerifiedPoint(targetID: "ammo.20", rva: 0x13D8_D78),
        VerifiedPoint(targetID: "crabTraps.0", rva: 0x1433_7B0),
        VerifiedPoint(targetID: "crabTraps.1", rva: 0x1433_7B8),
        VerifiedPoint(targetID: "crabTraps.2", rva: 0x0B7A_140),
        VerifiedPoint(targetID: "crabTraps.3", rva: 0x0B7A_148),
        VerifiedPoint(targetID: "crabTraps.4", rva: 0x0B7A_150),
        VerifiedPoint(targetID: "crabTraps.5", rva: 0x1469_87C),
        VerifiedPoint(targetID: "crabTraps.6", rva: 0x1469_884),
        VerifiedPoint(targetID: "weight.0", rva: 0x1DBC_C04),
        VerifiedPoint(targetID: "weight.1", rva: 0x1DBC_C14),
        VerifiedPoint(targetID: "weight.2", rva: 0x1DBC_C1C),
        VerifiedPoint(targetID: "weight.3", rva: 0x146B_428),
        VerifiedPoint(targetID: "weight.4", rva: 0x146B_430),
        VerifiedPoint(targetID: "weight.5", rva: 0x1ED0_F04),
        VerifiedPoint(targetID: "weight.6", rva: 0x1ED0_EFC),
        VerifiedPoint(targetID: "weight.7", rva: 0x1ED1_1FC),
        VerifiedPoint(targetID: "weight.8", rva: 0x1ED1_244),
        VerifiedPoint(targetID: "weight.9", rva: 0x1ED0_C90),
        VerifiedPoint(targetID: "weight.10", rva: 0x1ED1_254),
        VerifiedPoint(targetID: "weight.11", rva: 0x1ED2_D70),
        VerifiedPoint(targetID: "weight.12", rva: 0x1ED3_4FC),
        VerifiedPoint(
            targetID: "weight.13",
            rva: 0x20A4_65C,
            expectedBytes: [
                0xF4, 0x4F, 0xBE, 0xA9,
                0xFD, 0x7B, 0x01, 0xA9,
                0xFD, 0x43, 0x00, 0x91,
                0xF3, 0xE3, 0x03, 0xD0
            ]
        ),
        VerifiedPoint(targetID: "drones.0", rva: 0x0B7A_120),
        VerifiedPoint(targetID: "drones.1", rva: 0x1D33_6E4),
        VerifiedPoint(targetID: "drones.2", rva: 0x0B7A_128),
        VerifiedPoint(targetID: "drones.3", rva: 0x0B7A_130),
        VerifiedPoint(targetID: "stamina.0", rva: 0x100B_AE4),
        VerifiedPoint(targetID: "stamina.1", rva: 0x100B_AEC),
        VerifiedPoint(targetID: "stamina.2", rva: 0x100B_7A8),
        VerifiedPoint(targetID: "stamina.3", rva: 0x100B_E3C),
        VerifiedPoint(
            targetID: "wasabi.0",
            rva: 0x2152_C68,
            expectedBytes: [
                0xFD, 0x7B, 0xBF, 0xA9,
                0xFD, 0x03, 0x00, 0x91,
                0x08, 0x08, 0x40, 0xF9,
                0x48, 0x01, 0x00, 0xB4,
                0x09, 0x19, 0x40, 0xB9,
                0x3F, 0x00, 0x09, 0x6B,
                0x02, 0x01, 0x00, 0x54,
                0x08, 0xCD, 0x21, 0x8B
            ]
        ),
        VerifiedPoint(targetID: "wasabi.1", rva: 0x2152_E7C),
        VerifiedPoint(targetID: "wasabi.2", rva: 0x213E_EC4),
        VerifiedPoint(targetID: "wasabi.3", rva: 0x2152_7D0),
        VerifiedPoint(targetID: "wasabi.4", rva: 0x2152_AC4)
    ]

    private static let swimSpeedVerifiedPoints = [
        VerifiedPoint(targetID: "swimSpeed.0", rva: 0x20A4_8AC),
        VerifiedPoint(targetID: "swimSpeed.1", rva: 0x0B80_8D0),
        VerifiedPoint(targetID: "swimSpeed.2", rva: 0x100B_AF4),
        VerifiedPoint(targetID: "swimSpeed.4", rva: 0x0F64_794),
        VerifiedPoint(targetID: "swimSpeed.9", rva: 0x1152_180),
        VerifiedPoint(targetID: "swimSpeed.10", rva: 0x115B_59C)
    ]

    public static func make() -> [StaticGamePatch] {
        let baselinePatches = Dictionary(
            uniqueKeysWithValues: DefaultStaticGamePatches.make().map { ($0.id, $0) }
        )
        let evidenceByID = Dictionary(uniqueKeysWithValues: staticVerifiedPoints.map { ($0.targetID, $0) })
        let patches = supportedPatchIDs.map { patchID in
            guard let baseline = baselinePatches[patchID] else {
                preconditionFailure("Missing baseline patch: \(patchID)")
            }
            return relocatedPatch(baseline, evidenceByID: evidenceByID)
        }
        let pointCount = patches.reduce(0) { $0 + $1.points.count }
        precondition(pointCount == evidenceByID.count, "Unconsumed v1.0.6.710 patch evidence")
        return patches
    }

    public static func makeValuePatch(id: String, valueText: String) throws -> StaticGamePatch {
        guard id == "swimSpeed" else {
            throw TrainerError.invalidInput("v1.0.6.710 尚未验证固定数值 patch：\(id)")
        }
        let baseline = try DefaultStaticGamePatches.makeValuePatch(id: id, valueText: valueText)
        let evidenceByID = Dictionary(
            uniqueKeysWithValues: swimSpeedVerifiedPoints.map { ($0.targetID, $0) }
        )
        let patch = relocatedPatch(baseline, evidenceByID: evidenceByID)
        precondition(patch.points.count == evidenceByID.count, "Unconsumed v1.0.6.710 value patch evidence")
        return patch
    }

    private static func relocatedPatch(
        _ baseline: StaticGamePatch,
        evidenceByID: [String: VerifiedPoint]
    ) -> StaticGamePatch {
        let points: [StaticPatchPoint] = baseline.points.enumerated().compactMap { index, point -> StaticPatchPoint? in
            let targetID = point.resolvedTargetID(patchID: baseline.id, fallbackIndex: index)
            guard let evidence = evidenceByID[targetID] else {
                return nil
            }
            precondition(point.trampoline == nil, "Unverified trampoline in v1.0.6.710 profile: \(targetID)")
            return relocatedPoint(point, evidence: evidence)
        }
        precondition(!points.isEmpty, "v1.0.6.710 patch has no verified points: \(baseline.id)")
        return StaticGamePatch(id: baseline.id, title: baseline.title, points: points)
    }

    private static func relocatedPoint(
        _ baseline: StaticPatchPoint,
        evidence: VerifiedPoint
    ) -> StaticPatchPoint {
        StaticPatchPoint(
            rva: evidence.rva,
            expectedBytes: evidence.expectedBytes ?? baseline.expectedBytes,
            patchBytes: baseline.patchBytes,
            note: baseline.note,
            acceptsLegacyIntReturnPatch: baseline.acceptsLegacyIntReturnPatch,
            acceptsCompatibleAppliedPatch: baseline.acceptsCompatibleAppliedPatch,
            targetID: evidence.targetID
        )
    }
}
