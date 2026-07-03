import SwiftUI

struct StatusView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("DAVE THE DIVER 简单修改器")
                    .font(.largeTitle.bold())
                Text("先点一键准备。准备成功后，已校准的功能可以直接写入或冻结；未校准的功能点卡片里的校准按钮。")
                    .foregroundStyle(.secondary)
                ResultBanner()
                primaryActions
                statusGrid
                Divider()
                TrainerFeatureCardsView()
            }
            .padding(24)
        }
    }

    private var statusGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
            GridRow {
                Text("游戏版本").foregroundStyle(.secondary)
                Text(store.install?.signature.version ?? "未识别")
            }
            GridRow {
                Text("Build GUID").foregroundStyle(.secondary)
                Text(store.install?.signature.buildGUID ?? "未识别")
                    .textSelection(.enabled)
            }
            GridRow {
                Text("进程").foregroundStyle(.secondary)
                Text(store.targetProcess.map { "PID \($0.pid) / \($0.name)" } ?? "未运行")
            }
            GridRow {
                Text("附加状态").foregroundStyle(.secondary)
                Text(store.isAttached ? "已附加" : "未附加")
                    .foregroundStyle(store.isAttached ? .green : .orange)
            }
            GridRow {
                Text("地址表").foregroundStyle(.secondary)
                Text("\(store.addressBook.entries.count) 项")
            }
            GridRow {
                Text("存档").foregroundStyle(.secondary)
                Text("\(store.saveSnapshots.count) 个 .sav 文件")
            }
        }
    }

    private var primaryActions: some View {
        HStack(spacing: 12) {
            Button {
                store.quickPrepare()
            } label: {
                Label("一键准备", systemImage: "bolt.fill")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)

            Button("刷新状态") {
                store.refreshAll()
            }
            Button("附加进程") {
                store.attach()
            }
            Button("备份存档") {
                store.createBackup()
            }
        }
    }
}
