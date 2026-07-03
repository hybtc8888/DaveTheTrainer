import Foundation

public struct FeatureWriteRequest: Sendable {
    public let feature: TrainerFeature
    public let value: ScanValue
    public let addressBook: AddressBook

    public init(feature: TrainerFeature, value: ScanValue, addressBook: AddressBook) {
        self.feature = feature
        self.value = value
        self.addressBook = addressBook
    }
}

public final class FeatureWriter {
    public init() {}

    public func write(_ request: FeatureWriteRequest, session: MemorySession) throws {
        let entry = try request.addressBook.entry(for: request.feature.id, expectedBuild: request.feature.requiredBuild)
        guard entry.valueKind == request.value.kind else {
            throw TrainerError.invalidInput("地址表类型 \(entry.valueKind.rawValue) 与写入类型 \(request.value.kind.rawValue) 不一致。")
        }

        let data = try request.value.encodedBytes()
        try session.write(MemoryWriteRequest(address: entry.address, data: data))
    }
}
