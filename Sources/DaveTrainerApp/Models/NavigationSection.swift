import Foundation

enum NavigationSection: String, CaseIterable, Identifiable {
    case status
    case trainer
    case scanner
    case addresses
    case backups
    case logs

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .status:
            return "状态"
        case .trainer:
            return "训练器"
        case .scanner:
            return "扫描器"
        case .addresses:
            return "地址表"
        case .backups:
            return "备份"
        case .logs:
            return "日志"
        }
    }

    var systemImage: String {
        switch self {
        case .status:
            return "waveform.path.ecg"
        case .trainer:
            return "bolt.fill"
        case .scanner:
            return "scope"
        case .addresses:
            return "list.bullet.rectangle"
        case .backups:
            return "externaldrive.badge.timemachine"
        case .logs:
            return "doc.text.magnifyingglass"
        }
    }
}
