import Foundation

private let byteScanStride = 1

public enum ScanComparison: String, Codable, Sendable {
    case exact
    case increased
    case decreased
}

public struct ScanCandidate: Codable, Equatable, Identifiable, Sendable {
    public let address: UInt64
    public let value: ScanValue

    public var id: UInt64 {
        address
    }

    public init(address: UInt64, value: ScanValue) {
        self.address = address
        self.value = value
    }
}

public struct ExactScanRequest: Sendable {
    public let buffer: Data
    public let baseAddress: UInt64
    public let target: ScanValue

    public init(buffer: Data, baseAddress: UInt64, target: ScanValue) {
        self.buffer = buffer
        self.baseAddress = baseAddress
        self.target = target
    }
}

public struct RescanRequest: Sendable {
    public let previous: [ScanCandidate]
    public let buffer: Data
    public let baseAddress: UInt64
    public let comparison: ScanComparison

    public init(previous: [ScanCandidate], snapshot: MemorySnapshot, comparison: ScanComparison) {
        self.previous = previous
        self.buffer = snapshot.buffer
        self.baseAddress = snapshot.baseAddress
        self.comparison = comparison
    }
}

public struct MemorySnapshot: Sendable {
    public let buffer: Data
    public let baseAddress: UInt64

    public init(buffer: Data, baseAddress: UInt64) {
        self.buffer = buffer
        self.baseAddress = baseAddress
    }
}

public struct MemoryScanner {
    public init() {}

    public func scanExact(_ request: ExactScanRequest) -> [ScanCandidate] {
        let width = request.target.kind.byteWidth
        guard request.buffer.count >= width else {
            return []
        }

        let upperBound = request.buffer.count - width
        return stride(from: 0, through: upperBound, by: byteScanStride).compactMap { offset in
            candidate(offset: offset, request: request)
        }
    }

    public func rescan(_ request: RescanRequest) -> [ScanCandidate] {
        request.previous.compactMap { previous in
            let relativeAddress = previous.address.subtractingReportingOverflow(request.baseAddress)
            guard !relativeAddress.overflow, let offset = Int(exactly: relativeAddress.partialValue) else {
                return nil
            }

            guard let current = ScanValue.decode(kind: previous.value.kind, data: request.buffer, offset: offset) else {
                return nil
            }

            return matches(current: current, previous: previous.value, comparison: request.comparison)
                ? ScanCandidate(address: previous.address, value: current)
                : nil
        }
    }

    private func candidate(offset: Int, request: ExactScanRequest) -> ScanCandidate? {
        guard let value = ScanValue.decode(kind: request.target.kind, data: request.buffer, offset: offset) else {
            return nil
        }

        guard value.isEqual(to: request.target), let offset64 = UInt64(exactly: offset) else {
            return nil
        }

        return ScanCandidate(address: request.baseAddress + offset64, value: value)
    }

    private func matches(current: ScanValue, previous: ScanValue, comparison: ScanComparison) -> Bool {
        switch comparison {
        case .exact:
            return current.isEqual(to: previous)
        case .increased:
            return current.isGreater(than: previous)
        case .decreased:
            return current.isLess(than: previous)
        }
    }
}
