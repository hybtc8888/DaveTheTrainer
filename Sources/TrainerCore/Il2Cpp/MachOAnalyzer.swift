import Foundation

private let fatMagic = UInt32(0xCAFEBABE)
private let machOMagic64 = UInt32(0xFEEDFACF)
private let cpuTypeARM64 = UInt32(0x0100000C)
private let fatHeaderByteWidth = 8
private let fatArchByteWidth = 20
private let machHeader64ByteWidth = 32
private let loadCommandHeaderByteWidth = 8
private let nlist64ByteWidth = 16
private let lcSegment64 = UInt32(0x19)
private let lcSymtab = UInt32(0x2)
private let lcUUID = UInt32(0x1B)
private let symbolPrefixLookupByteWidth = 4

public struct MachOSymbol: Equatable, Sendable {
    public let name: String
    public let address: UInt64
    public let type: UInt8
    public let sectionIndex: UInt8

    public init(name: String, address: UInt64, type: UInt8, sectionIndex: UInt8) {
        self.name = name
        self.address = address
        self.type = type
        self.sectionIndex = sectionIndex
    }
}

public struct MachOSection: Equatable, Sendable {
    public let segmentName: String
    public let sectionName: String
    public let address: UInt64
    public let size: UInt64
    public let fileOffset: UInt64

    public init(segmentName: String, sectionName: String, address: UInt64, size: UInt64, fileOffset: UInt64) {
        self.segmentName = segmentName
        self.sectionName = sectionName
        self.address = address
        self.size = size
        self.fileOffset = fileOffset
    }
}

public struct MachOAnalysis: Equatable, Sendable {
    public let uuid: String?
    public let sections: [MachOSection]
    public let symbols: [String: [MachOSymbol]]

    public init(uuid: String?, sections: [MachOSection], symbols: [String: [MachOSymbol]]) {
        self.uuid = uuid
        self.sections = sections
        self.symbols = symbols
    }
}

struct MachOByteReadRequest: Equatable, Sendable {
    let id: String
    let rva: UInt64
    let count: Int
}

enum MachOByteReadResult: Equatable, Sendable {
    case bytes([UInt8])
    case unmapped(String)
}

struct MachOByteReadEvidence: Equatable, Sendable {
    let request: MachOByteReadRequest
    let result: MachOByteReadResult
}

struct MachOSymbolReadEvidence: Equatable, Sendable {
    let symbol: MachOSymbol
    let result: MachOByteReadResult
}

struct MachOBinaryInspectionRequest: Equatable, Sendable {
    let symbolPrefixes: Set<String>
    let byteReads: [MachOByteReadRequest]
    let symbolByteCount: Int
}

struct MachOBinaryInspection: Equatable, Sendable {
    let uuid: String?
    let byteReads: [MachOByteReadEvidence]
    let symbolsByPrefix: [String: [MachOSymbolReadEvidence]]
}

private struct MachOSlice: Sendable {
    let offset: Int
    let size: Int
}

private struct MachOLoadCommandScan: Sendable {
    let uuid: String?
    let sections: [MachOSection]
    let symoff: Int?
    let nsyms: Int?
    let stroff: Int?
    let strsize: Int?
}

private struct MachOParsedImage {
    let data: Data
    let slice: MachOSlice
    let scan: MachOLoadCommandScan
}

private struct MachOSymbolTableLocation {
    let offset: Int
    let count: Int
}

private struct MatchedSymbolString {
    let name: String
    let prefixes: [String]
}

private struct SymbolPrefixDescriptor {
    let value: String
    let bytes: [UInt8]
    let lookupKey: UInt32
}

public final class MachOAnalyzer {
    public init() {}

    public func analyzeArm64(url: URL, targetSymbols: Set<String>) throws -> MachOAnalysis {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let slice = try arm64Slice(in: data)
        let scan = try scanLoadCommands(data: data, slice: slice)
        let image = MachOParsedImage(data: data, slice: slice, scan: scan)
        let symbols = try readSymbols(image: image, targetSymbols: targetSymbols)
        return MachOAnalysis(uuid: scan.uuid, sections: scan.sections, symbols: symbols)
    }

