import SwiftUI

struct VehicleRowView: View {
    let vehicle: Vehicle
    @EnvironmentObject var store: AuctionStore

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: vehicle.images.first ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "car")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 100, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.fullTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                    Text(vehicle.odometerFormatted)
                    Text("•")
                    Text(vehicle.locationFormatted)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                HStack {
                    Text(store.currentBidFormatted(for: vehicle))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text("\(store.bidCount(for: vehicle)) bids")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    AuctionBadge(status: vehicle.normalizedAuctionStatus)
                }
            }
        }
        .padding(.vertical, 4)
        .overlay(alignment: .topTrailing) {
            if store.hasBid(on: vehicle) {
                Image(systemName: store.isWinning(vehicle: vehicle) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(store.isWinning(vehicle: vehicle) ? .green : .red)
            }
        }
    }
}

struct AuctionBadge: View {
    let status: AuctionStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .live: return .green.opacity(0.15)
        case .upcoming: return .blue.opacity(0.15)
        case .ended: return .gray.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .live: return .green
        case .upcoming: return .blue
        case .ended: return .gray
        }
    }
}
