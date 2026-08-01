import CryptoKit
import Foundation

private let compatibilityReportSchemaVersion = "1.2"
private let compatibilitySymbolByteCount = 3072
private let fileHashChunkByteCount = 1024 * 1024
private let gameAssemblyRelativePath = "Frameworks/GameAssembly.dylib"
private let rpgDamageTrampolineCodeCaveRVA = UInt64(0x940)
private let rpgDamageTrampolineCodeCaveByteCount = 72

public struct DaveTrainerReleaseIdentity: Codable, Equatable, Sendable {
    public let version: String
    public let build: String
    public let commit: String

    public init(version: String, build: String, commit: String) {
        self.version = version
        self.build = build
        self.commit = commit
    }
}

public struct DaveCompatibilityProfile: Equatable, Sendable {
    public let manifest: DaveTrainerManifest
    public let patches: [StaticGamePatch]

    public init(manifest: DaveTrainerManifest, patches: [StaticGamePatch]) {
        self.manifest = manifest
        self.patches = patches
    }

    public static let current = DaveCompatibilityProfile(
        manifest: .current,
        patches: makeCurrentPatches()
    )

    private static func makeCurrentPatches() -> [StaticGamePatch] {
        DefaultStaticGamePatches.make() + [
            requiredValuePatch(id: "swimSpeed", valueText: "5"),
            requiredValuePatch(id: "gold", valueText: "99999"),
            requiredValuePatch(id: "bei", valueText: "99999"),
            requiredValuePatch(id: "jungleGold", valueText: "99999"),
            requiredValuePatch(id: "materials", valueText: "999"),
            requiredValuePatch(id: "artisan", valueText: "999")
        ]
    }

    private static func requiredValuePatch(id: String, valueText: String) -> StaticGamePatch {
        do {
            return try DefaultStaticGamePatches.makeValuePatch(id: id, valueText: valueText)
        } catch {
            preconditionFailure("Invalid compatibility patch \(id): \(error.localizedDescription)")
        }
    }
}

public struct DaveCompatibilityReportRequest: Equatable, Sendable {
    public let build: GameBuildSignature
    public let trainer: DaveTrainerReleaseIdentity
    public let profile: DaveCompatibilityProfile

    public init(
        build: GameBuildSignature,
        trainer: DaveTrainerReleaseIdentity,
        profile: DaveCompatibilityProfile
    ) {
        self.build = build
        self.trainer = trainer
        self.profile = profile
    }
}

public struct DaveCompatibilityBuildIdentity: Codable, Equatable, Sendable {
    public let bundleID: String
    public let version: String
    public let buildGUID: String
}

public struct DaveCompatibilityFileIdentity: Codable, Equatable, Sendable {
    public let name: String
    public let byteCount: UInt64
    public let sha256: String
}

public struct DaveCompatibilityGameAssemblyIdentity: Codable, Equatable, Sendable {
    public let file: DaveCompatibilityFileIdentity
    public let arm64UUID: String?
}

public struct DaveCompatibilityMetadataIdentity: Codable, Equatable, Sendable {
    public let file: DaveCompatibilityFileIdentity
    public let version: UInt32
}

public struct DaveCompatibilityDetectedBuild: Codable, Equatable, Sendable {
    public let build: DaveCompatibilityBuildIdentity
    public let gameAssembly: DaveCompatibilityGameAssemblyIdentity
    public let metadata: DaveCompatibilityMetadataIdentity
}

public struct DaveCompatibilityBaselineIdentity: Codable, Equatable, Sendable {
    public let build: DaveCompatibilityBuildIdentity
    public let gameAssemblyArm64UUID: String?
    public let matchesDetectedBuild: Bool
}

public struct DaveCompatibilityReportContext: Codable, Equatable, Sendable {
    public let trainer: DaveTrainerReleaseIdentity
    public let detected: DaveCompatibilityDetectedBuild
    public let baseline: DaveCompatibilityBaselineIdentity
}

public struct DaveCompatibilityPatchTarget: Codable, Equatable, Sendable {
    public let patchID: String
    public let pointID: String
    public let note: String
}

