import Foundation

private let arm64ReturnInstruction = UInt32(0xD65F_03C0)
private let arm64UnconditionalBranchOpcode = UInt32(0x1400_0000)
private let arm64BranchWithLinkOpcode = UInt32(0x9400_0000)
private let arm64CompareAndBranchZero32Opcode = UInt32(0x3400_0000)
private let arm64CompareAndBranchNotZero32Opcode = UInt32(0x3500_0000)
private let arm64CompareAndBranchZero64Opcode = UInt32(0xB400_0000)
private let arm64CompareAndBranchNotZero64Opcode = UInt32(0xB500_0000)
private let arm64ConditionalBranchOpcode = UInt32(0x5400_0000)
private let arm64ConditionEqual = UInt32(0x0)
private let arm64ConditionNotEqual = UInt32(0x1)
private let arm64ConditionHigherOrSame = UInt32(0x2)
private let arm64ConditionLower = UInt32(0x3)
private let arm64MoveWideShift = UInt32(16)
private let arm64Int32Max = Int64(Int32.max)
private let arm64UInt16Max = Int64(UInt16.max)
private let arm64UInt12Limit = UInt32(1 << 12)
private let arm64ImmediateMask = UInt32(0xFFFF)
private let arm64BranchImmediateMask = Int64(0x03FF_FFFF)
private let arm64LiteralImmediateMask = Int64(0x7_FFFF)
private let arm64ConditionalBranchImmediateMask = Int64(0x7_FFFF)
private let arm64BranchScale = Int64(4)
private let arm64BranchRange = Int64(128 * 1024 * 1024)
private let arm64LoadLiteralRange = Int64(1024 * 1024)
private let arm64ConditionalBranchRange = Int64(1024 * 1024)
private let arm64InstructionWidth = UInt64(4)
private let arm64FloatImmediateTolerance = Float(0.0001)
private let arm64FloatImmediateByteMax = UInt32(UInt8.max)
private let obscuredIntTrailingWordOffset = UInt32(0x10)
private let vectorStoreScale = UInt32(16)
private let wordStoreScale = UInt32(4)
private let doublewordLoadScale = UInt32(8)
private let wordLoadScale = UInt32(4)
private let arm64Signed9ImmediateMax = Int32(255)
private let ingredientsDataCountsOffset = UInt32(0x28)
private let ingredientsDataEntityOffset = UInt32(0x50)
private let ingredientsEntityTypeOffset = UInt32(0x14)
private let il2CppArrayDataOffset = UInt32(0x20)
private let storageResolvedDataStackOffset = UInt32(0x8)
private let ingredientsCategoryPatchMaxValue = Int64(UInt16.max)
private let rpgDamageTrampolineMarkerA = UInt32(0x4454_5250)
private let rpgDamageTrampolineMarkerB = UInt32(0x3147_5048)

public struct RPGDamagePolicyTrampolineMode: OptionSet, Sendable, Equatable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let enemySuperDamage = RPGDamagePolicyTrampolineMode(rawValue: 1 << 0)
    public static let playerIgnoreDamage = RPGDamagePolicyTrampolineMode(rawValue: 1 << 1)
}

public struct RPGDamagePolicyTrampolineAddresses: Sendable {
    public let trampoline: UInt64
    public let resume: UInt64
    public let nullHandler: UInt64
    public let isEnemy: UInt64
}

public struct RPGDamagePolicyTrampolineRequest: Sendable {
    public let value: Int64
    public let mode: RPGDamagePolicyTrampolineMode
    public let addresses: RPGDamagePolicyTrampolineAddresses
}

public struct RPGEnemyOnlySuperDamageTrampolineAddresses: Sendable {
    public let trampoline: UInt64
    public let resume: UInt64
    public let nullHandler: UInt64
    public let isEnemy: UInt64
}

public struct RPGEnemyOnlySuperDamageTrampolineRequest: Sendable {
    public let value: Int64
    public let addresses: RPGEnemyOnlySuperDamageTrampolineAddresses
}

public struct ObscuredInt32PropertySavePatchRequest: Sendable {
    public let value: Int64
    public let patchRVA: UInt64
    public let fieldOffset: UInt32
    public let implicitIntRVA: UInt64
    public let getGameSaveRVA: UInt64
    public let updatePlayerSaveRVA: UInt64
    public let raiseNullReferenceRVA: UInt64

    public init(
        value: Int64,
        patchRVA: UInt64,
        fieldOffset: UInt32,
        implicitIntRVA: UInt64,
        getGameSaveRVA: UInt64,
        updatePlayerSaveRVA: UInt64,
        raiseNullReferenceRVA: UInt64
    ) {
        self.value = value
        self.patchRVA = patchRVA
        self.fieldOffset = fieldOffset
        self.implicitIntRVA = implicitIntRVA
        self.getGameSaveRVA = getGameSaveRVA
        self.updatePlayerSaveRVA = updatePlayerSaveRVA
        self.raiseNullReferenceRVA = raiseNullReferenceRVA
    }
}

public struct IngredientsSetCountPatchRequest: Sendable {
    public let value: Int64
    public let patchRVA: UInt64
    public let raiseNullReferenceRVA: UInt64
    public let raiseIndexOutOfRangeRVA: UInt64

