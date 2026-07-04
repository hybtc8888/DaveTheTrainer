import Foundation

public struct RuntimeAddressCacheKey: Hashable, Codable, Sendable {
    public let processID: Int32
    public let buildFingerprint: String
    public let moduleBaseAddress: UInt64
    public let moduleIdentity: String
    public let featureID: String

    public init(
        processID: Int32,
        buildFingerprint: String,
        moduleBaseAddress: UInt64,
        moduleIdentity: String,
        featureID: String
    ) {
        self.processID = processID
        self.buildFingerprint = buildFingerprint
        self.moduleBaseAddress = moduleBaseAddress
        self.moduleIdentity = moduleIdentity
        self.featureID = featureID
    }
}
