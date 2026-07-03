import Foundation
import MachMemory

private let pidGrowthFactor = 2
private let minimumPIDCapacity = 1
private let maxPIDCapacity = Int(Int32.max)
private let processPathBufferSize = Int(DT_PROCESS_PATH_BUFFER_SIZE)

public final class LibProcProcessResolver: ProcessResolving {
    public init() {}

    public func resolve(_ request: ProcessResolveRequest) throws -> TargetProcess {
        let processes = try listProcesses()
        guard let process = processes.first(where: { matches($0, request: request) }) else {
            throw TrainerError.processNotFound
        }
        return process
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

    private func matches(_ process: TargetProcess, request: ProcessResolveRequest) -> Bool {
        process.executablePath == request.executablePath || process.name == request.executableName
    }

    private func doubled(_ value: Int) throws -> Int {
        guard value <= maxPIDCapacity / pidGrowthFactor else {
            throw TrainerError.processQueryFailed("PID 缓冲区大小溢出")
        }
        return value * pidGrowthFactor
    }
}
