import XCTest
@testable import TrainerCore

final class MachMemoryTests: XCTestCase {
    func testAttachFailureIncludesTaskForPIDContext() {
        let access = MachMemoryAccess()
        let process = TargetProcess(pid: -1, name: "invalid", executablePath: "/invalid")

        XCTAssertThrowsError(try access.attach(to: process)) { error in
            XCTAssertTrue(error.localizedDescription.contains("task_for_pid(-1) failed"))
        }
    }

    func testCurrentProcessReadWriteUsesRealMachCalls() throws {
        let access = MachMemoryAccess()
        let session = access.currentProcessSession()
        var value = Int32(11)
        let address = UInt64(UInt(bitPattern: withUnsafePointer(to: &value) { $0 }))
        let newValue = try ScanValue.parse(kind: .int32, text: "77")

        try session.write(MemoryWriteRequest(address: address, data: try newValue.encodedBytes()))
        let data = try session.read(MemoryReadRequest(address: address, size: MemoryLayout<Int32>.size))
        let decoded = ScanValue.decode(kind: .int32, data: data, offset: 0)

        XCTAssertEqual(decoded?.intValue, 77)
        XCTAssertEqual(value, 77)
    }

    func testCurrentProcessInstructionCacheFlushUsesRealMachCall() throws {
        let access = MachMemoryAccess()
        let session = access.currentProcessSession()
        var value = Int32(11)
        let address = UInt64(UInt(bitPattern: withUnsafePointer(to: &value) { $0 }))

        try session.flushCache(MemoryCacheFlushRequest(
            address: address,
            size: UInt64(MemoryLayout<Int32>.size),
            kind: .instruction
        ))
    }
}
