import XCTest
@testable import TrainerCore

final class GameInstallResolverTests: XCTestCase {
    func testInstalledDaveTheDiverSatisfiesAdaptiveHardRequirements() throws {
        let resolver = GameInstallResolver()

        let install = try resolver.resolveInstalledGame()

        XCTAssertEqual(install.signature.bundleID, KnownGameBuild.current.bundleID)
        XCTAssertFalse(install.signature.version.isEmpty)
        XCTAssertFalse(install.signature.buildGUID.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: install.signature.executablePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: install.signature.metadataPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Self.gameAssemblyPath(for: install.signature)))
    }

    func testResolverAcceptsDaveInstallWithoutVersionOrBootConfig() throws {
        let fixture = try TemporaryDaveInstallFixture(options: .withoutVersionOrBootConfig())
        defer { fixture.remove() }

        let install = try fixture.resolver.resolveInstalledGame()

        XCTAssertEqual(install.signature.bundleID, KnownGameBuild.current.bundleID)
        XCTAssertEqual(install.signature.version, "unknown-version")
        XCTAssertTrue(install.signature.buildGUID.hasPrefix("unknown-build-guid:"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: install.signature.executablePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: install.signature.metadataPath))
    }

    func testResolverAcceptsDaveInstallWithoutBuildGUIDLine() throws {
        let fixture = try TemporaryDaveInstallFixture(options: .withoutBuildGUIDLine())
        defer { fixture.remove() }

        let install = try fixture.resolver.resolveInstalledGame()

        XCTAssertEqual(install.signature.version, "v-test")
        XCTAssertTrue(install.signature.buildGUID.hasPrefix("unknown-build-guid:"))
    }

    func testResolverReadsBuildGUIDWhenPresent() throws {
        let fixture = try TemporaryDaveInstallFixture(options: .standard)
        defer { fixture.remove() }

        let install = try fixture.resolver.resolveInstalledGame()

        XCTAssertEqual(install.signature.buildGUID, "test-guid")
    }

    func testResolverRejectsNonDaveBundle() throws {
        let fixture = try TemporaryDaveInstallFixture(options: .nonDaveBundle)
        defer { fixture.remove() }

        XCTAssertThrowsError(try fixture.resolver.resolveInstalledGame()) { error in
            guard case TrainerError.targetMismatch = error else {
                XCTFail("Expected targetMismatch, got \(error)")
                return
            }
        }
    }

    func testResolverRejectsMissingIl2CppFiles() throws {
        let missingGameAssembly = try TemporaryDaveInstallFixture(options: .withoutGameAssembly)
        defer { missingGameAssembly.remove() }
        XCTAssertThrowsError(try missingGameAssembly.resolver.resolveInstalledGame())

        let missingMetadata = try TemporaryDaveInstallFixture(options: .withoutMetadata)
        defer { missingMetadata.remove() }
        XCTAssertThrowsError(try missingMetadata.resolver.resolveInstalledGame())
    }

    private static func gameAssemblyPath(for signature: GameBuildSignature) -> String {
        URL(fileURLWithPath: signature.executablePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Frameworks/GameAssembly.dylib")
            .path
    }
}

private struct TemporaryDaveInstallOptions {
    var bundleID = KnownGameBuild.current.bundleID
    var includeVersion = true
    var bootConfigText: String? = "build-guid=test-guid\n"
    var includeGameAssembly = true
    var includeMetadata = true

    static let standard = TemporaryDaveInstallOptions()

    static func withoutVersionOrBootConfig() -> TemporaryDaveInstallOptions {
        var options = TemporaryDaveInstallOptions()
        options.includeVersion = false
        options.bootConfigText = nil
        return options
    }

    static func withoutBuildGUIDLine() -> TemporaryDaveInstallOptions {
        var options = TemporaryDaveInstallOptions()
        options.bootConfigText = "gfx-enable-gfx-jobs=1\n"
        return options
    }

    static var nonDaveBundle: TemporaryDaveInstallOptions {
        var options = TemporaryDaveInstallOptions()
        options.bundleID = "com.example.not-dave"
        return options
    }

    static var withoutGameAssembly: TemporaryDaveInstallOptions {
        var options = TemporaryDaveInstallOptions()
        options.includeGameAssembly = false
        return options
    }

    static var withoutMetadata: TemporaryDaveInstallOptions {
        var options = TemporaryDaveInstallOptions()
        options.includeMetadata = false
        return options
    }
}

private final class TemporaryDaveInstallFixture {
    let resolver: GameInstallResolver
    private let rootURL: URL
    private let fileManager: FileManager

    init(options: TemporaryDaveInstallOptions, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        self.rootURL = fileManager.temporaryDirectory
            .appendingPathComponent("DaveInstallResolverTests")
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("DaveTheDiver.app")
        self.resolver = GameInstallResolver(fileManager: fileManager, defaultOuterAppURL: rootURL)
        try makeInstall(options: options)
    }

    func remove() {
        try? fileManager.removeItem(at: rootURL.deletingLastPathComponent())
    }

    private func makeInstall(options: TemporaryDaveInstallOptions) throws {
        let innerAppURL = rootURL.appendingPathComponent("Contents/Game/DaveTheDiver.app")
        let executableURL = innerAppURL.appendingPathComponent("Contents/MacOS/DAVE THE DIVER")
        let metadataURL = innerAppURL.appendingPathComponent("Contents/Resources/Data/il2cpp_data/Metadata/global-metadata.dat")
        let gameAssemblyURL = innerAppURL.appendingPathComponent("Contents/Frameworks/GameAssembly.dylib")
        let bootConfigURL = innerAppURL.appendingPathComponent("Contents/Resources/Data/boot.config")
        let plistURL = innerAppURL.appendingPathComponent("Contents/Info.plist")

        try writeFile(executableURL, data: Data("exe".utf8))
        if options.includeMetadata {
            try writeFile(metadataURL, data: Data("metadata".utf8))
        }
        if options.includeGameAssembly {
            try writeFile(gameAssemblyURL, data: Data("assembly".utf8))
        }
        if let bootConfigText = options.bootConfigText {
            try writeFile(bootConfigURL, data: Data(bootConfigText.utf8))
        }
        try writeInfoPlist(plistURL, options: options)
    }

    private func writeFile(_ url: URL, data: Data) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func writeInfoPlist(_ url: URL, options: TemporaryDaveInstallOptions) throws {
        var plist = ["CFBundleIdentifier": options.bundleID]
        if options.includeVersion {
            plist["CFBundleShortVersionString"] = "v-test"
        }
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: .zero)
        try writeFile(url, data: data)
    }
}
