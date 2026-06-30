import SwiftUI

struct MyBidsView: View {
    @EnvironmentObject var store: AuctionStore

    var body: some View {
        NavigationStack {
            Group {
                if store.myBids.isEmpty {
                    ContentUnavailableView(
                        "No Bids Yet",
                        systemImage: "wallet.bifold",
                        description: Text("Browse vehicles and place your first bid.")
                    )
                } else {
                    List(store.myBids) { bid in
                        if let vehicle = store.vehicle(byId: bid.vehicleId) {
                            NavigationLink(value: vehicle.id) {
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: vehicle.images.first ?? "")) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                    }
                                    .frame(width: 60, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(vehicle.fullTitle)
                                            .font(.subheadline.weight(.semibold))
                                        HStack {
                                            Text("Your bid: \(bid.formattedAmount)")
                                                .font(.caption)
                                            Spacer()
                                            Image(systemName: store.isWinning(vehicle: vehicle) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                                .foregroundStyle(store.isWinning(vehicle: vehicle) ? .green : .red)
                                                .font(.caption)
                                            Text(store.isWinning(vehicle: vehicle) ? "Winning" : "Outbid")
                                                .font(.caption)
                                                .foregroundStyle(store.isWinning(vehicle: vehicle) ? .green : .red)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: String.self) { id in
                        if let vehicle = store.vehicle(byId: id) {
                            VehicleDetailView(vehicle: vehicle)
                        }
                    }
                }
            }
            .navigationTitle("My Bids")
        }
    }
}
