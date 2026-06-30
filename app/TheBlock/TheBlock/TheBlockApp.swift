import SwiftUI

@main
struct TheBlockApp: App {
    @StateObject private var store = AuctionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
