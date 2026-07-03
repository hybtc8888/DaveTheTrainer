import XCTest
@testable import TrainerCore

final class MemoryScannerTests: XCTestCase {
    func testScanExactInt32FindsExpectedAddress() throws {
        let target = try ScanValue.parse(kind: .int32, text: "42")
        let encodedTarget = try target.encodedBytes()
        let buffer = Data([0, 0, 0, 0]) + encodedTarget + Data([1, 2, 3, 4])
        let scanner = MemoryScanner()

        let candidates = scanner.scanExact(ExactScanRequest(buffer: buffer, baseAddress: 0x1000, target: target))

        XCTAssertEqual(candidates, [ScanCandidate(address: 0x1004, value: target)])
    }

    func testScanExactInt64FindsExpectedAddress() throws {
        let target = try ScanValue.parse(kind: .int64, text: "9876543210")
        let encodedTarget = try target.encodedBytes()
        let buffer = Data([9, 9]) + encodedTarget
        let scanner = MemoryScanner()

        let candidates = scanner.scanExact(ExactScanRequest(buffer: buffer, baseAddress: 0x2000, target: target))

        XCTAssertEqual(candidates, [ScanCandidate(address: 0x2002, value: target)])
    }

    func testScanExactFloat32FindsExpectedAddress() throws {
        let target = try ScanValue.parse(kind: .float32, text: "12.5")
        let encodedTarget = try target.encodedBytes()
        let buffer = Data([1, 2, 3]) + encodedTarget
        let scanner = MemoryScanner()

        let candidates = scanner.scanExact(ExactScanRequest(buffer: buffer, baseAddress: 0x3000, target: target))

        XCTAssertEqual(candidates.map(\.address), [0x3003])
    }

    func testScanExactDoubleFindsExpectedAddress() throws {
        let target = try ScanValue.parse(kind: .double, text: "1234.75")
        let encodedTarget = try target.encodedBytes()
        let buffer = Data([7]) + encodedTarget
        let scanner = MemoryScanner()

        let candidates = scanner.scanExact(ExactScanRequest(buffer: buffer, baseAddress: 0x4000, target: target))

        XCTAssertEqual(candidates.map(\.address), [0x4001])
    }

    func testRescanIncreasedAndDecreased() throws {
        let oldValue = try ScanValue.parse(kind: .int32, text: "10")
        let newValue = try ScanValue.parse(kind: .int32, text: "20")
        let lowerValue = try ScanValue.parse(kind: .int32, text: "5")
        let scanner = MemoryScanner()
        let previous = [ScanCandidate(address: 0x5000, value: oldValue)]

        let increasedSnapshot = MemorySnapshot(buffer: try newValue.encodedBytes(), baseAddress: 0x5000)
        let decreasedSnapshot = MemorySnapshot(buffer: try lowerValue.encodedBytes(), baseAddress: 0x5000)
        let increased = scanner.rescan(RescanRequest(previous: previous, snapshot: increasedSnapshot, comparison: .increased))
        let decreased = scanner.rescan(RescanRequest(previous: previous, snapshot: decreasedSnapshot, comparison: .decreased))

        XCTAssertEqual(increased.map(\.address), [0x5000])
        XCTAssertEqual(decreased.map(\.address), [0x5000])
    }
}
