import SwiftUI
import SwiftData

struct CardBrowserView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Card.cardNumber) var cards: [Card]
    @StateObject private var service = LorcanaAPIService()
    @State private var searchText = ""

    var filtered: [Card] {
        if searchText.isEmpty { return cards }
        return cards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            Group {
                if service.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.lorcanaGold)
                        Text("Loading cards...")
                            .foregroundStyle(.lorcanaGoldDeep)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.lorcanaVoid)

                } else if cards.isEmpty {
                    VStack(spacing: 16) {
                        Text("No cards found")
                            .foregroundStyle(.lorcanaGoldDeep)
                        Button("Load cards") {
                            Task { await service.syncCards(context: context) }
                        }
                        .foregroundStyle(.lorcanaGold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.lorcanaVoid)

                } else {
                    List(filtered) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.name)
                                .foregroundStyle(.lorcanaGoldLight)
                            Text("\(card.setName) · \(card.rarity)")
                                .font(.caption)
                                .foregroundStyle(.lorcanaGoldDeep)
                        }
                        .listRowBackground(Color.lorcanaPurple)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.lorcanaVoid)
                }
            }
            .navigationTitle("Cards")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search card...")
            .task {
                if cards.isEmpty {
                    await service.syncCards(context: context)
                }
            }
        }
    }
}
