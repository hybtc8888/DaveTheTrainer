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

public final class MachOAnalyzer {
    public init() {}

    public func analyzeArm64(url: URL, targetSymbols: Set<String>) throws -> MachOAnalysis {
        let data = try Data(contentsOf: url)
        let slice = try arm64Slice(in: data)
        let scan = try scanLoadCommands(data: data, slice: slice)
        let symbols = try readSymbols(data: data, slice: slice, scan: scan, targetSymbols: targetSymbols)
        return MachOAnalysis(uuid: scan.uuid, sections: scan.sections, symbols: symbols)
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

    private func readSymbols(data: Data, slice: MachOSlice, scan: MachOLoadCommandScan, targetSymbols: Set<String>) throws -> [String: [MachOSymbol]] {
        guard let symoff = scan.symoff, let nsyms = scan.nsyms, let stroff = scan.stroff, let strsize = scan.strsize else {
            throw TrainerError.fileOperationFailed("GameAssembly.dylib 缺少 LC_SYMTAB。")
        }

        let stringTable = try data.range(offset: slice.offset + stroff, size: strsize)
        let targetStringOffsets = findTargetStringOffsets(targetSymbols: targetSymbols, stringTable: stringTable)
        return try readMatchingSymbols(data: data, slice: slice, symoff: symoff, nsyms: nsyms, offsets: targetStringOffsets)
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

    private func readMatchingSymbols(data: Data, slice: MachOSlice, symoff: Int, nsyms: Int, offsets: [UInt32: String]) throws -> [String: [MachOSymbol]] {
        var result: [String: [MachOSymbol]] = [:]
        let symbolTableOffset = slice.offset + symoff
        for index in 0..<nsyms {
            let offset = symbolTableOffset + index * nlist64ByteWidth
            let stringOffset = try data.uint32LE(at: offset)
            guard let name = offsets[stringOffset] else {
                continue
            }

            let symbol = MachOSymbol(
                name: name,
                address: try data.uint64LE(at: offset + 8),
                type: try data.uint8(at: offset + 4),
                sectionIndex: try data.uint8(at: offset + 5)
            )
            result[name, default: []].append(symbol)
        }
        return result
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
