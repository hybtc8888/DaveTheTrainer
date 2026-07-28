import Foundation

private let il2CppMetadataMagic = UInt32(0xFAB11BAF)
private let metadataStringTableHeaderOffset = 0x18
private let metadataMethodDefinitionsHeaderOffset = 0x30
private let metadataFieldDefinitionsHeaderOffset = 0x60
private let methodDefinitionByteWidth = 36
private let fieldDefinitionByteWidth = 12
private let methodTokenOffset = 24
private let fieldTokenOffset = 8

public struct Il2CppMetadataRange: Equatable, Sendable {
    public let offset: Int
    public let size: Int

    public var bounds: Range<Int> {
        offset..<(offset + size)
    }

    public init(offset: Int, size: Int) {
        self.offset = offset
        self.size = size
    }
}

public struct Il2CppMetadataHeader: Equatable, Sendable {
    public let version: UInt32
    public let stringTable: Il2CppMetadataRange
    public let methodDefinitions: Il2CppMetadataRange
    public let fieldDefinitions: Il2CppMetadataRange

    public init(version: UInt32, stringTable: Il2CppMetadataRange, methodDefinitions: Il2CppMetadataRange, fieldDefinitions: Il2CppMetadataRange) {
        self.version = version
        self.stringTable = stringTable
        self.methodDefinitions = methodDefinitions
        self.fieldDefinitions = fieldDefinitions
    }
}

public struct Il2CppMetadataMethod: Equatable, Sendable {
    public let row: Int
    public let token: UInt32

    public init(row: Int, token: UInt32) {
        self.row = row
        self.token = token
    }
}

public struct Il2CppMetadataField: Equatable, Sendable {
    public let row: Int
    public let token: UInt32

    public init(row: Int, token: UInt32) {
        self.row = row
        self.token = token
    }
}

public struct Il2CppMetadataNameMatch: Equatable, Sendable {
    public let name: String
    public let rawOffsets: [Int]
    public let stringIndex: UInt32?
    public let stringOffset: Int?
    public let method: Il2CppMetadataMethod?
    public let field: Il2CppMetadataField?

    public var isInStringTable: Bool {
        stringIndex != nil
    }

    public init(name: String, rawOffsets: [Int], stringIndex: UInt32?, stringOffset: Int?, method: Il2CppMetadataMethod?, field: Il2CppMetadataField?) {
        self.name = name
        self.rawOffsets = rawOffsets
        self.stringIndex = stringIndex
        self.stringOffset = stringOffset
        self.method = method
        self.field = field
    }
}

public struct Il2CppMetadataAnalysis: Equatable, Sendable {
    public let header: Il2CppMetadataHeader
    public let matches: [String: Il2CppMetadataNameMatch]

    public init(header: Il2CppMetadataHeader, matches: [String: Il2CppMetadataNameMatch]) {
        self.header = header
        self.matches = matches
    }
}

public final class Il2CppMetadataAnalyzer {
    public init() {}

    public func analyze(metadataURL: URL, targetNames: [String]) throws -> Il2CppMetadataAnalysis {
        let data = try Data(contentsOf: metadataURL, options: .mappedIfSafe)
        let header = try parseHeader(data)
        let uniqueNames = Array(Set(targetNames)).sorted()
        let stringIndices = try findStringTableIndices(names: uniqueNames, header: header, data: data)
        let methods = try findMethods(indices: stringIndices, header: header, data: data)
        let fields = try findFields(indices: stringIndices, header: header, data: data)
        let matches = try uniqueNames.reduce(into: [String: Il2CppMetadataNameMatch]()) { result, name in
            let rawOffsets = try data.findAll(Data((name).utf8))
            let stringIndex = stringIndices[name]
            let match = Il2CppMetadataNameMatch(
                name: name,
                rawOffsets: rawOffsets,
                stringIndex: stringIndex,
                stringOffset: stringIndex.map { header.stringTable.offset + Int($0) },
                method: stringIndex.flatMap { methods[$0] },
                field: stringIndex.flatMap { fields[$0] }
            )
            result[name] = match
        }
        return Il2CppMetadataAnalysis(header: header, matches: matches)
    }

    private func parseHeader(_ data: Data) throws -> Il2CppMetadataHeader {
        let magic = try data.uint32LE(at: 0)
        guard magic == il2CppMetadataMagic else {
            throw TrainerError.fileOperationFailed("global-metadata.dat magic 不匹配：0x\(String(magic, radix: 16))")
        }

        let version = try data.uint32LE(at: 4)
        return Il2CppMetadataHeader(
            version: version,
            stringTable: try metadataRange(at: metadataStringTableHeaderOffset, data: data),
            methodDefinitions: try metadataRange(at: metadataMethodDefinitionsHeaderOffset, data: data),
            fieldDefinitions: try metadataRange(at: metadataFieldDefinitionsHeaderOffset, data: data)
        )
    }

