import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query var cards: [Card]
    @Query(sort: \PricePoint.date) var priceHistory: [PricePoint]

    var ownedCards: [Card] { cards.filter { $0.owned } }
    var totalValue: Double { ownedCards.compactMap { $0.isFoil ? $0.currentPriceFoil : $0.currentPriceNormal }.reduce(0, +) }
    var foilPercentage: Int { ownedCards.isEmpty ? 0 : Int(Double(ownedCards.filter { $0.isFoil }.count) / Double(ownedCards.count) * 100) }
    var legendaryCount: Int { ownedCards.filter { $0.rarity == "Legendary" }.count }
    var setCount: Int { Set(ownedCards.map { $0.setNumber }).count }

    var topCards: [Card] {
        ownedCards.sorted { ($0.isFoil ? $0.currentPriceFoil : $0.currentPriceNormal) ?? 0 > ($1.isFoil ? $1.currentPriceFoil : $1.currentPriceNormal) ?? 0 }.prefix(5).map { $0 }
    }

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()
            ScrollView {
                VStack(spacing: 24) {

                    // Totaalwaarde
                    VStack(spacing: 6) {
                        Text("TOTAL · VALUE")
                            .font(.system(size: 10)).tracking(2)
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                            .padding(.top, 24)

                        Text("€ \(String(format: "%.2f", totalValue))")
                            .font(.custom("Georgia", size: 38))
                            .foregroundStyle(Color(hex: "#C9A961"))
                    }

                    // Waardegrafiek
                    ArcaneBlock {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("LAST 90 DAYS")
                                .font(.system(size: 9)).tracking(2)
                                .foregroundStyle(Color(hex: "#8A7A4A"))

                            if priceHistory.count > 1 {
                                Chart(priceHistory) { point in
                                    LineMark(x: .value("Date", point.date), y: .value("Value", point.totalCollectionValue))
                                        .foregroundStyle(Color(hex: "#C9A961")).lineStyle(StrokeStyle(lineWidth: 1.5))
                                    AreaMark(x: .value("Date", point.date), y: .value("Value", point.totalCollectionValue))
                                        .foregroundStyle(LinearGradient(colors: [Color(hex: "#C9A961").opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                                }
                                .frame(height: 120)
                                .chartXAxis { AxisMarks { AxisValueLabel().foregroundStyle(Color(hex: "#8A7A4A")) } }
                                .chartYAxis { AxisMarks { AxisValueLabel().foregroundStyle(Color(hex: "#8A7A4A")) } }
                            } else {
                                Text("Sync prices to see the chart")
                                    .font(.custom("Georgia", size: 12)).italic()
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                                    .frame(height: 80, alignment: .center).frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Top 5
                    SectionLabel(title: "top 5 most valuable")
                        .padding(.horizontal)

                    ArcaneBlock {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(topCards.enumerated()), id: \.element.id) { index, card in
                                    NavigationLink(destination: CardPageView(cards: topCards, currentIndex: index)) {
                                        VStack(spacing: 6) {
                                            CachedAsyncImage(urlString: card.imageUrl)
                                                .scaledToFit()
                                                .frame(width: 60, height: 85)
                                                .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6))

                                            if let price = card.isFoil ? card.currentPriceFoil : card.currentPriceNormal {
                                                Text("€ \(String(format: "%.0f", price))")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(Color(hex: "#C9A961"))
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    NavigationLink(destination: CardGridView(
                        setNumber: nil,
                        setName: "All cards",
                        initialSortMode: .priceDesc,
                        filterOwned: true
                    )) {
                        HStack(spacing: 4) {
                            Text("show all")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                        }
                    }
                    .padding(.horizontal)

                    // Statistiek tegels
                    SectionLabel(title: "statistics")
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatTile(label: "CARDS", value: "\(ownedCards.count)")
                        StatTile(label: "FOIL %", value: "\(foilPercentage)%")
                        StatTile(label: "LEGENDARY", value: "\(legendaryCount)")
                        StatTile(label: "SETS", value: "\(setCount)")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Value")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
    }
}

struct StatTile: View {
    let label: String
    let value: String
    var body: some View {
        ArcaneBlock {
            VStack(spacing: 4) {
                Text(label).font(.system(size: 9)).tracking(1.5).foregroundStyle(Color(hex: "#8A7A4A"))
                Text(value).font(.custom("Georgia", size: 28)).foregroundStyle(Color(hex: "#C9A961"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