public struct DaveCompatibilityBaselineBytes: Codable, Equatable, Sendable {
    public let rva: String
    public let expected: String
}

public struct DaveCompatibilityObservedBytes: Codable, Equatable, Sendable {
    public let bytes: String?
    public let issue: String?
}

public struct DaveCompatibilitySymbolCandidate: Codable, Equatable, Sendable {
    public let rva: String
    public let observation: DaveCompatibilityObservedBytes
    public let matchingExpectedRVAs: [String]
}

public struct DaveCompatibilitySymbolDiscovery: Codable, Equatable, Sendable {
    public let prefix: String
    public let candidates: [DaveCompatibilitySymbolCandidate]
}

public struct DaveCompatibilityPatchPointEvidence: Codable, Equatable, Sendable {
    public let baseline: DaveCompatibilityBaselineBytes
    public let observation: DaveCompatibilityObservedBytes
    public let symbolDiscovery: DaveCompatibilitySymbolDiscovery?
}

public struct DaveCompatibilityPatchEvidence: Codable, Equatable, Sendable {
    public let target: DaveCompatibilityPatchTarget
    public let evidence: DaveCompatibilityPatchPointEvidence
}

public struct DaveCompatibilityDiagnosticByteEvidence: Codable, Equatable, Sendable {
    public let id: String
    public let baseline: DaveCompatibilityBaselineBytes
    public let observation: DaveCompatibilityObservedBytes
}

public struct DaveCompatibilityDiagnosticSymbolEvidence: Codable, Equatable, Sendable {
    public let id: String
    public let discovery: DaveCompatibilitySymbolDiscovery
}

public struct DaveCompatibilityDiagnostics: Codable, Equatable, Sendable {
    public let byteReads: [DaveCompatibilityDiagnosticByteEvidence]
    public let symbols: [DaveCompatibilityDiagnosticSymbolEvidence]
}

public struct DaveCompatibilityReport: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let context: DaveCompatibilityReportContext
    public let patches: [DaveCompatibilityPatchEvidence]
    public let diagnostics: DaveCompatibilityDiagnostics
}

public protocol DaveCompatibilityReportGenerating: Sendable {
    func generate(_ request: DaveCompatibilityReportRequest) throws -> DaveCompatibilityReport
}

protocol CompatibilityMachOInspecting {
    func inspectArm64(url: URL, request: MachOBinaryInspectionRequest) throws -> MachOBinaryInspection
}

protocol CompatibilityMetadataAnalyzing {
    func analyze(metadataURL: URL, targetNames: [String]) throws -> Il2CppMetadataAnalysis
}

protocol CompatibilityFileFingerprinting {
    func fingerprint(url: URL) throws -> DaveCompatibilityFileIdentity
}

extension MachOAnalyzer: CompatibilityMachOInspecting {}
extension Il2CppMetadataAnalyzer: CompatibilityMetadataAnalyzing {}

struct SHA256FileFingerprinter: CompatibilityFileFingerprinting {
    func fingerprint(url: URL) throws -> DaveCompatibilityFileIdentity {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = values.fileSize, let byteCount = UInt64(exactly: fileSize) else {
            throw TrainerError.fileOperationFailed("无法读取文件大小：\(url.lastPathComponent)")
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer {
            try? handle.close()
        }

        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: fileHashChunkByteCount), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        return DaveCompatibilityFileIdentity(name: url.lastPathComponent, byteCount: byteCount, sha256: digest)
    }
}

private struct CompatibilityDiagnosticByteDescriptor {
    let id: String
    let rva: UInt64
    let expectedBytes: [UInt8]
}

private struct CompatibilityDiagnosticSymbolDescriptor {
    let id: String
    let prefix: String
}

public final class DaveCompatibilityReportGenerator: DaveCompatibilityReportGenerating, @unchecked Sendable {
    private static let diagnosticByteDescriptors = [
        CompatibilityDiagnosticByteDescriptor(
            id: "damage.trampolineCodeCave",
            rva: rpgDamageTrampolineCodeCaveRVA,
            expectedBytes: Array(repeating: 0, count: rpgDamageTrampolineCodeCaveByteCount)
        )
    ]

