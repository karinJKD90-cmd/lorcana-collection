import SwiftUI
import SwiftData

struct WishlistView: View {
    @Query var allCards: [Card]
    @State private var selectedTab = 0
    @State private var selectedRarity: String? = nil
    @State private var sortAscending = true

    var priorityCards: [Card] { allCards.filter { $0.inPriorityWishlist && !$0.owned }.sorted { ($0.currentPriceNormal ?? 0) > ($1.currentPriceNormal ?? 0) } }
    var missingCards: [Card] {
        allCards.filter { !$0.owned }
            .filter { selectedRarity == nil || $0.rarity == selectedRarity }
            .sorted { a, b in
                let pa = a.currentPriceNormal ?? 0
                let pb = b.currentPriceNormal ?? 0
                return sortAscending ? pa < pb : pa > pb
            }
    }

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()
            VStack(spacing: 0) {

                // Tabs
                HStack(spacing: 0) {
                    WishlistTab(title: "Priority (\(priorityCards.count))", isActive: selectedTab == 0) { selectedTab = 0 }
                    WishlistTab(title: "All missing (\(missingCards.count))", isActive: selectedTab == 1) { selectedTab = 1 }
                }
                .background(Color(hex: "#0A0614").opacity(0.9))

                // Filters (alleen bij alles missing)
                if selectedTab == 1 {
                    HStack(spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                RarityChip(label: "ALLE", isActive: selectedRarity == nil) { selectedRarity = nil }
                                ForEach(["Common","Uncommon","Rare","Super_rare","Legendary","Enchanted"], id: \.self) { r in
                                    RarityChip(
                                        label: r == "Super_rare" ? "SR" : String(r.prefix(3)).uppercased(),
                                        isActive: selectedRarity == r,
                                        action: { selectedRarity = selectedRarity == r ? nil : r },
                                        rawRarity: r
                                    )
                                }
                            }
                            .padding(.leading, 16)
                        }

                        Button {
                            sortAscending.toggle()
                        } label: {
                            HStack(spacing: 3) {
                                Text("PRICE").font(.system(size: 9)).foregroundStyle(Color(hex: "#C9A961"))
                                Image(systemName: sortAscending ? "arrow.up" : "arrow.down").font(.system(size: 8)).foregroundStyle(Color(hex: "#C9A961"))
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(hex: "#C9A961").opacity(0.5), lineWidth: 0.5))
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.vertical, 8)
                    .background(Color(hex: "#0A0614").opacity(0.8))
                }

                SectionLabel(title: selectedTab == 0 ? "priority" : "all missing")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)

                List(selectedTab == 0 ? priorityCards : missingCards) { card in
                    let activeCards = selectedTab == 0 ? priorityCards : missingCards
                    NavigationLink(destination: CardPageView(cards: activeCards, currentIndex: activeCards.firstIndex(where: { $0.id == card.id }) ?? 0)) {
                        WishlistRow(card: card)
                    }
                    .listRowBackground(Color.black.opacity(0.6))
                    .listRowSeparatorTint(Color(hex: "#3A2F5A"))
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Wishlist")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
    }
}

struct WishlistTab: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title).font(.system(size: 12, weight: isActive ? .medium : .regular))
                    .foregroundStyle(isActive ? Color(hex: "#F4E4A1") : Color(hex: "#8A7A4A"))
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                Rectangle().fill(isActive ? Color(hex: "#C9A961") : Color.clear).frame(height: 1)
            }
        }
    }
}

struct WishlistRow: View {
    let card: Card
    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(urlString: card.imageUrl)
                .scaledToFit()
                .cornerRadius(3)
                .frame(width: 34, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(card.name).font(.system(size: 13, weight: .medium)).foregroundStyle(Color(hex: "#F4E4A1"))
                Text(card.type).font(.system(size: 10)).italic().foregroundStyle(Color(hex: "#8A7A4A"))
                Text("\(card.rarity.replacingOccurrences(of: "_", with: " ")) · #\(card.cardNumber)")
                    .font(.system(size: 10)).foregroundStyle(Color(hex: "#8A7A4A"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let price = card.currentPriceNormal {
                    Text("€ \(String(format: "%.2f", price))").font(.system(size: 13, weight: .medium)).foregroundStyle(Color(hex: "#C9A961"))
                    Text("normal").font(.system(size: 9)).foregroundStyle(Color(hex: "#8A7A4A"))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
