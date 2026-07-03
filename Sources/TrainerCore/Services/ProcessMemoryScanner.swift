import Foundation

private let bytesPerMebibyte = 1024 * 1024
private let processScanChunkMebibytes = 16
private let processScanChunkByteCount = processScanChunkMebibytes * bytesPerMebibyte

public struct ProcessScanRequest: Sendable {
    public let target: ScanValue

    public init(target: ScanValue) {
        self.target = target
    }
}

public struct ProcessScanFailure: Identifiable, Equatable, Sendable {
    public let regionAddress: UInt64
    public let reason: String

    public var id: UInt64 {
        regionAddress
    }

    public init(regionAddress: UInt64, reason: String) {
        self.regionAddress = regionAddress
        self.reason = reason
    }
}

public struct ProcessScanReport: Sendable {
    public let candidates: [ScanCandidate]
    public let failures: [ProcessScanFailure]

    public init(candidates: [ScanCandidate], failures: [ProcessScanFailure]) {
        self.candidates = candidates
        self.failures = failures
    }
}

public final class ProcessMemoryScanner {
    private let scanner: MemoryScanner

    public init(scanner: MemoryScanner = MemoryScanner()) {
        self.scanner = scanner
    }

    public func scanExact(_ request: ProcessScanRequest, session: MemorySession) throws -> ProcessScanReport {
        let regions = try session.regions().filter(\.canContainMutableValue)
        let partialReports = regions.map { region in
            scanRegion(region, request: request, session: session)
        }

        return ProcessScanReport(
            candidates: partialReports.flatMap(\.candidates),
            failures: partialReports.flatMap(\.failures)
        )
    }

    private func scanRegion(_ region: MemoryRegion, request: ProcessScanRequest, session: MemorySession) -> ProcessScanReport {
        let overlapByteCount = UInt64(request.target.kind.byteWidth - 1)
        var offset = UInt64.zero
        var candidates: [ScanCandidate] = []
        var failures: [ProcessScanFailure] = []

        while offset < region.size {
            let remainingByteCount = region.size - offset
            let readSize = Int(min(UInt64(processScanChunkByteCount), remainingByteCount))
            let readAddress = region.address + offset

            let readRequest = MemoryReadRequest(address: readAddress, size: readSize)
            let report = scanChunk(readRequest, scanRequest: request, session: session)
            candidates.append(contentsOf: report.candidates)
            failures.append(contentsOf: report.failures)

            let step = UInt64(readSize) > overlapByteCount ? UInt64(readSize) - overlapByteCount : UInt64(readSize)
            offset += step
        }

        return ProcessScanReport(candidates: uniqueCandidates(candidates), failures: failures)
    }

    private func scanChunk(_ readRequest: MemoryReadRequest, scanRequest: ProcessScanRequest, session: MemorySession) -> ProcessScanReport {
        do {
            let data = try session.read(readRequest)
            let candidates = scanner.scanExact(ExactScanRequest(buffer: data, baseAddress: readRequest.address, target: scanRequest.target))
            return ProcessScanReport(candidates: candidates, failures: [])
        } catch {
            let failure = ProcessScanFailure(regionAddress: readRequest.address, reason: error.localizedDescription)
            return ProcessScanReport(candidates: [], failures: [failure])
        }
    }

    private func uniqueCandidates(_ candidates: [ScanCandidate]) -> [ScanCandidate] {
        var seenAddresses = Set<UInt64>()
        return candidates.filter { candidate in
            seenAddresses.insert(candidate.address).inserted
        }
    }
}

private extension MemoryRegion {
    var canContainMutableValue: Bool {
        isReadable && isWritable
    }
}
