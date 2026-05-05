
import SwiftUI
import SwiftData

struct SetSelectionView: View {
    @Query var cards: [Card]

    struct SetData: Identifiable {
        let id: Int // setNumber
        let number: Int
        let name: String
        let owned: Int
        let total: Int
        let totalValue: Double
        let promoOwned: Int
        let promoTotal: Int
    }

    var setsData: [SetData] {
        let grouped = Dictionary(grouping: cards.filter { $0.rarity != "Promo" }) { $0.setNumber }
        let promoGrouped = Dictionary(grouping: cards.filter { $0.rarity == "Promo" }) { $0.setNumber }

        return grouped.compactMap { (number, setCards) -> SetData? in
            guard number > 0 else { return nil }
            let owned = setCards.filter { $0.owned }
            let value = owned.reduce(0.0) { sum, c in
                sum + (c.isFoil ? (c.currentPriceFoil ?? c.currentPriceNormal ?? 0) : (c.currentPriceNormal ?? 0))
            }
            let promos = promoGrouped[number] ?? []
            return SetData(
                id: number,
                number: number,
                name: setCards.first?.setName ?? "Unknown",
                owned: owned.count,
                total: setCards.count,
                totalValue: value,
                promoOwned: promos.filter { $0.owned }.count,
                promoTotal: promos.count
            )
        }
        .filter { $0.total > 0 }
        .sorted { $0.number < $1.number }
    }

    var totalOwnedCards: Int { cards.filter { $0.owned && $0.rarity != "Promo" }.count }
    var totalCards: Int { cards.filter { $0.setNumber > 0 && $0.rarity != "Promo" }.count }

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()
            ScrollView {
                VStack(spacing: 8) {
                    SectionLabel(title: "overview")
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                    NavigationLink(destination: CardGridView(setNumber: nil, setName: "All cards")) {
                        AllCardsRowView(
                            owned: totalOwnedCards,
                            total: totalCards
                        )
                    }
                    .buttonStyle(.plain)

                    SectionLabel(title: "my sets")
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 4)

                    ForEach(setsData) { cardSet in
                        VStack(spacing: 4) {
                            NavigationLink(destination: CardGridView(setNumber: cardSet.number, setName: cardSet.name)) {
                                SetRowView(cardSet: cardSet)
                            }
                            .buttonStyle(.plain)

                            // Promo rij — alleen tonen als de set promo kaarten heeft
                            if cardSet.promoTotal > 0 {
                                NavigationLink(destination: CardGridView(setNumber: cardSet.number, setName: "\(cardSet.name) — Promo's", initialRarity: "Promo")) {
                                    PromoRowView(owned: cardSet.promoOwned, total: cardSet.promoTotal)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 20)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Collection")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
    }
}

// MARK: - Set rij (met prijs)

struct SetRowView: View {
    let cardSet: SetSelectionView.SetData

    var percentage: Double { cardSet.total > 0 ? Double(cardSet.owned) / Double(cardSet.total) : 0 }
    var percentageInt: Int { Int(percentage * 100) }
    var isComplete: Bool { cardSet.owned == cardSet.total && cardSet.total > 0 }

    var inkColor: Color {
        let colors: [Color] = [
            Color(hex: "#E8A923"),
            Color(hex: "#5A8FBF"),
            Color(hex: "#3A9D5D"),
            Color(hex: "#B378BF"),
            Color(hex: "#E24B4A")
        ]
        let index = (cardSet.number - 1) % colors.count
        return colors[max(0, min(index, colors.count - 1))]
    }

    var barColor: Color { isComplete ? Color(hex: "#C9A961") : inkColor }

    var body: some View {
        HStack(spacing: 12) {

            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(inkColor.opacity(0.12))
                    .overlay(Rectangle().strokeBorder(inkColor.opacity(0.4), lineWidth: 0.5))
                LorcanaSymbol(color: inkColor).frame(width: 22, height: 22)
            }
            .frame(width: 44, height: 56)

            // Info
            VStack(alignment: .leading, spacing: 5) {

                // Set label + prijs op zelfde regel
                HStack(alignment: .firstTextBaseline) {
                    Text("SET \(String(format: "%02d", cardSet.number))")
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "#8A7A4A"))
                    Spacer()
                    if cardSet.totalValue > 0 {
                        Text("€\(String(format: "%.0f", cardSet.totalValue))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(hex: "#C9A961").opacity(0.85))
                    }
                }

                // Naam
                Text(cardSet.name)
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(Color(hex: "#F4E4A1"))
                    .lineLimit(1)

                // Progressie
                VStack(alignment: .leading, spacing: 3) {
                    // Balk
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "#1A1428"))
                                .frame(height: 4)
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: isComplete
                                            ? [Color(hex: "#C9A961"), Color(hex: "#F4E4A1")]
                                            : [barColor.opacity(0.7), barColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * percentage, percentage > 0 ? 4 : 0), height: 4)
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)

                    // Count + percentage
                    HStack(spacing: 0) {
                        Text("\(cardSet.owned)")
                            .foregroundStyle(cardSet.owned > 0 ? Color(hex: "#C9A961").opacity(0.8) : Color(hex: "#6A5A3A"))
                        Text("/\(cardSet.total)")
                            .foregroundStyle(Color(hex: "#6A5A3A"))
                        Spacer()
                        if isComplete {
                            Text("COMPLETE")
                                .foregroundStyle(Color(hex: "#C9A961"))
                        } else {
                            Text("\(percentageInt)%")
                                .foregroundStyle(Color(hex: "#6A5A3A"))
                        }
                    }
                    .font(.system(size: 9, design: .monospaced))
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#C9A961").opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(0.70)
                .overlay(Rectangle().strokeBorder(
                    isComplete ? Color(hex: "#C9A961").opacity(0.5) : Color(hex: "#C9A961").opacity(0.25),
                    lineWidth: 0.6
                ))
        )
    }
}

