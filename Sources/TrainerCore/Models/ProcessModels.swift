import Foundation

public struct ProcessResolveRequest: Equatable, Sendable {
    public let bundleID: String
    public let executableName: String
    public let executablePath: String

    public init(bundleID: String, executableName: String, executablePath: String) {
        self.bundleID = bundleID
        self.executableName = executableName
        self.executablePath = executablePath
    }
}

public struct TargetProcess: Equatable, Sendable {
    public let pid: Int32
    public let name: String
    public let executablePath: String

    public init(pid: Int32, name: String, executablePath: String) {
        self.pid = pid
        self.name = name
        self.executablePath = executablePath
    }
}

public struct MemoryRegion: Equatable, Sendable {
    public let address: UInt64
    public let size: UInt64
    public let protection: Int32
    public let maxProtection: Int32
    public let isSubmap: Bool
    public let userTag: UInt32

    public init(descriptor: MemoryRegionDescriptor) {
        self.address = descriptor.range.address
        self.size = descriptor.range.size
        self.protection = descriptor.protection.current
        self.maxProtection = descriptor.protection.maximum
        self.isSubmap = descriptor.flags.isSubmap
        self.userTag = descriptor.flags.userTag
    }

    public var isReadable: Bool {
        protection & MemoryProtection.read != 0
    }

    public var isWritable: Bool {
        protection & MemoryProtection.write != 0
    }

    public var isExecutable: Bool {
        protection & MemoryProtection.execute != 0
    }
}

public struct MemoryRange: Equatable, Sendable {
    public let address: UInt64
    public let size: UInt64

    public init(address: UInt64, size: UInt64) {
        self.address = address
        self.size = size
    }
}

public struct MemoryProtectionInfo: Equatable, Sendable {
    public let current: Int32
    public let maximum: Int32

    public init(current: Int32, maximum: Int32) {
        self.current = current
        self.maximum = maximum
    }
}

public struct MemoryRegionFlags: Equatable, Sendable {
    public let isSubmap: Bool
    public let userTag: UInt32

    public init(isSubmap: Bool, userTag: UInt32) {
        self.isSubmap = isSubmap
        self.userTag = userTag
    }
}

public struct MemoryRegionDescriptor: Equatable, Sendable {
    public let range: MemoryRange
    public let protection: MemoryProtectionInfo
    public let flags: MemoryRegionFlags

    public init(range: MemoryRange, protection: MemoryProtectionInfo, flags: MemoryRegionFlags) {
        self.range = range
        self.protection = protection
        self.flags = flags
    }
}

public enum MemoryProtection {
    public static let read: Int32 = 1
    public static let write: Int32 = 2
    public static let execute: Int32 = 4
    public static let copy: Int32 = 16
}

public enum MemoryCacheKind: Sendable {
    case instruction
}
