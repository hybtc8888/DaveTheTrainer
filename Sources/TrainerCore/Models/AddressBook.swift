import Foundation

public struct AddressEntry: Codable, Equatable, Identifiable, Sendable {
    public let featureID: String
    public let address: UInt64
    public let valueKind: ScanValueKind
    public let note: String

    public var id: String {
        featureID
    }

    public init(featureID: String, details: AddressEntryDetails) {
        self.featureID = featureID
        self.address = details.address
        self.valueKind = details.valueKind
        self.note = details.note
    }
}

public struct AddressEntryDetails: Codable, Equatable, Sendable {
    public let address: UInt64
    public let valueKind: ScanValueKind
    public let note: String

    public init(address: UInt64, valueKind: ScanValueKind, note: String) {
        self.address = address
        self.valueKind = valueKind
        self.note = note
    }
}

public struct AddressBook: Codable, Equatable, Sendable {
    public let build: GameBuildSignature
    public let entries: [String: AddressEntry]

    public init(build: GameBuildSignature, entries: [String: AddressEntry]) {
        self.build = build
        self.entries = entries
    }

    public static func empty(build: GameBuildSignature) -> AddressBook {
        AddressBook(build: build, entries: [:])
    }

    public func entry(for featureID: String, expectedBuild: GameBuildSignature) throws -> AddressEntry {
        guard build == expectedBuild else {
            throw TrainerError.buildMismatch(expected: expectedBuild, actual: build)
        }

        guard let entry = entries[featureID] else {
            throw TrainerError.addressNotCalibrated(featureID: featureID)
        }

        return entry
    }

    public func updating(_ entry: AddressEntry, expectedBuild: GameBuildSignature) throws -> AddressBook {
        guard build == expectedBuild else {
            throw TrainerError.buildMismatch(expected: expectedBuild, actual: build)
        }

        var nextEntries = entries
        nextEntries[entry.featureID] = entry
        return AddressBook(build: build, entries: nextEntries)
    }
}