    private func metadataRange(at headerOffset: Int, data: Data) throws -> Il2CppMetadataRange {
        let offset = Int(try data.uint32LE(at: headerOffset))
        let size = Int(try data.uint32LE(at: headerOffset + MemoryLayout<UInt32>.size))
        guard offset >= 0, size >= 0, offset + size <= data.count else {
            throw TrainerError.fileOperationFailed("metadata 表越界：offset=\(offset), size=\(size)")
        }
        return Il2CppMetadataRange(offset: offset, size: size)
    }

    private func findStringTableIndices(names: [String], header: Il2CppMetadataHeader, data: Data) throws -> [String: UInt32] {
        try names.reduce(into: [String: UInt32]()) { result, name in
            let needle = Data((name + "\0").utf8)
            guard let absoluteOffset = data.firstRange(of: needle, in: header.stringTable.bounds)?.lowerBound else {
                return
            }
            let stringIndex = absoluteOffset - header.stringTable.offset
            guard let exactIndex = UInt32(exactly: stringIndex) else {
                throw TrainerError.fileOperationFailed("metadata 字符串索引越界：\(name)")
            }
            result[name] = exactIndex
        }
    }

    private func findMethods(indices: [String: UInt32], header: Il2CppMetadataHeader, data: Data) throws -> [UInt32: Il2CppMetadataMethod] {
        let wanted = Set(indices.values)
        return try findDefinitions(range: header.methodDefinitions, recordSize: methodDefinitionByteWidth, tokenOffset: methodTokenOffset, wanted: wanted, data: data) { row, token in
            Il2CppMetadataMethod(row: row, token: token)
        }
    }

    private func findFields(indices: [String: UInt32], header: Il2CppMetadataHeader, data: Data) throws -> [UInt32: Il2CppMetadataField] {
        let wanted = Set(indices.values)
        return try findDefinitions(range: header.fieldDefinitions, recordSize: fieldDefinitionByteWidth, tokenOffset: fieldTokenOffset, wanted: wanted, data: data) { row, token in
            Il2CppMetadataField(row: row, token: token)
        }
    }

    private func findDefinitions<T>(
        range: Il2CppMetadataRange,
        recordSize: Int,
        tokenOffset: Int,
        wanted: Set<UInt32>,
        data: Data,
        makeMatch: (Int, UInt32) -> T
    ) throws -> [UInt32: T] {
        guard !wanted.isEmpty else {
            return [:]
        }
        guard range.size % recordSize == 0 else {
            throw TrainerError.fileOperationFailed("metadata 表大小 \(range.size) 不能整除记录宽度 \(recordSize)。")
        }

        var result: [UInt32: T] = [:]
        for row in 0..<(range.size / recordSize) {
            let recordOffset = range.offset + row * recordSize
            let nameIndex = try data.uint32LE(at: recordOffset)
            guard wanted.contains(nameIndex), result[nameIndex] == nil else {
                continue
            }

            let token = try data.uint32LE(at: recordOffset + tokenOffset)
            result[nameIndex] = makeMatch(row, token)
        }
        return result
    }
}

private extension Data {
    func uint32LE(at offset: Int) throws -> UInt32 {
        guard offset >= 0, offset + MemoryLayout<UInt32>.size <= count else {
            throw TrainerError.fileOperationFailed("读取 UInt32 越界：\(offset)")
        }
        return self[offset..<(offset + 4)].enumerated().reduce(UInt32.zero) { partial, item in
            partial | (UInt32(item.element) << UInt32(item.offset * UInt8.bitWidth))
        }
    }

    func firstRange(of needle: Data, in bounds: Range<Int>) -> Range<Int>? {
        self[bounds].range(of: needle).map { absoluteRange in
            absoluteRange.lowerBound..<absoluteRange.upperBound
        }
    }

    func findAll(_ needle: Data) throws -> [Int] {
        guard !needle.isEmpty else {
            throw TrainerError.invalidInput("metadata 搜索串不能为空。")
        }

        var result: [Int] = []
        var searchStart = startIndex
        while searchStart < endIndex {
            guard let range = self[searchStart..<endIndex].range(of: needle) else {
                return result
            }
            result.append(range.lowerBound)
            searchStart = index(after: range.lowerBound)
        }
        return result
    }
}
