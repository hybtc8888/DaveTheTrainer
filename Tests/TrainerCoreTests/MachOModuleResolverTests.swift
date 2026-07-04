import Foundation
import XCTest
@testable import TrainerCore

private let headerReadSize = 16 * 1024
private let fatMagic = UInt32(0xCAFE_BABE)
private let arm64CPUType = UInt32(0x0100_000C)
private let x86_64CPUType = UInt32(0x0100_0007)
private let fatHeaderByteCount = 8
private let fatArchByteCount = 20

final class MachOModuleResolverTests: XCTestCase {
    func testResolverRejectsMainExecutableHeader() throws {
        let data = try readHeader(path: KnownGameBuild.current.executablePath)
        XCTAssertFalse(MachOModuleResolver.isGameAssemblyDylibHeader(data))
    }

    func testResolverAcceptsGameAssemblyDylibHeader() throws {
        let data = try readHeader(path: gameAssemblyPath)
        XCTAssertTrue(MachOModuleResolver.isGameAssemblyDylibHeader(data))
    }

    func testResolverRejectsX86GameAssemblyDylibHeader() throws {
        let data = try readHeader(path: gameAssemblyPath, cpuType: x86_64CPUType)
        XCTAssertFalse(MachOModuleResolver.isGameAssemblyDylibHeader(data))
    }

    func testResolverExtractsGameAssemblyArm64UUID() throws {
        let data = try readHeader(path: gameAssemblyPath)
        let identity = MachOModuleResolver.moduleIdentity(in: data)

        XCTAssertEqual(identity.moduleName, "GameAssembly.dylib")
        XCTAssertEqual(identity.architecture, "arm64")
        XCTAssertEqual(identity.machoUUID, "7BA6FD17-58B4-31CC-A621-45EE26D462F9")
        XCTAssertEqual(identity.cacheKey, "GameAssembly.dylib:arm64:7BA6FD17-58B4-31CC-A621-45EE26D462F9")
    }

    func testStrictPolicyRejectsExpectedGameAssemblyUUIDMismatch() throws {
        let session = SingleModuleSession(data: try readHeader(path: gameAssemblyPath))
        let resolver = MachOModuleResolver(expectedModuleIdentity: DaveModuleIdentity(
            id: DaveTrainerManifest.gameAssemblyModuleID,
            moduleName: "GameAssembly.dylib",
            architecture: "arm64",
            machoUUID: "00000000-0000-0000-0000-000000000000",
            pathMatchPolicy: "image-name"
        ), validationPolicy: .strict)

        XCTAssertThrowsError(try resolver.resolveGameAssembly(session: session)) { error in
            guard case TrainerError.targetMismatch = error else {
                XCTFail("Expected targetMismatch, got \(error)")
                return
            }
        }
    }

    func testAdaptivePolicyAcceptsGameAssemblyUUIDMismatchAsProfileSignal() throws {
        let session = SingleModuleSession(data: try readHeader(path: gameAssemblyPath))
        let resolver = MachOModuleResolver(expectedModuleIdentity: DaveModuleIdentity(
            id: DaveTrainerManifest.gameAssemblyModuleID,
            moduleName: "GameAssembly.dylib",
            architecture: "arm64",
            machoUUID: "00000000-0000-0000-0000-000000000000",
            pathMatchPolicy: "image-name"
        ))

        let module = try resolver.resolveGameAssembly(session: session)

        XCTAssertEqual(module.moduleIdentity, "GameAssembly.dylib:arm64:7BA6FD17-58B4-31CC-A621-45EE26D462F9")
        XCTAssertEqual(module.identityValidation, .uuidMismatch(
            expected: "00000000-0000-0000-0000-000000000000",
            actual: "7BA6FD17-58B4-31CC-A621-45EE26D462F9"
        ))
    }

    private func readHeader(path: String, cpuType: UInt32 = arm64CPUType) throws -> Data {
        let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
        defer {
            try? handle.close()
        }

        let prefix = try handle.read(upToCount: headerReadSize) ?? Data()
        guard prefix.bigEndianUInt32(at: 0) == fatMagic else {
            return prefix
        }

        let offset = try sliceOffset(in: prefix, cpuType: cpuType)
        try handle.seek(toOffset: offset)
        return try handle.read(upToCount: headerReadSize) ?? Data()
    }

    private func sliceOffset(in data: Data, cpuType expectedCPUType: UInt32) throws -> UInt64 {
        let archCount = Int(data.bigEndianUInt32(at: 4))
        for index in 0..<archCount {
            let offset = fatHeaderByteCount + index * fatArchByteCount
            guard offset + fatArchByteCount <= data.count else {
                break
            }
            if data.bigEndianUInt32(at: offset) == expectedCPUType {
                return UInt64(data.bigEndianUInt32(at: offset + 8))
            }
        }

        throw TrainerError.fileOperationFailed("Mach-O 文件缺少请求的 CPU slice：\(expectedCPUType)。")
    }
}

private final class SingleModuleSession: ModuleMemorySession {
    private let baseAddress: UInt64
    private let data: Data

    init(baseAddress: UInt64 = 0x1_0000_0000, data: Data) {
        self.baseAddress = baseAddress
        self.data = data
    }

    func read(_ request: MemoryReadRequest) throws -> Data {
        guard request.address == baseAddress, request.size <= data.count else {
            throw TrainerError.memoryReadFailed("unexpected test read")
        }
        return data.prefix(request.size)
    }

    func regions() throws -> [MemoryRegion] {
        [
            MemoryRegion(descriptor: MemoryRegionDescriptor(
                range: MemoryRange(address: baseAddress, size: UInt64(data.count)),
                protection: MemoryProtectionInfo(
                    current: MemoryProtection.read | MemoryProtection.execute,
                    maximum: MemoryProtection.read | MemoryProtection.execute
                ),
                flags: MemoryRegionFlags(isSubmap: false, userTag: 0)
            ))
        ]
    }
}

private var gameAssemblyPath: String {
    URL(fileURLWithPath: KnownGameBuild.current.executablePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Frameworks/GameAssembly.dylib")
        .path
}

private extension Data {
    func bigEndianUInt32(at offset: Int) -> UInt32 {
        let end = offset + 4
        guard offset >= 0, end <= count else {
            return 0
        }

        let bytes = self[offset..<end]
        return bytes.reduce(UInt32(0)) { result, byte in
            (result << 8) | UInt32(byte)
        }
    }
}
