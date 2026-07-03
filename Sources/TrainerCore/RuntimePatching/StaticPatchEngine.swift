import Darwin
import Foundation

private let arm64ReturnInstruction = UInt32(0xD65F_03C0)
private let arm64MoveWide32W0Mask = UInt32(0xFFE0_001F)
private let arm64MoveZ32W0Pattern = UInt32(0x5280_0000)
private let arm64MoveK32W0Shift16Pattern = UInt32(0x72A0_0000)
private let arm64MoveZ32W8Pattern = UInt32(0x5280_0008)
private let arm64MoveK32W8Shift16Pattern = UInt32(0x72A0_0008)
private let arm64StoreW8X0Plus120Instruction = UInt32(0xB900_7808)
private let arm64StoreByteW8X0Plus96Instruction = UInt32(0x3901_8008)
private let arm64BranchMask = UInt32(0xFC00_0000)
private let arm64BranchPattern = UInt32(0x1400_0000)
private let arm64FloatMoveImmediateMask = UInt32(0xFFE0_1FE0)
private let arm64FloatLiteralLoadMask = UInt32(0xFF00_001F)
private let arm64FloatLiteralLoadS0Pattern = UInt32(0x1C00_0000)
private let arm64FloatMoveSImmediatePattern = UInt32(0x1E20_1000)
private let arm64FmovS0W8Instruction = UInt32(0x1E27_0100)
private let arm64NoOperationInstruction = UInt32(0xD503_201F)
private let arm64LdrX8X0Plus80Instruction = UInt32(0xF940_2808)
private let arm64LdrX8SPPlus8Instruction = UInt32(0xF940_07E8)
private let arm64InstructionByteCount = 4
private let arm64BranchImmediateSignBit = Int32(1 << 25)
private let arm64BranchImmediateSignExtendMask = Int32(~((1 << 26) - 1))
private let arm64BranchRange = UInt64(128 * 1024 * 1024)
private let machVMFlagsFixed = Int32(0)
private let trampolineMarkerSearchLimit = UInt64(256)
private let rpgDamagePolicyModeMask = UInt32(0x3)

public struct StaticPatchApplyRequest: Sendable {
    public let patch: StaticGamePatch
    public let isEnabled: Bool

    public init(patch: StaticGamePatch, isEnabled: Bool) {
        self.patch = patch
        self.isEnabled = isEnabled
    }
}

public final class StaticPatchEngine {
    private let moduleResolver: MachOModuleResolver

    public init(moduleResolver: MachOModuleResolver = MachOModuleResolver()) {
        self.moduleResolver = moduleResolver
    }

    public func preflight(_ request: StaticPatchApplyRequest, session: MemorySession) throws {
        let module = try moduleResolver.resolveGameAssembly(session: session)
        let mutations = try request.patch.points.map { point in
            try makeMutation(point, module: module, session: session)
        }

        if request.isEnabled {
            try mutations.forEach(validateCanApplyWithoutWriting)
            return
        }

        try mutations.forEach(validateCanRestoreWithoutWriting)
    }

    public func apply(_ request: StaticPatchApplyRequest, session: MemorySession) throws {
        let module = try moduleResolver.resolveGameAssembly(session: session)
        let mutations = try request.patch.points.map { point in
            try makeMutation(point, module: module, session: session)
        }

        if request.isEnabled {
            try mutations.forEach(validateCanApply)
            try mutations.forEach(applyPatch)
            return
        }

        try mutations.forEach(validateCanRestore)
        try mutations.forEach(restorePatch)
    }

    public func verify(_ patch: StaticGamePatch, session: MemorySession) throws {
        let module = try moduleResolver.resolveGameAssembly(session: session)
        for point in patch.points {
            try verifyPoint(point, module: module, session: session)
        }
    }

    private func makeMutation(_ point: StaticPatchPoint, module: LoadedMachOModule, session: MemorySession) throws -> PatchMutation {
        guard point.patchBytes.count <= point.expectedBytes.count else {
            throw TrainerError.invalidInput("静态 patch \(point.note) 的 patchBytes 长度不能超过 expectedBytes。")
        }

        let address = module.baseAddress + point.rva
        let current = try session.read(MemoryReadRequest(address: address, size: point.expectedBytes.count))
        return PatchMutation(
            address: address,
            rva: point.rva,
            moduleBase: module.baseAddress,
            current: current,
            expected: Data(point.expectedBytes),
            patch: Data(point.patchBytes),
            trampoline: point.trampoline,
            acceptsLegacyIntReturnPatch: point.acceptsLegacyIntReturnPatch,
            acceptsCompatibleAppliedPatch: point.acceptsCompatibleAppliedPatch,
            session: session
        )
    }