    func inspectArm64(url: URL, request: MachOBinaryInspectionRequest) throws -> MachOBinaryInspection {
        guard request.symbolByteCount > 0 else {
            throw TrainerError.invalidInput("Mach-O 符号证据读取长度必须大于零。")
        }

        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let slice = try arm64Slice(in: data)
        let scan = try scanLoadCommands(data: data, slice: slice)
        let image = MachOParsedImage(data: data, slice: slice, scan: scan)
        let symbols = try readSymbolsMatchingPrefixes(image: image, prefixes: request.symbolPrefixes)
        let byteReads = request.byteReads.map {
            readEvidence(request: $0, image: image)
        }
        let symbolsByPrefix = symbols.mapValues { matches in
            matches.map { symbol in
                let read = MachOByteReadRequest(
                    id: symbol.name,
                    rva: symbol.address,
                    count: request.symbolByteCount
                )
                return MachOSymbolReadEvidence(
                    symbol: symbol,
                    result: readEvidence(request: read, image: image).result
                )
            }
        }
        return MachOBinaryInspection(uuid: scan.uuid, byteReads: byteReads, symbolsByPrefix: symbolsByPrefix)
    }

    private func arm64Slice(in data: Data) throws -> MachOSlice {
        let magic = try data.uint32BE(at: 0)
        if magic == fatMagic {
            return try arm64FatSlice(in: data)
        }

        let littleMagic = try data.uint32LE(at: 0)
        guard littleMagic == machOMagic64 else {
            throw TrainerError.fileOperationFailed("GameAssembly.dylib 不是 Mach-O 64 或 FAT Mach-O。")
        }
        return MachOSlice(offset: 0, size: data.count)
    }

    private func arm64FatSlice(in data: Data) throws -> MachOSlice {
        let archCount = Int(try data.uint32BE(at: 4))
        for index in 0..<archCount {
            let offset = fatHeaderByteWidth + index * fatArchByteWidth
            let cpuType = try data.uint32BE(at: offset)
            guard cpuType == cpuTypeARM64 else {
                continue
            }

            let sliceOffset = Int(try data.uint32BE(at: offset + 8))
            let sliceSize = Int(try data.uint32BE(at: offset + 12))
            try validateSlice(offset: sliceOffset, size: sliceSize, dataCount: data.count)
            return MachOSlice(offset: sliceOffset, size: sliceSize)
        }

        throw TrainerError.fileOperationFailed("GameAssembly.dylib 缺少 arm64 slice。")
    }

    private func validateSlice(offset: Int, size: Int, dataCount: Int) throws {
        guard offset >= 0, size > 0, offset + size <= dataCount else {
            throw TrainerError.fileOperationFailed("Mach-O slice 越界：offset=\(offset), size=\(size)")
        }
    }

    private func scanLoadCommands(data: Data, slice: MachOSlice) throws -> MachOLoadCommandScan {
        let headerOffset = slice.offset
        let magic = try data.uint32LE(at: headerOffset)
        guard magic == machOMagic64 else {
            throw TrainerError.fileOperationFailed("arm64 slice magic 不匹配：0x\(String(magic, radix: 16))")
        }

        let commandCount = Int(try data.uint32LE(at: headerOffset + 16))
        var offset = headerOffset + machHeader64ByteWidth
        var sections: [MachOSection] = []
        var uuid: String?
        var symtab = (symoff: Int?.none, nsyms: Int?.none, stroff: Int?.none, strsize: Int?.none)

        for _ in 0..<commandCount {
            let command = try data.uint32LE(at: offset)
            let commandSize = Int(try data.uint32LE(at: offset + 4))
            try validateLoadCommand(offset: offset, size: commandSize, slice: slice)

            if command == lcSegment64 {
                sections.append(contentsOf: try readSections(commandOffset: offset, data: data))
            } else if command == lcSymtab {
                symtab = try readSymtab(commandOffset: offset, data: data)
            } else if command == lcUUID {
                uuid = try readUUID(commandOffset: offset, data: data)
            }

            offset += commandSize
        }

        return MachOLoadCommandScan(uuid: uuid, sections: sections, symoff: symtab.symoff, nsyms: symtab.nsyms, stroff: symtab.stroff, strsize: symtab.strsize)
    }

    private func validateLoadCommand(offset: Int, size: Int, slice: MachOSlice) throws {
        let sliceEnd = slice.offset + slice.size
        guard size >= loadCommandHeaderByteWidth, offset + size <= sliceEnd else {
            throw TrainerError.fileOperationFailed("Mach-O load command 越界。")
        }
    }

    private func readSections(commandOffset: Int, data: Data) throws -> [MachOSection] {
        let segmentName = try data.fixedString(at: commandOffset + 8, length: 16)
        let sectionCount = Int(try data.uint32LE(at: commandOffset + 64))
        let sectionBase = commandOffset + 72
        return try (0..<sectionCount).map { index in
            let offset = sectionBase + index * 80
            return MachOSection(
                segmentName: segmentName,
                sectionName: try data.fixedString(at: offset, length: 16),
                address: try data.uint64LE(at: offset + 32),
                size: try data.uint64LE(at: offset + 40),
                fileOffset: UInt64(try data.uint32LE(at: offset + 48))
            )
        }
    }

