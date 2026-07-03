import Foundation

private let addressBookFileName = "address-book.json"

public final class AddressBookStore {
    private let fileManager: FileManager
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileManager: FileManager = .default, fileURL: URL? = nil) throws {
        self.fileManager = fileManager
        self.fileURL = try fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load(build: GameBuildSignature) throws -> AddressBook {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .empty(build: build)
        }

        let data = try Data(contentsOf: fileURL)
        let book = try decoder.decode(AddressBook.self, from: data)
        guard book.build == build else {
            throw TrainerError.buildMismatch(expected: build, actual: book.build)
        }
        return book
    }

    public func save(_ book: AddressBook) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(book)
        try data.write(to: fileURL, options: .atomic)
    }

    public static func defaultFileURL(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("DaveTheTrainer", isDirectory: true).appendingPathComponent(addressBookFileName)
    }
}