    private func verifyPoint(_ point: StaticPatchPoint, module: LoadedMachOModule, session: MemorySession) throws {
        guard point.patchBytes.count <= point.expectedBytes.count else {
            throw TrainerError.invalidInput("静态 patch \(point.note) 的 patchBytes 长度不能超过 expectedBytes。")
        }

        let address = module.baseAddress + point.rva
        let snapshot = try session.read(MemoryReadRequest(address: address, size: point.expectedBytes.count))
        let mutation = PatchMutation(
            address: address,
            rva: point.rva,
            moduleBase: module.baseAddress,
            current: snapshot,
            expected: Data(point.expectedBytes),
            patch: Data(point.patchBytes),
            trampoline: point.trampoline,
            acceptsLegacyIntReturnPatch: point.acceptsLegacyIntReturnPatch,
            acceptsCompatibleAppliedPatch: point.acceptsCompatibleAppliedPatch,
            session: session
        )

        try applyPatch(mutation)
        if point.trampoline != nil {
            let updated = try session.read(MemoryReadRequest(address: address, size: point.expectedBytes.count))
            try restorePatch(mutation.replacingCurrent(updated))
            return
        }

        try writeCode(address: address, data: snapshot, session: session)
    }

    private func validateCanApplyWithoutWriting(_ mutation: PatchMutation) throws {
        guard let trampoline = mutation.trampoline else {
            try validateCanApply(mutation)
            return
        }

        try validateTrampolineCanApplyWithoutWriting(mutation, trampoline: trampoline)
    }

    private func validateCanRestoreWithoutWriting(_ mutation: PatchMutation) throws {
        guard let trampoline = mutation.trampoline else {
            try validateCanRestore(mutation)
            return
        }

        try validateTrampolineCanRestoreWithoutWriting(mutation, trampoline: trampoline)
    }

    private func applyPatch(_ mutation: PatchMutation) throws {
        if let trampoline = mutation.trampoline {
            try applyTrampolinePatch(mutation, trampoline: trampoline)
            return
        }

        try validateCanApply(mutation)
        let image = enabledImage(mutation)
        if mutation.current == image {
            try flushInstructionCache(address: mutation.address, size: UInt64(image.count), session: mutation.session)
            return
        }

        try writeCode(address: mutation.address, data: image, session: mutation.session)
    }

    private func restorePatch(_ mutation: PatchMutation) throws {
        if let trampoline = mutation.trampoline {
            try restoreTrampolinePatch(mutation, trampoline: trampoline)
            return
        }

        try validateCanRestore(mutation)
        guard mutation.current != mutation.expected else {
            return
        }

        try writeCode(address: mutation.address, data: mutation.expected, session: mutation.session)
    }

    private func validateTrampolineCanApplyWithoutWriting(_ mutation: PatchMutation, trampoline: StaticPatchTrampoline) throws {
        _ = try trampolineMode(for: trampoline)
        if (try? installedTrampoline(mutation, trampoline: trampoline)) != nil {
            return
        }

        guard mutation.current == mutation.expected else {
            throw TrainerError.targetMismatch("AOB 校验失败：0x\(String(mutation.address, radix: 16)) 当前字节不匹配。")
        }

        if trampoline.codeCaveRVA != nil {
            try validateCodeCaveTrampolineCanApplyWithoutWriting(mutation, trampoline: trampoline)
            return
        }

        _ = try findTrampolineAllocationCandidate(mutation, trampoline: trampoline)
    }

    private func validateTrampolineCanRestoreWithoutWriting(_ mutation: PatchMutation, trampoline: StaticPatchTrampoline) throws {
        guard mutation.current != mutation.expected else {
            return
        }

        _ = try installedTrampoline(mutation, trampoline: trampoline)
        _ = try trampolineMode(for: trampoline)
    }

    private func validateCodeCaveTrampolineCanApplyWithoutWriting(
        _ mutation: PatchMutation,
        trampoline: StaticPatchTrampoline
    ) throws {
        guard let codeCaveRVA = trampoline.codeCaveRVA, let expectedBytes = trampoline.codeCaveExpectedBytes else {
            throw TrainerError.invalidInput("静态代码洞跳板缺少 codeCaveRVA 或 expectedBytes。")
        }

        let codeCaveAddress = mutation.moduleBase + codeCaveRVA
        let expected = Data(expectedBytes)
        let current = try mutation.session.read(MemoryReadRequest(address: codeCaveAddress, size: expected.count))
        guard current == expected else {
            throw TrainerError.targetMismatch("RPG damage trampoline code cave 校验失败：0x\(String(codeCaveAddress, radix: 16)) 当前字节不匹配。")
        }
    }

