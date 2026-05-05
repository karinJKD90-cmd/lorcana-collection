import SwiftUI
import SwiftData

struct DeckBuilderView: View {
    @Bindable var deck: Deck
    @Environment(\.modelContext) private var context
    @Query private var allCards: [Card]

    @State private var showPicker = false
    @State private var editingName = false
    @State private var draftName = ""
    @State private var selectedCard: Card? = nil

    private func card(for entry: DeckEntry) -> Card? {
        allCards.first { $0.id == entry.cardID }
    }

    let inkColors: [String: Color] = [
        "Amber": Color(hex: "#E8A923"), "Amethyst": Color(hex: "#B378BF"),
        "Emerald": Color(hex: "#3A9D5D"), "Ruby": Color(hex: "#E24B4A"),
        "Sapphire": Color(hex: "#5A8FBF"), "Steel": Color(hex: "#A8B5C0")
    ]

    // Entries gesorteerd: op inkt, daarna op cost
    var sortedEntries: [DeckEntry] {
        deck.entries.sorted {
            $0.ink == $1.ink ? $0.cost < $1.cost : $0.ink < $1.ink
        }
    }

    // Groepeer op inkt voor de lijst
    var entriesByInk: [(ink: String, entries: [DeckEntry])] {
        let grouped = Dictionary(grouping: sortedEntries) { $0.ink }
        return grouped.map { (ink: $0.key, entries: $0.value.sorted { $0.cost < $1.cost }) }
            .sorted { $0.ink < $1.ink }
    }

    var countColor: Color {
        let n = deck.totalCards
        if n == 60 { return Color(hex: "#3A9D5D") }
        if n > 60  { return Color(hex: "#E24B4A") }
        return Color(hex: "#8A7A4A")
    }

    // Type breakdown
    var characterCount: Int { deck.entries.filter { ($0.cardType ?? "").lowercased().contains("character") }.reduce(0) { $0 + $1.quantity } }
    var actionCount: Int    { deck.entries.filter { ($0.cardType ?? "").lowercased().contains("action") && !($0.cardType ?? "").lowercased().contains("item") }.reduce(0) { $0 + $1.quantity } }
    var itemCount: Int      { deck.entries.filter { ($0.cardType ?? "").lowercased().contains("item") }.reduce(0) { $0 + $1.quantity } }
    var locationCount: Int  { deck.entries.filter { ($0.cardType ?? "").lowercased().contains("location") }.reduce(0) { $0 + $1.quantity } }

    // Cost curve: cost 0–9, alles erboven in 9+
    var costCurve: [Int] {
        var buckets = Array(repeating: 0, count: 10)
        for entry in deck.entries {
            let bucket = min(entry.cost, 9)
            buckets[bucket] += entry.quantity
        }
        return buckets
    }

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()

            VStack(spacing: 0) {

                // Deck header
                ZStack {
                    Color.black.opacity(0.7)
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.3), .clear],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(height: 0.6)
                        Spacer()
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.3), .clear],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(height: 0.6)
                    }

                    HStack(spacing: 16) {
                        // Ink icons
                        HStack(spacing: 5) {
                            ForEach(deck.inkColors, id: \.self) { ink in
                                VStack(spacing: 2) {
                                    Image("ink_\(ink.lowercased())")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                    Text(String(ink.prefix(3)).uppercased())
                                        .font(.system(size: 7, design: .monospaced))
                                        .tracking(0.5)
                                        .foregroundStyle(inkColors[ink] ?? Color(hex: "#C9A961"))
                                }
                            }
                        }
                        .frame(minWidth: 40, alignment: .leading)

                        Spacer()

                        // Kaartenteller
                        VStack(spacing: 2) {
                            Text("\(deck.totalCards)")
                                .font(.custom("Georgia", size: 26))
                                .foregroundStyle(countColor)
                            Text("of 60")
                                .font(.system(size: 8, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                        }

                        Spacer()

                        // Validatie-badges
                        VStack(alignment: .trailing, spacing: 4) {
                            if deck.totalCards > 60 {
                                DeckBadge(text: "TOO MANY", color: Color(hex: "#E24B4A"))
                            }
                            if deck.inkColors.count > 2 {
                                DeckBadge(text: "> 2 INK", color: Color(hex: "#E24B4A"))
                            }
                            if deck.inkColors.count < 1 && deck.totalCards > 0 {
                                DeckBadge(text: "NO INK", color: Color(hex: "#E24B4A"))
                            }
                            if deck.totalCards == 60 && deck.inkColors.count >= 1 && deck.inkColors.count <= 2 {
                                DeckBadge(text: "VALID", color: Color(hex: "#3A9D5D"))
                            }
                        }
                        .frame(minWidth: 70, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .frame(height: 62)

                // Type breakdown + inkable row
                if !deck.entries.isEmpty {
                    HStack(spacing: 6) {
                        if characterCount > 0 { TypePill(label: "CHAR", count: characterCount, color: Color(hex: "#B378BF")) }
                        if actionCount > 0    { TypePill(label: "ACT",  count: actionCount,    color: Color(hex: "#E24B4A")) }
                        if itemCount > 0      { TypePill(label: "ITEM", count: itemCount,       color: Color(hex: "#3A9D5D")) }
                        if locationCount > 0  { TypePill(label: "LOC",  count: locationCount,   color: Color(hex: "#5A8FBF")) }
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hex: "#C9A961").opacity(0.7))
                            Text("\(deck.inkableCount) inkable")
                                .font(.system(size: 9, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))

                    // Cost curve
                    InkCostCurveView(costCurve: costCurve)
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                }

                if deck.entries.isEmpty {
                    // Lege staat
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: "#3A2F5A"))
                        Text("Deck is empty")
                            .font(.custom("Georgia", size: 15))
                            .italic()
                            .foregroundStyle(Color(hex: "#6A5A3A"))
                        Text("Tap + to add cards")
                            .font(.system(size: 10, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(Color(hex: "#4A3A2A"))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(entriesByInk, id: \.ink) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    DeckEntryRow(
                                        entry: entry,
                                        inkColor: inkColors[entry.ink] ?? Color(hex: "#C9A961"),
                                        onAdd: {
                                            deck.incrementEntry(cardID: entry.cardID)
                                            try? context.save()
                                        },
                                        onRemove: {
                                            deck.removeCard(cardID: entry.cardID)
                                            try? context.save()
                                        },
                                        onTap: {
                                            if let c = card(for: entry) { selectedCard = c }
                                        }
                                    )
                                    .listRowBackground(Color.black.opacity(0.6))
                                    .listRowSeparatorTint(Color(hex: "#3A2F5A"))
                                }
                                .onDelete { offsets in
                                    let ids = offsets.map { group.entries[$0].cardID }
                                    ids.forEach { deck.removeAllCopies(cardID: $0) }
                                    try? context.save()
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image("ink_\(group.ink.lowercased())")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                    Text(group.ink.uppercased())
                                        .font(.system(size: 9, design: .monospaced))
                                        .tracking(3)
                                        .foregroundStyle(inkColors[group.ink] ?? Color(hex: "#C9A961"))
                                    Text("·  \(group.entries.reduce(0) { $0 + $1.quantity }) cards")
                                        .font(.system(size: 9, design: .monospaced))
                                        .tracking(1)
                                        .foregroundStyle(Color(hex: "#6A5A3A"))
                                }
                                .padding(.bottom, 2)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .contentMargins(.bottom, 90, for: .scrollContent)
                }
            }

            // FAB: kaart toevoegen
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { showPicker = true } label: {
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
                if editingName {
                    TextField("Deck name", text: $draftName, onCommit: saveName)
                        .font(.custom("Georgia", size: 17))
                        .foregroundStyle(Color(hex: "#F4E4A1"))
                        .multilineTextAlignment(.center)
                        .submitLabel(.done)
                } else {
                    Button {
                        draftName = deck.name
                        editingName = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(deck.name)
                                .font(.custom("Georgia", size: 17))
                                .foregroundStyle(Color(hex: "#C9A961"))
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            DeckCardPickerView(deck: deck)
        }
        .navigationDestination(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
    }

    private func saveName() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { deck.name = trimmed }
        editingName = false
        try? context.save()
    }
}

// MARK: - Badge

struct DeckBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(color.opacity(0.5), lineWidth: 0.5))
    }
}

