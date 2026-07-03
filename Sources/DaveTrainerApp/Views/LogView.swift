import SwiftUI

struct LogView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("日志")
                .font(.largeTitle.bold())
            List(store.logs.indices, id: \.self) { index in
                Text(store.logs[index])
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .padding(24)
    }
}
