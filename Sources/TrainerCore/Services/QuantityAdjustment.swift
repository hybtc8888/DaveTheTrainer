import Foundation

private let minimumAdjustedQuantityInt32 = Int32(1)
private let minimumAdjustedQuantityInt64 = Int64(1)

func adjustedQuantity(current: Int32, delta: Int64, overflowMessage: String) throws -> Int32 {
    let result = Int64(current).addingReportingOverflow(delta)
    guard !result.overflow else {
        throw TrainerError.invalidInput(overflowMessage)
    }

    let minimumValue = Int64(minimumAdjustedQuantityInt32)
    guard result.partialValue >= minimumValue else {
        return minimumAdjustedQuantityInt32
    }
    guard let next = Int32(exactly: result.partialValue) else {
        throw TrainerError.invalidInput(overflowMessage)
    }
    return next
}

func adjustedQuantity(current: Int64, delta: Int64, overflowMessage: String) throws -> Int64 {
    let result = current.addingReportingOverflow(delta)
    guard !result.overflow else {
        throw TrainerError.invalidInput(overflowMessage)
    }
    return max(result.partialValue, minimumAdjustedQuantityInt64)
}
