import Foundation

private let machOMagic64Bytes = Data([0xCF, 0xFA, 0xED, 0xFE])
private let gameAssemblyImageName = "GameAssembly.dylib"
private let moduleHeaderReadSize = 16 * 1024
private let machHeader64ByteCount = 32
private let loadCommandHeaderByteCount = 8
private let dylibCommandByteCount = 24
private let machOFileTypeDylib = UInt32(6)
private let machOCPUTypeARM64 = UInt32(0x0100_000C)
private let loadCommandUUID = UInt32(0x1B)
private let loadCommandIDDylib = UInt32(0x0D)
private let machOCPUTypeOffset = 4
private let machOFileTypeOffset = 12
private let machONCommandsOffset = 16
private let machOSizeOfCommandsOffset = 20
private let uuidCommandByteCount = 24
private let moduleIdentityUnknownUUID = "unknown"

public struct LoadedMachOModule: Equatable, Sendable {
    public let name: String
    public let baseAddress: UInt64
    public let headerSize: Int
    public let moduleIdentity: String

    public init(name: String, baseAddress: UInt64, headerSize: Int, moduleIdentity: String? = nil) {
        self.name = name
        self.baseAddress = baseAddress
        self.headerSize = headerSize
        self.moduleIdentity = moduleIdentity ?? name
    }
}

public protocol ModuleMemorySession: AnyObject {
    func read(_ request: MemoryReadRequest) throws -> Data
    func regions() throws -> [MemoryRegion]
}

extension MemorySession: ModuleMemorySession {}

public protocol GameAssemblyResolving {
    func resolveGameAssembly(session: ModuleMemorySession) throws -> LoadedMachOModule
}

public final class MachOModuleResolver: GameAssemblyResolving {
    private let expectedModuleIdentity: DaveModuleIdentity?

    public init(expectedModuleIdentity: DaveModuleIdentity? = nil) {
        self.expectedModuleIdentity = expectedModuleIdentity
    }

    public func resolveGameAssembly(session: ModuleMemorySession) throws -> LoadedMachOModule {
        let regions = try session.regions().filter { $0.isReadable && $0.isExecutable }
        for region in regions {
            if let module = try readModule(region: region, session: session) {
                return module
            }
        }

        throw TrainerError.addressNotCalibrated(featureID: "GameAssembly.dylib")
    }

    private func readModule(region: MemoryRegion, session: ModuleMemorySession) throws -> LoadedMachOModule? {
        let readSize = Int(min(UInt64(moduleHeaderReadSize), region.size))
        guard readSize >= machOMagic64Bytes.count else {
            return nil
        }

        let data = try session.read(MemoryReadRequest(address: region.address, size: readSize))
        guard data.starts(with: machOMagic64Bytes) else {
            return nil
        }

        guard Self.isGameAssemblyDylibHeader(data) else {
            return nil
        }

        let identity = Self.moduleIdentity(in: data)
        try validateExpectedModuleIdentity(identity)
        return LoadedMachOModule(
            name: gameAssemblyImageName,
            baseAddress: region.address,
            headerSize: readSize,
            moduleIdentity: identity.cacheKey
        )
    }

    static func isGameAssemblyDylibHeader(_ data: Data) -> Bool {
        guard data.count >= machHeader64ByteCount else {
            return false
        }
        guard data.starts(with: machOMagic64Bytes) else {
            return false
        }
        guard data.littleEndianUInt32(at: machOCPUTypeOffset) == machOCPUTypeARM64 else {
            return false
        }
        guard data.littleEndianUInt32(at: machOFileTypeOffset) == machOFileTypeDylib else {
            return false
        }

        let commandCount = Int(data.littleEndianUInt32(at: machONCommandsOffset))
        let commandBytes = Int(data.littleEndianUInt32(at: machOSizeOfCommandsOffset))
        let commandsEnd = machHeader64ByteCount + commandBytes
        guard commandCount > 0, commandsEnd <= data.count else {
            return false
        }

        return containsGameAssemblyIDDylib(data, commandCount: commandCount, commandsEnd: commandsEnd)
    }

    static func moduleIdentity(in data: Data) -> LoadedMachOModuleIdentity {
        LoadedMachOModuleIdentity(
            moduleName: gameAssemblyImageName,
            architecture: data.littleEndianUInt32(at: machOCPUTypeOffset) == machOCPUTypeARM64 ? "arm64" : "unknown",
            machoUUID: machoUUID(in: data)
        )
    }

