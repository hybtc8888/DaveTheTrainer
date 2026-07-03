import SwiftUI
import TrainerCore

struct AddressBookView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedFeatureID = "gold"
    @State private var addressText = ""
    @State private var valueKind: ScanValueKind = .int32
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("地址表")
                .font(.largeTitle.bold())
            editor
            table
        }
        .padding(24)
    }

    private var editor: some View {
        HStack {
            Picker("功能", selection: $selectedFeatureID) {
                ForEach(store.features) { feature in
                    Text(feature.title).tag(feature.id)
                }
            }
            TextField("地址，例如 0x1000", text: $addressText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
            Picker("类型", selection: $valueKind) {
                ForEach(ScanValueKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            TextField("备注", text: $note)
                .textFieldStyle(.roundedBorder)
            Button("保存") {
                save()
            }
        }
    }

    private var table: some View {
        Table(Array(store.addressBook.entries.values)) {
            TableColumn("功能") { entry in
                Text(entry.featureID)
            }
            TableColumn("地址") { entry in
                Text("0x\(String(entry.address, radix: 16))")
                    .monospaced()
            }
            TableColumn("类型") { entry in
                Text(entry.valueKind.rawValue)
            }
            TableColumn("备注") { entry in
                Text(entry.note)
            }
        }
    }

    private func save() {
        let cleaned = addressText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")
        guard let address = UInt64(cleaned, radix: 16) else {
            store.recordInputError("地址格式无效：\(addressText)")
            return
        }
        let details = AddressEntryDetails(address: address, valueKind: valueKind, note: note)
        let entry = AddressEntry(featureID: selectedFeatureID, details: details)
        store.saveAddress(entry: entry)
    }
}