    public init(
        value: Int64,
        patchRVA: UInt64,
        raiseNullReferenceRVA: UInt64,
        raiseIndexOutOfRangeRVA: UInt64
    ) {
        self.value = value
        self.patchRVA = patchRVA
        self.raiseNullReferenceRVA = raiseNullReferenceRVA
        self.raiseIndexOutOfRangeRVA = raiseIndexOutOfRangeRVA
    }
}

public enum IngredientsTypeMatcher: Equatable, Sendable {
    case equals(UInt32)
    case lessThan(UInt32)
}

public struct IngredientsCategoryPatchRequest: Sendable {
    public let value: Int64
    public let matcher: IngredientsTypeMatcher
    public let patchRVA: UInt64

    public init(value: Int64, matcher: IngredientsTypeMatcher, patchRVA: UInt64) {
        self.value = value
        self.matcher = matcher
        self.patchRVA = patchRVA
    }
}

public enum Arm64ReturnCode {
    public static var rpgDamagePolicyTrampolineMarker: [UInt8] {
        littleEndianBytes([rpgDamageTrampolineMarkerA, rpgDamageTrampolineMarkerB])
    }

    public static var rpgEnemyOnlySuperDamageTrampolineMarker: [UInt8] {
        rpgDamagePolicyTrampolineMarker
    }

    public static func unconditionalBranch(from sourceAddress: UInt64, to targetAddress: UInt64) throws -> [UInt8] {
        try littleEndianBytes([branch(from: sourceAddress, to: targetAddress)])
    }

    public static func returnInt32(_ value: Int64) throws -> [UInt8] {
        var instructions = try moveInt32(value, register: .w0, errorLabel: "整数返回值")
        instructions.append(arm64ReturnInstruction)
        return littleEndianBytes(instructions)
    }

    public static func moveInt32ToW8(_ value: Int64) throws -> [UInt8] {
        try littleEndianBytes(moveInt32(value, register: .w8, errorLabel: "w8 写入值"))
    }

    public static func moveInt32ToW0(_ value: Int64) throws -> [UInt8] {
        try littleEndianBytes(moveInt32(value, register: .w0, errorLabel: "w0 写入值"))
    }

    public static func moveInt32ToW1(_ value: Int64) throws -> [UInt8] {
        try littleEndianBytes(moveInt32(value, register: .w1, errorLabel: "w1 写入值"))
    }

    public static func moveInt32ToW20(_ value: Int64) throws -> [UInt8] {
        try littleEndianBytes(moveInt32(value, register: .w20, errorLabel: "w20 写入值"))
    }

    public static func moveInt32ToW21(_ value: Int64) throws -> [UInt8] {
        try littleEndianBytes(moveInt32(value, register: .w21, errorLabel: "w21 写入值"))
    }

    public static func moveInt32ToW22(_ value: Int64) throws -> [UInt8] {
        try littleEndianBytes(moveInt32(value, register: .w22, errorLabel: "w22 写入值"))
    }

    public static func moveInt32ToW23(_ value: Int64) throws -> [UInt8] {
        try littleEndianBytes(moveInt32(value, register: .w23, errorLabel: "w23 写入值"))
    }

    public static func returnObscuredInt32(_ value: Int64, patchRVA: UInt64, implicitIntRVA: UInt64) throws -> [UInt8] {
        var instructions = try moveInt32(value, register: .w0, errorLabel: "ObscuredInt 返回值")

        let branchRVA = patchRVA + UInt64(instructions.count) * arm64InstructionWidth
        instructions.append(try branch(from: branchRVA, to: implicitIntRVA))
        return littleEndianBytes(instructions)
    }

    public static func returnFloat32(_ value: Float) -> [UInt8] {
        var instructions = materializeFloat32(value, into: .s0)
        instructions.append(arm64ReturnInstruction)
        return littleEndianBytes(instructions)
    }

    public static var returnZeroFloat32: [UInt8] {
        littleEndianBytes([Instruction.fmovS0Wzr.rawValue, arm64ReturnInstruction])
    }

    public static var returnThirtyOneFloat32: [UInt8] {
        littleEndianBytes([Instruction.fmovS0ThirtyOne.rawValue, arm64ReturnInstruction])
    }

    public static func returnImmediateFloat32(_ value: Float) throws -> [UInt8] {
        littleEndianBytes([try fmovImmediateFloat32(value, register: .s0), arm64ReturnInstruction])
    }

    public static func moveImmediateFloat32ToS0(_ value: Float) throws -> [UInt8] {
        try littleEndianBytes([fmovImmediateFloat32(value, register: .s0)])
    }

    public static func moveImmediateFloat32ToS2(_ value: Float) throws -> [UInt8] {
        try littleEndianBytes([fmovImmediateFloat32(value, register: .s2)])
    }

    public static func moveImmediateFloat32ToS9(_ value: Float) throws -> [UInt8] {
        try littleEndianBytes([fmovImmediateFloat32(value, register: .s9)])
    }

    public static func loadFloat32LiteralToS0AndBranch(
        value: Float,
        patchRVA: UInt64,
        literalRVA: UInt64,
        continueRVA: UInt64
    ) throws -> [UInt8] {
        let instructions = [
            try ldrS0Literal(from: patchRVA, to: literalRVA),
            try branch(from: patchRVA + arm64InstructionWidth, to: continueRVA),
            Instruction.nop.rawValue,
            value.bitPattern
        ]
        return littleEndianBytes(instructions)
    }

