import SwiftUI
import TrainerCore

struct TrainerFeatureCardsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
            ForEach(store.features) { feature in
                TrainerFeatureCard(feature: feature)
            }
        }
    }
}

private struct TrainerFeatureCard: View {
    @EnvironmentObject private var store: AppStore
    let feature: TrainerFeature
    @State private var valueText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.title)
                        .font(.title3.bold())
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(hasAddress ? Color.secondary : Color.orange)
                }
                Spacer()
                Text(feature.valueKind.rawValue)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            TextField("写入值", text: $valueText)
                .textFieldStyle(.roundedBorder)

            if hasAddress {
                calibratedActions
            } else {
                Button {
                    store.beginCalibration(for: feature)
                } label: {
                    Label("校准这个功能", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(hasAddress ? Color.green.opacity(0.35) : Color.orange.opacity(0.35))
        }
        .onAppear {
            guard valueText.isEmpty else {
                return
            }
            valueText = store.defaultValueText(for: feature)
        }
    }

    private var calibratedActions: some View {
        HStack {
            Button {
                store.writeFeature(feature, text: effectiveValueText)
            } label: {
                Label("写入", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                store.toggleFreeze(feature, text: effectiveValueText)
            } label: {
                Label(freezeTitle, systemImage: freezeIcon)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var hasAddress: Bool {
        store.addressEntry(for: feature) != nil
    }

    private var statusText: String {
        guard let entry = store.addressEntry(for: feature) else {
            return "未校准，点这里直接校准"
        }
        return "已校准 0x\(String(entry.address, radix: 16))"
    }

    private var effectiveValueText: String {
        valueText.isEmpty ? store.defaultValueText(for: feature) : valueText
    }

    private var freezeTitle: String {
        store.frozenFeatureIDs.contains(feature.id) ? "停止冻结" : "冻结"
    }

    private var freezeIcon: String {
        store.frozenFeatureIDs.contains(feature.id) ? "pause.circle" : "snowflake"
    }
}
