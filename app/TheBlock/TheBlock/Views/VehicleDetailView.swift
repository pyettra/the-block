import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @EnvironmentObject var store: AuctionStore
    @State private var showBidSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PhotoCarousel(urls: vehicle.images)

                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    bidSection
                    specsSection
                    conditionSection
                    dealershipSection
                }
                .padding()
            }
        }
        .navigationTitle(vehicle.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bidBar
        }
        .sheet(isPresented: $showBidSheet) {
            BidSheetView(vehicle: vehicle)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vehicle.fullTitle)
                .font(.title2.weight(.bold))

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                    Text(vehicle.odometerFormatted)
                }
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                    Text(vehicle.locationFormatted)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(vehicle.exteriorColor)
                Text("·")
                Text(vehicle.drivetrain)
                Text("·")
                Text(vehicle.transmission.capitalized)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var bidSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Bid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.currentBidFormatted(for: vehicle))
                        .font(.title.weight(.bold))
                        .foregroundStyle(.orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(store.bidCount(for: vehicle)) bids")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    AuctionBadge(status: vehicle.normalizedAuctionStatus)
                }
            }

            if let bid = store.bids[vehicle.id] {
                HStack {
                    Image(systemName: store.isWinning(vehicle: vehicle) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text(store.isWinning(vehicle: vehicle) ? "You're the highest bidder" : "You've been outbid")
                    Spacer()
                    Text(bid.formattedAmount)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundStyle(store.isWinning(vehicle: vehicle) ? .green : .red)
                .padding(10)
                .background((store.isWinning(vehicle: vehicle) ? Color.green : .red).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let reserve = vehicle.reservePrice {
                let met = store.currentBid(for: vehicle) >= reserve
                HStack(spacing: 4) {
                    Image(systemName: met ? "checkmark.seal.fill" : "info.circle")
                    Text(met ? "Reserve met" : "Reserve not yet met")
                }
                .font(.caption)
                .foregroundStyle(met ? .green : .orange)
            }

            if let buyNow = vehicle.buyNowPrice, store.currentBid(for: vehicle) < buyNow {
                let formatted = NumberFormatter.currency.string(from: NSNumber(value: buyNow)) ?? "$\(buyNow)"
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                    Text("Buy Now: \(formatted)")
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var specsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Specifications")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                SpecRow(label: "Engine", value: vehicle.engine)
                SpecRow(label: "Transmission", value: vehicle.transmission.capitalized)
                SpecRow(label: "Drivetrain", value: vehicle.drivetrain)
                SpecRow(label: "Fuel", value: vehicle.fuelType.capitalized)
                SpecRow(label: "Body", value: vehicle.bodyStyle)
                SpecRow(label: "Interior", value: vehicle.interiorColor)
                SpecRow(label: "VIN", value: vehicle.vin)
                SpecRow(label: "Lot", value: vehicle.lot)
            }
        }
    }

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Condition")
                .font(.headline)

            HStack(spacing: 4) {
                ConditionDots(grade: vehicle.conditionGrade)
                Text(String(format: "%.1f / 5.0", vehicle.conditionGrade))
                    .font(.subheadline.weight(.medium))
            }

            Text(vehicle.conditionReport)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: vehicle.titleStatus == "clean" ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                Text("\(vehicle.titleStatus.capitalized) Title")
            }
            .font(.subheadline)
            .foregroundStyle(vehicle.titleStatus == "clean" ? .green : .orange)

            if !vehicle.damageNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Damage Notes")
                        .font(.subheadline.weight(.medium))
                    ForEach(vehicle.damageNotes, id: \.self) { note in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var dealershipSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Selling Dealership")
                .font(.headline)
            HStack {
                Image(systemName: "building.2")
                Text(vehicle.sellingDealership)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var bidBar: some View {
        let status = vehicle.normalizedAuctionStatus
        return VStack(spacing: 0) {
            switch status {
            case .live:
                Button {
                    showBidSheet = true
                } label: {
                    HStack {
                        Text("Place Bid")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Min: \(NumberFormatter.currency.string(from: NSNumber(value: store.minimumBid(for: vehicle))) ?? "")")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)

            case .upcoming(let startDate):
                HStack {
                    Image(systemName: "clock")
                    Text("Bidding opens \(startDate.formatted(.relative(presentation: .named)))")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .background(.ultraThinMaterial)

            case .ended:
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Auction ended")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}

struct SpecRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ConditionDots: View {
    let grade: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(Double(i) <= grade.rounded() ? Color.orange : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct PhotoCarousel: View {
    let urls: [String]
    @State private var currentIndex = 0

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                AsyncImage(url: URL(string: urlString)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            ProgressView()
                        }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 260)
        .background(Color(.systemGray6))
    }
}
