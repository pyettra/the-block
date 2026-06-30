import SwiftUI

struct FilterView: View {
    @EnvironmentObject var store: AuctionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Make") {
                    ForEach(store.availableMakes, id: \.self) { make in
                        Button {
                            if store.selectedMakes.contains(make) {
                                store.selectedMakes.remove(make)
                            } else {
                                store.selectedMakes.insert(make)
                            }
                        } label: {
                            HStack {
                                Text(make)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if store.selectedMakes.contains(make) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }

                Section("Body Style") {
                    ForEach(store.availableBodyStyles, id: \.self) { style in
                        Button {
                            if store.selectedBodyStyles.contains(style) {
                                store.selectedBodyStyles.remove(style)
                            } else {
                                store.selectedBodyStyles.insert(style)
                            }
                        } label: {
                            HStack {
                                Text(style)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if store.selectedBodyStyles.contains(style) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { store.clearFilters() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
