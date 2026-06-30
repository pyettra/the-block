import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AuctionStore

    var body: some View {
        TabView {
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "car.2")
                }

            MyBidsView()
                .tabItem {
                    Label("My Bids", systemImage: "wallet.bifold")
                }
        }
        .tint(.orange)
    }
}