    private func readSymtab(commandOffset: Int, data: Data) throws -> (symoff: Int?, nsyms: Int?, stroff: Int?, strsize: Int?) {
        (
            symoff: Int(try data.uint32LE(at: commandOffset + 8)),
            nsyms: Int(try data.uint32LE(at: commandOffset + 12)),
            stroff: Int(try data.uint32LE(at: commandOffset + 16)),
            strsize: Int(try data.uint32LE(at: commandOffset + 20))
        )
    }

    private func readUUID(commandOffset: Int, data: Data) throws -> String {
        let bytes = try data.bytes(at: commandOffset + 8, count: 16)
        let hex = bytes.map { String(format: "%02X", $0) }
        return "\(hex[0...3].joined())-\(hex[4...5].joined())-\(hex[6...7].joined())-\(hex[8...9].joined())-\(hex[10...15].joined())"
    }

    private func readSymbols(
        image: MachOParsedImage,
        targetSymbols: Set<String>
    ) throws -> [String: [MachOSymbol]] {
        guard let symoff = image.scan.symoff, let nsyms = image.scan.nsyms,
              let stroff = image.scan.stroff, let strsize = image.scan.strsize else {
            throw TrainerError.fileOperationFailed("GameAssembly.dylib 缺少 LC_SYMTAB。")
        }

        let stringTable = try image.data.range(offset: image.slice.offset + stroff, size: strsize)
        let targetStringOffsets = findTargetStringOffsets(targetSymbols: targetSymbols, stringTable: stringTable)
        return try readMatchingSymbols(
            image: image,
            table: MachOSymbolTableLocation(offset: symoff, count: nsyms),
            offsets: targetStringOffsets
        )
    }

    private func findTargetStringOffsets(targetSymbols: Set<String>, stringTable: Data) -> [UInt32: String] {
        targetSymbols.reduce(into: [UInt32: String]()) { result, symbol in
            let needle = Data((symbol + "\0").utf8)
            guard let range = stringTable.range(of: needle), let index = UInt32(exactly: range.lowerBound) else {
                return
            }
            result[index] = symbol
        }
    }

    private func readMatchingSymbols(
        image: MachOParsedImage,
        table: MachOSymbolTableLocation,
        offsets: [UInt32: String]
    ) throws -> [String: [MachOSymbol]] {
        var result: [String: [MachOSymbol]] = [:]
        let symbolTableOffset = image.slice.offset + table.offset
        for index in 0..<table.count {
            let offset = symbolTableOffset + index * nlist64ByteWidth
            let stringOffset = try image.data.uint32LE(at: offset)
            guard let name = offsets[stringOffset] else {
                continue
            }

            let symbol = MachOSymbol(
                name: name,
                address: try image.data.uint64LE(at: offset + 8),
                type: try image.data.uint8(at: offset + 4),
                sectionIndex: try image.data.uint8(at: offset + 5)
            )
            result[name, default: []].append(symbol)
        }
        return result
    }

    private func readSymbolsMatchingPrefixes(
        image: MachOParsedImage,
        prefixes: Set<String>
    ) throws -> [String: [MachOSymbol]] {
        guard !prefixes.isEmpty else {
            return [:]
        }
        guard let symoff = image.scan.symoff, let nsyms = image.scan.nsyms,
              let stroff = image.scan.stroff, let strsize = image.scan.strsize else {
            throw TrainerError.fileOperationFailed("GameAssembly.dylib 缺少 LC_SYMTAB。")
        }

        let stringTable = try image.data.range(offset: image.slice.offset + stroff, size: strsize)
        let matchedStrings = try findPrefixStringOffsets(prefixes: prefixes, stringTable: stringTable)
        return try readPrefixSymbols(
            image: image,
            table: MachOSymbolTableLocation(offset: symoff, count: nsyms),
            matchedStrings: matchedStrings
        )
    }