    private func applyTrampolinePatch(_ mutation: PatchMutation, trampoline: StaticPatchTrampoline) throws {
        let requestedMode = try trampolineMode(for: trampoline)
        if let installed = try? installedTrampoline(mutation, trampoline: trampoline) {
            let nextMode = installed.mode.union(requestedMode)
            if installed.isLegacyMode || nextMode != installed.mode {
                let image = try makeStoredTrampolineImage(mutation, trampoline: trampoline, address: installed.address, mode: nextMode)
                try writeTrampolineCode(address: installed.address, data: image, trampoline: trampoline, session: mutation.session)
            }
            try flushInstructionCache(address: mutation.address, size: UInt64(mutation.expected.count), session: mutation.session)
            return
        }

        if trampoline.codeCaveRVA != nil {
            try applyCodeCaveTrampolinePatch(mutation, trampoline: trampoline, mode: requestedMode)
            return
        }

        guard mutation.current == mutation.expected else {
            throw TrainerError.targetMismatch("AOB 校验失败：0x\(String(mutation.address, radix: 16)) 当前字节不匹配。")
        }

        let allocation = try allocateTrampolinePage(mutation, trampoline: trampoline)
        do {
            let image = try makeStoredTrampolineImage(mutation, trampoline: trampoline, address: allocation, mode: requestedMode)
            try writeAllocatedCode(address: allocation, data: image, session: mutation.session)
            let hook = try Arm64ReturnCode.unconditionalBranch(from: mutation.address, to: allocation)
            try writeCode(address: mutation.address, data: Data(hook), session: mutation.session)
        } catch {
            try? mutation.session.deallocate(MemoryDeallocateRequest(address: allocation, size: trampolinePageSize()))
            throw error
        }
    }

    private func restoreTrampolinePatch(_ mutation: PatchMutation, trampoline: StaticPatchTrampoline) throws {
        guard mutation.current != mutation.expected else {
            return
        }

        let installed = try installedTrampoline(mutation, trampoline: trampoline)
        let requestedMode = try trampolineMode(for: trampoline)
        let nextMode = installed.mode.subtracting(requestedMode)
        guard !nextMode.isEmpty else {
            try writeCode(address: mutation.address, data: mutation.expected, session: mutation.session)
            try restoreTrampolineStorage(address: installed.address, trampoline: trampoline, session: mutation.session)
            return
        }

        let image = try makeStoredTrampolineImage(mutation, trampoline: trampoline, address: installed.address, mode: nextMode)
        try writeTrampolineCode(address: installed.address, data: image, trampoline: trampoline, session: mutation.session)
        try flushInstructionCache(address: mutation.address, size: UInt64(mutation.expected.count), session: mutation.session)
    }

    private func applyCodeCaveTrampolinePatch(
        _ mutation: PatchMutation,
        trampoline: StaticPatchTrampoline,
        mode: RPGDamagePolicyTrampolineMode
    ) throws {
        guard let codeCaveRVA = trampoline.codeCaveRVA, let expectedBytes = trampoline.codeCaveExpectedBytes else {
            throw TrainerError.invalidInput("静态代码洞跳板缺少 codeCaveRVA 或 expectedBytes。")
        }

        guard mutation.current == mutation.expected else {
            throw TrainerError.targetMismatch("AOB 校验失败：0x\(String(mutation.address, radix: 16)) 当前字节不匹配。")
        }

        let codeCaveAddress = mutation.moduleBase + codeCaveRVA
        let expected = Data(expectedBytes)
        let current = try mutation.session.read(MemoryReadRequest(address: codeCaveAddress, size: expected.count))
        guard current == expected else {
            throw TrainerError.targetMismatch("RPG damage trampoline code cave 校验失败：0x\(String(codeCaveAddress, radix: 16)) 当前字节不匹配。")
        }

        do {
            let image = try makeStoredTrampolineImage(mutation, trampoline: trampoline, address: codeCaveAddress, mode: mode)
            try writeCode(address: codeCaveAddress, data: image, session: mutation.session)
            let hook = try Arm64ReturnCode.unconditionalBranch(from: mutation.address, to: codeCaveAddress)
            try writeCode(address: mutation.address, data: Data(hook), session: mutation.session)
        } catch {
            try? writeCode(address: codeCaveAddress, data: expected, session: mutation.session)
            throw error
        }
    }