// MARK: - Promo rij

struct PromoRowView: View {
    let owned: Int
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Rectangle()
                    .fill(Color(hex: "#B378BF").opacity(0.08))
                    .overlay(Rectangle().strokeBorder(Color(hex: "#B378BF").opacity(0.3), lineWidth: 0.5))
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#B378BF").opacity(0.7))
            }
            .frame(width: 34, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("PROMO")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#B378BF"))
                Text("\(owned)/\(total) owned")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#8A7A4A"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#B378BF").opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Color.black.opacity(0.55)
                .overlay(Rectangle().strokeBorder(Color(hex: "#B378BF").opacity(0.2), lineWidth: 0.5))
        )
    }
}

// MARK: - Alle kaarten rij

struct AllCardsRowView: View {
    let owned: Int
    let total: Int
    var percentage: Double { total > 0 ? Double(owned) / Double(total) : 0 }
    var percentageInt: Int { Int(percentage * 100) }

    var body: some View {
        HStack(spacing: 12) {

            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(Color(hex: "#C9A961").opacity(0.10))
                    .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.4), lineWidth: 0.5))
                LorcanaSymbol(color: Color(hex: "#C9A961")).frame(width: 22, height: 22)
            }
            .frame(width: 44, height: 56)

            // Info
            VStack(alignment: .leading, spacing: 5) {

                // Label
                Text("ALL SETS")
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Color(hex: "#8A7A4A"))

                // Naam
                Text("All cards")
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(Color(hex: "#F4E4A1"))

                // Progressie
                VStack(alignment: .leading, spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "#1A1428"))
                                .frame(height: 4)
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#C9A961").opacity(0.6), Color(hex: "#C9A961")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * percentage, percentage > 0 ? 4 : 0), height: 4)
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)

                    HStack(spacing: 0) {
                        Text("\(owned)")
                            .foregroundStyle(owned > 0 ? Color(hex: "#C9A961").opacity(0.8) : Color(hex: "#6A5A3A"))
                        Text("/\(total)")
                            .foregroundStyle(Color(hex: "#6A5A3A"))
                        Spacer()
                        Text("\(percentageInt)%")
                            .foregroundStyle(Color(hex: "#6A5A3A"))
                    }
                    .font(.system(size: 9, design: .monospaced))
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#C9A961").opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(0.70)
                .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.5), lineWidth: 0.8))
        )
    }
}
