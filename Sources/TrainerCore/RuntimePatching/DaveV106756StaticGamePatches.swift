import Foundation

public enum DaveV106756StaticGamePatches {
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

    // Verified against the local v1.0.6.756 arm64 image; see docs/compatibility-v1.0.6.756.mac.md.
    private static let staticVerifiedPoints = [
        VerifiedPoint(targetID: "god.0", rva: 0xB86670),
        VerifiedPoint(targetID: "god.1", rva: 0xB868FC),
        VerifiedPoint(targetID: "god.2", rva: 0xB82F60),
        VerifiedPoint(targetID: "god.3", rva: 0xB7A8FC),
        VerifiedPoint(targetID: "god.4", rva: 0x1BC9E40),
        VerifiedPoint(targetID: "god.5", rva: 0x1BC62F8),
        VerifiedPoint(targetID: "god.6", rva: 0x1BC6318),
        VerifiedPoint(targetID: "oxygen.0", rva: 0x14158D8),
        VerifiedPoint(targetID: "oxygen.1", rva: 0x1418594),
        VerifiedPoint(targetID: "oxygen.2", rva: 0x1BC023C),
        VerifiedPoint(targetID: "oxygen.3", rva: 0x1BC9AE4),
        VerifiedPoint(targetID: "ammo.0", rva: 0xB8DC70),
        VerifiedPoint(targetID: "ammo.1", rva: 0xB89268),
        VerifiedPoint(targetID: "ammo.2", rva: 0x1BBB530),
        VerifiedPoint(targetID: "ammo.3", rva: 0x1BBB5F8),
        VerifiedPoint(targetID: "ammo.4", rva: 0x1BAED24),
        VerifiedPoint(targetID: "ammo.5", rva: 0x1BADFC4),
        VerifiedPoint(targetID: "ammo.6", rva: 0x1BAEAC8),
        VerifiedPoint(targetID: "ammo.7", rva: 0x1BAF57C),
        VerifiedPoint(targetID: "ammo.8", rva: 0x1BAE4DC),
        VerifiedPoint(targetID: "ammo.9", rva: 0x1BAE70C),
        VerifiedPoint(targetID: "ammo.10", rva: 0x13E3C88),
        VerifiedPoint(targetID: "ammo.11", rva: 0x13E36A4),
        VerifiedPoint(targetID: "ammo.12", rva: 0x13E3744),
        VerifiedPoint(targetID: "ammo.13", rva: 0x1374B10),
        VerifiedPoint(targetID: "ammo.14", rva: 0x1D95AD8),
        VerifiedPoint(targetID: "ammo.15", rva: 0x13F1978),
        VerifiedPoint(targetID: "ammo.16", rva: 0x13F7314),
        VerifiedPoint(targetID: "ammo.17", rva: 0x13F73C8),
        VerifiedPoint(targetID: "ammo.18", rva: 0x13FB560),
        VerifiedPoint(targetID: "ammo.19", rva: 0x13FBB98),
        VerifiedPoint(targetID: "ammo.20", rva: 0x13FBC24),
        VerifiedPoint(targetID: "crabTraps.0", rva: 0x1457588),
        VerifiedPoint(targetID: "crabTraps.1", rva: 0x1457590),
        VerifiedPoint(targetID: "crabTraps.2", rva: 0xB7B158),
        VerifiedPoint(targetID: "crabTraps.3", rva: 0xB7B160),
        VerifiedPoint(targetID: "crabTraps.4", rva: 0xB7B168),
        VerifiedPoint(targetID: "crabTraps.5", rva: 0x148E980),
        VerifiedPoint(targetID: "crabTraps.6", rva: 0x148E988),
        VerifiedPoint(targetID: "weight.0", rva: 0x1E1FB70),
        VerifiedPoint(targetID: "weight.1", rva: 0x1E1FB80),
        VerifiedPoint(targetID: "weight.2", rva: 0x1E1FB88),
        VerifiedPoint(targetID: "weight.3", rva: 0x1490610),
        VerifiedPoint(targetID: "weight.4", rva: 0x1490618),
        VerifiedPoint(targetID: "weight.5", rva: 0x1F35FF4),
        VerifiedPoint(targetID: "weight.6", rva: 0x1F35FEC),
        VerifiedPoint(targetID: "weight.7", rva: 0x1F362EC),
        VerifiedPoint(targetID: "weight.8", rva: 0x1F36334),
        VerifiedPoint(targetID: "weight.9", rva: 0x1F35D80),
        VerifiedPoint(targetID: "weight.10", rva: 0x1F36344),
        VerifiedPoint(targetID: "weight.11", rva: 0x1F37E60),
        VerifiedPoint(targetID: "weight.12", rva: 0x1F385EC),
        VerifiedPoint(
            targetID: "weight.13",
            rva: 0x210BBAC,
            expectedBytes: [
                0xF4, 0x4F, 0xBE, 0xA9,
                0xFD, 0x7B, 0x01, 0xA9,
                0xFD, 0x43, 0x00, 0x91,
                0x13, 0xE6, 0x03, 0xD0
            ]
        ),
        VerifiedPoint(targetID: "drones.0", rva: 0xB7B138),
        VerifiedPoint(targetID: "drones.1", rva: 0x1D962AC),
        VerifiedPoint(targetID: "drones.2", rva: 0xB7B140),
        VerifiedPoint(targetID: "drones.3", rva: 0xB7B148),
        VerifiedPoint(targetID: "stamina.0", rva: 0x1029FCC),
        VerifiedPoint(targetID: "stamina.1", rva: 0x1029FD4),
        VerifiedPoint(targetID: "stamina.2", rva: 0x1029C90),
        VerifiedPoint(targetID: "stamina.3", rva: 0x102A324),
        VerifiedPoint(
            targetID: "wasabi.0",
            rva: 0x21D4F50,
            expectedBytes: [
                0xFD, 0x7B, 0xBF, 0xA9,
                0xFD, 0x03, 0x00, 0x91,
                0x08, 0x08, 0x40, 0xF9,
                0x48, 0x01, 0x00, 0xB4,
                0x09, 0x19, 0x40, 0xB9,
                0x3F, 0x00, 0x09, 0x6B,
                0x02, 0x01, 0x00, 0x54,
                0x08, 0xCD, 0x21, 0x8B,
                0x08, 0x11, 0x40, 0xF9,
                0x88, 0x00, 0x00, 0xB4,
                0x00, 0x11, 0x40, 0xB9,
                0xFD, 0x7B, 0xC1, 0xA8,
                0xC0, 0x03, 0x5F, 0xD6
            ]
        ),
        VerifiedPoint(targetID: "wasabi.1", rva: 0x21D52A0),
        VerifiedPoint(targetID: "wasabi.2", rva: 0x21D5168),
        VerifiedPoint(targetID: "wasabi.3", rva: 0x21D4A10),
        VerifiedPoint(targetID: "wasabi.4", rva: 0x21D4D24)
    ]