// MARK: - Type pill

struct TypePill: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(color.opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Cost curve

struct InkCostCurveView: View {
    let costCurve: [Int] // index 0–9, index 9 = "9+"

    private let labels = ["0","1","2","3","4","5","6","7","8","9+"]
    private let barColor = Color(hex: "#C9A961")

    var maxVal: Int { costCurve.max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<costCurve.count, id: \.self) { i in
                let val = costCurve[i]
                VStack(spacing: 2) {
                    if val > 0 {
                        Text("\(val)")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(barColor.opacity(0.8))
                    } else {
                        Text(" ")
                            .font(.system(size: 7))
                    }
                    GeometryReader { geo in
                        let barH = maxVal > 0 ? CGFloat(val) / CGFloat(maxVal) * geo.size.height : 0
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .fill(barColor.opacity(val > 0 ? 0.6 : 0.15))
                                .frame(height: max(barH, val > 0 ? 2 : 1))
                        }
                    }
                    Text(labels[i])
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(Color(hex: "#6A5A3A"))
                }
            }
        }
    }
}

// MARK: - Entry rij

struct DeckEntryRow: View {
    let entry: DeckEntry
    let inkColor: Color
    let onAdd: () -> Void
    let onRemove: () -> Void
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Kaartgedeelte — tapbaar voor detail
            Button(action: { onTap?() }) {
                HStack(spacing: 12) {
                    CachedAsyncImage(urlString: entry.imageUrl)
                        .scaledToFit()
                        .cornerRadius(3)
                        .frame(width: 30, height: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.cardName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .lineLimit(1)
                        if let version = entry.cardVersion, !version.isEmpty {
                            Text(version)
                                .font(.custom("Georgia", size: 10))
                                .italic()
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                                .lineLimit(1)
                        }
                        HStack(spacing: 5) {
                            Image("ink_\(entry.ink.lowercased())")
                                .resizable().scaledToFit().frame(width: 11, height: 11)
                            Text("\(entry.ink)  ·  \(entry.cost) ink")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                            if entry.inkable == true {
                                Text("✦")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(hex: "#C9A961").opacity(0.6))
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onTap == nil)

            Spacer()

            // Stepper
            HStack(spacing: 0) {
                Button(action: onRemove) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "#8A7A4A"))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Text("\(entry.quantity)")
                    .font(.custom("Georgia", size: 16))
                    .foregroundStyle(entry.quantity == 4 ? Color(hex: "#C9A961") : Color(hex: "#F4E4A1"))
                    .frame(width: 24, alignment: .center)

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(entry.quantity >= 4 ? Color(hex: "#3A2F5A") : Color(hex: "#C9A961"))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(entry.quantity >= 4)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(hex: "#3A2F5A"), lineWidth: 0.5))
            )
        }
        .padding(.vertical, 3)
    }
}
