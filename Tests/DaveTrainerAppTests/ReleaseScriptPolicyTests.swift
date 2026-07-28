import XCTest

final class ReleaseScriptPolicyTests: XCTestCase {
    func testBuildScriptCreatesRealDistAppInsteadOfSymlinkOnlyArtifact() throws {
        let script = try Self.readProjectFile("script/build_and_run.sh")

        XCTAssertFalse(script.contains("ln -s \"$LOCAL_APP_BUNDLE\" \"$APP_BUNDLE\""))
        XCTAssertTrue(script.contains("/usr/bin/ditto --norsrc"))
        XCTAssertTrue(script.contains("COPYFILE_DISABLE=1"))
        XCTAssertTrue(script.contains("/usr/bin/ditto --norsrc -c -k --keepParent"))
        XCTAssertTrue(script.contains("CFBundleShortVersionString"))
        XCTAssertTrue(script.contains("DaveTrainerManifestSchemaVersion"))
        XCTAssertTrue(script.contains("DaveTrainerGitCommit"))
        XCTAssertTrue(script.contains("DaveTrainerBuildDate"))
        XCTAssertTrue(script.contains("APP_VERSION=\"${DAVE_TRAINER_VERSION:-0.1.3}\""))
        XCTAssertTrue(script.contains("APP_BUILD_VERSION=\"${DAVE_TRAINER_BUILD_VERSION:-4}\""))
    }

    func testReleasePackageUsesReleaseBuildAndRequiresExplicitSigningIdentity() throws {
        let script = try Self.readProjectFile("script/build_and_run.sh")

        XCTAssertTrue(script.contains("--release-package|release-package"))
        XCTAssertTrue(script.contains("swift build -c release"))
        XCTAssertTrue(script.contains("DAVE_TRAINER_SIGN_IDENTITY is required for release packages"))
        XCTAssertTrue(script.contains("BUNDLE_ID=\"${DAVE_TRAINER_BUNDLE_ID:-com.github.davethetrainer.DaveTheTrainer}\""))
    }

    func testReleasePackageVerifiesZipHasNoAppleDoubleMetadata() throws {
        let script = try Self.readProjectFile("script/build_and_run.sh")

        XCTAssertTrue(script.contains("zipinfo -1 \"$APP_ZIP\""))
        XCTAssertTrue(script.contains("(^|/)\\._|\\.DS_Store"))
        XCTAssertTrue(script.contains("mktemp -d \"${TMPDIR:-/tmp}/davetrainer-release-verify.XXXXXX\""))
        XCTAssertTrue(script.contains("trap cleanup EXIT"))
        XCTAssertTrue(script.contains("/usr/bin/ditto -x -k \"$APP_ZIP\" \"$ZIP_VERIFY_DIR\""))
        XCTAssertTrue(script.contains("/usr/bin/codesign --verify --deep --strict \"$ZIP_VERIFY_DIR/$APP_NAME.app\""))
    }

    func testRuntimeLivePatchCliRequiresExplicitDevelopmentFlag() throws {
        let source = try Self.readProjectFile("Sources/DaveTrainerApp/App/RuntimeCommandLineTool.swift")

        XCTAssertTrue(source.contains("DAVE_TRAINER_ENABLE_LIVE_PATCH_CLI"))
        XCTAssertTrue(source.contains("Live patch CLI is disabled"))
    }

    func testAdministratorRelaunchDoesNotUseFixedTmpRootLogPath() throws {
        let source = try Self.readProjectFile("Sources/DaveTrainerApp/Stores/AppStore.swift")

        XCTAssertFalse(source.contains("/tmp/DaveTheTrainer-admin.log"))
        XCTAssertTrue(source.contains("FileManager.default.temporaryDirectory"))
        XCTAssertTrue(source.contains("UUID().uuidString"))
    }

    func testBuildScriptKeepsLatestAppsInConfigurableUserApplicationsAndProjectDist() throws {
        let script = try Self.readProjectFile("script/build_and_run.sh")

        XCTAssertFalse(script.contains("/Users/"))
        XCTAssertTrue(script.contains("DEFAULT_LOCAL_APP_DIR=\"${HOME:?HOME is required}/Applications\""))
        XCTAssertTrue(script.contains("LOCAL_APP_DIR=\"${DAVE_TRAINER_LOCAL_APP_DIR:-$DEFAULT_LOCAL_APP_DIR}\""))
        XCTAssertTrue(script.contains("DIST_DIR=\"$ROOT_DIR/dist\""))
        XCTAssertTrue(script.contains("APP_ZIP=\"$DIST_DIR/$APP_ZIP_FILE_NAME\""))
        XCTAssertTrue(script.contains("mktemp -d \"${TMPDIR:-/tmp}/davetrainer-release-stage.XXXXXX\""))
        XCTAssertFalse(script.contains("/private/tmp/$APP_NAME"))
    }

    func testReleaseChecksumUsesPortableAssetNameAndVerifiesIt() throws {
        let script = try Self.readProjectFile("script/build_and_run.sh")

        XCTAssertTrue(script.contains("APP_ZIP_FILE_NAME=\"$APP_NAME-v$APP_VERSION-macOS.zip\""))
        XCTAssertTrue(script.contains("/usr/bin/shasum -a 256 \"$APP_ZIP_FILE_NAME\""))
        XCTAssertTrue(script.contains("/usr/bin/shasum -a 256 -c"))
    }

    func testPlayerFooterUsesPackagedVersionMetadata() throws {
        let source = try Self.readProjectFile("Sources/DaveTrainerApp/Views/SimpleTrainerView.swift")

        XCTAssertFalse(source.contains("Local Mac V2 ICache"))
        XCTAssertTrue(source.contains("CFBundleShortVersionString"))
        XCTAssertTrue(source.contains("CFBundleVersion"))
    }

    func testPasswordlessAdminScriptDoesNotInstallBroadGuiSudoersRule() throws {
        let script = try Self.readProjectFile("script/install_passwordless_admin.sh")

        XCTAssertFalse(script.contains("NOPASSWD"))
        XCTAssertFalse(script.contains("/etc/sudoers.d"))
        XCTAssertTrue(script.contains("passwordless administrator launch is intentionally unsupported"))
    }

    func testUninstallScriptRequiresExplicitLegacyCleanupFlag() throws {
        let script = try Self.readProjectFile("script/uninstall_passwordless_admin.sh")

        XCTAssertTrue(script.contains("--legacy-cleanup"))
        XCTAssertTrue(script.contains("Refusing to remove privileged legacy files without --legacy-cleanup"))
    }

    func testPublicRepositoryBoundaryFilesExistAndIgnoreLocalArtifacts() throws {
        let requiredFiles = [
            "README.md",
            "LICENSE",
            "CONTRIBUTING.md",
            "SECURITY.md",
            "CHANGELOG.md",
            "docs/permissions-and-privacy.md",
            "docs/development-fixtures.md",
            "docs/release-checklist.md"
        ]

        for path in requiredFiles {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }

        let gitignore = try Self.readProjectFile(".gitignore")
        for pattern in ["tmp/", ".codex/", ".agents/", "docs/superpowers/", "*.log", "*.dSYM", "*.xcarchive"] {
            XCTAssertTrue(gitignore.contains(pattern), pattern)
        }
    }

    private static func readProjectFile(_ path: String) throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = root.appendingPathComponent(path)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
