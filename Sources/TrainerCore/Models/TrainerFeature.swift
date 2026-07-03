import Foundation

public enum TrainerMode: String, Codable, CaseIterable, Sendable {
    case setValue
    case freeze
    case addressEdit
}

public enum ScanValueKind: String, Codable, CaseIterable, Sendable {
    case int32
    case int64
    case float32
    case double

    public var byteWidth: Int {
        switch self {
        case .int32, .float32:
            return MemoryLayout<UInt32>.size
        case .int64, .double:
            return MemoryLayout<UInt64>.size
        }
    }
}

public struct TrainerFeature: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let mode: TrainerMode
    public let requiredBuild: GameBuildSignature
    public let valueKind: ScanValueKind

    public init(descriptor: TrainerFeatureDescriptor) {
        self.id = descriptor.identity.id
        self.title = descriptor.identity.title
        self.mode = descriptor.behavior.mode
        self.requiredBuild = descriptor.requiredBuild
        self.valueKind = descriptor.behavior.valueKind
    }
}

public struct TrainerFeatureIdentity: Codable, Equatable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct TrainerFeatureBehavior: Codable, Equatable, Sendable {
    public let mode: TrainerMode
    public let valueKind: ScanValueKind

    public init(mode: TrainerMode, valueKind: ScanValueKind) {
        self.mode = mode
        self.valueKind = valueKind
    }
}

public struct TrainerFeatureDescriptor: Codable, Equatable, Sendable {
    public let identity: TrainerFeatureIdentity
    public let behavior: TrainerFeatureBehavior
    public let requiredBuild: GameBuildSignature

    public init(identity: TrainerFeatureIdentity, behavior: TrainerFeatureBehavior, requiredBuild: GameBuildSignature) {
        self.identity = identity
        self.behavior = behavior
        self.requiredBuild = requiredBuild
    }
}

public enum DefaultTrainerFeatures {
    public static func make(requiredBuild: GameBuildSignature) -> [TrainerFeature] {
        [
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "gold", title: "设置金币"),
                behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int64),
                requiredBuild: requiredBuild
            )),
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "bei", title: "鲛人族贝壳"),
                behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int32),
                requiredBuild: requiredBuild
            )),
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "jungleGold", title: "丛林货币"),
                behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int32),
                requiredBuild: requiredBuild
            )),
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "oxygen", title: "锁氧气/生命"),
                behavior: TrainerFeatureBehavior(mode: .freeze, valueKind: .float32),
                requiredBuild: requiredBuild
            )),
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "weight", title: "负重控制"),
                behavior: TrainerFeatureBehavior(mode: .freeze, valueKind: .float32),
                requiredBuild: requiredBuild
            )),
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "ammo", title: "弹药/鱼叉资源"),
                behavior: TrainerFeatureBehavior(mode: .freeze, valueKind: .int32),
                requiredBuild: requiredBuild
            )),
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "materials", title: "材料数量"),
                behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int32),
                requiredBuild: requiredBuild
            )),
            TrainerFeature(descriptor: TrainerFeatureDescriptor(
                identity: TrainerFeatureIdentity(id: "artisan", title: "匠人火焰"),
                behavior: TrainerFeatureBehavior(mode: .setValue, valueKind: .int32),
                requiredBuild: requiredBuild
            ))
        ]
    }
}
