import Foundation
import MachMemory

private let pidGrowthFactor = 2
private let minimumPIDCapacity = 1
private let maxPIDCapacity = Int(Int32.max)
private let processPathBufferSize = Int(DT_PROCESS_PATH_BUFFER_SIZE)

public final class LibProcProcessResolver: ProcessResolving {
    public init() {}

    public func resolve(_ request: ProcessResolveRequest) throws -> TargetProcess {
        try Self.selectProcess(from: listProcesses(), request: request)
    }

    static func selectProcess(from processes: [TargetProcess], request: ProcessResolveRequest) throws -> TargetProcess {
        let exactPathMatches = processes.filter {
            canonicalPath($0.executablePath) == canonicalPath(request.executablePath)
        }
        if !exactPathMatches.isEmpty {
            return try uniqueProcess(from: exactPathMatches)
        }

        let nameMatches = processes.filter { process in
            process.name == request.executableName
                || URL(fileURLWithPath: process.executablePath).lastPathComponent == request.executableName
        }
        guard !nameMatches.isEmpty else {
            throw TrainerError.processNotFound
        }
        return try uniqueProcess(from: nameMatches)
    }

    public func listProcesses() throws -> [TargetProcess] {
        let pids = try readPIDs()
        return pids.compactMap { pid in
            readProcess(pid: pid)
        }
    }

    private func readPIDs() throws -> [pid_t] {
        let byteCount = dt_pid_list_byte_count()
        guard byteCount > 0 else {
            throw TrainerError.processQueryFailed("proc_listpids 返回 \(byteCount)")
        }

        let requestedCapacity = Int(byteCount) / MemoryLayout<pid_t>.stride
        guard requestedCapacity <= maxPIDCapacity else {
            throw TrainerError.processQueryFailed("PID 缓冲区容量超出 Int32 上限")
        }

        var capacity = max(requestedCapacity, minimumPIDCapacity)
        while true {
            var pids = [pid_t](repeating: 0, count: capacity)
            let count = dt_list_pids(&pids, Int32(capacity))
            guard count >= 0 else {
                throw TrainerError.processQueryFailed("dt_list_pids 返回 \(count)")
            }

            guard Int(count) < capacity else {
                capacity = try doubled(capacity)
                continue
            }

            return pids.prefix(Int(count)).filter { $0 > 0 }
        }
    }

    private func readProcess(pid: pid_t) -> TargetProcess? {
        guard let path = readString(pid: pid, reader: dt_pid_path), !path.isEmpty else {
            return nil
        }

        let name = readString(pid: pid, reader: dt_pid_name) ?? URL(fileURLWithPath: path).lastPathComponent
        return TargetProcess(pid: pid, name: name, executablePath: path)
    }

    private func readString(pid: pid_t, reader: (pid_t, UnsafeMutablePointer<CChar>?, Int32) -> Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: processPathBufferSize)
        let length = buffer.withUnsafeMutableBufferPointer { rawBuffer in
            reader(pid, rawBuffer.baseAddress, Int32(rawBuffer.count))
        }
        guard length > 0 else {
            return nil
        }
        return String(cString: buffer)
    }

    private static func uniqueProcess(from processes: [TargetProcess]) throws -> TargetProcess {
        guard processes.count == 1, let process = processes.first else {
            let processIDs = processes.map { String($0.pid) }.joined(separator: ", ")
            throw TrainerError.processQueryFailed("发现多个 DAVE THE DIVER 候选进程（PID \(processIDs)），无法安全选择目标。")
        }
        return process
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }

    private func doubled(_ value: Int) throws -> Int {
        guard value <= maxPIDCapacity / pidGrowthFactor else {
            throw TrainerError.processQueryFailed("PID 缓冲区大小溢出")
        }
        return value * pidGrowthFactor
    }
}
