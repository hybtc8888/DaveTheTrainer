import CryptoKit
import Foundation

private let compatibilityReportSchemaVersion = "1.1"
private let compatibilitySymbolByteCount = 1024
private let fileHashChunkByteCount = 1024 * 1024
private let gameAssemblyRelativePath = "Frameworks/GameAssembly.dylib"

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

public struct DaveCompatibilityReport: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let context: DaveCompatibilityReportContext
    public let patches: [DaveCompatibilityPatchEvidence]
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

public final class DaveCompatibilityReportGenerator: DaveCompatibilityReportGenerating, @unchecked Sendable {
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
            patches: Self.patchEvidence(descriptors: descriptors, inspection: inspection)
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
        let prefixes = Set(descriptors.compactMap(\.symbolPrefix))
        let reads = descriptors.map { descriptor in
            MachOByteReadRequest(
                id: descriptor.pointID,
                rva: descriptor.point.rva,
                count: descriptor.point.expectedBytes.count
            )
        }
        return MachOBinaryInspectionRequest(
            symbolPrefixes: prefixes,
            byteReads: reads,
            symbolByteCount: compatibilitySymbolByteCount
        )
    }

    private static func patchPointDescriptors(
        in patches: [StaticGamePatch]
    ) -> [CompatibilityPatchPointDescriptor] {
        patches.flatMap { patch in
            patch.points.enumerated().map { index, point in
                CompatibilityPatchPointDescriptor(
                    patchID: patch.id,
                    pointID: point.resolvedTargetID(patchID: patch.id, fallbackIndex: index),
                    point: point,
                    symbolPrefix: symbolPrefix(for: point.note)
                )
            }
        }
    }

    private static func symbolPrefix(for note: String) -> String? {
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
