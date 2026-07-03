import SwiftUI
import TrainerCore

struct TrainerView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("经典训练器")
                    .font(.largeTitle.bold())
                Text("像风灵月影一样直接点功能卡片。未校准时点“校准这个功能”，扫描到候选后点“设为地址”。")
                    .foregroundStyle(.secondary)
                ResultBanner()
                TrainerFeatureCardsView()
            }
            .padding(24)
        }
    }
}

struct ResultBanner: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: store.latestMessageIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(store.latestMessageIsError ? .orange : .green)
            Text(store.latestMessage)
                .textSelection(.enabled)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .font(.callout)
        .padding(12)
        .background(store.latestMessageIsError ? Color.orange.opacity(0.12) : Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}
