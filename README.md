# The Block — iOS

A SwiftUI buyer-side vehicle auction app built for the OPENLANE coding challenge.

---

## How to Run

1. Open `TheBlock.xcodeproj` in Xcode (15 or later)
2. Select a simulator — iPhone 17 Pro or any iOS 17+ device
3. If building to a physical device, select your development team under **Signing & Capabilities**
4. Press **Cmd+R**

This is a self contained project so no dependencies, package manager, nor backend treatment was used.

---

## Time Spent

Using around 3 to 4 hours, I tried to focus on getting the core buyer experience. My main goal was to add the browsing mechanism (with filtering and sorting), the detailed vehicle view and the bidding experience. Some business logic such as meeting the minimum bid, the bid status and availability were core to make the app function as a proper auction. I chose to leave persistence and advanced filtering out of scope to stay within the timebox. Had Claude as a coding assistant to accelarate the scaffolding and developing of inital views and store, going through product and technical decisions as I was testing the final result.  

## Assumptions and Scope

**Included:**
- Full inventory browsing with search, filtering, and sorting
- Vehicle detail view with photos, specs, condition, damage notes, and dealership info
- A bid flow with minimum enforcement, quick-pick suggestions, and live state feedback
- Auction status normalization (Live / Upcoming / Ended) relative to current time
- My Bids tab tracking all bids placed in the current session

**Skipped or simplified:**
- No authentication or user accounts
- No backend — all state is in-memory for the session
- No bid persistence across app launches
- No seller workflows, checkout, or payments
- Auction timestamps are synthetic, so status is normalized (see Notable Decisions)

## Stack

- **Platform:** iOS 17+
- **Language:** Swift 5.9
- **UI:** SwiftUI
- **Architecture:** MVVM
- **Data:** Local JSON bundle (`vehicles.json`), no network calls
- **Backend:** None
- **Database:** None

## What I Built

A native iOS auction browsing experience where a buyer can explore 200 vehicles, inspect details, and place bids.

The app has two tabs: **Browse** shows the full inventory in a searchable, filterable, sortable list. With an arrow beside each vehicle cell, tapping a vehicle opens a detail view with a photo carousel, full specs, condition grade, damage notes, reserve and buy-now (if available) indicators, and a persistent bid bar at the bottom. Tapping "Place Bid" opens a sheet where the buyer enters an amount, sees quick-pick suggestions, and confirms. **My Bids** shows every bid placed in the session, with winning/outbid status and a tap-through back to the vehicle detail.

## Notable Decisions

### Architecture — single shared store

I chose to go for a local store, `AuctionStore`, which served as my main view model. Having it as a `@MainActor ObservableObject`, I was able to inject it at the root via `@EnvironmentObject` and use it throughout the whole app (all pages where dependent of its data). It's responsible for the vehicle list, bid status, search text, filters, and sorting options. Since it's working as our view model, our views are going to read from it and write to it directly. I didn't feel the need, right now, to add separate view models for each screen. 

Keeping it local and responsible for all data, I aimed for simplicity: `filteredVehicles` is a single computed property that reacts to search, filter, and sort changes in one pass. `myBids` is also an array that keeps track of all bids placed inside the app and having them be displayed at the My Bids page. SwiftUI's reactive model means no explicit refresh calls anywhere. The tradeoff is that `AuctionStore` grows with the app, and in a larger codebase we would want to split concerns and have separate stores or specific services.

### Bid state — in-memory only

Bids are stored in three `[String: Int]` dictionaries keyed by vehicle ID: `bids`, `currentBids`, and `bidCounts`. These live for the duration of the app session, since we don't have persistency. My Bids works because both tabs share the same `AuctionStore` instance — it's not persisted anywhere.

One bid per vehicle is intentional: placing a new bid on the same vehicle replaces the previous one in the dictionary, since in a real auction only your highest bid matters to the seller.

The tradeoff is concerning for production-readiness, since closing the app makes everything disappear. In a production version, bids would live on a backend, and the app would sync on launch. We would also need live updates, with subscriptions, for the lastest bids, number of bids, current bid and minimum bid value.

### Auction status normalization

