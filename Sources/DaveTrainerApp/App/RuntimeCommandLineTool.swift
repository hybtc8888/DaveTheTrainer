import Darwin
import Foundation
import TrainerCore

private let livePatchRequiredValueCount = 2
private let gameExecutableName = "DAVE THE DIVER"
private let livePatchCLIEnvironmentFlag = "DAVE_TRAINER_ENABLE_LIVE_PATCH_CLI"

enum RuntimeCommandLineTool {
    static func runIfRequested(arguments: [String]) {
        do {
            if try handle(arguments: arguments) {
                exit(EXIT_SUCCESS)
            }
        } catch {
            writeStandardError("ERROR: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        }
    }

    private static func handle(arguments: [String]) throws -> Bool {
        if arguments.contains(RuntimeArguments.printEffectiveUserID) {
            print(geteuid())
            return true
        }

        guard let command = try LivePatchCommand.parse(arguments: arguments) else {
            return false
        }
        guard isLivePatchCLIEnabled(environment: ProcessInfo.processInfo.environment) else {
            throw TrainerError.invalidInput("Live patch CLI is disabled. Set \(livePatchCLIEnvironmentFlag)=1 only for explicit development diagnostics.")
        }

        try applyLivePatch(command)
        return true
    }

    private static func isLivePatchCLIEnabled(environment: [String: String]) -> Bool {
        environment[livePatchCLIEnvironmentFlag] == "1"
    }

    private static func applyLivePatch(_ command: LivePatchCommand) throws {
        let target = try resolveGameProcess()
        let session = try MachMemoryAccess().attach(to: target)
        let patch = try buildPatch(command)
        let engine = StaticPatchEngine()
        if command.mode == .verify {
            try engine.verify(patch, session: session)
        } else {
            try engine.apply(
                StaticPatchApplyRequest(patch: patch, isEnabled: command.isEnabled),
                session: session
            )
        }
        print("OK: \(command.mode.rawValue) patch=\(patch.id) pid=\(target.pid) points=\(patch.points.count)")
    }

    private static func buildPatch(_ command: LivePatchCommand) throws -> StaticGamePatch {
        if let patch = DefaultStaticGamePatches.make().first(where: { $0.id == command.patchID }) {
            return patch
        }

        guard let valueText = command.valueText else {
            throw TrainerError.invalidInput("数值 patch 需要提供 value：\(command.patchID)")
        }
        return try DefaultStaticGamePatches.makeValuePatch(id: command.patchID, valueText: valueText)
    }

    private static func resolveGameProcess() throws -> TargetProcess {
        let request = ProcessResolveRequest(
            bundleID: KnownGameBuild.current.bundleID,
            executableName: gameExecutableName,
            executablePath: KnownGameBuild.current.executablePath
        )
        return try LibProcProcessResolver().resolve(request)
    }

    private static func writeStandardError(_ message: String) {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
    }
}

private struct LivePatchCommand {
    let mode: LivePatchMode
    let patchID: String
    let valueText: String?

    var isEnabled: Bool {
        mode != .disable
    }

    static func parse(arguments: [String]) throws -> LivePatchCommand? {
        guard let markerIndex = arguments.firstIndex(of: RuntimeArguments.livePatch) else {
            return nil
        }

        let values = Array(arguments.dropFirst(markerIndex + 1))
        guard values.count >= livePatchRequiredValueCount else {
            throw TrainerError.invalidInput(Self.usage)
        }

        let mode = try LivePatchMode(rawValueOrThrow: values[0])
        let patchID = values[1]
        let valueText = values.dropFirst(2).first
        return LivePatchCommand(mode: mode, patchID: patchID, valueText: valueText)
    }

    private static let usage = "用法：\(RuntimeArguments.livePatch) enable|disable|verify <patchID> [value]"
}

private enum LivePatchMode: String {
    case enable
    case disable
    case verify

    init(rawValueOrThrow rawValue: String) throws {
        guard let mode = Self(rawValue: rawValue) else {
            throw TrainerError.invalidInput("未知 live patch 模式：\(rawValue)")
        }
        self = mode
    }
}