    private static let diagnosticSymbolDescriptors = [
        CompatibilityDiagnosticSymbolDescriptor(id: "damage.isEnemy", prefix: "_BattleUtils_IsEnemy_m"),
        CompatibilityDiagnosticSymbolDescriptor(id: "obscuredInt.fromInt", prefix: "_ObscuredInt_op_Implicit_m"),
        CompatibilityDiagnosticSymbolDescriptor(id: "saveSystem.getGameSave", prefix: "_SaveSystem_GetGameSave_m"),
        CompatibilityDiagnosticSymbolDescriptor(id: "saveData.updatePlayerSave", prefix: "_SaveData_UpdatePlayerSave_m"),
        CompatibilityDiagnosticSymbolDescriptor(
            id: "runtime.raiseNullReference",
            prefix: "__Z45il2cpp_codegen_raise_null_reference_exceptionv"
        ),
        CompatibilityDiagnosticSymbolDescriptor(
            id: "runtime.raiseIndexOutOfRange",
            prefix: "__Z49il2cpp_codegen_raise_index_out_of_range_exceptionv"
        ),
        CompatibilityDiagnosticSymbolDescriptor(
            id: "runtime.saveSystemSingleton.instance",
            prefix: "_Singleton_1_get_Instance_mFC618E338A7B241D0CF1919A12AC4B3F787E7381_RuntimeMethod_var"
        ),
        CompatibilityDiagnosticSymbolDescriptor(
            id: "runtime.saveSystemSingleton.hasInstance",
            prefix: "_Singleton_1_get_hasInstance_mB2D77CCC1A8BF769F8D14738F0969975E8176A55_RuntimeMethod_var"
        ),
        CompatibilityDiagnosticSymbolDescriptor(
            id: "runtime.ingredientsStorageSingleton.instance",
            prefix: "_SingletonNoMono_1_get_Instance_mF29D3D880C6EC42811EE9C6ABBF1F545C4001E79_RuntimeMethod_var"
        ),
        CompatibilityDiagnosticSymbolDescriptor(
            id: "runtime.ingredientsStorageSingleton.constructor",
            prefix: "_SingletonNoMono_1__ctor_m519D29DCFD59A6704139CD3245D7124E144CAB1F_RuntimeMethod_var"
        )
    ]

    private static let symbolPrefixOverrides = [
        "god.7": "_InCombatStateController_CalculateCombatResult_m",
        "god.8": "_InCombatStateController_CalculateCombatResult_m",
        "god.9": "_EffectResultHandler_DealDamage_m",
        "damage.0": "_HarpoonProjectile_get_BuffedProjectileDamage_m",
        "damage.1": "_HarpoonProjectile_get_ProjectileDamage_m",
        "damage.2": "_HarpoonProjectile_get_GlobalProjectileDamage_m",
        "damage.3": "_HarpoonProjectile_CollisionDetection_m",
        "damage.4": "_PirateRopeChainController_OnTakeRopeDamage_m",
        "damage.5": "_PirateRopeChainController_OnTakeRopeDamage_m",
        "damage.6": "_NPCPlayer_JohnWatson_OnTakeDamage_m",
        "damage.7": "_WreckController_OnTakeDamage_m",
        "damage.8": "_FishAISystem_OnTakeDamage_m",
        "damage.9": "_NPC_Mxmtoon_OnTakeDamage_m",
        "damage.10": "_NPCPlayer_PirateBase_OnTakeDamage_m",
        "damage.11": "_NPCPlayer_PirateBase_OnTakeDamage_m",
        "damage.12": "_NPCPlayerCharacter_OnTakeDamage_m",
        "damage.13": "_Damageable_TakeDamage_m",
        "damage.14": "_Damageable_TakeDamage_m",
        "damage.15": "_RockBlocker_TakeDamageBefore_m",
        "damage.16": "_BossGiantSquidController_OnTakeDamage_m",
        "damage.17": "_BossWolffishController_OnTakeDamage_m",
        "damage.18": "_BossWolffishController_OnTakeDamage_m",
        "damage.19": "_BossWolffishController_OnTakeDamage_m",
        "damage.20": "_InCombatStateController_CalculateCombatResult_m",
        "damage.21": "_InCombatStateController_CalculateCombatResult_m",
        "damage.22": "_InCombatStateController_CalculateCombatResult_m",
        "damage.23": "_EffectResultHandler_DealDamage_m",
        "damage.24": "_AttackData_get_BuffedDamage_m",
        "damage.25": "_Damager_SetDamageValue_m",
        "damage.26": "_ExtensionIDamager_GetBuffedDamage_m",
        "damage.27": "_U3CHandleResultU3Ed__13_MoveNext_m",
        "swimSpeed.11": "_ChangeSwimSpeed_OnSLStateEnter_m",
        "swimSpeed.12": "_ChangeSwimSpeed_OnSLStateNoTransitionUpdate_m"
    ]

