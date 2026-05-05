import SwiftUI
import SwiftData

struct DeckCardPickerView: View {
    @Bindable var deck: Deck
    @Environment(\.dismiss) private var dismiss
    @Query var allCards: [Card]

    @State private var searchText = ""
    @State private var selectedInk: String? = nil
    @State private var selectedSet: Int? = nil
    @State private var showOnlyOwned = false

    let inkColors: [String: Color] = [
        "Amber": Color(hex: "#E8A923"), "Amethyst": Color(hex: "#B378BF"),
        "Emerald": Color(hex: "#3A9D5D"), "Ruby": Color(hex: "#E24B4A"),
        "Sapphire": Color(hex: "#5A8FBF"), "Steel": Color(hex: "#A8B5C0")
    ]
    let inkOptions = ["Amber", "Amethyst", "Emerald", "Ruby", "Sapphire", "Steel"]

    var uniqueSets: [(number: Int, name: String)] {
        let grouped = Dictionary(grouping: allCards) { $0.setNumber }
        return grouped
            .map { setNum, setCards in (number: setNum, name: setCards.first?.setName ?? "") }
            .filter { $0.number > 0 }
            .sorted { $0.number < $1.number }
    }

    var filteredCards: [Card] {
        var result = allCards

        if showOnlyOwned {
            result = result.filter { $0.owned }
        }
        if let ink = selectedInk {
            result = result.filter { $0.ink == ink }
        }
        if let setNum = selectedSet {
            result = result.filter { $0.setNumber == setNum }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result.sorted {
            $0.setNumber == $1.setNumber ? $0.cardNumber < $1.cardNumber : $0.setNumber < $1.setNumber
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0A0614").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Inkt filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                selectedInk = nil
                            } label: {
                                Text("ALLE")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .tracking(1.5)
                                    .foregroundStyle(selectedInk == nil ? Color(hex: "#F4E4A1") : Color(hex: "#8A7A4A"))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(selectedInk == nil ? Color(hex: "#C9A961") : Color(hex: "#3A2F5A"), lineWidth: 0.6)
                                    )
                            }

                            ForEach(inkOptions, id: \.self) { ink in
                                let color = inkColors[ink] ?? Color(hex: "#C9A961")
                                let active = selectedInk == ink
                                let hasSel = selectedInk != nil
                                Button {
                                    selectedInk = active ? nil : ink
                                } label: {
                                    HStack(spacing: 5) {
                                        Image("ink_\(ink.lowercased())")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                            .opacity(hasSel && !active ? 0.25 : 1.0)
                                            .saturation(hasSel && !active ? 0.15 : 1.0)
                                        Text(ink.uppercased())
                                            .font(.system(size: 9, design: .monospaced))
                                            .tracking(1)
                                    }
                                    .foregroundStyle(active ? color : (hasSel ? Color(hex: "#3A2A4A") : Color(hex: "#8A7A4A")))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(active ? color : Color(hex: "#3A2F5A"), lineWidth: 0.6)
                                    )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeOut(duration: 0.15), value: active)
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                    }
                    .background(Color(hex: "#0A0614"))

