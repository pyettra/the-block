import Foundation

struct Vehicle: Codable, Identifiable {
    let id: String
    let vin: String
    let year: Int
    let make: String
    let model: String
    let trim: String
    let bodyStyle: String
    let exteriorColor: String
    let interiorColor: String
    let engine: String
    let transmission: String
    let drivetrain: String
    let odometerKm: Int
    let fuelType: String
    let conditionGrade: Double
    let conditionReport: String
    let damageNotes: [String]
    let titleStatus: String
    let province: String
    let city: String
    let auctionStart: String
    let startingBid: Int
    let reservePrice: Int?
    let buyNowPrice: Int?
    let images: [String]
    let sellingDealership: String
    let lot: String
    let currentBid: Int?
    let bidCount: Int

    enum CodingKeys: String, CodingKey {
        case id, vin, year, make, model, trim
        case bodyStyle = "body_style"
        case exteriorColor = "exterior_color"
        case interiorColor = "interior_color"
        case engine, transmission, drivetrain
        case odometerKm = "odometer_km"
        case fuelType = "fuel_type"
        case conditionGrade = "condition_grade"
        case conditionReport = "condition_report"
        case damageNotes = "damage_notes"
        case titleStatus = "title_status"
        case province, city
        case auctionStart = "auction_start"
        case startingBid = "starting_bid"
        case reservePrice = "reserve_price"
        case buyNowPrice = "buy_now_price"
        case images
        case sellingDealership = "selling_dealership"
        case lot
        case currentBid = "current_bid"
        case bidCount = "bid_count"
    }

    var title: String { "\(year) \(make) \(model)" }
    var fullTitle: String { "\(year) \(make) \(model) \(trim)" }
    var odometerFormatted: String { "\(NumberFormatter.grouped.string(from: NSNumber(value: odometerKm)) ?? "\(odometerKm)") km" }
    var locationFormatted: String { "\(city), \(province)" }

    var auctionDate: Date? {
        ISO8601DateFormatter.flexible.date(from: auctionStart)
    }

    var auctionStatus: AuctionStatus {
        guard let date = auctionDate else { return .ended }
        let now = Date()
        let endDate = date.addingTimeInterval(24 * 3600)
        if now < date { return .upcoming(date) }
        if now < endDate { return .live(endDate) }
        return .ended
    }

    // Spreads all auctions across a realistic -20h to +8h window relative to now
    // using a deterministic hash of the vehicle ID, so the mix of Upcoming/Live/Ended
    // is stable across launches but varies vehicle-to-vehicle.
    var normalizedAuctionStatus: AuctionStatus {
        let hash = id.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let bucketCount = 200
        let bucket = abs(hash) % bucketCount
        // Spread -20h … +8h (28h window). 0-based bucket → offset in seconds.
        let windowSeconds: Double = 28 * 3600
        let offsetSeconds = (Double(bucket) / Double(bucketCount)) * windowSeconds - 20 * 3600
        let auctionStart = Date().addingTimeInterval(offsetSeconds)
        let auctionEnd = auctionStart.addingTimeInterval(2 * 3600)
        let now = Date()
        if now < auctionStart { return .upcoming(auctionStart) }
        if now < auctionEnd   { return .live(auctionEnd) }
        return .ended
    }
}

enum AuctionStatus {
    case upcoming(Date)
    case live(Date)
    case ended

    var label: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .live: return "Live"
        case .ended: return "Ended"
        }
    }

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }
}

extension NumberFormatter {
    static let grouped: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.currencySymbol = "$"
        f.maximumFractionDigits = 0
        return f
    }()
}

extension ISO8601DateFormatter {
    static let flexible: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

extension String {
    var iso8601Date: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.date(from: self)
    }
}