    private func findPrefixStringOffsets(
        prefixes: Set<String>,
        stringTable: Data
    ) throws -> [UInt32: MatchedSymbolString] {
        let descriptors = try prefixes.map(makePrefixDescriptor).sorted { $0.value < $1.value }
        let descriptorsByKey = Dictionary(grouping: descriptors, by: \.lookupKey)
        return try stringTable.withUnsafeBytes { rawBuffer in
            var result: [UInt32: MatchedSymbolString] = [:]
            var start = 0
            while start < rawBuffer.count {
                let end = nextNullOffset(in: rawBuffer, start: start)
                if let match = matchingSymbolString(
                    in: rawBuffer,
                    bounds: start..<end,
                    descriptorsByKey: descriptorsByKey
                ) {
                    guard let offset = UInt32(exactly: start) else {
                        throw TrainerError.fileOperationFailed("Mach-O 字符串表偏移超过 UInt32。")
                    }
                    result[offset] = match
                }
                start = end + 1
            }
            return result
        }
    }

    private func makePrefixDescriptor(_ prefix: String) throws -> SymbolPrefixDescriptor {
        let bytes = Array(prefix.utf8)
        guard bytes.count >= symbolPrefixLookupByteWidth else {
            throw TrainerError.invalidInput("Mach-O 符号前缀至少需要 \(symbolPrefixLookupByteWidth) 个 UTF-8 字节：\(prefix)")
        }
        return SymbolPrefixDescriptor(
            value: prefix,
            bytes: bytes,
            lookupKey: Self.prefixLookupKey(bytes: bytes, offset: 0)
        )
    }

    private func nextNullOffset(in buffer: UnsafeRawBufferPointer, start: Int) -> Int {
        var offset = start
        while offset < buffer.count, buffer[offset] != 0 {
            offset += 1
        }
        return offset
    }

    private func matchingSymbolString(
        in buffer: UnsafeRawBufferPointer,
        bounds: Range<Int>,
        descriptorsByKey: [UInt32: [SymbolPrefixDescriptor]]
    ) -> MatchedSymbolString? {
        guard bounds.count >= symbolPrefixLookupByteWidth else {
            return nil
        }
        let key = Self.prefixLookupKey(buffer: buffer, offset: bounds.lowerBound)
        guard let candidates = descriptorsByKey[key] else {
            return nil
        }

        let matches = candidates.filter { descriptor in
            Self.buffer(buffer, bounds: bounds, hasPrefix: descriptor.bytes)
        }
        guard !matches.isEmpty else {
            return nil
        }
        let name = String(decoding: buffer[bounds], as: UTF8.self)
        return MatchedSymbolString(name: name, prefixes: matches.map(\.value))
    }

    private func readPrefixSymbols(
        image: MachOParsedImage,
        table: MachOSymbolTableLocation,
        matchedStrings: [UInt32: MatchedSymbolString]
    ) throws -> [String: [MachOSymbol]] {
        let tableOffset = image.slice.offset + table.offset
        let tableSize = table.count * nlist64ByteWidth
        guard tableOffset >= image.slice.offset,
              tableOffset + tableSize <= image.slice.offset + image.slice.size else {
            throw TrainerError.fileOperationFailed("Mach-O 符号表越界。")
        }

        return image.data.withUnsafeBytes { buffer in
            var result: [String: [MachOSymbol]] = [:]
            for index in 0..<table.count {
                let offset = tableOffset + index * nlist64ByteWidth
                let stringOffset = Self.uint32LE(in: buffer, offset: offset)
                guard let matched = matchedStrings[stringOffset] else {
                    continue
                }
                let symbol = MachOSymbol(
                    name: matched.name,
                    address: Self.uint64LE(in: buffer, offset: offset + 8),
                    type: buffer[offset + 4],
                    sectionIndex: buffer[offset + 5]
                )
                for prefix in matched.prefixes {
                    result[prefix, default: []].append(symbol)
                }
            }
            return result.mapValues { $0.sorted { $0.address < $1.address } }
        }
    }

    private func readEvidence(
        request: MachOByteReadRequest,
        image: MachOParsedImage
    ) -> MachOByteReadEvidence {
        guard let fileOffset = mappedFileOffset(request: request, image: image) else {
            return MachOByteReadEvidence(
                request: request,
                result: .unmapped("RVA 0x\(String(request.rva, radix: 16)) 不在可读取的文件 section 内。")
            )
        }

        do {
            return MachOByteReadEvidence(
                request: request,
                result: .bytes(try image.data.bytes(at: fileOffset, count: request.count))
            )
        } catch {
            return MachOByteReadEvidence(request: request, result: .unmapped(error.localizedDescription))
        }
    }

