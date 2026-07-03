import Foundation

public enum TrainerError: Error, LocalizedError {
    case processNotFound
    case processQueryFailed(String)
    case permissionDenied(String)
    case buildMismatch(expected: GameBuildSignature, actual: GameBuildSignature)
    case targetMismatch(String)
    case addressNotCalibrated(featureID: String)
    case memoryReadFailed(String)
    case memoryWriteFailed(String)
    case verifyFailed(String)
    case invalidInput(String)
    case installNotFound(String)
    case fileOperationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .processNotFound:
            return "未找到正在运行的 DAVE THE DIVER 进程。"
        case .processQueryFailed(let detail):
            return "查询进程列表失败：\(detail)"
        case .permissionDenied(let detail):
            return "权限不足：\(detail)"
        case .buildMismatch(let expected, let actual):
            return "游戏版本不匹配。期望 \(expected.version) / \(expected.buildGUID)，实际 \(actual.version) / \(actual.buildGUID)。"
        case .targetMismatch(let detail):
            return "目标不匹配：\(detail)"
        case .addressNotCalibrated(let featureID):
            return "功能 \(featureID) 尚未校准地址，禁止写入。"
        case .memoryReadFailed(let detail):
            return "读取内存失败：\(detail)"
        case .memoryWriteFailed(let detail):
            return "写入内存失败：\(detail)"
        case .verifyFailed(let detail):
            return "写后校验失败：\(detail)"
        case .invalidInput(let detail):
            return "输入无效：\(detail)"
        case .installNotFound(let detail):
            return "未找到游戏安装：\(detail)"
        case .fileOperationFailed(let detail):
            return "文件操作失败：\(detail)"
        }
    }
}
