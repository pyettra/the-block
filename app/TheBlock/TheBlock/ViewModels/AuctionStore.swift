import Foundation

@MainActor
final class AuctionStore: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var searchText = ""
    // Brands such as Toyota, BWM, Ford...
    @Published var selectedMakes: Set<String> = []
    // Car style such as Coupe, SUV...
    @Published var selectedBodyStyles: Set<String> = []
    // Defalt sort option: we want to first show the offers that are ending soon
    @Published var sortOption: SortOption = .endingSoon
    @Published var bids: [String: Bid] = [:]
    @Published var currentBids: [String: Int] = [:]
    @Published var bidCounts: [String: Int] = [:]

    var availableMakes: [String] {
        Array(Set(vehicles.map(\.make))).sorted()
    }

    var availableBodyStyles: [String] {
        Array(Set(vehicles.map(\.bodyStyle))).sorted()
    }

    var filteredVehicles: [Vehicle] {
        var result = vehicles

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.trim.lowercased().contains(query) ||
                $0.make.lowercased().contains(query) ||
                $0.model.lowercased().contains(query) ||
                $0.exteriorColor.lowercased().contains(query) ||
                $0.sellingDealership.lowercased().contains(query) ||
                $0.city.lowercased().contains(query)
            }
        }

        if !selectedMakes.isEmpty {
            result = result.filter { selectedMakes.contains($0.make) }
        }

        if !selectedBodyStyles.isEmpty {
            result = result.filter { selectedBodyStyles.contains($0.bodyStyle) }
        }

        switch sortOption {
        case .endingSoon:
            result.sort { ($0.auctionDate ?? .distantFuture) < ($1.auctionDate ?? .distantFuture) }
        case .priceLow:
            result.sort { currentBid(for: $0) < currentBid(for: $1) }
        case .priceHigh:
            result.sort { currentBid(for: $0) > currentBid(for: $1) }
        case .newest:
            result.sort { $0.year > $1.year }
        case .mostBids:
            result.sort { bidCount(for: $0) > bidCount(for: $1) }
        }

        return result
    }

    var myBids: [Bid] {
        Array(bids.values).sorted { $0.timestamp > $1.timestamp }
    }

    var activeFilterCount: Int {
        (selectedMakes.isEmpty ? 0 : 1) + (selectedBodyStyles.isEmpty ? 0 : 1)
    }

    init() {
        loadVehicles()
    }

    func currentBid(for vehicle: Vehicle) -> Int {
        currentBids[vehicle.id] ?? vehicle.currentBid ?? vehicle.startingBid
    }

    func bidCount(for vehicle: Vehicle) -> Int {
        bidCounts[vehicle.id] ?? vehicle.bidCount
    }

    func currentBidFormatted(for vehicle: Vehicle) -> String {
        let amount = currentBid(for: vehicle)
        return NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    func placeBid(on vehicle: Vehicle, amount: Int) -> Bool {
        let current = currentBid(for: vehicle)
        guard amount > current else { return false }

        let bid = Bid(vehicleId: vehicle.id, amount: amount, timestamp: Date())
        bids[vehicle.id] = bid
        currentBids[vehicle.id] = amount
        bidCounts[vehicle.id] = bidCount(for: vehicle) + 1
        return true
    }

    func hasBid(on vehicle: Vehicle) -> Bool {
        bids[vehicle.id] != nil
    }

    func isWinning(vehicle: Vehicle) -> Bool {
        guard let bid = bids[vehicle.id] else { return false }
        return bid.amount >= currentBid(for: vehicle)
    }

    func minimumBid(for vehicle: Vehicle) -> Int {
        let current = currentBid(for: vehicle)
        return current + bidIncrement(for: current)
    }

    func clearFilters() {
        selectedMakes.removeAll()
        selectedBodyStyles.removeAll()
    }

    func vehicle(byId id: String) -> Vehicle? {
        vehicles.first { $0.id == id }
    }

    private func bidIncrement(for amount: Int) -> Int {
        switch amount {
        case ..<5000: return 100
        case ..<15000: return 250
        case ..<50000: return 500
        default: return 1000
        }
    }

    private func loadVehicles() {
        guard let url = Bundle.main.url(forResource: "vehicles", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        let decoder = JSONDecoder()
        vehicles = (try? decoder.decode([Vehicle].self, from: data)) ?? []
    }
}

enum SortOption: String, CaseIterable {
    case endingSoon = "Ending Soon"
    case priceLow = "Price: Low"
    case priceHigh = "Price: High"
    case newest = "Newest"
    case mostBids = "Most Bids"
}
