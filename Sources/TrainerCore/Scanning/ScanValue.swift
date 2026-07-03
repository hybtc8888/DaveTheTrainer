import Foundation

private let defaultFloatEpsilon = 0.0001

public struct ScanValue: Codable, Equatable, Sendable {
    public let kind: ScanValueKind
    public let intValue: Int64?
    public let doubleValue: Double?

    public init(kind: ScanValueKind, intValue: Int64? = nil, doubleValue: Double? = nil) {
        self.kind = kind
        self.intValue = intValue
        self.doubleValue = doubleValue
    }

    public static func parse(kind: ScanValueKind, text: String) throws -> ScanValue {
        switch kind {
        case .int32:
            guard let value = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw TrainerError.invalidInput("需要 Int32 数值。")
            }
            return ScanValue(kind: kind, intValue: Int64(value))
        case .int64:
            guard let value = Int64(text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw TrainerError.invalidInput("需要 Int64 数值。")
            }
            return ScanValue(kind: kind, intValue: value)
        case .float32, .double:
            guard let value = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw TrainerError.invalidInput("需要浮点数值。")
            }
            return ScanValue(kind: kind, doubleValue: value)
        }
    }

    public func encodedBytes() throws -> Data {
        switch kind {
        case .int32:
            guard let intValue else {
                throw TrainerError.invalidInput("Int32 缺少整数值。")
            }
            guard let exactValue = Int32(exactly: intValue) else {
                throw TrainerError.invalidInput("Int32 数值越界。")
            }
            let value = exactValue.littleEndian
            return Data(littleEndianBytes: value)
        case .int64:
            guard let intValue else {
                throw TrainerError.invalidInput("Int64 缺少整数值。")
            }
            let value = intValue.littleEndian
            return Data(littleEndianBytes: value)
        case .float32:
            guard let doubleValue else {
                throw TrainerError.invalidInput("Float32 缺少浮点值。")
            }
            let floatValue = Float(doubleValue)
            guard doubleValue.isFinite, floatValue.isFinite else {
                throw TrainerError.invalidInput("Float32 需要有限数值。")
            }
            let value = floatValue.bitPattern.littleEndian
            return Data(littleEndianBytes: value)
        case .double:
            guard let doubleValue else {
                throw TrainerError.invalidInput("Double 缺少浮点值。")
            }
            guard doubleValue.isFinite else {
                throw TrainerError.invalidInput("Double 需要有限数值。")
            }
            let value = doubleValue.bitPattern.littleEndian
            return Data(littleEndianBytes: value)
        }
    }

    public func isEqual(to other: ScanValue) -> Bool {
        guard kind == other.kind else {
            return false
        }

        switch kind {
        case .int32, .int64:
            return intValue == other.intValue
        case .float32, .double:
            guard let lhs = doubleValue, let rhs = other.doubleValue else {
                return false
            }
            return abs(lhs - rhs) <= defaultFloatEpsilon
        }
    }

    public func isGreater(than other: ScanValue) -> Bool {
        guard kind == other.kind else {
            return false
        }

        switch kind {
        case .int32, .int64:
            guard let lhs = intValue, let rhs = other.intValue else {
                return false
            }
            return lhs > rhs
        case .float32, .double:
            guard let lhs = doubleValue, let rhs = other.doubleValue else {
                return false
            }
            return lhs > rhs + defaultFloatEpsilon
        }
    }

    public func isLess(than other: ScanValue) -> Bool {
        guard kind == other.kind else {
            return false
        }

        switch kind {
        case .int32, .int64:
            guard let lhs = intValue, let rhs = other.intValue else {
                return false
            }
            return lhs < rhs
        case .float32, .double:
            guard let lhs = doubleValue, let rhs = other.doubleValue else {
                return false
            }
            return lhs + defaultFloatEpsilon < rhs
        }
    }

    public static func decode(kind: ScanValueKind, data: Data, offset: Int) -> ScanValue? {
        guard let bytes = data.bytes(offset: offset, count: kind.byteWidth) else {
            return nil
        }

        switch kind {
        case .int32:
            let raw = Int32(littleEndianBytes: bytes)
            return ScanValue(kind: kind, intValue: Int64(raw))
        case .int64:
            let raw = Int64(littleEndianBytes: bytes)
            return ScanValue(kind: kind, intValue: raw)
        case .float32:
            let raw = UInt32(littleEndianBytes: bytes)
            return ScanValue(kind: kind, doubleValue: Double(Float(bitPattern: raw)))
        case .double:
            let raw = UInt64(littleEndianBytes: bytes)
            return ScanValue(kind: kind, doubleValue: Double(bitPattern: raw))
        }
    }
}

extension Data {
    init<T: FixedWidthInteger>(littleEndianBytes value: T) {
        var copy = value
        self = Swift.withUnsafeBytes(of: &copy) { Data($0) }
    }

    func bytes(offset: Int, count: Int) -> [UInt8]? {
        guard offset >= 0, count >= 0, offset + count <= self.count else {
            return nil
        }

        return Array(self[offset..<(offset + count)])
    }
}

extension FixedWidthInteger {
    init(littleEndianBytes bytes: [UInt8]) {
        let value = bytes.enumerated().reduce(UInt64.zero) { partial, item in
            partial | (UInt64(item.element) << UInt64(item.offset * UInt8.bitWidth))
        }
        self = Self(truncatingIfNeeded: value)
    }
}