    static func machoUUID(in data: Data) -> String? {
        guard data.count >= machHeader64ByteCount else {
            return nil
        }

        let commandCount = Int(data.littleEndianUInt32(at: machONCommandsOffset))
        let commandBytes = Int(data.littleEndianUInt32(at: machOSizeOfCommandsOffset))
        let commandsEnd = machHeader64ByteCount + commandBytes
        guard commandCount > 0, commandsEnd <= data.count else {
            return nil
        }

        var offset = machHeader64ByteCount
        for _ in 0..<commandCount {
            guard let command = loadCommand(in: data, offset: offset, commandsEnd: commandsEnd) else {
                return nil
            }
            if command.cmd == loadCommandUUID, let uuid = uuidString(in: data, offset: offset, commandSize: command.size) {
                return uuid
            }
            offset += command.size
        }

        return nil
    }

    private static func containsGameAssemblyIDDylib(_ data: Data, commandCount: Int, commandsEnd: Int) -> Bool {
        var offset = machHeader64ByteCount
        for _ in 0..<commandCount {
            guard let command = loadCommand(in: data, offset: offset, commandsEnd: commandsEnd) else {
                return false
            }
            if command.cmd == loadCommandIDDylib, commandName(in: data, offset: offset, commandSize: command.size) == gameAssemblyImageName {
                return true
            }
            offset += command.size
        }

        return false
    }

    private static func loadCommand(in data: Data, offset: Int, commandsEnd: Int) -> (cmd: UInt32, size: Int)? {
        guard offset + loadCommandHeaderByteCount <= commandsEnd else {
            return nil
        }

        let commandSize = Int(data.littleEndianUInt32(at: offset + 4))
        guard commandSize >= loadCommandHeaderByteCount, offset + commandSize <= commandsEnd else {
            return nil
        }

        return (data.littleEndianUInt32(at: offset), commandSize)
    }

    private static func commandName(in data: Data, offset: Int, commandSize: Int) -> String? {
        guard commandSize >= dylibCommandByteCount else {
            return nil
        }

        let nameOffset = Int(data.littleEndianUInt32(at: offset + 8))
        guard nameOffset >= dylibCommandByteCount, nameOffset < commandSize else {
            return nil
        }

        let absoluteNameOffset = offset + nameOffset
        let commandEnd = offset + commandSize
        guard let end = data[absoluteNameOffset..<commandEnd].firstIndex(of: 0) else {
            return nil
        }

        let name = String(decoding: data[absoluteNameOffset..<end], as: UTF8.self)
        return URL(fileURLWithPath: name).lastPathComponent
    }

    private static func uuidString(in data: Data, offset: Int, commandSize: Int) -> String? {
        guard commandSize >= uuidCommandByteCount, offset + uuidCommandByteCount <= data.count else {
            return nil
        }

        let bytes = data[(offset + loadCommandHeaderByteCount)..<(offset + uuidCommandByteCount)]
        let hex = bytes.map { String(format: "%02X", $0) }
        return "\(hex[0...3].joined())-\(hex[4...5].joined())-\(hex[6...7].joined())-\(hex[8...9].joined())-\(hex[10...15].joined())"
    }

    private func validateExpectedModuleIdentity(_ actual: LoadedMachOModuleIdentity) throws {
        guard let expectedModuleIdentity else {
            return
        }
        guard expectedModuleIdentity.moduleName == actual.moduleName else {
            throw TrainerError.targetMismatch("GameAssembly 模块名不匹配。期望 \(expectedModuleIdentity.moduleName)，实际 \(actual.moduleName)。")
        }
        guard expectedModuleIdentity.architecture == actual.architecture else {
            throw TrainerError.targetMismatch("GameAssembly 架构不匹配。期望 \(expectedModuleIdentity.architecture)，实际 \(actual.architecture)。")
        }
        guard let expectedUUID = expectedModuleIdentity.machoUUID else {
            return
        }
        guard actual.machoUUID == expectedUUID else {
            throw TrainerError.targetMismatch("GameAssembly UUID 不匹配。期望 \(expectedUUID)，实际 \(actual.machoUUID ?? moduleIdentityUnknownUUID)。")
        }
    }
}

public struct LoadedMachOModuleIdentity: Equatable, Sendable {
    public let moduleName: String
    public let architecture: String
    public let machoUUID: String?

    public init(moduleName: String, architecture: String, machoUUID: String?) {
        self.moduleName = moduleName
        self.architecture = architecture
        self.machoUUID = machoUUID
    }

    public var cacheKey: String {
        "\(moduleName):\(architecture):\(machoUUID ?? moduleIdentityUnknownUUID)"
    }
}

private extension Data {
    func littleEndianUInt32(at offset: Int) -> UInt32 {
        let end = offset + 4
        guard offset >= 0, end <= count else {
            return 0
        }

        let bytes = self[offset..<end]
        return bytes.enumerated().reduce(UInt32(0)) { result, element in
            result | UInt32(element.element) << UInt32(element.offset * 8)
        }
    }
}
