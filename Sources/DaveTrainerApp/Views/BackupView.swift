import SwiftUI

struct BackupView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("存档备份")
                .font(.largeTitle.bold())
            Text("V1 只做只读识别和目录备份，不写回 .sav。")
                .foregroundStyle(.secondary)
            HStack {
                Button("刷新存档") {
                    store.refreshSaves()
                }
                Button("创建备份") {
                    store.createBackup()
                }
            }
            List(store.saveSnapshots) { snapshot in
                HStack {
                    Text(snapshot.url.lastPathComponent)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(snapshot.size), countStyle: .file))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }
}