    private func allocateTrampolinePage(_ mutation: PatchMutation, trampoline: StaticPatchTrampoline) throws -> UInt64 {
        let candidate = try findTrampolineAllocationCandidate(mutation, trampoline: trampoline)
        let allocated = try mutation.session.allocate(MemoryAllocateRequest(address: candidate, size: trampolinePageSize(), flags: machVMFlagsFixed))
        guard allocated == candidate else {
            throw TrainerError.memoryWriteFailed("mach_vm_allocate 返回了非固定跳板地址：0x\(String(allocated, radix: 16))。")
        }
        return allocated
    }

    private func findTrampolineAllocationCandidate(_ mutation: PatchMutation, trampoline: StaticPatchTrampoline) throws -> UInt64 {
        let size = trampolinePageSize()
        let bounds = trampolineSearchBounds(mutation, trampoline: trampoline, pageSize: size)
        return try nearestFreePage(
            in: mutation.session.regions(),
            bounds: bounds,
            reference: mutation.address,
            size: size
        )
    }

    private func makeTrampolineImage(
        _ mutation: PatchMutation,
        trampoline: StaticPatchTrampoline,
        address: UInt64,
        mode: RPGDamagePolicyTrampolineMode
    ) throws -> Data {
        switch trampoline.kind {
        case .rpgEnemyOnlySuperDamage, .rpgDamagePolicySuperDamage, .rpgDamagePolicyIgnoreDamage:
            let addresses = RPGDamagePolicyTrampolineAddresses(
                trampoline: address,
                resume: mutation.moduleBase + trampoline.resumeRVA,
                nullHandler: mutation.moduleBase + trampoline.nullHandlerRVA,
                isEnemy: mutation.moduleBase + trampoline.helperRVA
            )
            let request = RPGDamagePolicyTrampolineRequest(value: trampoline.value, mode: mode, addresses: addresses)
            return Data(try Arm64ReturnCode.writeRPGDamagePolicyTrampoline(request))
        }
    }

    private func makeStoredTrampolineImage(
        _ mutation: PatchMutation,
        trampoline: StaticPatchTrampoline,
        address: UInt64,
        mode: RPGDamagePolicyTrampolineMode
    ) throws -> Data {
        let image = try makeTrampolineImage(mutation, trampoline: trampoline, address: address, mode: mode)
        guard let expectedBytes = trampoline.codeCaveExpectedBytes else {
            return image
        }

        guard image.count <= expectedBytes.count else {
            throw TrainerError.invalidInput("RPG damage trampoline 超出静态代码洞容量。")
        }

        var padded = Data(expectedBytes)
        padded.replaceSubrange(0..<image.count, with: image)
        return padded
    }

    private func writeTrampolineCode(
        address: UInt64,
        data: Data,
        trampoline: StaticPatchTrampoline,
        session: MemorySession
    ) throws {
        if trampoline.codeCaveRVA != nil {
            try writeCode(address: address, data: data, session: session)
            return
        }

        try writeAllocatedCode(address: address, data: data, session: session)
    }

    private func restoreTrampolineStorage(address: UInt64, trampoline: StaticPatchTrampoline, session: MemorySession) throws {
        if let expectedBytes = trampoline.codeCaveExpectedBytes {
            try writeCode(address: address, data: Data(expectedBytes), session: session)
            return
        }

        try session.deallocate(MemoryDeallocateRequest(address: address, size: trampolinePageSize()))
    }

    private func writeAllocatedCode(address: UInt64, data: Data, session: MemorySession) throws {
        try session.protect(MemoryProtectRequest(address: address, size: trampolinePageSize(), protection: MemoryProtection.read | MemoryProtection.write))
        try session.write(MemoryWriteRequest(address: address, data: data))
        try session.protect(MemoryProtectRequest(address: address, size: trampolinePageSize(), protection: MemoryProtection.read | MemoryProtection.execute))
        try verifyCodeWrite(address: address, data: data, session: session)
        try session.flushCache(MemoryCacheFlushRequest(address: address, size: trampolinePageSize(), kind: .instruction))
    }