    private let machOInspector: CompatibilityMachOInspecting
    private let metadataAnalyzer: CompatibilityMetadataAnalyzing
    private let fileFingerprinter: CompatibilityFileFingerprinting

    public convenience init() {
        self.init(
            machOInspector: MachOAnalyzer(),
            metadataAnalyzer: Il2CppMetadataAnalyzer(),
            fileFingerprinter: SHA256FileFingerprinter()
        )
    }

    init(
        machOInspector: CompatibilityMachOInspecting,
        metadataAnalyzer: CompatibilityMetadataAnalyzing,
        fileFingerprinter: CompatibilityFileFingerprinting
    ) {
        self.machOInspector = machOInspector
        self.metadataAnalyzer = metadataAnalyzer
        self.fileFingerprinter = fileFingerprinter
    }

    public func generate(_ request: DaveCompatibilityReportRequest) throws -> DaveCompatibilityReport {
        let descriptors = Self.patchPointDescriptors(in: request.profile.patches)
        let gameAssemblyURL = Self.gameAssemblyURL(for: request.build)
        let inspection = try machOInspector.inspectArm64(
            url: gameAssemblyURL,
            request: Self.inspectionRequest(for: descriptors)
        )
        let metadataURL = URL(fileURLWithPath: request.build.metadataPath)
        let metadata = try metadataAnalyzer.analyze(metadataURL: metadataURL, targetNames: [])
        let detected = try detectedBuild(
            request: request,
            inspection: inspection,
            files: CompatibilityAnalyzedFiles(
                gameAssembly: gameAssemblyURL,
                metadata: metadataURL,
                metadataVersion: metadata.header.version
            )
        )
        let baseline = Self.baselineIdentity(request: request, detectedUUID: inspection.uuid)
        let context = DaveCompatibilityReportContext(
            trainer: request.trainer,
            detected: detected,
            baseline: baseline
        )
        return DaveCompatibilityReport(
            schemaVersion: compatibilityReportSchemaVersion,
            context: context,
            patches: Self.patchEvidence(descriptors: descriptors, inspection: inspection),
            diagnostics: Self.diagnosticEvidence(inspection: inspection)
        )
    }

    private func detectedBuild(
        request: DaveCompatibilityReportRequest,
        inspection: MachOBinaryInspection,
        files: CompatibilityAnalyzedFiles
    ) throws -> DaveCompatibilityDetectedBuild {
        let assemblyFile = try fileFingerprinter.fingerprint(url: files.gameAssembly)
        let metadataFile = try fileFingerprinter.fingerprint(url: files.metadata)
        return DaveCompatibilityDetectedBuild(
            build: Self.buildIdentity(request.build),
            gameAssembly: DaveCompatibilityGameAssemblyIdentity(
                file: assemblyFile,
                arm64UUID: inspection.uuid
            ),
            metadata: DaveCompatibilityMetadataIdentity(
                file: metadataFile,
                version: files.metadataVersion
            )
        )
    }

