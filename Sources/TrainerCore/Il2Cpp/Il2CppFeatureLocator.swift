import Foundation

private let gameAssemblyRelativePath = "Frameworks/GameAssembly.dylib"

public enum Il2CppFeatureLocationStatus: String, Codable, Equatable, Sendable {
    case matched
    case partial
    case missing
}

public struct Il2CppFeatureSignature: Equatable, Sendable {
    public let featureID: String
    public let title: String
    public let requiredMetadataNames: [String]
    public let optionalMetadataNames: [String]
    public let requiredAssemblySymbols: [String]

    public init(featureID: String, title: String, requiredMetadataNames: [String], optionalMetadataNames: [String], requiredAssemblySymbols: [String]) {
        self.featureID = featureID
        self.title = title
        self.requiredMetadataNames = requiredMetadataNames
        self.optionalMetadataNames = optionalMetadataNames
        self.requiredAssemblySymbols = requiredAssemblySymbols
    }
}

public struct Il2CppFeatureLocationReport: Equatable, Sendable {
    public let featureID: String
    public let title: String
    public let status: Il2CppFeatureLocationStatus
    public let metadataMatches: [String: Il2CppMetadataNameMatch]
    public let assemblySymbols: [String: [MachOSymbol]]

    public init(featureID: String, title: String, status: Il2CppFeatureLocationStatus, metadataMatches: [String: Il2CppMetadataNameMatch], assemblySymbols: [String: [MachOSymbol]]) {
        self.featureID = featureID
        self.title = title
        self.status = status
        self.metadataMatches = metadataMatches
        self.assemblySymbols = assemblySymbols
    }
}

public struct Il2CppStaticLocationReport: Equatable, Sendable {
    public let metadataVersion: UInt32
    public let gameAssemblyUUID: String?
    public let features: [Il2CppFeatureLocationReport]

    public init(metadataVersion: UInt32, gameAssemblyUUID: String?, features: [Il2CppFeatureLocationReport]) {
        self.metadataVersion = metadataVersion
        self.gameAssemblyUUID = gameAssemblyUUID
        self.features = features
    }
}

public enum DefaultIl2CppFeatureSignatures {
    public static func make() -> [Il2CppFeatureSignature] {
        [
            Il2CppFeatureSignature(
                featureID: "oxygen",
                title: "无限氧气",
                requiredMetadataNames: ["curOxygen", "maxOxygen", "UpdateOxygen"],
                optionalMetadataNames: ["OnChargeOxygen", "Event_OnUseOxygenCapsule", "onlyOxygen"],
                requiredAssemblySymbols: defaultAssemblySymbols
            ),
            Il2CppFeatureSignature(
                featureID: "ammo",
                title: "无限弹药/鱼叉资源",
                requiredMetadataNames: ["Event_OnUseAmmo"],
                optionalMetadataNames: ["Event_OnLoseHarpoonProjectile", "Event_OnHookedHarpoonProjectile", "harpoonSpec"],
                requiredAssemblySymbols: defaultAssemblySymbols
            ),
            Il2CppFeatureSignature(
                featureID: "weight",
                title: "设置负重上限",
                requiredMetadataNames: ["overweightProperty", "m_IsCurrentFishOverweight"],
                optionalMetadataNames: ["get_weight", "weight"],
                requiredAssemblySymbols: defaultAssemblySymbols
            ),
            Il2CppFeatureSignature(
                featureID: "gold",
                title: "设置金币",
                requiredMetadataNames: ["totalGold"],
                optionalMetadataNames: ["Gold", "gold", "Bei", "money"],
                requiredAssemblySymbols: defaultAssemblySymbols
            ),
            Il2CppFeatureSignature(
                featureID: "materials",
                title: "设置全部食材数量",
                requiredMetadataNames: ["Ingredient"],
                optionalMetadataNames: ["ingredient", "ingredients", "useIngredientsList"],
                requiredAssemblySymbols: defaultAssemblySymbols
            )
        ]
    }

    private static let defaultAssemblySymbols = [
        "_g_CodeRegistration",
        "_g_MetadataRegistration",
        "_g_CodeGenModules"
    ]
}

public final class Il2CppStaticFeatureLocator {
    private let metadataAnalyzer: Il2CppMetadataAnalyzer
    private let machOAnalyzer: MachOAnalyzer

    public init(metadataAnalyzer: Il2CppMetadataAnalyzer = Il2CppMetadataAnalyzer(), machOAnalyzer: MachOAnalyzer = MachOAnalyzer()) {
        self.metadataAnalyzer = metadataAnalyzer
        self.machOAnalyzer = machOAnalyzer
    }

    public func locate(build: GameBuildSignature, signatures: [Il2CppFeatureSignature] = DefaultIl2CppFeatureSignatures.make()) throws -> Il2CppStaticLocationReport {
        let metadataNames = Set(signatures.flatMap { $0.requiredMetadataNames + $0.optionalMetadataNames })
        let assemblySymbols = Set(signatures.flatMap(\.requiredAssemblySymbols))
        let metadata = try metadataAnalyzer.analyze(metadataURL: URL(fileURLWithPath: build.metadataPath), targetNames: Array(metadataNames))
        let assembly = try machOAnalyzer.analyzeArm64(url: gameAssemblyURL(for: build), targetSymbols: assemblySymbols)
        let features = signatures.map { signature in
            featureReport(signature: signature, metadata: metadata, assembly: assembly)
        }
        return Il2CppStaticLocationReport(metadataVersion: metadata.header.version, gameAssemblyUUID: assembly.uuid, features: features)
    }

    public func gameAssemblyURL(for build: GameBuildSignature) -> URL {
        URL(fileURLWithPath: build.executablePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(gameAssemblyRelativePath)
    }

    private func featureReport(signature: Il2CppFeatureSignature, metadata: Il2CppMetadataAnalysis, assembly: MachOAnalysis) -> Il2CppFeatureLocationReport {
        let names = signature.requiredMetadataNames + signature.optionalMetadataNames
        let metadataMatches = names.reduce(into: [String: Il2CppMetadataNameMatch]()) { result, name in
            result[name] = metadata.matches[name]
        }
        let symbolMatches = signature.requiredAssemblySymbols.reduce(into: [String: [MachOSymbol]]()) { result, name in
            result[name] = assembly.symbols[name] ?? []
        }
        let status = statusFor(signature: signature, metadataMatches: metadataMatches, symbolMatches: symbolMatches)
        return Il2CppFeatureLocationReport(featureID: signature.featureID, title: signature.title, status: status, metadataMatches: metadataMatches, assemblySymbols: symbolMatches)
    }

    private func statusFor(signature: Il2CppFeatureSignature, metadataMatches: [String: Il2CppMetadataNameMatch], symbolMatches: [String: [MachOSymbol]]) -> Il2CppFeatureLocationStatus {
        let requiredMetadataMatched = signature.requiredMetadataNames.allSatisfy { metadataMatches[$0]?.isInStringTable == true }
        let requiredSymbolsMatched = signature.requiredAssemblySymbols.allSatisfy { symbolMatches[$0]?.isEmpty == false }
        if requiredMetadataMatched && requiredSymbolsMatched {
            return .matched
        }

        let anyMetadataMatched = metadataMatches.values.contains { $0.isInStringTable || !$0.rawOffsets.isEmpty }
        let anySymbolMatched = symbolMatches.values.contains { !$0.isEmpty }
        return anyMetadataMatched || anySymbolMatched ? .partial : .missing
    }
}