    private func installedTrampoline(_ mutation: PatchMutation, trampoline: StaticPatchTrampoline?) throws -> InstalledTrampoline {
        guard trampoline != nil, mutation.current.count >= arm64InstructionByteCount else {
            throw TrainerError.targetMismatch("跳板恢复校验失败：0x\(String(mutation.address, radix: 16)) 当前字节不是有效跳板分支。")
        }

        let instruction = mutation.current.littleEndianUInt32(at: 0)
        guard let target = branchTarget(from: instruction, source: mutation.address) else {
            throw TrainerError.targetMismatch("跳板恢复校验失败：0x\(String(mutation.address, radix: 16)) 当前字节不是有效跳板分支。")
        }

        let marker = Data(Arm64ReturnCode.rpgDamagePolicyTrampolineMarker)
        let current = try mutation.session.read(MemoryReadRequest(address: target, size: trampolineMarkerSearchByteCount()))
        guard let markerRange = current.range(of: marker) else {
            throw TrainerError.targetMismatch("跳板恢复校验失败：0x\(String(target, radix: 16)) 缺少 RPG damage trampoline marker。")
        }
        let mode = trampolineMode(from: current, markerOffset: markerRange.lowerBound)
        return InstalledTrampoline(address: target, mode: mode.value, isLegacyMode: mode.isLegacy)
    }

    private func trampolineMode(for trampoline: StaticPatchTrampoline) throws -> RPGDamagePolicyTrampolineMode {
        switch trampoline.kind {
        case .rpgEnemyOnlySuperDamage, .rpgDamagePolicySuperDamage:
            return .enemySuperDamage
        case .rpgDamagePolicyIgnoreDamage:
            return .playerIgnoreDamage
        }
    }

    private func trampolineMode(from image: Data, markerOffset: Int) -> (value: RPGDamagePolicyTrampolineMode, isLegacy: Bool) {
        guard markerOffset >= arm64InstructionByteCount else {
            return (.enemySuperDamage, true)
        }

        let rawMode = image.littleEndianUInt32(at: markerOffset - arm64InstructionByteCount)
        guard rawMode != 0, rawMode & ~rpgDamagePolicyModeMask == 0 else {
            return (.enemySuperDamage, true)
        }

        return (RPGDamagePolicyTrampolineMode(rawValue: rawMode), false)
    }

    private func branchTarget(from instruction: UInt32, source: UInt64) -> UInt64? {
        guard isUnconditionalBranch(instruction) else {
            return nil
        }

        let rawImmediate = Int32(bitPattern: instruction & ~arm64BranchMask)
        let signedImmediate = signExtendBranchImmediate(rawImmediate)
        let distance = Int64(signedImmediate) * Int64(arm64InstructionByteCount)
        return UInt64(Int64(source) + distance)
    }

    private func signExtendBranchImmediate(_ immediate: Int32) -> Int32 {
        if immediate & arm64BranchImmediateSignBit == 0 {
            return immediate
        }

        return immediate | arm64BranchImmediateSignExtendMask
    }

    private func isUnconditionalBranch(_ instruction: UInt32) -> Bool {
        (instruction & arm64BranchMask) == arm64BranchPattern
    }

    private func trampolineSearchBounds(
        _ mutation: PatchMutation,
        trampoline: StaticPatchTrampoline,
        pageSize: UInt64
    ) -> AddressBounds {
        let targets = [
            mutation.address,
            mutation.moduleBase + trampoline.resumeRVA,
            mutation.moduleBase + trampoline.nullHandlerRVA,
            mutation.moduleBase + trampoline.helperRVA
        ]
        let lower = targets.map { branchLowerBound(around: $0, pageSize: pageSize) }.max() ?? 0
        let upper = targets.map { branchUpperBound(around: $0, pageSize: pageSize) }.min() ?? UInt64.max
        return AddressBounds(lower: lower, upper: upper)
    }

    private func branchLowerBound(around address: UInt64, pageSize: UInt64) -> UInt64 {
        let range = arm64BranchRange - pageSize
        return address > range ? address - range : 0
    }

    private func branchUpperBound(around address: UInt64, pageSize: UInt64) -> UInt64 {
        let range = arm64BranchRange - pageSize
        let upper = address.addingReportingOverflow(range)
        return upper.overflow ? UInt64.max : upper.partialValue
    }

    private func nearestFreePage(
        in regions: [MemoryRegion],
        bounds: AddressBounds,
        reference: UInt64,
        size: UInt64
    ) throws -> UInt64 {
        let sortedRegions = regions.sorted { $0.address < $1.address }
        var previousEnd = UInt64.zero
        var best: UInt64?
        for region in sortedRegions {
            best = nearestCandidate(best, candidate: candidatePage(from: previousEnd, to: region.address, bounds: bounds, size: size), reference: reference)
            previousEnd = max(previousEnd, regionEnd(region))
        }

        best = nearestCandidate(best, candidate: candidatePage(from: previousEnd, to: UInt64.max, bounds: bounds, size: size), reference: reference)
        guard let best else {
            throw TrainerError.memoryWriteFailed("未找到 RPG damage trampoline 的 ±128MB 可分配空洞。")
        }
        return best
    }