    private static func gameAssemblyURL(for build: GameBuildSignature) -> URL {
        URL(fileURLWithPath: build.executablePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(gameAssemblyRelativePath)
    }

    private static func inspectionRequest(
        for descriptors: [CompatibilityPatchPointDescriptor]
    ) -> MachOBinaryInspectionRequest {
        let patchPrefixes = descriptors.compactMap(\.symbolPrefix)
        let diagnosticPrefixes = diagnosticSymbolDescriptors.map(\.prefix)
        let patchReads = descriptors.map { descriptor in
            MachOByteReadRequest(
                id: descriptor.pointID,
                rva: descriptor.point.rva,
                count: descriptor.point.expectedBytes.count
            )
        }
        let diagnosticReads = diagnosticByteDescriptors.map { descriptor in
            MachOByteReadRequest(
                id: descriptor.id,
                rva: descriptor.rva,
                count: descriptor.expectedBytes.count
            )
        }
        return MachOBinaryInspectionRequest(
            symbolPrefixes: Set(patchPrefixes + diagnosticPrefixes),
            byteReads: patchReads + diagnosticReads,
            symbolByteCount: compatibilitySymbolByteCount
        )
    }

    private static func patchPointDescriptors(
        in patches: [StaticGamePatch]
    ) -> [CompatibilityPatchPointDescriptor] {
        patches.flatMap { patch in
            patch.points.enumerated().map { index, point in
                let pointID = point.resolvedTargetID(patchID: patch.id, fallbackIndex: index)
                return CompatibilityPatchPointDescriptor(
                    patchID: patch.id,
                    pointID: pointID,
                    point: point,
                    symbolPrefix: symbolPrefix(pointID: pointID, note: point.note)
                )
            }
        }
    }

    private static func symbolPrefix(pointID: String, note: String) -> String? {
        if let prefix = symbolPrefixOverrides[pointID] {
            return prefix
        }
        guard let token = note.split(separator: " ").first else {
            return nil
        }
        let method = token.split(separator: "(", maxSplits: 1).first.map(String.init) ?? ""
        guard method.contains("_") else {
            return nil
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard method.unicodeScalars.allSatisfy(allowed.contains) else {
            return nil
        }
        return "_\(method)_m"
    }

    private static func patchEvidence(
        descriptors: [CompatibilityPatchPointDescriptor],
        inspection: MachOBinaryInspection
    ) -> [DaveCompatibilityPatchEvidence] {
        let reads = Dictionary(uniqueKeysWithValues: inspection.byteReads.map { ($0.request.id, $0.result) })
        return descriptors.map { descriptor in
            let baseline = DaveCompatibilityBaselineBytes(
                rva: hexRVA(descriptor.point.rva),
                expected: hexBytes(descriptor.point.expectedBytes)
            )
            let observation = observedBytes(reads[descriptor.pointID])
            let discovery = descriptor.symbolPrefix.map {
                symbolDiscovery(
                    prefix: $0,
                    expectedBytes: descriptor.point.expectedBytes,
                    inspection: inspection
                )
            }
            let pointEvidence = DaveCompatibilityPatchPointEvidence(
                baseline: baseline,
                observation: observation,
                symbolDiscovery: discovery
            )
            return DaveCompatibilityPatchEvidence(
                target: DaveCompatibilityPatchTarget(
                    patchID: descriptor.patchID,
                    pointID: descriptor.pointID,
                    note: descriptor.point.note
                ),
                evidence: pointEvidence
            )
        }
    }

    private static func diagnosticEvidence(
        inspection: MachOBinaryInspection
    ) -> DaveCompatibilityDiagnostics {
        let reads = Dictionary(
            uniqueKeysWithValues: inspection.byteReads.map { ($0.request.id, $0.result) }
        )
        let byteEvidence = diagnosticByteDescriptors.map { descriptor in
            DaveCompatibilityDiagnosticByteEvidence(
                id: descriptor.id,
                baseline: DaveCompatibilityBaselineBytes(
                    rva: hexRVA(descriptor.rva),
                    expected: hexBytes(descriptor.expectedBytes)
                ),
                observation: observedBytes(reads[descriptor.id])
            )
        }
        let symbolEvidence = diagnosticSymbolDescriptors.map { descriptor in
            DaveCompatibilityDiagnosticSymbolEvidence(
                id: descriptor.id,
                discovery: symbolDiscovery(
                    prefix: descriptor.prefix,
                    expectedBytes: [],
                    inspection: inspection
                )
            )
        }
        return DaveCompatibilityDiagnostics(byteReads: byteEvidence, symbols: symbolEvidence)
    }

    private static func symbolDiscovery(
        prefix: String,
        expectedBytes: [UInt8],
        inspection: MachOBinaryInspection
    ) -> DaveCompatibilitySymbolDiscovery {
        let evidence = inspection.symbolsByPrefix[prefix] ?? []
        var candidatesByRVA: [UInt64: DaveCompatibilitySymbolCandidate] = [:]
        for candidate in evidence {
            candidatesByRVA[candidate.symbol.address] = DaveCompatibilitySymbolCandidate(
                rva: hexRVA(candidate.symbol.address),
                observation: observedBytes(candidate.result),
                matchingExpectedRVAs: matchingExpectedRVAs(
                    baseRVA: candidate.symbol.address,
                    result: candidate.result,
                    expectedBytes: expectedBytes
                )
            )
        }
        return DaveCompatibilitySymbolDiscovery(
            prefix: prefix,
            candidates: candidatesByRVA.sorted { $0.key < $1.key }.map(\.value)
        )
    }

    private static func matchingExpectedRVAs(
        baseRVA: UInt64,
        result: MachOByteReadResult,
        expectedBytes: [UInt8]
    ) -> [String] {
        guard case .bytes(let bytes) = result,
              !expectedBytes.isEmpty,
              bytes.count >= expectedBytes.count else {
            return []
        }
        let lastOffset = bytes.count - expectedBytes.count
        return stride(from: 0, through: lastOffset, by: MemoryLayout<UInt32>.size).compactMap { offset in
            let endIndex = offset + expectedBytes.count
            guard bytes[offset..<endIndex].elementsEqual(expectedBytes) else {
                return nil
            }
            let (rva, overflow) = baseRVA.addingReportingOverflow(UInt64(offset))
            return overflow ? nil : hexRVA(rva)
        }
    }

    private static func observedBytes(_ result: MachOByteReadResult?) -> DaveCompatibilityObservedBytes {
        guard let result else {
            return DaveCompatibilityObservedBytes(bytes: nil, issue: "没有读取结果。")
        }
        switch result {
        case .bytes(let bytes):
            return DaveCompatibilityObservedBytes(bytes: hexBytes(bytes), issue: nil)
        case .unmapped(let issue):
            return DaveCompatibilityObservedBytes(bytes: nil, issue: issue)
        }
    }

    private static func baselineIdentity(
        request: DaveCompatibilityReportRequest,
        detectedUUID: String?
    ) -> DaveCompatibilityBaselineIdentity {
        let expectedUUID = request.profile.manifest
            .moduleIdentity(id: DaveTrainerManifest.gameAssemblyModuleID)?
            .machoUUID
        let buildMatches = request.build.matchesIdentity(of: request.profile.manifest.gameBuild)
        let moduleMatches = expectedUUID == nil || expectedUUID == detectedUUID
        return DaveCompatibilityBaselineIdentity(
            build: buildIdentity(request.profile.manifest.gameBuild),
            gameAssemblyArm64UUID: expectedUUID,
            matchesDetectedBuild: buildMatches && moduleMatches
        )
    }

    private static func buildIdentity(_ build: GameBuildSignature) -> DaveCompatibilityBuildIdentity {
        DaveCompatibilityBuildIdentity(
            bundleID: build.bundleID,
            version: build.version,
            buildGUID: build.buildGUID
        )
    }

    private static func hexRVA(_ value: UInt64) -> String {
        "0x\(String(value, radix: 16, uppercase: true))"
    }

    private static func hexBytes(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

private struct CompatibilityPatchPointDescriptor {
    let patchID: String
    let pointID: String
    let point: StaticPatchPoint
    let symbolPrefix: String?
}

private struct CompatibilityAnalyzedFiles {
    let gameAssembly: URL
    let metadata: URL
    let metadataVersion: UInt32
}
