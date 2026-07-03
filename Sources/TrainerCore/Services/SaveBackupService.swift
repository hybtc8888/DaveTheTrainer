import Foundation

private let backupDateFormat = "yyyyMMdd-HHmmss-SSS"
private let savExtension = "sav"

public struct SaveFileSnapshot: Identifiable, Equatable {
    public let url: URL
    public let size: UInt64
    public let modifiedAt: Date?

    public var id: String {
        url.path
    }

    public init(url: URL, size: UInt64, modifiedAt: Date?) {
        self.url = url
        self.size = size
        self.modifiedAt = modifiedAt
    }
}

public struct BackupRequest {
    public let sourceDirectory: URL
    public let destinationRoot: URL

    public init(sourceDirectory: URL, destinationRoot: URL) {
        self.sourceDirectory = sourceDirectory
        self.destinationRoot = destinationRoot
    }
}

public final class SaveBackupService {
    public static let saveDirectoryEnvironmentKey = "DAVE_TRAINER_SAVE_DIR"

    private let fileManager: FileManager
    private let saveDirectory: URL

    public init(
        fileManager: FileManager = .default,
        defaultSaveDirectory: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.fileManager = fileManager
        self.saveDirectory = defaultSaveDirectory ?? Self.resolveDefaultSaveDirectory(environment: environment)
    }

    public var defaultSaveDirectory: URL {
        saveDirectory
    }

    public func inspectSaves(at directory: URL) throws -> [SaveFileSnapshot] {
        let files = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        return try files
            .filter { $0.pathExtension.lowercased() == savExtension }
            .map(snapshot)
            .sorted { $0.url.lastPathComponent < $1.url.lastPathComponent }
    }

    public func createBackup(_ request: BackupRequest) throws -> URL {
        guard fileManager.fileExists(atPath: request.sourceDirectory.path) else {
            throw TrainerError.fileOperationFailed("存档目录不存在：\(request.sourceDirectory.path)")
        }

        try fileManager.createDirectory(at: request.destinationRoot, withIntermediateDirectories: true)
        let destination = request.destinationRoot.appendingPathComponent("DaveSave-\(timestamp())", isDirectory: true)

        guard !fileManager.fileExists(atPath: destination.path) else {
            throw TrainerError.fileOperationFailed("备份目录已存在：\(destination.path)")
        }

        try fileManager.copyItem(at: request.sourceDirectory, to: destination)
        return destination
    }

    public static func defaultBackupRoot(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("DaveTheTrainer/Backups", isDirectory: true)
    }

    private static func resolveDefaultSaveDirectory(environment: [String: String]) -> URL {
        if let overridePath = environment[saveDirectoryEnvironmentKey], !overridePath.isEmpty {
            return URL(fileURLWithPath: overridePath, isDirectory: true)
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.nexon.dave/SteamSData", isDirectory: true)
    }

    private func snapshot(_ url: URL) throws -> SaveFileSnapshot {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        return SaveFileSnapshot(url: url, size: UInt64(values.fileSize ?? 0), modifiedAt: values.contentModificationDate)
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = backupDateFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}