    private func candidatePage(from start: UInt64, to end: UInt64, bounds: AddressBounds, size: UInt64) -> UInt64? {
        let candidateStart = max(start, bounds.lower)
        let aligned = alignUpToPage(candidateStart)
        guard aligned <= bounds.upper, aligned >= start else {
            return nil
        }

        let candidateEnd = aligned.addingReportingOverflow(size)
        guard !candidateEnd.overflow, candidateEnd.partialValue <= end else {
            return nil
        }
        return aligned
    }

    private func nearestCandidate(_ current: UInt64?, candidate: UInt64?, reference: UInt64) -> UInt64? {
        guard let candidate else {
            return current
        }
        guard let current else {
            return candidate
        }

        return distance(candidate, reference) < distance(current, reference) ? candidate : current
    }

    private func distance(_ lhs: UInt64, _ rhs: UInt64) -> UInt64 {
        lhs > rhs ? lhs - rhs : rhs - lhs
    }

    private func regionEnd(_ region: MemoryRegion) -> UInt64 {
        let end = region.address.addingReportingOverflow(region.size)
        return end.overflow ? UInt64.max : end.partialValue
    }

    private func alignUpToPage(_ address: UInt64) -> UInt64 {
        let pageSize = trampolinePageSize()
        let mask = pageSize - 1
        let added = address.addingReportingOverflow(mask)
        guard !added.overflow else {
            return UInt64.max
        }
        return added.partialValue & ~mask
    }

    private func trampolinePageSize() -> UInt64 {
        UInt64(getpagesize())
    }

    private func trampolineMarkerSearchByteCount() -> Int {
        Int(min(trampolinePageSize(), trampolineMarkerSearchLimit))
    }

    private func validateCanApply(_ mutation: PatchMutation) throws {
        guard canApply(mutation) else {
            throw TrainerError.targetMismatch("AOB 校验失败：0x\(String(mutation.address, radix: 16)) 当前字节不匹配。")
        }
    }

    private func validateCanRestore(_ mutation: PatchMutation) throws {
        guard mutation.current == mutation.expected || canRestore(mutation) else {
            throw TrainerError.targetMismatch("AOB 恢复校验失败：0x\(String(mutation.address, radix: 16)) 当前字节不匹配。")
        }
    }

    private func canApply(_ mutation: PatchMutation) -> Bool {
        if mutation.current == mutation.expected || canRestore(mutation) {
            return true
        }

        return false
    }

    private func canRestore(_ mutation: PatchMutation) -> Bool {
        if mutation.current == enabledImage(mutation) || mutation.current.starts(with: mutation.patch) {
            return true
        }

        if mutation.acceptsLegacyIntReturnPatch && Self.isLegacyIntReturnPatch(mutation.current) {
            return true
        }

        return mutation.acceptsCompatibleAppliedPatch && Self.isCompatibleAppliedPatch(mutation.current)
    }

    private func enabledImage(_ mutation: PatchMutation) -> Data {
        var image = mutation.expected
        image.replaceSubrange(0..<mutation.patch.count, with: mutation.patch)
        return image
    }

    private func writeCode(address: UInt64, data: Data, session: MemorySession) throws {
        let range = protectedPageRange(address: address, size: UInt64(data.count))
        let writableCopy = MemoryProtection.read | MemoryProtection.write | MemoryProtection.copy
        try session.protect(MemoryProtectRequest(address: range.address, size: range.size, protection: writableCopy))
        try session.write(MemoryWriteRequest(address: address, data: data))
        try session.protect(MemoryProtectRequest(address: range.address, size: range.size, protection: MemoryProtection.read | MemoryProtection.execute))
        try verifyCodeWrite(address: address, data: data, session: session)
        try session.flushCache(MemoryCacheFlushRequest(address: range.address, size: range.size, kind: .instruction))
    }

    private func flushInstructionCache(address: UInt64, size: UInt64, session: MemorySession) throws {
        let range = protectedPageRange(address: address, size: size)
        try session.flushCache(MemoryCacheFlushRequest(address: range.address, size: range.size, kind: .instruction))
    }

