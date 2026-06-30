import Foundation

struct Bid: Identifiable {
    let id = UUID()
    let vehicleId: String
    let amount: Int
    let timestamp: Date

    var formattedAmount: String {
        NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: timestamp)
    }
}
