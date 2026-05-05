import SwiftUI

import SwiftData

struct SyncView: View {

    @Environment(\.modelContext) private var context

    @Query var cards: [Card]

    @State private var isSyncing = false

    @State private var progress: Double = 0

    @State private var currentCard = ""

    @State private var totalSynced = 0

    @State private var syncDone = false

    @State private var newValue: Double = 0

    var ownedCards: [Card] { cards.filter { $0.owned } }

    var body: some View {

        ZStack {

            SwirlBackground()
            ArcaneFrame()

            VStack(spacing: 30) {

                Spacer()

                // Lorcana symbool (roteert tijdens sync)

                LorcanaSymbol()

                    .frame(width: 60, height: 60)

                    .rotationEffect(.degrees(isSyncing ? 360 : 0))

                    .animation(isSyncing ? .linear(duration: 4).repeatForever(autoreverses: false) : .default, value: isSyncing)

                Text(syncDone ? "Sync complete" : "Sync prices")

                    .font(.custom("Georgia", size: 22))

                    .foregroundStyle(Color.lorcanaGold)

                if isSyncing {

                    VStack(spacing: 10) {

                        ProgressView(value: progress)

                            .tint(Color.lorcanaGold)

                            .padding(.horizontal, 40)

                        Text(currentCard)

                            .font(.system(size: 11))

                            .foregroundStyle(Color.lorcanaGoldDeep)

                            .lineLimit(1)

                        Text("\(Int(progress * Double(ownedCards.count))) / \(ownedCards.count) cards")

                            .font(.system(size: 13))

                            .foregroundStyle(Color.lorcanaGoldDeep)

                    }

                } else if syncDone {

                    VStack(spacing: 8) {

                        Text("Collection is now worth € \(String(format: "%.2f", newValue))")

                            .font(.system(size: 15))

                            .foregroundStyle(Color.lorcanaGoldLight)

                    }

                } else {

                    Text("\(ownedCards.count) cards will be synced with Lorcast")

                        .font(.system(size: 13))

                        .foregroundStyle(Color.lorcanaGoldDeep)

                        .multilineTextAlignment(.center)

                        .padding(.horizontal, 40)

                }

                if !isSyncing {

                    Button {

                        Task { await startSync() }

                    } label: {

                        Text(syncDone ? "Sync again" : "Start sync")

                            .font(.system(size: 15, weight: .medium))

                            .foregroundStyle(Color.lorcanaVoid)

                            .padding(.horizontal, 32)

                            .padding(.vertical, 12)

                            .background(Color.lorcanaGold)

                            .cornerRadius(10)

                    }

                }

                Spacer()

            }

        }

        .navigationBarTitleDisplayMode(.inline)

        .toolbarColorScheme(.dark, for: .navigationBar)

        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sync")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }

    }

    func startSync() async {

        isSyncing = true

        syncDone = false

        progress = 0

        totalSynced = 0

        for (index, card) in ownedCards.enumerated() {

            currentCard = card.name

            await syncPrice(for: card)

            totalSynced += 1

            progress = Double(index + 1) / Double(ownedCards.count)

            try? await Task.sleep(nanoseconds: 500_000_000)

        }

        // Sla totaalwaarde op als PricePoint

        newValue = ownedCards.compactMap {

            $0.isFoil ? $0.currentPriceFoil : $0.currentPriceNormal

        }.reduce(0, +)

        let point = PricePoint(date: Date(), totalCollectionValue: newValue)

        context.insert(point)

        try? context.save()

        isSyncing = false

        syncDone = true

    }

    func syncPrice(for card: Card) async {

        guard let url = URL(string: "https://api.lorcast.com/v0/cards/\(card.id)") else { return }

        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }

        struct PriceResponse: Codable {

            let prices: Prices?

            struct Prices: Codable {

                let usd: Double?

                let usd_foil: Double?

            }

        }

        if let response = try? JSONDecoder().decode(PriceResponse.self, from: data) {

            card.currentPriceNormal = response.prices?.usd

            card.currentPriceFoil = response.prices?.usd_foil

            card.lastPriceUpdate = Date()

            try? context.save()

        }

    }

}