    private static let swimSpeedVerifiedPoints = [
        VerifiedPoint(targetID: "swimSpeed.0", rva: 0x210BDFC),
        VerifiedPoint(targetID: "swimSpeed.1", rva: 0xB81BC8),
        VerifiedPoint(targetID: "swimSpeed.2", rva: 0x1029FDC),
        VerifiedPoint(targetID: "swimSpeed.4", rva: 0xF7FB70),
        VerifiedPoint(targetID: "swimSpeed.9", rva: 0x116F610),
        VerifiedPoint(targetID: "swimSpeed.10", rva: 0x1178B3C)
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
        precondition(pointCount == evidenceByID.count, "Unconsumed v1.0.6.756 patch evidence")
        return patches
    }

    public static func makeValuePatch(id: String, valueText: String) throws -> StaticGamePatch {
        guard id == "swimSpeed" else {
            throw TrainerError.invalidInput("v1.0.6.756 尚未验证固定数值 patch：\(id)")
        }
        let baseline = try DefaultStaticGamePatches.makeValuePatch(id: id, valueText: valueText)
        let evidenceByID = Dictionary(
            uniqueKeysWithValues: swimSpeedVerifiedPoints.map { ($0.targetID, $0) }
        )
        let patch = relocatedPatch(baseline, evidenceByID: evidenceByID)
        precondition(patch.points.count == evidenceByID.count, "Unconsumed v1.0.6.756 value patch evidence")
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
            precondition(point.trampoline == nil, "Unverified trampoline in v1.0.6.756 profile: \(targetID)")
            return relocatedPoint(point, evidence: evidence)
        }
        precondition(!points.isEmpty, "v1.0.6.756 patch has no verified points: \(baseline.id)")
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
