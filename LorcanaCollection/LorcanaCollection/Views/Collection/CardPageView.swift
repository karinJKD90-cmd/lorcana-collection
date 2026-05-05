import SwiftUI

/// Wrapper die CardDetailView inbed in een horizontaal swipebare TabView.
/// Geeft subtiele pijl-knoppen aan de zijkant om naar vorige/volgende kaart te navigeren.
struct CardPageView: View {
    let cards: [Card]
    @State var currentIndex: Int

    var body: some View {
        ZStack {
            Color(hex: "#060311").ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardDetailView(card: card)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(hex: "#060311").ignoresSafeArea())

            // Pijl links
            if currentIndex > 0 {
                HStack {
                    Button {
                        withAnimation { currentIndex -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "#C9A961").opacity(0.6))
                            .frame(width: 32, height: 64)
                            .background(Color.black.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .ignoresSafeArea(edges: .vertical)
            }

            // Pijl rechts
            if currentIndex < cards.count - 1 {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { currentIndex += 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "#C9A961").opacity(0.6))
                            .frame(width: 32, height: 64)
                            .background(Color.black.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
                .ignoresSafeArea(edges: .vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: "#8A7A4A"))
            }
        }
    }
}