                    // Zoekbalk + set filter + owned toggle
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass").foregroundStyle(Color(hex: "#8A7A4A"))
                            TextField("search by name...", text: $searchText)
                                .foregroundStyle(Color(hex: "#F4E4A1"))
                                .font(.custom("Georgia", size: 14))
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color(hex: "#8A7A4A"))
                                }
                            }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(Color.black.opacity(0.6))
                        .overlay(Rectangle().strokeBorder(Color(hex: "#3A2F5A"), lineWidth: 0.6))

                        // Owned toggle
                        Button {
                            showOnlyOwned.toggle()
                        } label: {
                            Image(systemName: showOnlyOwned ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(showOnlyOwned ? Color(hex: "#3A9D5D") : Color(hex: "#8A7A4A"))
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.6))
                                .overlay(Rectangle().strokeBorder(
                                    showOnlyOwned ? Color(hex: "#3A9D5D").opacity(0.5) : Color(hex: "#3A2F5A"),
                                    lineWidth: 0.6
                                ))
                        }

                        Menu {
                            Button("Alle sets") { selectedSet = nil }
                            Divider()
                            ForEach(uniqueSets, id: \.number) { s in
                                Button("Set \(String(format: "%02d", s.number)) · \(s.name)") { selectedSet = s.number }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.stack.3d.down.dashed")
                                    .font(.system(size: 13))
                                    .foregroundStyle(selectedSet != nil ? Color(hex: "#C9A961") : Color(hex: "#8A7A4A"))
                                if let setNum = selectedSet {
                                    Text("S\(String(format: "%02d", setNum))")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: "#C9A961"))
                                }
                            }
                            .padding(9)
                            .background(Color.black.opacity(0.6))
                            .overlay(Rectangle().strokeBorder(
                                selectedSet != nil ? Color(hex: "#C9A961").opacity(0.5) : Color(hex: "#3A2F5A"),
                                lineWidth: 0.6
                            ))
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 8)

                    // Resultaatteller
                    HStack {
                        Text("\(filteredCards.count) cards")
                            .font(.system(size: 10, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(Color(hex: "#6A5A3A"))
                        if showOnlyOwned {
                            Text("· IN COLLECTION")
                                .font(.system(size: 10, design: .monospaced))
                                .tracking(1.5)
                                .foregroundStyle(Color(hex: "#3A9D5D").opacity(0.8))
                        }
                        Spacer()
                        Text("deck: \(deck.totalCards)/60")
                            .font(.system(size: 10, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(deck.totalCards > 60 ? Color(hex: "#E24B4A") : Color(hex: "#6A5A3A"))
                    }
                    .padding(.horizontal, 16).padding(.bottom, 6)

                    // Kaartlijst
                    List(filteredCards) { card in
                        PickerCardRow(
                            card: card,
                            quantity: deck.quantityFor(cardID: card.id),
                            inkColor: inkColors[card.ink] ?? Color(hex: "#C9A961"),
                            onAdd: { deck.addCard(card) },
                            onRemove: { deck.removeCard(cardID: card.id) }
                        )
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
                    Text("Choose card")
                        .font(.custom("Georgia", size: 17))
                        .foregroundStyle(Color(hex: "#C9A961"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#C9A961"))
                }
            }
        }
    }
}

// MARK: - Picker rij

struct PickerCardRow: View {
    let card: Card
    let quantity: Int
    let inkColor: Color
    let onAdd: () -> Void
    let onRemove: () -> Void

    var canAdd: Bool { quantity < 4 }
    var isCharacter: Bool { card.type.lowercased().contains("character") }
    var isLocation: Bool { card.type.lowercased().contains("location") }

    var body: some View {
        HStack(spacing: 12) {

            // Kaartafbeelding
            CachedAsyncImage(urlString: card.imageUrl)
                .scaledToFit()
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(inkColor.opacity(0.4), lineWidth: 0.6))
                .frame(width: 38, height: 53)

            // Info kolom
            VStack(alignment: .leading, spacing: 4) {

                // Naam + owned + subtitle
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(card.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .lineLimit(1)
                        if card.owned {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#3A9D5D").opacity(0.85))
                        }
                    }
                    if let version = card.version, !version.isEmpty {
                        Text(version)
                            .font(.custom("Georgia", size: 10))
                            .italic()
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                            .lineLimit(1)
                    }
                }

                // Inkt · cost · type
                HStack(spacing: 5) {
                    Image("ink_\(card.ink.lowercased())")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                    Text("\(card.ink)  ·")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#6A5A3A"))
                    Image("cost")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(Color(hex: "#C9A961").opacity(0.7))
                    Text("\(card.cost)  ·  \(card.type)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#6A5A3A"))
                        .lineLimit(1)
                }

                // Stats
                if isCharacter || isLocation {
                    HStack(spacing: 10) {
                        if isCharacter {
                            if let str = card.strength {
                                CardStat(iconName: "strength", value: str, color: Color(hex: "#E24B4A"))
                            }
                            if let wp = card.willpower {
                                CardStat(iconName: "defense", value: wp, color: Color(hex: "#5A8FBF"))
                            }
                        }
                        if let lore = card.lore {
                            CardStat(iconName: "pip", value: lore, color: Color(hex: "#C9A961"))
                        }
                    }
                }

                // Body tekst (abilities)
                if let body = card.bodyText, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#A09080"))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 4)

            // Stepper: [−] [count] [+]
            HStack(spacing: 0) {
                // Minus
                Button(action: onRemove) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(quantity > 0 ? Color(hex: "#C9A961") : Color(hex: "#3A2F5A"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#0A0614"))
                        .overlay(
                            Rectangle().strokeBorder(Color(hex: "#3A2F5A"), lineWidth: 0.6)
                        )
                }
                .disabled(quantity == 0)

                // Count
                Text("\(quantity)")
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(quantity > 0 ? Color(hex: "#F4E4A1") : Color(hex: "#3A2F5A"))
                    .frame(width: 28, height: 28)
                    .background(quantity > 0
                        ? Color(hex: "#C9A961").opacity(0.10)
                        : Color(hex: "#0A0614"))
                    .overlay(
                        Rectangle().strokeBorder(Color(hex: "#3A2F5A"), lineWidth: 0.6)
                    )
                    .multilineTextAlignment(.center)

                // Plus
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(canAdd ? Color(hex: "#C9A961") : Color(hex: "#3A2F5A"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#0A0614"))
                        .overlay(
                            Rectangle().strokeBorder(Color(hex: "#3A2F5A"), lineWidth: 0.6)
                        )
                }
                .disabled(!canAdd)
            }
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4)
                .strokeBorder(quantity > 0
                    ? Color(hex: "#C9A961").opacity(0.35)
                    : Color(hex: "#3A2F5A"),
                    lineWidth: 0.6))
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Stat chip

private struct CardStat: View {
    let iconName: String   // asset naam: "strength", "defense", "pip"
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(iconName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 11, height: 11)
                .foregroundStyle(color.opacity(0.85))
            Text("\(value)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(color.opacity(0.25), lineWidth: 0.5))
    }
}
