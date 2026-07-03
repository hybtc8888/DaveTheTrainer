import Foundation

public struct FeatureIncrementRequest: Sendable {
    public let feature: TrainerFeature
    public let delta: Int64
    public let addressBook: AddressBook

    public init(feature: TrainerFeature, delta: Int64, addressBook: AddressBook) {
        self.feature = feature
        self.delta = delta
        self.addressBook = addressBook
    }
}

public struct FeatureIncrementResult: Sendable, Equatable {
    public let previous: ScanValue
    public let next: ScanValue

    public init(previous: ScanValue, next: ScanValue) {
        self.previous = previous
        self.next = next
    }
}

public final class FeatureIncrementer {
    public init() {}

    public func increment(_ request: FeatureIncrementRequest, session: MemorySession) throws -> FeatureIncrementResult {
        let entry = try request.addressBook.entry(for: request.feature.id, expectedBuild: request.feature.requiredBuild)
        guard entry.valueKind == request.feature.valueKind else {
            throw TrainerError.invalidInput("地址表类型 \(entry.valueKind.rawValue) 与功能类型 \(request.feature.valueKind.rawValue) 不一致。")
        }

        let data = try session.read(MemoryReadRequest(address: entry.address, size: entry.valueKind.byteWidth))
        guard let previous = ScanValue.decode(kind: entry.valueKind, data: data, offset: 0) else {
            throw TrainerError.memoryReadFailed("无法解码 \(request.feature.title) 当前值：0x\(String(entry.address, radix: 16))。")
        }

        let next = try incrementedValue(previous, delta: request.delta)
        try session.write(MemoryWriteRequest(address: entry.address, data: try next.encodedBytes()))
        return FeatureIncrementResult(previous: previous, next: next)
    }

    private func incrementedValue(_ value: ScanValue, delta: Int64) throws -> ScanValue {
        switch value.kind {
        case .int32:
            guard let current = value.intValue else {
                throw TrainerError.invalidInput("Int32 增量缺少当前值。")
            }
            guard let currentInt32 = Int32(exactly: current) else {
                throw TrainerError.invalidInput("Int32 增量当前值越界。")
            }
            let next = try adjustedQuantity(
                current: currentInt32,
                delta: delta,
                overflowMessage: "Int32 增量结果越界。"
            )
            return ScanValue(kind: .int32, intValue: Int64(next))
        case .int64:
            guard let current = value.intValue else {
                throw TrainerError.invalidInput("Int64 增量缺少当前值。")
            }
            let next = try adjustedQuantity(
                current: current,
                delta: delta,
                overflowMessage: "Int64 增量结果越界。"
            )
            return ScanValue(kind: .int64, intValue: next)
        case .float32, .double:
            throw TrainerError.invalidInput("增量写入只支持整数数量。")
        }
    }
}
