import SwiftUI

struct BidSheetView: View {
    let vehicle: Vehicle
    @EnvironmentObject var store: AuctionStore
    @Environment(\.dismiss) private var dismiss
    @State private var bidAmount = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var confirmedAmount: Int? = nil
    @State private var snapshotCurrentBid: Int? = nil
    @State private var snapshotMinimumBid: Int? = nil

    private var minimumBid: Int { store.minimumBid(for: vehicle) }

    private func formatted(_ amount: Int) -> String {
        NumberFormatter.grouped.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private var bidValue: Int? {
        Int(bidAmount.filter(\.isNumber))
    }

    private var isValid: Bool {
        guard let value = bidValue else { return false }
        return value >= minimumBid
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(vehicle.fullTitle)
                        .font(.headline)
                    Text("Lot \(vehicle.lot)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Current Bid")
                        Spacer()
                        Text(NumberFormatter.currency.string(from: NSNumber(value: snapshotCurrentBid ?? store.currentBid(for: vehicle))) ?? "")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    HStack {
                        Text("Minimum Bid")
                        Spacer()
                        Text(NumberFormatter.currency.string(from: NSNumber(value: snapshotMinimumBid ?? minimumBid)) ?? "")
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Bid")
                        .font(.subheadline.weight(.medium))

                    HStack {
                        Text("$")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.secondary)
                        TextField("Enter amount", text: $bidAmount)
                            .font(.title2.weight(.bold))
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if !showSuccess, let value = bidValue, value < minimumBid {
                        Text("Bid must be at least \(NumberFormatter.currency.string(from: NSNumber(value: minimumBid)) ?? "")")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                HStack(spacing: 8) {
                    ForEach([minimumBid, minimumBid + 500, minimumBid + 1000], id: \.self) { amount in
                        Button {
                            bidAmount = formatted(amount)
                        } label: {
                            Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                if showSuccess, let amount = confirmedAmount {
                    Label(
                        "Bid of \(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "") placed!",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.green)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    guard let value = bidValue else { return }
                    let currentBidBeforePlace = store.currentBid(for: vehicle)
                    let minimumBidBeforePlace = minimumBid
                    guard store.placeBid(on: vehicle, amount: value) else {
                        showError = true
                        return
                    }
                    confirmedAmount = value
                    snapshotCurrentBid = currentBidBeforePlace
                    snapshotMinimumBid = minimumBidBeforePlace
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                } label: {
                    Text("Confirm Bid")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? .orange : .gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValid)
            }
            .padding()
            .navigationTitle("Place Bid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                bidAmount = formatted(minimumBid)
            }
            .onChange(of: bidAmount) { _, newValue in
                let digits = newValue.filter(\.isNumber)
                guard let value = Int(digits), !digits.isEmpty else {
                    if digits.isEmpty { bidAmount = "" }
                    return
                }
                let formatted = NumberFormatter.grouped.string(from: NSNumber(value: value)) ?? digits
                if formatted != newValue { bidAmount = formatted }
            }
            .alert("Bid Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text("Your bid must be higher than the current bid.")
            }
        }
        .presentationDetents([.medium, .large])
    }
}