    private func verifyCodeWrite(address: UInt64, data: Data, session: MemorySession) throws {
        let current = try session.read(MemoryReadRequest(address: address, size: data.count))
        guard current == data else {
            throw TrainerError.verifyFailed("0x\(String(address, radix: 16)) 目标进程字节未变更。")
        }
    }

    private func protectedPageRange(address: UInt64, size: UInt64) -> MemoryRange {
        let pageSize = UInt64(getpagesize())
        let start = address & ~(pageSize - 1)
        let end = (address + size + pageSize - 1) & ~(pageSize - 1)
        return MemoryRange(address: start, size: end - start)
    }

    private static func isLegacyIntReturnPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 2 else {
            return false
        }

        let first = data.littleEndianUInt32(at: 0)
        let second = data.littleEndianUInt32(at: arm64InstructionByteCount)
        if isMoveZ32W0(first) && second == arm64ReturnInstruction {
            return true
        }

        guard data.count >= arm64InstructionByteCount * 3 else {
            return false
        }

        let third = data.littleEndianUInt32(at: arm64InstructionByteCount * 2)
        return isMoveZ32W0(first) && isMoveK32W0Shift16(second) && third == arm64ReturnInstruction
    }

    private static func isCompatibleAppliedPatch(_ data: Data) -> Bool {
        isLegacyIntReturnPatch(data)
            || isObscuredIntReturnPatch(data)
            || isImmediateFloatReturnPatch(data)
            || isImmediateFloatMovePatch(data)
            || isMaterializedFloatReturnPatch(data)
            || isFloatLiteralLoadPatch(data)
            || isFmovS1ImmediatePatch(data)
            || isScaledUnscaledDeltaTimePatch(data)
            || isObscuredPropertySetterPatch(data)
            || isIngredientsSetCountPatch(data)
            || isIngredientsCategoryPatch(data)
            || isLegacyDamagerDamageValuePatch(data)
    }

    private static func isObscuredIntReturnPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 2 else {
            return false
        }

        let first = data.littleEndianUInt32(at: 0)
        let second = data.littleEndianUInt32(at: arm64InstructionByteCount)
        if isMoveZ32W0(first) && isBranch(second) {
            return true
        }

        guard data.count >= arm64InstructionByteCount * 3 else {
            return false
        }

        let third = data.littleEndianUInt32(at: arm64InstructionByteCount * 2)
        return isMoveZ32W0(first) && isMoveK32W0Shift16(second) && isBranch(third)
    }

    private static func isImmediateFloatReturnPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 2 else {
            return false
        }

        let first = data.littleEndianUInt32(at: 0)
        let second = data.littleEndianUInt32(at: arm64InstructionByteCount)
        return isSupportedFloatImmediateMove(first, register: 0) && second == arm64ReturnInstruction
    }

    private static func isImmediateFloatMovePatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount else {
            return false
        }

        let first = data.littleEndianUInt32(at: 0)
        return isSupportedFloatImmediateMove(first, register: 0)
            || isSupportedFloatImmediateMove(first, register: 1)
            || isSupportedFloatImmediateMove(first, register: 2)
            || isSupportedFloatImmediateMove(first, register: 9)
    }

    private static func isMaterializedFloatReturnPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 3 else {
            return false
        }

        let first = data.littleEndianUInt32(at: 0)
        let second = data.littleEndianUInt32(at: arm64InstructionByteCount)
        let third = data.littleEndianUInt32(at: arm64InstructionByteCount * 2)
        if isMoveZ32W8(first) && second == arm64FmovS0W8Instruction && third == arm64ReturnInstruction {
            return true
        }

        guard data.count >= arm64InstructionByteCount * 4 else {
            return false
        }

        let fourth = data.littleEndianUInt32(at: arm64InstructionByteCount * 3)
        return isMoveZ32W8(first)
            && isMoveK32W8Shift16(second)
            && third == arm64FmovS0W8Instruction
            && fourth == arm64ReturnInstruction
    }

    private static func isFloatLiteralLoadPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 4 else {
            return false
        }

        let first = data.littleEndianUInt32(at: 0)
        let second = data.littleEndianUInt32(at: arm64InstructionByteCount)
        let third = data.littleEndianUInt32(at: arm64InstructionByteCount * 2)
        guard (first & arm64FloatLiteralLoadMask) == arm64FloatLiteralLoadS0Pattern else {
            return false
        }

        return (isBranch(second) && third == arm64NoOperationInstruction)
            || (second == arm64ReturnInstruction && third == arm64ReturnInstruction)
    }

    private static func isFmovS1ImmediatePatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount else {
            return false
        }

        return isSupportedFloatImmediateMove(data.littleEndianUInt32(at: 0), register: 1)
    }

    private static func isScaledUnscaledDeltaTimePatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 3 else {
            return false
        }

        return data.littleEndianUInt32(at: 0) == 0xA9BF_7BFD
            && data.littleEndianUInt32(at: 4) == 0x9100_03FD
            && data.littleEndianUInt32(at: 8) == 0xD280_0000
    }

    private static func isObscuredPropertySetterPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 3 else {
            return false
        }

        return data.littleEndianUInt32(at: 0) == 0xA9BD_7BFD
            && data.littleEndianUInt32(at: 4) == 0x9100_03FD
            && data.littleEndianUInt32(at: 8) == 0xF900_17E0
    }

    private static func isIngredientsSetCountPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 2 else {
            return false
        }

        return data.littleEndianUInt32(at: 0) == 0xF940_1408
            && data.littleEndianUInt32(at: 4) == 0xB400_0128
    }

    private static func isIngredientsCategoryPatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount else {
            return false
        }

        let first = data.littleEndianUInt32(at: 0)
        return first == arm64LdrX8X0Plus80Instruction || first == arm64LdrX8SPPlus8Instruction
    }

    private static func isLegacyDamagerDamageValuePatch(_ data: Data) -> Bool {
        guard data.count >= arm64InstructionByteCount * 6 else {
            return false
        }

        return isMoveZ32W8(data.littleEndianUInt32(at: 0))
            && isMoveK32W8Shift16(data.littleEndianUInt32(at: 4))
            && data.littleEndianUInt32(at: 8) == arm64StoreW8X0Plus120Instruction
            && isMoveZ32W8(data.littleEndianUInt32(at: 12))
            && data.littleEndianUInt32(at: 16) == arm64StoreByteW8X0Plus96Instruction
            && data.littleEndianUInt32(at: 20) == arm64ReturnInstruction
    }

    private static func isMoveZ32W0(_ instruction: UInt32) -> Bool {
        (instruction & arm64MoveWide32W0Mask) == arm64MoveZ32W0Pattern
    }

    private static func isMoveK32W0Shift16(_ instruction: UInt32) -> Bool {
        (instruction & arm64MoveWide32W0Mask) == arm64MoveK32W0Shift16Pattern
    }

    private static func isMoveZ32W8(_ instruction: UInt32) -> Bool {
        (instruction & arm64MoveWide32W0Mask) == arm64MoveZ32W8Pattern
    }

    private static func isMoveK32W8Shift16(_ instruction: UInt32) -> Bool {
        (instruction & arm64MoveWide32W0Mask) == arm64MoveK32W8Shift16Pattern
    }

    private static func isBranch(_ instruction: UInt32) -> Bool {
        (instruction & arm64BranchMask) == arm64BranchPattern
    }

    private static func isSupportedFloatImmediateMove(_ instruction: UInt32, register: UInt32) -> Bool {
        let masked = instruction & arm64FloatMoveImmediateMask
        let hasRegister = (instruction & UInt32(0x1F)) == register
        return hasRegister && masked == arm64FloatMoveSImmediatePattern
    }
}

