import Foundation

private let innerAppRelativePath = "Contents/Game/DaveTheDiver.app"
private let innerExecutableRelativePath = "Contents/MacOS/DAVE THE DIVER"
private let metadataRelativePath = "Contents/Resources/Data/il2cpp_data/Metadata/global-metadata.dat"
private let gameAssemblyRelativePath = "Contents/Frameworks/GameAssembly.dylib"
private let bootConfigRelativePath = "Contents/Resources/Data/boot.config"
private let infoPlistRelativePath = "Contents/Info.plist"
private let buildGUIDPrefix = "build-guid="
private let unknownVersionFingerprint = "unknown-version"

public struct GameInstall {
    public let outerAppURL: URL
    public let innerAppURL: URL
    public let signature: GameBuildSignature

    public init(outerAppURL: URL, innerAppURL: URL, signature: GameBuildSignature) {
        self.outerAppURL = outerAppURL
        self.innerAppURL = innerAppURL
        self.signature = signature
    }
}

public protocol GameInstallResolving {
    func resolveInstalledGame() throws -> GameInstall
    func validateCurrentInstall() throws -> GameInstall
}

public final class GameInstallResolver: GameInstallResolving {
    private let fileManager: FileManager
    private let defaultOuterAppURL: URL

    public init(fileManager: FileManager = .default, defaultOuterAppURL: URL = URL(fileURLWithPath: "/Applications/DaveTheDiver.app")) {
        self.fileManager = fileManager
        self.defaultOuterAppURL = defaultOuterAppURL
    }

    public func resolveInstalledGame() throws -> GameInstall {
        try resolve(at: defaultOuterAppURL)
    }

    public func resolve(at outerAppURL: URL) throws -> GameInstall {
        let innerAppURL = outerAppURL.appendingPathComponent(innerAppRelativePath)
        let executableURL = innerAppURL.appendingPathComponent(innerExecutableRelativePath)
        let metadataURL = innerAppURL.appendingPathComponent(metadataRelativePath)
        let gameAssemblyURL = innerAppURL.appendingPathComponent(gameAssemblyRelativePath)
        let plistURL = innerAppURL.appendingPathComponent(infoPlistRelativePath)
        let bootConfigURL = innerAppURL.appendingPathComponent(bootConfigRelativePath)

        try requireFile(executableURL)
        try requireFile(metadataURL)
        try requireFile(gameAssemblyURL)

        let plist = try readPlist(plistURL)
        let signature = GameBuildSignature(
            identity: GameBuildIdentity(
                bundleID: try stringValue("CFBundleIdentifier", in: plist),
                version: optionalStringValue("CFBundleShortVersionString", in: plist) ?? unknownVersionFingerprint,
                buildGUID: buildGUID(from: bootConfigURL, gameAssemblyURL: gameAssemblyURL, metadataURL: metadataURL)
            ),
            paths: GameBuildPaths(
                executablePath: executableURL.path,
                metadataPath: metadataURL.path
            )
        )
        try requireDaveBundle(signature)

        return GameInstall(outerAppURL: outerAppURL, innerAppURL: innerAppURL, signature: signature)
    }

    public func validateCurrentInstall() throws -> GameInstall {
        try resolveInstalledGame()
    }

    private func requireFile(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw TrainerError.installNotFound(url.path)
        }
    }

    private func readPlist(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dictionary = object as? [String: Any] else {
            throw TrainerError.installNotFound("Info.plist 不是字典：\(url.path)")
        }
        return dictionary
    }

    private func stringValue(_ key: String, in plist: [String: Any]) throws -> String {
        guard let value = plist[key] as? String, !value.isEmpty else {
            throw TrainerError.installNotFound("Info.plist 缺少 \(key)")
        }
        return value
    }

    private func optionalStringValue(_ key: String, in plist: [String: Any]) -> String? {
        guard let value = plist[key] as? String, !value.isEmpty else {
            return nil
        }
        return value
    }

    private func requireDaveBundle(_ signature: GameBuildSignature) throws {
        guard signature.isDaveTheDiverBundle else {
            throw TrainerError.targetMismatch("Bundle ID 不匹配。期望 \(KnownGameBuild.current.bundleID)，实际 \(signature.bundleID)。")
        }
    }

    private func buildGUID(from bootConfigURL: URL, gameAssemblyURL: URL, metadataURL: URL) -> String {
        if let buildGUID = readBuildGUID(bootConfigURL), !buildGUID.isEmpty {
            return buildGUID
        }
        return unknownBuildGUID(gameAssemblyURL: gameAssemblyURL, metadataURL: metadataURL)
    }

    private func readBuildGUID(_ url: URL) -> String? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        guard let line = text.split(separator: "\n").first(where: { $0.hasPrefix(buildGUIDPrefix) }) else {
            return nil
        }
        return String(line.dropFirst(buildGUIDPrefix.count))
    }

    private func unknownBuildGUID(gameAssemblyURL: URL, metadataURL: URL) -> String {
        let assemblyFingerprint = fileFingerprint(gameAssemblyURL)
        let metadataFingerprint = fileFingerprint(metadataURL)
        return "unknown-build-guid:assembly-\(assemblyFingerprint):metadata-\(metadataFingerprint)"
    }

    private func fileFingerprint(_ url: URL) -> String {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return "unreadable"
        }
        let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        let modified = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        return "\(size)-\(Int(modified))"
    }
}
