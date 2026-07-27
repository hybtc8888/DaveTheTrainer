import XCTest
@testable import TrainerCore

final class ProcessResolverTests: XCTestCase {
    func testExactExecutablePathWinsOverEarlierNameMatch() throws {
        let request = Self.request(executablePath: "/Applications/Dave.app/Contents/MacOS/DAVE THE DIVER")
        let nameOnlyMatch = TargetProcess(
            pid: 10,
            name: request.executableName,
            executablePath: "/Custom/Dave.app/Contents/MacOS/DAVE THE DIVER"
        )
        let exactMatch = TargetProcess(
            pid: 20,
            name: request.executableName,
            executablePath: request.executablePath
        )

        let process = try LibProcProcessResolver.selectProcess(
            from: [nameOnlyMatch, exactMatch],
            request: request
        )

        XCTAssertEqual(process, exactMatch)
    }

    func testUniqueNameMatchSupportsNonstandardInstallPath() throws {
        let request = Self.request(executablePath: KnownGameBuild.current.executablePath)
        let relocatedProcess = TargetProcess(
            pid: 30,
            name: request.executableName,
            executablePath: "/Volumes/Games/Dave.app/Contents/MacOS/DAVE THE DIVER"
        )

        let process = try LibProcProcessResolver.selectProcess(from: [relocatedProcess], request: request)

        XCTAssertEqual(process, relocatedProcess)
    }

    func testMultipleNameMatchesFailInsteadOfSelectingArbitraryProcess() {
        let request = Self.request(executablePath: KnownGameBuild.current.executablePath)
        let candidates = [
            TargetProcess(pid: 40, name: request.executableName, executablePath: "/One/DAVE THE DIVER"),
            TargetProcess(pid: 50, name: request.executableName, executablePath: "/Two/DAVE THE DIVER")
        ]

        XCTAssertThrowsError(try LibProcProcessResolver.selectProcess(from: candidates, request: request)) { error in
            guard case TrainerError.processQueryFailed = error else {
                XCTFail("Expected processQueryFailed, got \(error)")
                return
            }
        }
    }

    func testMissingProcessFailsExplicitly() {
        let request = Self.request(executablePath: KnownGameBuild.current.executablePath)

        XCTAssertThrowsError(try LibProcProcessResolver.selectProcess(from: [], request: request)) { error in
            guard case TrainerError.processNotFound = error else {
                XCTFail("Expected processNotFound, got \(error)")
                return
            }
        }
    }

    private static func request(executablePath: String) -> ProcessResolveRequest {
        ProcessResolveRequest(
            bundleID: KnownGameBuild.current.bundleID,
            executableName: "DAVE THE DIVER",
            executablePath: executablePath
        )
    }
}
