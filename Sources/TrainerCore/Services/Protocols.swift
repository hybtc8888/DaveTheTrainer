import Foundation

public protocol ProcessResolving {
    func resolve(_ request: ProcessResolveRequest) throws -> TargetProcess
}

public protocol MemoryAccess {
    func attach(to process: TargetProcess) throws -> MemorySession
}
