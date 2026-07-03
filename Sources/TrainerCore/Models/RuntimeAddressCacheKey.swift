import Foundation

public struct RuntimeAddressCacheKey: Hashable, Codable, Sendable {
    public let processID: Int32
    public let buildGUID: String
    public let moduleBaseAddress: UInt64
    public let moduleIdentity: String
    public let featureID: String

    public init(
        processID: Int32,
        buildGUID: String,
        moduleBaseAddress: UInt64,
        moduleIdentity: String,
        featureID: String
    ) {
        self.processID = processID
        self.buildGUID = buildGUID
        self.moduleBaseAddress = moduleBaseAddress
        self.moduleIdentity = moduleIdentity
        self.featureID = featureID
    }
}