    private func mappedFileOffset(
        request: MachOByteReadRequest,
        image: MachOParsedImage
    ) -> Int? {
        guard request.count >= 0, let byteCount = UInt64(exactly: request.count) else {
            return nil
        }
        let requestedEnd = request.rva.addingReportingOverflow(byteCount)
        guard !requestedEnd.overflow else {
            return nil
        }

        for section in image.scan.sections {
            guard contains(rva: request.rva, end: requestedEnd.partialValue, section: section) else {
                continue
            }
            let relativeOffset = section.fileOffset + (request.rva - section.address)
            guard let fileOffset = Int(exactly: relativeOffset),
                  fileOffset + request.count <= image.slice.size else {
                return nil
            }
            return image.slice.offset + fileOffset
        }
        return nil
    }

    private func contains(rva: UInt64, end: UInt64, section: MachOSection) -> Bool {
        let sectionEnd = section.address.addingReportingOverflow(section.size)
        guard !sectionEnd.overflow else {
            return false
        }
        return rva >= section.address && end <= sectionEnd.partialValue
    }

    private static func prefixLookupKey(bytes: [UInt8], offset: Int) -> UInt32 {
        bytes[offset..<(offset + symbolPrefixLookupByteWidth)].enumerated().reduce(UInt32.zero) { result, item in
            result | UInt32(item.element) << UInt32(item.offset * UInt8.bitWidth)
        }
    }

    private static func prefixLookupKey(buffer: UnsafeRawBufferPointer, offset: Int) -> UInt32 {
        (0..<symbolPrefixLookupByteWidth).reduce(UInt32.zero) { result, index in
            result | UInt32(buffer[offset + index]) << UInt32(index * UInt8.bitWidth)
        }
    }

    private static func buffer(
        _ buffer: UnsafeRawBufferPointer,
        bounds: Range<Int>,
        hasPrefix prefix: [UInt8]
    ) -> Bool {
        guard bounds.lowerBound + prefix.count <= bounds.upperBound else {
            return false
        }
        for index in prefix.indices where buffer[bounds.lowerBound + index] != prefix[index] {
            return false
        }
        return true
    }

    private static func uint32LE(in buffer: UnsafeRawBufferPointer, offset: Int) -> UInt32 {
        (0..<MemoryLayout<UInt32>.size).reduce(UInt32.zero) { result, index in
            result | UInt32(buffer[offset + index]) << UInt32(index * UInt8.bitWidth)
        }
    }

    private static func uint64LE(in buffer: UnsafeRawBufferPointer, offset: Int) -> UInt64 {
        (0..<MemoryLayout<UInt64>.size).reduce(UInt64.zero) { result, index in
            result | UInt64(buffer[offset + index]) << UInt64(index * UInt8.bitWidth)
        }
    }
}

private extension Data {
    func uint8(at offset: Int) throws -> UInt8 {
        guard offset >= 0, offset < count else {
            throw TrainerError.fileOperationFailed("读取 UInt8 越界：\(offset)")
        }
        return self[offset]
    }

    func uint32BE(at offset: Int) throws -> UInt32 {
        let bytes = try bytes(at: offset, count: 4)
        return bytes.reduce(UInt32.zero) { partial, byte in
            (partial << UInt32(UInt8.bitWidth)) | UInt32(byte)
        }
    }

    func uint32LE(at offset: Int) throws -> UInt32 {
        let bytes = try bytes(at: offset, count: 4)
        return bytes.enumerated().reduce(UInt32.zero) { partial, item in
            partial | (UInt32(item.element) << UInt32(item.offset * UInt8.bitWidth))
        }
    }

    func uint64LE(at offset: Int) throws -> UInt64 {
        let bytes = try bytes(at: offset, count: 8)
        return bytes.enumerated().reduce(UInt64.zero) { partial, item in
            partial | (UInt64(item.element) << UInt64(item.offset * UInt8.bitWidth))
        }
    }

    func fixedString(at offset: Int, length: Int) throws -> String {
        let bytes = try bytes(at: offset, count: length)
        let trimmed = bytes.prefix { $0 != 0 }
        return String(decoding: trimmed, as: UTF8.self)
    }

    func bytes(at offset: Int, count requestedCount: Int) throws -> [UInt8] {
        guard offset >= 0, requestedCount >= 0, offset + requestedCount <= count else {
            throw TrainerError.fileOperationFailed("读取字节越界：offset=\(offset), count=\(requestedCount)")
        }
        return Array(self[offset..<(offset + requestedCount)])
    }

    func range(offset: Int, size: Int) throws -> Data {
        guard offset >= 0, size >= 0, offset + size <= count else {
            throw TrainerError.fileOperationFailed("读取 Data range 越界：offset=\(offset), size=\(size)")
        }
        return Data(self[offset..<(offset + size)])
    }
}