All 200 auction timestamps in the dataset are synthetic past dates. If taken literally, every auction would already be over, making the prototype unusable. My first approach was to map the vehicle's time-of-day to today's date and its scheduled time. If a vehicle's auction time was set for 14:00, I would consider it as 14:00 of today. However, I had an issue since all the auction hours fall between 9am and 8pm, leaving me with a restrictive window to test different bid states: I'd only see Live bids between those hours, Upcoming before, and Ended after. 

Given that, I decided to go through another route: using a deterministic hash of each vehicle's ID to assign a fixed offset related to now. This would spread the auctions across a 28 hour window, regardless of time of day. This way I'm able to test Live, Upcoming, and Ended
states every time the app is opened. 

The consequence is that "Ending Soon" sort currently sorts by the raw JSON timestamp rather than normalized status, so Ended vehicles still appear in the list. That's a known gap (see What I'd Do With More Time).

### Bid restrictions by auction status

The Place Bid button is replaced by a contextual non-interactive bar depending on status:
- **Live** → orange "Place Bid" button
- **Upcoming** → "Bidding opens [relative time]"
- **Ended** → "Auction ended"

The bid sheet is non-tapable for non-live auctions at the UI level. This doesn't enforce anything at the data layer (there's no backend), but it's the right UX constraint for a prototype.

### Bid minimum enforcement and input formatting

I wanted to give more of a realistic touch of bidding, so minimum bids now follow an increment: $100 under $5K, $250 under $15K, $500 under $50K, $1,000 above. The bid sheet shows the minimum, offers three quick-pick amounts (following the increments), and uses a `.onChange` formatter to apply grouping separators as the user types. If the bid is below the minimum value, we'll show a warning message about it and it only appears when the user is activily typing the bid. The confirm button is disabled below the minimum.

I had one issue with data updates: placing a bid updates `AuctionStore` synchronously, which triggers the necessary re-render on SwiftUI before the successful bid state is set. This caused the minimum-bid warning to appear rapidly after the confirmation, and also for the Current Bid and Minimium Bid values to update unwantedly. The fix was to snapshot the pre-bid values and set all state changes in the same synchronous block so they batch into a single re-render.

### Reserve price — visibility

Buyers can see whether the reserve has been met or not, but not its value. This mirrors how most real vehicle auctions work — the reserve is a seller-side threshold, not buyer-facing information.

### Buy Now price

Shown as an informational indicator when present. The label disappears once the current bid meets or exceeds the buy-now price. No "Buy Now" action was implemented and I'm treating it as a regular bid for now. It would be interesting to have a "Buy Now" button for more straightfoward acquisition.

### Image loading

Images are loaded on demand via `AsyncImage` from `placehold.co`. The URLs required a `.png` extension to force PNG responses — the default SVG responses are not supported by `UIImage` / `AsyncImage`. No caching layer was added; images reload on scroll.


## Testing

Manual testing on iPhone 17 Pro simulator (iOS 26.5). Tested:
- Browsing, searching, filtering, and sorting across all 200 vehicles
- Vehicle detail view across vehicles with and without reserve price, buy-now price, and damage notes
- Bid placement, minimum enforcement, and quick-pick amounts
- Winning/outbid state transitions
- Auction status display across Live, Upcoming, and Ended vehicles
- My Bids tab state after placing multiple bids across different vehicles

No automated tests were written within the timebox.

## What I'd Do With More Time

- **Filter ended auctions from the default list** — the Ending Soon sort should exclude Ended vehicles and surface Live ones first, using normalized status rather than raw JSON timestamps
- **Persist bids across launches** — SwiftData would be the natural fit here, replacing the in-memory dictionaries with a proper local store
- **Image caching** — avoid reloading placeholder images on every scroll with `NSCache` or a lightweight caching layer over `AsyncImage`
- **Reserve and Buy Now education** — a tooltip or popover explaining what these values mean to first-time buyers
- **Buy Now action** — a dedicated "Buy Now" button that bypasses the bid flow and sets a "Sold" state on the vehicle
- **Reserve value visibility** — consider showing the reserve amount once it's been met, as confirmation for the buyer
- **Map links** — tapping the dealership location could deep-link to Apple Maps
- **Simpler bid sheet header** — the full vehicle title takes up space; a shorter lot + year/make/model line would be cleaner
- **Bid undo window** — a short grace period (e.g. 5 seconds) to cancel an accidental bid before it commits
