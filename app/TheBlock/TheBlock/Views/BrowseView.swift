import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var store: AuctionStore
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            List(store.filteredVehicles) { vehicle in
                NavigationLink(value: vehicle.id) {
                    VehicleRowView(vehicle: vehicle)
                }
            }
            .listStyle(.plain)
            .navigationTitle("The Block")
            .searchable(text: $store.searchText, prompt: "Search make, model, color, city…")
            .navigationDestination(for: String.self) { id in
                if let vehicle = store.vehicle(byId: id) {
                    VehicleDetailView(vehicle: vehicle)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle\(store.activeFilterCount > 0 ? ".fill" : "")")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                store.sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if store.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView()
            }
            .overlay {
                if store.filteredVehicles.isEmpty {
                    ContentUnavailableView.search(text: store.searchText)
                }
            }
        }
    }
}