private struct PatchMutation {
    let address: UInt64
    let rva: UInt64
    let moduleBase: UInt64
    let current: Data
    let expected: Data
    let patch: Data
    let trampoline: StaticPatchTrampoline?
    let acceptsLegacyIntReturnPatch: Bool
    let acceptsCompatibleAppliedPatch: Bool
    let session: MemorySession

    func replacingCurrent(_ current: Data) -> PatchMutation {
        PatchMutation(
            address: address,
            rva: rva,
            moduleBase: moduleBase,
            current: current,
            expected: expected,
            patch: patch,
            trampoline: trampoline,
            acceptsLegacyIntReturnPatch: acceptsLegacyIntReturnPatch,
            acceptsCompatibleAppliedPatch: acceptsCompatibleAppliedPatch,
            session: session
        )
    }
}

private struct InstalledTrampoline {
    let address: UInt64
    let mode: RPGDamagePolicyTrampolineMode
    let isLegacyMode: Bool
}

private struct AddressBounds {
    let lower: UInt64
    let upper: UInt64
}

private extension Data {
    func littleEndianUInt32(at offset: Int) -> UInt32 {
        let end = offset + arm64InstructionByteCount
        let bytes = self[offset..<end]
        return bytes.enumerated().reduce(UInt32(0)) { result, element in
            result | UInt32(element.element) << UInt32(element.offset * 8)
        }
    }
}