    public static func loadFloat32LiteralToS0ReturnAndDisableSetter(
        value: Float,
        patchRVA: UInt64,
        literalRVA: UInt64
    ) throws -> [UInt8] {
        let instructions = [
            try ldrS0Literal(from: patchRVA, to: literalRVA),
            arm64ReturnInstruction,
            arm64ReturnInstruction,
            value.bitPattern
        ]
        return littleEndianBytes(instructions)
    }

    public static func writeObscuredInt32PropertyAndSave(_ request: ObscuredInt32PropertySavePatchRequest) throws -> [UInt8] {
        var instructions = [
            Instruction.stpX29X30PreindexSPMinus48.rawValue,
            Instruction.movX29SP.rawValue,
            Instruction.strX0SPPlus40.rawValue
        ]
        try appendMoveInt32(request.value, register: .w0, to: &instructions, errorLabel: "ObscuredInt 写入值")
        instructions.append(Instruction.addX8SPPlus16.rawValue)
        try appendBranchLink(to: request.implicitIntRVA, patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(contentsOf: [
            Instruction.ldrX9SPPlus40.rawValue,
            Instruction.ldrQ0SPPlus16.rawValue,
            Instruction.ldrW10SPPlus32.rawValue
        ])
        instructions.append(try strQ0X9(offset: request.fieldOffset))
        instructions.append(try strW10X9(offset: request.fieldOffset + obscuredIntTrailingWordOffset))
        instructions.append(Instruction.movX0Zero.rawValue)
        try appendBranchLink(to: request.getGameSaveRVA, patchRVA: request.patchRVA, instructions: &instructions)
        try appendCompareZeroX0ToNullHandler(patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(Instruction.movX1Zero.rawValue)
        instructions.append(Instruction.ldpX29X30PostindexSPPlus48.rawValue)
        try appendBranch(to: request.updatePlayerSaveRVA, patchRVA: request.patchRVA, instructions: &instructions)
        try appendBranchLink(to: request.raiseNullReferenceRVA, patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(Instruction.brk1.rawValue)
        return littleEndianBytes(instructions)
    }

    public static func writeIngredientsSetCount(_ request: IngredientsSetCountPatchRequest) throws -> [UInt8] {
        guard (0...arm64UInt16Max).contains(request.value) else {
            throw TrainerError.invalidInput("食材 SetCount patch 的写入值必须在 0...\(arm64UInt16Max) 范围内，避免覆盖相邻函数。")
        }

        var instructions = [Instruction.ldrX8X0Plus40.rawValue]
        try appendCompareZeroX8ToNullHandler(patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(contentsOf: [
            Instruction.ldrW9X8Plus24.rawValue,
            Instruction.cmpW1W9.rawValue
        ])
        try appendUnsignedHigherOrSameToRangeHandler(patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(Instruction.addX8X8W1Sxtw2.rawValue)
        try appendMoveInt32(request.value, register: .w2, to: &instructions, errorLabel: "食材 SetCount 写入值")
        instructions.append(contentsOf: [
            Instruction.strW2X8Plus32.rawValue,
            Instruction.movW0W2.rawValue,
            arm64ReturnInstruction
        ])
        try appendBranchLink(to: request.raiseNullReferenceRVA, patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(Instruction.brk1.rawValue)
        try appendBranchLink(to: request.raiseIndexOutOfRangeRVA, patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(Instruction.brk1.rawValue)
        return littleEndianBytes(instructions)
    }

    public static func writeIngredientsCategoryTotalCount(_ request: IngredientsCategoryPatchRequest) throws -> [UInt8] {
        var instructions = try ingredientsCategoryPrefix(request, missingEntityTargetIndex: 5, forcedValueTargetIndex: 9)
        instructions.append(contentsOf: [
            try ldrUnsigned64(offset: ingredientsDataCountsOffset, base: .x0, target: .x8),
            Instruction.ldpW9W8X8Plus32.rawValue,
            Instruction.addW0W8W9.rawValue,
            arm64ReturnInstruction
        ])
        try appendCategoryMove(request, register: .w0, instructions: &instructions)
        instructions.append(arm64ReturnInstruction)
        return littleEndianBytes(instructions)
    }

    public static func writeIngredientsCategoryGetCount(_ request: IngredientsCategoryPatchRequest) throws -> [UInt8] {
        var instructions = try ingredientsCategoryPrefix(request, missingEntityTargetIndex: 5, forcedValueTargetIndex: 9)
        instructions.append(contentsOf: [
            try ldrUnsigned64(offset: ingredientsDataCountsOffset, base: .x0, target: .x8),
            Instruction.addX8X8W1Sxtw2.rawValue,
            Instruction.ldrW0X8Plus32.rawValue,
            arm64ReturnInstruction
        ])
        try appendCategoryMove(request, register: .w0, instructions: &instructions)
        instructions.append(arm64ReturnInstruction)
        return littleEndianBytes(instructions)
    }

    public static func writeIngredientsCategorySetCount(_ request: IngredientsCategoryPatchRequest) throws -> [UInt8] {
        var instructions = [
            try ldrUnsigned64(offset: ingredientsDataEntityOffset, base: .x0, target: .x8),
            try compareAndBranchZero64(
                register: .x8,
                from: instructionRVA(base: request.patchRVA, index: 1),
                to: instructionRVA(base: request.patchRVA, index: 6)
            ),
            try ldrUnsigned32(offset: ingredientsEntityTypeOffset, base: .x8, target: .w8),
            try cmpImmediate32(register: .w8, immediate: matcherImmediate(request.matcher)),
            try conditionalBranch(
                condition: nonMatchCondition(request.matcher),
                from: instructionRVA(base: request.patchRVA, index: 4),
                to: instructionRVA(base: request.patchRVA, index: 6)
            )
        ]
        try appendCategoryMove(request, register: .w2, instructions: &instructions)
        instructions.append(contentsOf: [
            try ldrUnsigned64(offset: ingredientsDataCountsOffset, base: .x0, target: .x8),
            Instruction.addX8X8W1Sxtw2.rawValue,
            Instruction.strW2X8Plus32.rawValue,
            Instruction.movW0W2.rawValue,
            arm64ReturnInstruction
        ])
        return littleEndianBytes(instructions)
    }

    public static func writeIngredientsCategoryIsEnough(_ request: IngredientsCategoryPatchRequest) throws -> [UInt8] {
        var instructions = try ingredientsCategoryPrefix(request, missingEntityTargetIndex: 5, forcedValueTargetIndex: 11)
        instructions.append(contentsOf: [
            try ldrUnsigned64(offset: ingredientsDataCountsOffset, base: .x0, target: .x8),
            Instruction.addX8X8W1Sxtw2.rawValue,
            Instruction.ldrW8X8Plus32.rawValue,
            Instruction.cmpW8W2.rawValue,
            Instruction.csetW0GE.rawValue,
            arm64ReturnInstruction,
            Instruction.movW0One.rawValue,
            arm64ReturnInstruction
        ])
        return littleEndianBytes(instructions)
    }

    public static func writeIngredientsCategoryIsEnoughTotal(_ request: IngredientsCategoryPatchRequest) throws -> [UInt8] {
        var instructions = try ingredientsCategoryPrefix(request, missingEntityTargetIndex: 5, forcedValueTargetIndex: 11)
        instructions.append(contentsOf: [
            try ldrUnsigned64(offset: ingredientsDataCountsOffset, base: .x0, target: .x8),
            Instruction.ldpW9W8X8Plus32.rawValue,
            Instruction.addW8W8W9.rawValue,
            Instruction.cmpW8W1.rawValue,
            Instruction.csetW0GE.rawValue,
            arm64ReturnInstruction,
            Instruction.movW0One.rawValue,
            arm64ReturnInstruction
        ])
        return littleEndianBytes(instructions)
    }

    public static func writeIngredientsStorageCategoryGetCount(_ request: IngredientsCategoryPatchRequest) throws -> [UInt8] {
        var instructions = [
            try ldrUnsigned64(offset: storageResolvedDataStackOffset, base: .sp, target: .x8),
            try ldrUnsigned64(offset: ingredientsDataEntityOffset, base: .x8, target: .x9),
            try compareAndBranchZero64(
                register: .x9,
                from: instructionRVA(base: request.patchRVA, index: 2),
                to: instructionRVA(base: request.patchRVA, index: 8)
            ),
            try ldrUnsigned32(offset: ingredientsEntityTypeOffset, base: .x9, target: .w9),
            try cmpImmediate32(register: .w9, immediate: matcherImmediate(request.matcher)),
            try conditionalBranch(
                condition: nonMatchCondition(request.matcher),
                from: instructionRVA(base: request.patchRVA, index: 5),
                to: instructionRVA(base: request.patchRVA, index: 8)
            )
        ]
        try appendCategoryMove(request, register: .w0, instructions: &instructions)
        try appendBranch(to: instructionRVA(base: request.patchRVA, index: 11), patchRVA: request.patchRVA, instructions: &instructions)
        instructions.append(contentsOf: [
            try ldrUnsigned64(offset: ingredientsDataCountsOffset, base: .x8, target: .x8),
            Instruction.ldpW9W8X8Plus32.rawValue,
            Instruction.addW0W8W9.rawValue,
            Instruction.ldpX29X30SPPlus48.rawValue,
            Instruction.ldpX20X19SPPlus32.rawValue,
            Instruction.ldpX22X21SPPlus16.rawValue,
            Instruction.addSPPlus64.rawValue,
            arm64ReturnInstruction
        ])
        return littleEndianBytes(instructions)
    }

    public static func writeRPGDamagePolicyTrampoline(_ request: RPGDamagePolicyTrampolineRequest) throws -> [UInt8] {
        guard !request.mode.isEmpty else {
            throw TrainerError.invalidInput("RPG damage trampoline 至少需要启用一个策略位。")
        }

        var instructions = [
            try compareAndBranchNotZero64(
                register: .x0,
                from: request.addresses.trampoline,
                to: instructionRVA(base: request.addresses.trampoline, index: 2)
            )
        ]
        try appendBranch(to: request.addresses.nullHandler, patchRVA: request.addresses.trampoline, instructions: &instructions)
        instructions.append(contentsOf: [
            Instruction.movX28X0.rawValue,
            Instruction.movX0X20.rawValue
        ])
        try appendBranchLink(to: request.addresses.isEnemy, patchRVA: request.addresses.trampoline, instructions: &instructions)
        try appendRPGDamagePolicyBody(request, instructions: &instructions)
        instructions.append(Instruction.movX0X28.rawValue)
        try appendBranch(to: request.addresses.resume, patchRVA: request.addresses.trampoline, instructions: &instructions)
        instructions.append(request.mode.rawValue)
        instructions.append(contentsOf: [rpgDamageTrampolineMarkerA, rpgDamageTrampolineMarkerB])
        return littleEndianBytes(instructions)
    }

    public static func writeRPGEnemyOnlySuperDamageTrampoline(_ request: RPGEnemyOnlySuperDamageTrampolineRequest) throws -> [UInt8] {
        let addresses = RPGDamagePolicyTrampolineAddresses(
            trampoline: request.addresses.trampoline,
            resume: request.addresses.resume,
            nullHandler: request.addresses.nullHandler,
            isEnemy: request.addresses.isEnemy
        )
        return try writeRPGDamagePolicyTrampoline(RPGDamagePolicyTrampolineRequest(
            value: request.value,
            mode: .enemySuperDamage,
            addresses: addresses
        ))
    }

    private static func appendRPGDamagePolicyBody(
        _ request: RPGDamagePolicyTrampolineRequest,
        instructions: inout [UInt32]
    ) throws {
        let hasSuperDamage = request.mode.contains(.enemySuperDamage)
        let hasIgnoreDamage = request.mode.contains(.playerIgnoreDamage)
        if hasSuperDamage && hasIgnoreDamage {
            try appendCombinedRPGDamagePolicyBody(request, instructions: &instructions)
            return
        }

        let skipIndex = instructions.count
        instructions.append(Instruction.nop.rawValue)
        let value = hasSuperDamage ? request.value : 0
        let label = hasSuperDamage ? "RPG 敌方目标超级伤害值" : "RPG 我方目标忽略伤害值"
        try appendMoveInt32(value, register: .w21, to: &instructions, errorLabel: label)
        let skipAddress = instructionRVA(base: request.addresses.trampoline, index: instructions.count)
        instructions[skipIndex] = try singlePolicyRPGBranch(
            mode: request.mode,
            from: instructionRVA(base: request.addresses.trampoline, index: skipIndex),
            to: skipAddress
        )
    }

    private static func appendCombinedRPGDamagePolicyBody(
        _ request: RPGDamagePolicyTrampolineRequest,
        instructions: inout [UInt32]
    ) throws {
        let nonEnemyIndex = instructions.count
        instructions.append(Instruction.nop.rawValue)
        try appendMoveInt32(request.value, register: .w21, to: &instructions, errorLabel: "RPG 敌方目标超级伤害值")
        let restoreIndex = instructions.count
        instructions.append(Instruction.nop.rawValue)
        let nonEnemyAddress = instructionRVA(base: request.addresses.trampoline, index: instructions.count)
        instructions[nonEnemyIndex] = try compareAndBranchZero32(
            register: .w0,
            from: instructionRVA(base: request.addresses.trampoline, index: nonEnemyIndex),
            to: nonEnemyAddress
        )
        try appendMoveInt32(0, register: .w21, to: &instructions, errorLabel: "RPG 我方目标忽略伤害值")
        let restoreAddress = instructionRVA(base: request.addresses.trampoline, index: instructions.count)
        instructions[restoreIndex] = try branch(
            from: instructionRVA(base: request.addresses.trampoline, index: restoreIndex),
            to: restoreAddress
        )
    }

    private static func singlePolicyRPGBranch(
        mode: RPGDamagePolicyTrampolineMode,
        from sourceRVA: UInt64,
        to targetRVA: UInt64
    ) throws -> UInt32 {
        if mode.contains(.enemySuperDamage) {
            return try compareAndBranchZero32(register: .w0, from: sourceRVA, to: targetRVA)
        }

        return try compareAndBranchNotZero32(register: .w0, from: sourceRVA, to: targetRVA)
    }

    private static func materializeFloat32(_ value: Float, into register: FloatRegister32) -> [UInt32] {
        let bitPattern = value.bitPattern
        var instructions = [moveZ32(register: .w8, immediate: bitPattern & arm64ImmediateMask, shift: 0)]
        let upper = (bitPattern >> arm64MoveWideShift) & arm64ImmediateMask
        if upper != 0 {
            instructions.append(moveK32(register: .w8, immediate: upper, shift: arm64MoveWideShift))
        }
        instructions.append(Instruction.fmovS0W8.rawValue | register.rawValue)
        return instructions
    }

    private static func appendMoveInt32(
        _ value: Int64,
        register: GeneralRegister32,
        to instructions: inout [UInt32],
        errorLabel: String
    ) throws {
        instructions.append(contentsOf: try moveInt32(value, register: register, errorLabel: errorLabel))
    }

    private static func moveInt32(_ value: Int64, register: GeneralRegister32, errorLabel: String) throws -> [UInt32] {
        guard (0...arm64Int32Max).contains(value) else {
            throw TrainerError.invalidInput("\(errorLabel)必须在 0...\(arm64Int32Max) 范围内。")
        }

        let bitPattern = UInt32(value)
        var instructions = [moveZ32(register: register, immediate: bitPattern & arm64ImmediateMask, shift: 0)]
        let upper = (bitPattern >> arm64MoveWideShift) & arm64ImmediateMask
        if upper != 0 {
            instructions.append(moveK32(register: register, immediate: upper, shift: arm64MoveWideShift))
        }
        return instructions
    }

    private static func appendBranchLink(to targetRVA: UInt64, patchRVA: UInt64, instructions: inout [UInt32]) throws {
        let sourceRVA = instructionRVA(base: patchRVA, index: instructions.count)
        instructions.append(try branchWithLink(from: sourceRVA, to: targetRVA))
    }

    private static func appendBranch(to targetRVA: UInt64, patchRVA: UInt64, instructions: inout [UInt32]) throws {
        let sourceRVA = instructionRVA(base: patchRVA, index: instructions.count)
        instructions.append(try branch(from: sourceRVA, to: targetRVA))
    }

    private static func appendCompareZeroX0ToNullHandler(patchRVA: UInt64, instructions: inout [UInt32]) throws {
        let sourceIndex = instructions.count
        let targetIndex = sourceIndex + 4
        instructions.append(try compareAndBranchZero64(
            register: .x0,
            from: instructionRVA(base: patchRVA, index: sourceIndex),
            to: instructionRVA(base: patchRVA, index: targetIndex)
        ))
    }

    private static func appendCompareZeroX8ToNullHandler(patchRVA: UInt64, instructions: inout [UInt32]) throws {
        let sourceIndex = instructions.count
        let targetIndex = sourceIndex + 9
        instructions.append(try compareAndBranchZero64(
            register: .x8,
            from: instructionRVA(base: patchRVA, index: sourceIndex),
            to: instructionRVA(base: patchRVA, index: targetIndex)
        ))
    }

    private static func appendUnsignedHigherOrSameToRangeHandler(patchRVA: UInt64, instructions: inout [UInt32]) throws {
        let sourceIndex = instructions.count
        let targetIndex = sourceIndex + 8
        instructions.append(try conditionalBranch(
            condition: arm64ConditionHigherOrSame,
            from: instructionRVA(base: patchRVA, index: sourceIndex),
            to: instructionRVA(base: patchRVA, index: targetIndex)
        ))
    }

    private static func ingredientsCategoryPrefix(
        _ request: IngredientsCategoryPatchRequest,
        missingEntityTargetIndex: Int,
        forcedValueTargetIndex: Int
    ) throws -> [UInt32] {
        [
            try ldrUnsigned64(offset: ingredientsDataEntityOffset, base: .x0, target: .x8),
            try compareAndBranchZero64(
                register: .x8,
                from: instructionRVA(base: request.patchRVA, index: 1),
                to: instructionRVA(base: request.patchRVA, index: missingEntityTargetIndex)
            ),
            try ldrUnsigned32(offset: ingredientsEntityTypeOffset, base: .x8, target: .w8),
            try cmpImmediate32(register: .w8, immediate: matcherImmediate(request.matcher)),
            try conditionalBranch(
                condition: matchCondition(request.matcher),
                from: instructionRVA(base: request.patchRVA, index: 4),
                to: instructionRVA(base: request.patchRVA, index: forcedValueTargetIndex)
            )
        ]
    }

    private static func appendCategoryMove(
        _ request: IngredientsCategoryPatchRequest,
        register: GeneralRegister32,
        instructions: inout [UInt32]
    ) throws {
        guard (0...ingredientsCategoryPatchMaxValue).contains(request.value) else {
            throw TrainerError.invalidInput("分类食材 patch 的写入值必须在 0...\(ingredientsCategoryPatchMaxValue) 范围内，避免覆盖相邻 IL2CPP 函数。")
        }

        try appendMoveInt32(request.value, register: register, to: &instructions, errorLabel: "分类食材写入值")
    }

    private static func matcherImmediate(_ matcher: IngredientsTypeMatcher) -> UInt32 {
        switch matcher {
        case .equals(let value), .lessThan(let value):
            return value
        }
    }

    private static func matchCondition(_ matcher: IngredientsTypeMatcher) -> UInt32 {
        switch matcher {
        case .equals:
            return arm64ConditionEqual
        case .lessThan:
            return arm64ConditionLower
        }
    }

    private static func nonMatchCondition(_ matcher: IngredientsTypeMatcher) -> UInt32 {
        switch matcher {
        case .equals:
            return arm64ConditionNotEqual
        case .lessThan:
            return arm64ConditionHigherOrSame
        }
    }

    private static func moveZ32(register: GeneralRegister32, immediate: UInt32, shift: UInt32) -> UInt32 {
        moveWide32(opcode: 0x5280_0000, register: register, immediate: immediate, shift: shift)
    }

    private static func moveK32(register: GeneralRegister32, immediate: UInt32, shift: UInt32) -> UInt32 {
        moveWide32(opcode: 0x7280_0000, register: register, immediate: immediate, shift: shift)
    }

    private static func moveWide32(opcode: UInt32, register: GeneralRegister32, immediate: UInt32, shift: UInt32) -> UInt32 {
        let shiftField = (shift / arm64MoveWideShift) << 21
        return opcode | shiftField | ((immediate & arm64ImmediateMask) << 5) | register.rawValue
    }

    private static func branch(from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        try branchInstruction(opcode: arm64UnconditionalBranchOpcode, from: sourceRVA, to: targetRVA)
    }

    private static func branchWithLink(from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        try branchInstruction(opcode: arm64BranchWithLinkOpcode, from: sourceRVA, to: targetRVA)
    }

    private static func branchInstruction(opcode: UInt32, from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let distance = Int64(targetRVA) - Int64(sourceRVA)
        guard distance % arm64BranchScale == 0 else {
            throw TrainerError.invalidInput("ARM64 分支目标没有 4 字节对齐。")
        }
        guard (-arm64BranchRange..<arm64BranchRange).contains(distance) else {
            throw TrainerError.invalidInput("ARM64 分支目标超出 ±128MB 范围。")
        }

        let immediate = (distance / arm64BranchScale) & arm64BranchImmediateMask
        return opcode | UInt32(immediate)
    }

    private static func compareAndBranchZero64(register: GeneralRegister64, from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let immediate = try conditionalBranchImmediate(from: sourceRVA, to: targetRVA)
        return arm64CompareAndBranchZero64Opcode | (immediate << 5) | register.rawValue
    }

    private static func compareAndBranchNotZero64(register: GeneralRegister64, from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let immediate = try conditionalBranchImmediate(from: sourceRVA, to: targetRVA)
        return arm64CompareAndBranchNotZero64Opcode | (immediate << 5) | register.rawValue
    }

    private static func compareAndBranchZero32(register: GeneralRegister32, from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let immediate = try conditionalBranchImmediate(from: sourceRVA, to: targetRVA)
        return arm64CompareAndBranchZero32Opcode | (immediate << 5) | register.rawValue
    }

    private static func compareAndBranchNotZero32(register: GeneralRegister32, from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let immediate = try conditionalBranchImmediate(from: sourceRVA, to: targetRVA)
        return arm64CompareAndBranchNotZero32Opcode | (immediate << 5) | register.rawValue
    }

    private static func conditionalBranch(condition: UInt32, from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let immediate = try conditionalBranchImmediate(from: sourceRVA, to: targetRVA)
        return arm64ConditionalBranchOpcode | (immediate << 5) | condition
    }

    private static func conditionalBranchImmediate(from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let distance = Int64(targetRVA) - Int64(sourceRVA)
        guard distance % arm64BranchScale == 0 else {
            throw TrainerError.invalidInput("ARM64 条件分支目标没有 4 字节对齐。")
        }
        guard (-arm64ConditionalBranchRange..<arm64ConditionalBranchRange).contains(distance) else {
            throw TrainerError.invalidInput("ARM64 条件分支目标超出 ±1MB 范围。")
        }

        return UInt32((distance / arm64BranchScale) & arm64ConditionalBranchImmediateMask)
    }

    private static func ldrS0Literal(from sourceRVA: UInt64, to targetRVA: UInt64) throws -> UInt32 {
        let distance = Int64(targetRVA) - Int64(sourceRVA)
        guard distance % arm64BranchScale == 0 else {
            throw TrainerError.invalidInput("ARM64 float literal 目标没有 4 字节对齐。")
        }
        guard (-arm64LoadLiteralRange..<arm64LoadLiteralRange).contains(distance) else {
            throw TrainerError.invalidInput("ARM64 float literal 目标超出 ±1MB 范围。")
        }

        let immediate = (distance / arm64BranchScale) & arm64LiteralImmediateMask
        return Instruction.ldrS0Literal.rawValue | (UInt32(immediate) << 5) | FloatRegister32.s0.rawValue
    }

    private static func fmovImmediateFloat32(_ value: Float, register: FloatRegister32) throws -> UInt32 {
        for immediate in UInt32(0)...arm64FloatImmediateByteMax {
            let candidate = Float(bitPattern: floatImmediateBitPattern(immediate))
            if isSupportedFloatImmediate(value, candidate: candidate) {
                return Instruction.fmovSImmediateBase.rawValue | (immediate << 13) | register.rawValue
            }
        }
        throw TrainerError.invalidInput("ARM64 单指令 float patch 不支持 \(value)。请使用 1、2、2.5、3、4、5、6、8、10 等可编码速度。")
    }

    private static func floatImmediateBitPattern(_ immediate: UInt32) -> UInt32 {
        let sign = (immediate & 0x80) << 24
        let exponentHead = (immediate & 0x40) == 0 ? UInt32(0x80) : UInt32(0x7C)
        let exponent = (exponentHead | ((immediate >> 4) & 0x3)) << 23
        let significand = (immediate & 0xF) << 19
        return sign | exponent | significand
    }

    private static func isSupportedFloatImmediate(_ value: Float, candidate: Float) -> Bool {
        abs(value - candidate) <= arm64FloatImmediateTolerance
    }

    private static func strQ0X9(offset: UInt32) throws -> UInt32 {
        if offset.isMultiple(of: vectorStoreScale) {
            return try scaledStore(baseOpcode: 0x3D80_0000, offset: offset, scale: vectorStoreScale, base: .x9, source: .q0)
        }

        return try unscaledStoreQ0(baseOpcode: 0x3C80_0000, offset: offset, base: .x9)
    }

    private static func strW10X9(offset: UInt32) throws -> UInt32 {
        try scaledStore(baseOpcode: 0xB900_0000, offset: offset, scale: wordStoreScale, base: .x9, source: .w10)
    }

    private static func scaledStore(baseOpcode: UInt32, offset: UInt32, scale: UInt32, base: GeneralRegister64, source: StoreSourceRegister) throws -> UInt32 {
        guard offset.isMultiple(of: scale) else {
            throw TrainerError.invalidInput("ARM64 store offset 必须按 \(scale) 字节对齐。")
        }

        let scaledOffset = offset / scale
        guard scaledOffset < UInt32(1 << 12) else {
            throw TrainerError.invalidInput("ARM64 store offset 超出 12-bit unsigned immediate 范围。")
        }
        return baseOpcode | (scaledOffset << 10) | (base.rawValue << 5) | source.rawValue
    }

    private static func unscaledStoreQ0(baseOpcode: UInt32, offset: UInt32, base: GeneralRegister64) throws -> UInt32 {
        guard let signedOffset = Int32(exactly: offset), signedOffset <= arm64Signed9ImmediateMax else {
            throw TrainerError.invalidInput("ARM64 unscaled store offset 超出 signed 9-bit immediate 范围。")
        }

        let immediate = UInt32(bitPattern: signedOffset) & 0x1FF
        return baseOpcode | (immediate << 12) | (base.rawValue << 5)
    }

    private static func ldrUnsigned64(offset: UInt32, base: GeneralRegister64, target: GeneralRegister64) throws -> UInt32 {
        try scaledLoad(baseOpcode: 0xF940_0000, offset: offset, scale: doublewordLoadScale, base: base, target: target.rawValue)
    }

    private static func ldrUnsigned32(offset: UInt32, base: GeneralRegister64, target: GeneralRegister32) throws -> UInt32 {
        try scaledLoad(baseOpcode: 0xB940_0000, offset: offset, scale: wordLoadScale, base: base, target: target.rawValue)
    }

    private static func scaledLoad(
        baseOpcode: UInt32,
        offset: UInt32,
        scale: UInt32,
        base: GeneralRegister64,
        target: UInt32
    ) throws -> UInt32 {
        guard offset.isMultiple(of: scale) else {
            throw TrainerError.invalidInput("ARM64 load offset 必须按 \(scale) 字节对齐。")
        }

        let scaledOffset = offset / scale
        guard scaledOffset < arm64UInt12Limit else {
            throw TrainerError.invalidInput("ARM64 load offset 超出 12-bit unsigned immediate 范围。")
        }
        return baseOpcode | (scaledOffset << 10) | (base.rawValue << 5) | target
    }

    private static func cmpImmediate32(register: GeneralRegister32, immediate: UInt32) throws -> UInt32 {
        guard immediate < arm64UInt12Limit else {
            throw TrainerError.invalidInput("ARM64 cmp immediate 超出 12-bit unsigned immediate 范围。")
        }

        return 0x7100_001F | (immediate << 10) | (register.rawValue << 5)
    }

    private static func instructionRVA(base: UInt64, index: Int) -> UInt64 {
        base + UInt64(index) * arm64InstructionWidth
    }

    private static func littleEndianBytes(_ instructions: [UInt32]) -> [UInt8] {
        instructions.flatMap { instruction in
            let value = instruction.littleEndian
            return [
                UInt8(truncatingIfNeeded: value),
                UInt8(truncatingIfNeeded: value >> 8),
                UInt8(truncatingIfNeeded: value >> 16),
                UInt8(truncatingIfNeeded: value >> 24)
            ]
        }
    }
}

private enum GeneralRegister32: UInt32 {
    case w0 = 0
    case w1 = 1
    case w2 = 2
    case w8 = 8
    case w9 = 9
    case w20 = 20
    case w21 = 21
    case w22 = 22
    case w23 = 23
}

private enum GeneralRegister64: UInt32 {
    case x0 = 0
    case x8 = 8
    case x9 = 9
    case sp = 31
}

private enum FloatRegister32: UInt32 {
    case s0 = 0
    case s2 = 2
    case s9 = 9
}

private enum StoreSourceRegister: UInt32 {
    case q0 = 0
    case w10 = 10
}

private enum Instruction: UInt32 {
    case fmovS0W8 = 0x1E27_0100
    case fmovS0Wzr = 0x1E27_03E0
    case fmovSImmediateBase = 0x1E20_1000
    case fmovS0ThirtyOne = 0x1E27_F000
    case stpX29X30PreindexSPMinus48 = 0xA9BD_7BFD
    case movX29SP = 0x9100_03FD
    case strX0SPPlus40 = 0xF900_17E0
    case addX8SPPlus16 = 0x9100_43E8
    case ldrX9SPPlus40 = 0xF940_17E9
    case ldrQ0SPPlus16 = 0x3DC0_07E0
    case ldrW10SPPlus32 = 0xB940_23EA
    case movX0Zero = 0xD280_0000
    case movX1Zero = 0xD280_0001
    case ldpX29X30PostindexSPPlus48 = 0xA8C3_7BFD
    case ldrX8X0Plus40 = 0xF940_1408
    case ldrW9X8Plus24 = 0xB940_1909
    case cmpW1W9 = 0x6B09_003F
    case addX8X8W1Sxtw2 = 0x8B21_C908
    case strW2X8Plus32 = 0xB900_2102
    case movW0W2 = 0x2A02_03E0
    case ldpW9W8X8Plus32 = 0x2944_2109
    case addW0W8W9 = 0x0B09_0100
    case addW8W8W9 = 0x0B09_0108
    case ldrW0X8Plus32 = 0xB940_2100
    case ldrW8X8Plus32 = 0xB940_2108
    case cmpW8W1 = 0x6B01_011F
    case cmpW8W2 = 0x6B02_011F
    case csetW0GE = 0x1A9F_B7E0
    case movW0One = 0x5280_0020
    case movX28X0 = 0xAA00_03FC
    case movX0X20 = 0xAA14_03E0
    case movX0X28 = 0xAA1C_03E0
    case ldpX29X30SPPlus48 = 0xA943_7BFD
    case ldpX20X19SPPlus32 = 0xA942_4FF4
    case ldpX22X21SPPlus16 = 0xA941_57F6
    case addSPPlus64 = 0x9101_03FF
    case strW8X0Plus120 = 0xB900_7808
    case movW8One = 0x5280_0028
    case strbW8X0Plus96 = 0x3901_8008
    case ldrS0Literal = 0x1C00_0000
    case nop = 0xD503_201F
    case brk1 = 0xD420_0020
}
