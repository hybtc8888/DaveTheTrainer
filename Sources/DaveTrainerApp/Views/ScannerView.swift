import SwiftUI
import TrainerCore

struct ScannerView: View {
    @EnvironmentObject private var store: AppStore
    @State private var valueText = "100"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("校准向导")
                .font(.largeTitle.bold())
            Text("选择功能，输入游戏里现在看到的数值，扫描后把最像的候选设为地址。")
                .foregroundStyle(.secondary)
            ResultBanner()
            controls
            resultSummary
            candidateList
        }
        .padding(24)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("校准功能", selection: $store.calibrationFeatureID) {
                    ForEach(store.features) { feature in
                        Text(feature.title).tag(feature.id)
                    }
                }
                .frame(width: 220)

                Text(featureTypeText)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            }

            HStack {
                TextField("当前游戏数值，例如 100", text: $valueText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)

                Button {
                    scanSelectedFeature()
                } label: {
                    Label("扫描当前数值", systemImage: "scope")
                        .frame(minWidth: 140)
                }
                .buttonStyle(.borderedProminent)

                Button("一键准备") {
                    store.quickPrepare()
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var resultSummary: some View {
        HStack {
            Text("候选 \(store.scanCandidates.count)")
            Text("读取失败区域 \(store.scanFailures.count)")
            Spacer()
            Text("提示：候选太多时，回游戏改变数值后再扫新的当前值。")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.secondary)
    }

    private var candidateList: some View {
        List(store.scanCandidates) { candidate in
            HStack {
                Text("0x\(String(candidate.address, radix: 16))")
                    .monospaced()
                Spacer()
                Text(valueText(for: candidate.value))
                    .foregroundStyle(.secondary)
                Button("设为地址") {
                    store.saveCandidate(candidate, forFeatureID: store.calibrationFeatureID)
                }
                .disabled(!candidateMatchesSelectedFeature(candidate))
            }
        }
    }

    private var selectedFeature: TrainerFeature? {
        store.feature(for: store.calibrationFeatureID)
    }

    private var featureTypeText: String {
        guard let selectedFeature else {
            return "未知功能"
        }
        return "扫描类型：\(selectedFeature.valueKind.rawValue)"
    }

    private func scanSelectedFeature() {
        guard let selectedFeature else {
            store.recordInputError("请先选择一个要校准的功能。")
            return
        }
        store.scanExact(kind: selectedFeature.valueKind, text: valueText)
    }

    private func candidateMatchesSelectedFeature(_ candidate: ScanCandidate) -> Bool {
        candidate.value.kind == selectedFeature?.valueKind
    }

    private func valueText(for value: ScanValue) -> String {
        value.intValue.map(String.init) ?? value.doubleValue.map { String(format: "%.4f", $0) } ?? "-"
    }
}
