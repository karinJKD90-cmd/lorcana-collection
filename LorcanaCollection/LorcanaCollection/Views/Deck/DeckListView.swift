import SwiftUI
import SwiftData

struct DeckListView: View {
    @Query(sort: \Deck.lastModified, order: .reverse) var decks: [Deck]
    @Environment(\.modelContext) private var context

    @State private var showNewDeck = false
    @State private var newDeckName = ""

    let inkColors: [String: Color] = [
        "Amber": Color(hex: "#E8A923"), "Amethyst": Color(hex: "#B378BF"),
        "Emerald": Color(hex: "#3A9D5D"), "Ruby": Color(hex: "#E24B4A"),
        "Sapphire": Color(hex: "#5A8FBF"), "Steel": Color(hex: "#A8B5C0")
    ]

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()

            VStack(spacing: 0) {
                SectionLabel(title: "my decks")
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 14)

                if decks.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(hex: "#3A2F5A"))
                        Text("No decks yet")
                            .font(.custom("Georgia", size: 15))
                            .italic()
                            .foregroundStyle(Color(hex: "#6A5A3A"))
                        Text("Create your first deck")
                            .font(.system(size: 11, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(Color(hex: "#4A3A2A"))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(decks) { deck in
                            NavigationLink(destination: DeckBuilderView(deck: deck)) {
                                DeckRow(deck: deck, inkColors: inkColors)
                            }
                            .listRowBackground(Color.black.opacity(0.6))
                            .listRowSeparatorTint(Color(hex: "#3A2F5A"))
                        }
                        .onDelete(perform: deleteDecks)
                    }
                    .scrollContentBackground(.hidden)
                }
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        newDeckName = ""
                        showNewDeck = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#0A0614"))
                                .overlay(Circle().strokeBorder(Color(hex: "#C9A961").opacity(0.7), lineWidth: 1))
                                .frame(width: 52, height: 52)
                                .shadow(color: Color(hex: "#C9A961").opacity(0.25), radius: 8)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(Color(hex: "#C9A961"))
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Decks")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
        .alert("New deck", isPresented: $showNewDeck) {
            TextField("Deck name", text: $newDeckName)
            Button("Create") { createDeck() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give your deck a name")
        }
    }

    private func createDeck() {
        guard !newDeckName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let deck = Deck(name: newDeckName.trimmingCharacters(in: .whitespaces))
        context.insert(deck)
    }

    private func deleteDecks(at offsets: IndexSet) {
        for i in offsets { context.delete(decks[i]) }
    }
}

struct DeckRow: View {
    let deck: Deck
    let inkColors: [String: Color]

    var countColor: Color {
        let n = deck.totalCards
        if n == 60 { return Color(hex: "#3A9D5D") }
        if n > 60  { return Color(hex: "#E24B4A") }
        return Color(hex: "#8A7A4A")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Ink icons
            VStack(spacing: 4) {
                ForEach(deck.inkColors, id: \.self) { ink in
                    Image("ink_\(ink.lowercased())")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }
                if deck.inkColors.isEmpty {
                    Circle()
                        .fill(Color(hex: "#3A2F5A"))
                        .frame(width: 10, height: 10)
                }
            }
            .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(deck.name)
                    .font(.custom("Georgia", size: 15))
                    .foregroundStyle(Color(hex: "#F4E4A1"))
                Text(deck.inkColors.isEmpty ? "no ink" : deck.inkColors.joined(separator: " · "))
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "#8A7A4A"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(deck.totalCards)/60")
                    .font(.custom("Georgia", size: 16))
                    .foregroundStyle(countColor)
                Text(deck.isValid ? "VALID" : "DRAFT")
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(deck.isValid ? Color(hex: "#3A9D5D") : Color(hex: "#6A5A3A"))
            }
        }
        .padding(.vertical, 6)
    }
}
