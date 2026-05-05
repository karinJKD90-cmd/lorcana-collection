import SwiftUI
import SwiftData

struct CardGridView: View {
    /// nil = alle sets
    let setNumber: Int?
    let setName: String
    var initialRarity: String? = nil
    var initialSortMode: SortMode? = nil
    var filterOwned: Bool = false

    @Query var allCards: [Card]
    @State private var selectedInks: Set<String> = []
    @State private var selectedRarities: Set<String> = []
    @State private var showOnlySigned = false
    @State private var sortMode: SortMode = .cardNumber
    @State private var searchText = ""
    @State private var cardNumberSearch = ""
    @State private var showInkPicker = false
    @FocusState private var searchFocused: Bool
    @FocusState private var numberFocused: Bool
    @State private var bulkMode = false
    @State private var bulkAddedCount = 0
    @State private var bulkSnapshot: [String: (owned: Bool, isFoil: Bool)] = [:]

    // Async filter + paginering
    @State private var displayedCards: [Card] = []
    @State private var displayLimit = 150
    @State private var filterTask: Task<Void, Never>? = nil

    enum SortMode: String, CaseIterable {
        case cardNumber = "#"
        case priceDesc  = "€↓"
        case priceAsc   = "€↑"
    }

    let inkOptions = ["Amber","Amethyst","Emerald","Ruby","Sapphire","Steel"]
    let inkColors: [String: Color] = [
        "Amber": Color(hex: "#E8A923"), "Amethyst": Color(hex: "#B378BF"),
        "Emerald": Color(hex: "#3A9D5D"), "Ruby": Color(hex: "#E24B4A"),
        "Sapphire": Color(hex: "#5A8FBF"), "Steel": Color(hex: "#A8B5C0")
    ]
    let rarityOptions = ["Common","Uncommon","Rare","Super_rare","Legendary","Enchanted","Epic","Iconic","Special_rarity","Promo"]

    func rarityLabel(_ rarity: String) -> String {
        switch rarity {
        case "Super_rare":     return "SUPER RARE"
        case "Special_rarity": return "SPECIAL"
        case "Promo":          return "PROMO"
        case "Enchanted":      return "ENCHANTED"
        case "Epic":           return "EPIC"
        case "Iconic":         return "ICONIC"
        default:               return rarity.uppercased()
        }
    }

    private func computeFilter() -> [Card] {
        let base = allCards
            .filter { setNumber == nil || $0.setNumber == setNumber }
            .filter { !filterOwned || $0.owned }
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .filter { card in cardNumberSearch.isEmpty || Int(cardNumberSearch).map { $0 == card.cardNumber } ?? false }
            .filter { selectedInks.isEmpty || selectedInks.contains($0.ink) }
            .filter { selectedRarities.isEmpty || selectedRarities.contains($0.rarity) }
            .filter { !showOnlySigned || $0.isSigned }

        switch sortMode {
        case .cardNumber:
            return base.sorted { a, b in
                a.setNumber == b.setNumber ? a.cardNumber < b.cardNumber : a.setNumber < b.setNumber
            }
        case .priceDesc:
            return base.sorted { a, b in
                let pa = (a.isFoil ? a.currentPriceFoil : a.currentPriceNormal) ?? (a.currentPriceNormal ?? 0)
                let pb = (b.isFoil ? b.currentPriceFoil : b.currentPriceNormal) ?? (b.currentPriceNormal ?? 0)
                return pa > pb
            }
        case .priceAsc:
            return base.sorted { a, b in
                let pa = (a.isFoil ? a.currentPriceFoil : a.currentPriceNormal) ?? (a.currentPriceNormal ?? 0)
                let pb = (b.isFoil ? b.currentPriceFoil : b.currentPriceNormal) ?? (b.currentPriceNormal ?? 0)
                return pa < pb
            }
        }
    }

    private func scheduleFilter(delay: Bool = false) {
        filterTask?.cancel()
        filterTask = Task { @MainActor in
            if delay { try? await Task.sleep(for: .milliseconds(120)) }
            guard !Task.isCancelled else { return }
            let result = computeFilter()
            displayedCards = result
            displayLimit = 150
            // Prefetch eerste batch afbeeldingen
            prefetchImages(Array(result.prefix(180)))
        }
    }

    private func loadMore() {
        let newLimit = displayLimit + 100
        displayLimit = newLimit
        // Prefetch volgende batch
        let start = newLimit - 20
        let end = min(newLimit + 80, displayedCards.count)
        if start < end {
            prefetchImages(Array(displayedCards[start..<end]))
        }
    }

    private func prefetchImages(_ cards: [Card]) {
        let urls = cards.map { $0.imageUrl }
        Task {
            for url in urls {
                _ = await ImageCache.shared.load(url)
            }
        }
    }

    // Zichtbare slice voor het grid
    var visibleCards: [Card] { Array(displayedCards.prefix(displayLimit)) }
    var hasMore: Bool { displayLimit < displayedCards.count }

    var ownedInSet: Int { allCards.filter { (setNumber == nil || $0.setNumber == setNumber) && $0.owned }.count }
    var totalInSet: Int { allCards.filter { setNumber == nil || $0.setNumber == setNumber }.count }
    var percentage: Int { totalInSet > 0 ? Int(Double(ownedInSet) / Double(totalInSet) * 100) : 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            SwirlBackground()
            VStack(spacing: 0) {

                // ── 1. Rarity + SIG — multiselect met image assets ───
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {

                        // Rarity chips
                        ForEach(rarityOptions, id: \.self) { rarity in
                            let isActive = selectedRarities.contains(rarity)
                            let hasSel   = !selectedRarities.isEmpty
                            let assetName = rarity == "Special_rarity" ? "rarity_promo" : "rarity_\(rarity.lowercased())"
                            Button {
                                if isActive { selectedRarities.remove(rarity) }
                                else        { selectedRarities.insert(rarity) }
                            } label: {
                                VStack(spacing: 5) {
                                    Image(assetName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .opacity(hasSel && !isActive ? 0.12 : 1.0)
                                        .saturation(hasSel && !isActive ? 0 : 1)
                                    Text(rarityLabel(rarity).lowercased())
                                        .font(.system(size: 7.5))
                                        .foregroundStyle(
                                            isActive
                                                ? Color(hex: "#F4E4A1")
                                                : (hasSel ? Color(hex: "#2A2040") : Color(hex: "#6A5A7A"))
                                        )
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .padding(.vertical, 8)
                                .background(
                                    ZStack {
                                        if isActive {
                                            Rectangle().fill(Color(hex: "#C9A961").opacity(0.10))
                                            VStack {
                                                Rectangle().fill(Color(hex: "#C9A961")).frame(height: 1.5)
                                                Spacer()
                                            }
                                        }
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeOut(duration: 0.13), value: isActive)
                        }

                        // Scheidertje
                        Rectangle().fill(Color(hex: "#221840")).frame(width: 0.5, height: 36).padding(.horizontal, 4)

                        // SIG chip
                        Button { showOnlySigned.toggle() } label: {
                            VStack(spacing: 5) {
                                // Pen-nib icoon via Canvas
                                Canvas { ctx, size in
                                    let w = size.width; let h = size.height
                                    let base = Color(hex: "#C9A961")
                                    let col  = base.opacity(showOnlySigned ? 1.0 : (selectedRarities.isEmpty ? 0.45 : 0.18))

                                    // Veer-body: gebogen blad-vorm diagonaal van rechtsboven naar linksonder
                                    var feather = Path()
                                    feather.move(to: CGPoint(x: w * 0.76, y: h * 0.07))
                                    feather.addCurve(
                                        to: CGPoint(x: w * 0.26, y: h * 0.72),
                                        control1: CGPoint(x: w * 0.96, y: h * 0.32),
                                        control2: CGPoint(x: w * 0.58, y: h * 0.64)
                                    )
                                    feather.addCurve(
                                        to: CGPoint(x: w * 0.76, y: h * 0.07),
                                        control1: CGPoint(x: w * 0.04, y: h * 0.46),
                                        control2: CGPoint(x: w * 0.52, y: h * 0.10)
                                    )
                                    ctx.fill(feather, with: .color(col.opacity(0.15)))
                                    ctx.stroke(feather, with: .color(col), style: StrokeStyle(lineWidth: 1.1))

                                    // Ruggengraat
                                    var spine = Path()
                                    spine.move(to: CGPoint(x: w * 0.76, y: h * 0.07))
                                    spine.addCurve(
                                        to: CGPoint(x: w * 0.28, y: h * 0.88),
                                        control1: CGPoint(x: w * 0.62, y: h * 0.34),
                                        control2: CGPoint(x: w * 0.40, y: h * 0.66)
                                    )
                                    ctx.stroke(spine, with: .color(col), style: StrokeStyle(lineWidth: 0.9))

                                    // Kiel-punt (schrijftip)
                                    var tip = Path()
                                    tip.move(to: CGPoint(x: w * 0.28, y: h * 0.88))
                                    tip.addLine(to: CGPoint(x: w * 0.14, y: h * 0.82))
                                    tip.move(to: CGPoint(x: w * 0.28, y: h * 0.88))
                                    tip.addLine(to: CGPoint(x: w * 0.22, y: h * 0.98))
                                    ctx.stroke(tip, with: .color(col), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
                                }
                                .frame(width: 36, height: 36)

                                Text("sig")
                                    .font(.system(size: 7.5))
                                    .foregroundStyle(
                                        showOnlySigned
                                            ? Color(hex: "#F4E4A1")
                                            : (selectedRarities.isEmpty ? Color(hex: "#6A5A7A") : Color(hex: "#2A2040"))
                                    )
                            }
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    if showOnlySigned {
                                        Rectangle().fill(Color(hex: "#C9A961").opacity(0.10))
                                        VStack {
                                            Rectangle().fill(Color(hex: "#C9A961")).frame(height: 1.5)
                                            Spacer()
                                        }
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.13), value: showOnlySigned)

                        // Wis-knop (verschijnt bij actieve selectie)
                        if !selectedRarities.isEmpty || showOnlySigned {
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedRarities = []
                                    showOnlySigned = false
                                }
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundStyle(Color(hex: "#C9A961").opacity(0.5))
                                        .frame(width: 30, height: 30)
                                    Text("clear")
                                        .font(.system(size: 7.5))
                                        .foregroundStyle(Color(hex: "#C9A961").opacity(0.4))
                                }
                                .frame(width: 56)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                }
                .background(Color(hex: "#06030F"))

                // ── 2. Zoeken — # links, naam rechts ─────────────────
                HStack(spacing: 8) {
                    // Kaartnummer (#) — vaste breedte links
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                        TextField("#", text: $cardNumberSearch)
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .font(.system(size: 12, design: .monospaced))
                            .keyboardType(.numberPad)
                            .frame(width: 40)
                            .focused($numberFocused)
                        if !cardNumberSearch.isEmpty {
                            Button { cardNumberSearch = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.55).overlay(Rectangle().strokeBorder(Color(hex: "#221840"), lineWidth: 0.5)))
                    .contentShape(Rectangle())
                    .onTapGesture { numberFocused = true }

                    // Naam — flex rechts
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                        TextField("name...", text: $searchText)
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .font(.system(size: 12))
                            .focused($searchFocused)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.55).overlay(Rectangle().strokeBorder(Color(hex: "#221840"), lineWidth: 0.5)))
                    .contentShape(Rectangle())
                    .onTapGesture { searchFocused = true }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(hex: "#06030F"))

                // ── 3+4. Inkt + Sortering ────────────────────────────
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {

                        // Ink trigger (links)
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) { showInkPicker.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                                if selectedInks.isEmpty {
                                    Text("all inks")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: "#6A5A7A"))
                                } else {
                                    HStack(spacing: 4) {
                                        ForEach(inkOptions.filter { selectedInks.contains($0) }, id: \.self) { ink in
                                            Image("ink_\(ink.lowercased())")
                                                .resizable().scaledToFit().frame(width: 16, height: 16)
                                        }
                                    }
                                }
                                Image(systemName: showInkPicker ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                                    .animation(.easeOut(duration: 0.18), value: showInkPicker)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(
                                Color.black.opacity(0.45)
                                    .overlay(Rectangle().strokeBorder(
                                        selectedInks.isEmpty ? Color(hex: "#221840") : Color(hex: "#C9A961").opacity(0.40),
                                        lineWidth: 0.5
                                    ))
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if showInkPicker {
                                    withAnimation(.easeOut(duration: 0.18)) { showInkPicker = false }
                                }
                            }

                        // Reset + sort (rechts)
                        let hasFilter = !selectedInks.isEmpty || !selectedRarities.isEmpty || showOnlySigned || sortMode != .cardNumber || !searchText.isEmpty || !cardNumberSearch.isEmpty
                        if hasFilter {
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    selectedInks = []; selectedRarities = []
                                    showOnlySigned = false; sortMode = .cardNumber
                                    searchText = ""; cardNumberSearch = ""
                                    showInkPicker = false
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "xmark").font(.system(size: 7, weight: .bold))
                                    Text("reset").font(.system(size: 9, design: .monospaced)).tracking(0.8)
                                }
                                .foregroundStyle(Color(hex: "#C9A961").opacity(0.45))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 12)
                            .transition(.opacity.animation(.easeOut(duration: 0.15)))
                        }

                        Rectangle().fill(Color(hex: "#221840")).frame(width: 0.5, height: 16).padding(.trailing, 8)

                        HStack(spacing: 0) {
                            ForEach(Array(SortMode.allCases.enumerated()), id: \.element) { idx, mode in
                                let active = sortMode == mode
                                Button { sortMode = mode } label: {
                                    Text(mode == .priceAsc ? "€↑" : mode == .priceDesc ? "€↓" : "#")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(active ? Color(hex: "#C9A961") : Color(hex: "#4A3A2A"))
                                        .frame(width: 36, height: 30)
                                        .background(active ? Color(hex: "#C9A961").opacity(0.10) : Color.clear)
                                }
                                .buttonStyle(.plain)
                                if idx < SortMode.allCases.count - 1 {
                                    Rectangle().fill(Color(hex: "#221840")).frame(width: 0.5, height: 16)
                                }
                            }
                        }
                        .background(
                            ZStack {
                                Rectangle().fill(Color(hex: "#08050F"))
                                Rectangle().strokeBorder(Color(hex: "#221840"), lineWidth: 0.5)
                            }
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                }
                .background(Color(hex: "#06030F"))

                // Scheidingslijn
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.20), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 0.6)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(visibleCards) { card in
                            if bulkMode {
                                BulkCardTile(card: card, onAdded: { bulkAddedCount += 1 })
                            } else {
                                NavigationLink(destination: CardPageView(cards: displayedCards, currentIndex: displayedCards.firstIndex(where: { $0.id == card.id }) ?? 0)) {
                                    CardTile(card: card)
                                }.buttonStyle(.plain)
                            }
                        }

                        // Pagineringsentinel — laadt volgende 100 zodra zichtbaar
                        if hasMore {
                            Color.clear
                                .frame(height: 1)
                                .onAppear { loadMore() }
                        }
                    }
                    .padding(10)
                    .padding(.top, 10)
                    .padding(.bottom, bulkMode ? 80 : 32)
                }
                .overlay(alignment: .top) {
                    if showInkPicker {
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(.easeOut(duration: 0.12)) { selectedInks = [] }
                            } label: {
                                HStack(spacing: 12) {
                                    Color.clear.frame(width: 20, height: 20)
                                    Text("all inks")
                                        .font(.system(size: 11, design: .monospaced))
                                        .tracking(0.5)
                                        .foregroundStyle(selectedInks.isEmpty ? Color(hex: "#C9A961") : Color(hex: "#6A5A7A"))
                                    Spacer()
                                    if selectedInks.isEmpty {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(Color(hex: "#C9A961"))
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(selectedInks.isEmpty ? Color(hex: "#C9A961").opacity(0.07) : Color.clear)
                            }
                            .buttonStyle(.plain)

                            Rectangle().fill(Color(hex: "#2A1F40")).frame(height: 0.5)

                            ForEach(inkOptions, id: \.self) { ink in
                                let isActive = selectedInks.contains(ink)
                                let color    = inkColors[ink] ?? Color(hex: "#C9A961")
                                Button {
                                    withAnimation(.easeOut(duration: 0.12)) {
                                        if isActive { selectedInks.remove(ink) }
                                        else        { selectedInks.insert(ink) }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image("ink_\(ink.lowercased())")
                                            .resizable().scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .opacity(isActive ? 1.0 : 0.40)
                                            .saturation(isActive ? 1.0 : 0.3)
                                        Text(ink.lowercased())
                                            .font(.system(size: 12))
                                            .foregroundStyle(isActive ? Color(hex: "#F4E4A1") : Color(hex: "#6A5A7A"))
                                        Spacer()
                                        if isActive {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundStyle(color)
                                        }
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(isActive ? color.opacity(0.09) : Color.clear)
                                }
                                .buttonStyle(.plain)
                                if ink != inkOptions.last {
                                    Rectangle().fill(Color(hex: "#1A1230")).frame(height: 0.5)
                                }
                            }
                        }
                        .background(
                            Color(hex: "#08050F").opacity(0.97)
                                .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.22), lineWidth: 0.5))
                        )
                        .padding(.horizontal, 14)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Arcane bulk action bar
            if bulkMode {
                ArcaneBulkBar(
                    addedCount: bulkAddedCount,
                    onSelectAll: {
                        for card in displayedCards { card.markOwned() }
                        bulkAddedCount = displayedCards.filter { $0.owned }.count
                    },
                    onClearAll: {
                        for card in displayedCards { card.markNotOwned() }
                        bulkAddedCount = 0
                    }
                )
            }
        }
        .navigationTitle(setName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(setName).font(.system(size: 13, weight: .medium)).foregroundStyle(Color(hex: "#C9A961"))
                    if let setNumber {
                        Text("SET \(String(format: "%02d", setNumber)) · \(ownedInSet)/\(totalInSet) · \(percentage)%")
                            .font(.system(size: 9)).foregroundStyle(Color(hex: "#8A7A4A"))
                    } else {
                        Text("\(ownedInSet)/\(totalInSet) · \(percentage)%")
                            .font(.system(size: 9)).foregroundStyle(Color(hex: "#8A7A4A"))
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if bulkMode {
                    Button("Done") {
                        bulkMode = false; bulkAddedCount = 0; bulkSnapshot = [:]
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#C9A961"))
                } else {
                    Button {
                        bulkSnapshot = Dictionary(uniqueKeysWithValues: displayedCards.map { ($0.id, (owned: $0.owned, isFoil: $0.isFoil)) })
                        bulkMode = true
                    } label: {
                        Text("bulk")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color(hex: "#C9A961"))
                    }
                }
            }
            if bulkMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        for card in displayedCards {
                            if let snap = bulkSnapshot[card.id] {
                                card.owned = snap.owned
                                card.isFoil = snap.isFoil
                            }
                        }
                        bulkMode = false; bulkAddedCount = 0; bulkSnapshot = [:]
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                    }
                }
            }
        }
        .onAppear {
            if let r = initialRarity  { selectedRarities = [r] }
            if let s = initialSortMode { sortMode = s }
        }
        .task(id: allCards.count) { scheduleFilter() }
        .onChange(of: selectedInks)     { scheduleFilter() }
        .onChange(of: selectedRarities) { scheduleFilter() }
        .onChange(of: showOnlySigned)   { scheduleFilter() }
        .onChange(of: sortMode)         { scheduleFilter() }
        .onChange(of: searchText)       { scheduleFilter(delay: true) }
        .onChange(of: cardNumberSearch) { scheduleFilter(delay: true) }
    }
}

// MARK: - Arcane Bulk Bar

struct ArcaneBulkBar: View {
    let addedCount: Int
    let onSelectAll: () -> Void
    let onClearAll: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Wissen
            Button(action: onClearAll) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                    Text("Clear")
                        .font(.system(size: 12, design: .monospaced))
                        .tracking(0.5)
                }
                .foregroundStyle(Color(hex: "#E24B4A"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#E24B4A").opacity(0.08))
                .overlay(Rectangle().strokeBorder(Color(hex: "#E24B4A").opacity(0.3), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            // Teller
            VStack(spacing: 1) {
                Text(addedCount == 0 ? "—" : "\(addedCount)")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
                Text("added")
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "#6A5A3A"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#0A0614").opacity(0.95))
            .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.2), lineWidth: 0.5))

            // Alles toevoegen
            Button(action: onSelectAll) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                    Text("All")
                        .font(.system(size: 12, design: .monospaced))
                        .tracking(0.5)
                }
                .foregroundStyle(Color(hex: "#C9A961"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#C9A961").opacity(0.08))
                .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.3), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .background(
            Color(hex: "#0A0614")
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.15), .clear],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(height: 0.6),
                    alignment: .top
                )
        )
        .shadow(color: Color.black.opacity(0.6), radius: 12, y: -4)
    }
}

// MARK: - Card tile

struct CardTile: View {
    let card: Card
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Color.black

                CachedAsyncImage(urlString: card.imageUrl)
                    .scaledToFit()
                    .opacity(card.owned ? 1 : 0.30)

                if !card.owned {
                    Color.black.opacity(0.55)
                }

                if card.owned && card.isFoil { FoilCorner() }
                if card.owned && card.isSigned {
                    VStack {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 7))
                                .foregroundStyle(Color(hex: "#C9A961"))
                                .padding(2)
                                .background(Circle().fill(Color.black.opacity(0.7)))
                                .padding(2)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                Rectangle()
                    .strokeBorder(Color(hex: "#C9A961").opacity(card.owned ? 0.5 : 0.2), lineWidth: 0.6)

                Canvas { ctx, size in
                    let w = size.width; let h = size.height
                    let gold = Color(hex: "#C9A961")
                    let s = StrokeStyle(lineWidth: 0.8)
                    var tl = Path()
                    tl.move(to: CGPoint(x: 0, y: 5)); tl.addLine(to: CGPoint(x: 0, y: 0)); tl.addLine(to: CGPoint(x: 5, y: 0))
                    ctx.stroke(tl, with: .color(gold.opacity(card.owned ? 0.8 : 0.35)), style: s)
                    var br = Path()
                    br.move(to: CGPoint(x: w, y: h - 5)); br.addLine(to: CGPoint(x: w, y: h)); br.addLine(to: CGPoint(x: w - 5, y: h))
                    ctx.stroke(br, with: .color(gold.opacity(card.owned ? 0.8 : 0.35)), style: s)
                }
                .allowsHitTesting(false)
            }
            .aspectRatio(5/7, contentMode: .fit)

            HStack(spacing: 0) {
                Text("#\(card.cardNumber)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(card.owned ? Color(hex: "#8A7A4A") : Color(hex: "#3A2F5A"))
                Spacer()
                if card.owned, let price = card.isFoil ? card.currentPriceFoil : card.currentPriceNormal {
                    Text("€\(String(format: "%.2f", price))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: "#8A7A4A"))
                } else {
                    Text("—")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: "#3A2F5A"))
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

struct BulkCardTile: View {
    @Bindable var card: Card
    let onAdded: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Color.black

                CachedAsyncImage(urlString: card.imageUrl)
                    .scaledToFit()
                    .opacity(card.owned ? 1 : 0.35)

                if !card.owned {
                    Color.black.opacity(0.55)
                }

                if card.owned && card.isFoil { FoilCorner() }

                Rectangle()
                    .strokeBorder(Color(hex: "#C9A961").opacity(card.owned ? 0.5 : 0.2), lineWidth: 0.6)

                Canvas { ctx, size in
                    let w = size.width; let h = size.height
                    let gold = Color(hex: "#C9A961")
                    let s = StrokeStyle(lineWidth: 0.8)
                    var tl = Path()
                    tl.move(to: CGPoint(x: 0, y: 5)); tl.addLine(to: CGPoint(x: 0, y: 0)); tl.addLine(to: CGPoint(x: 5, y: 0))
                    ctx.stroke(tl, with: .color(gold.opacity(card.owned ? 0.8 : 0.35)), style: s)
                    var br = Path()
                    br.move(to: CGPoint(x: w, y: h - 5)); br.addLine(to: CGPoint(x: w, y: h)); br.addLine(to: CGPoint(x: w - 5, y: h))
                    ctx.stroke(br, with: .color(gold.opacity(card.owned ? 0.8 : 0.35)), style: s)
                }
                .allowsHitTesting(false)

                if card.owned {
                    Button {
                        card.markNotOwned()
                    } label: {
                        ZStack {
                            Color.clear
                            Image(systemName: "xmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color(hex: "#C9A961"))
                                .shadow(color: Color(hex: "#C9A961").opacity(0.5), radius: 6)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: 14) {
                        Button {
                            card.markOwned(); onAdded()
                        } label: {
                            Text("+")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(Color(hex: "#F4E4A1"))
                                .frame(width: 39, height: 39)
                                .background(Circle().fill(Color(hex: "#0A0614").opacity(0.8)))
                        }
                        .buttonStyle(.plain)

                        if !card.alwaysFoil {
                            Button {
                                card.markOwned(); card.isFoil = true; onAdded()
                            } label: {
                                Text("F")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color(hex: "#C9A961"))
                                    .frame(width: 39, height: 39)
                                    .background(Circle().fill(Color(hex: "#0A0614").opacity(0.8)))
                                    .overlay(Circle().strokeBorder(Color(hex: "#C9A961").opacity(0.7), lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .aspectRatio(5/7, contentMode: .fit)
            Text("#\(card.cardNumber)").font(.system(size: 8)).foregroundStyle(Color(hex: "#8A7A4A"))
        }
    }
}

struct CardPlaceholderView: View {
    let card: Card
    var body: some View {
        ZStack {
            Color.black
            Rectangle()
                .strokeBorder(Color(hex: "#C9A961").opacity(0.2), lineWidth: 0.6)
            Canvas { ctx, size in
                let w = size.width; let h = size.height
                let gold = Color(hex: "#C9A961")
                let s = StrokeStyle(lineWidth: 0.8)
                var tl = Path()
                tl.move(to: CGPoint(x: 0, y: 5)); tl.addLine(to: CGPoint(x: 0, y: 0)); tl.addLine(to: CGPoint(x: 5, y: 0))
                ctx.stroke(tl, with: .color(gold.opacity(0.35)), style: s)
                var br = Path()
                br.move(to: CGPoint(x: w, y: h - 5)); br.addLine(to: CGPoint(x: w, y: h)); br.addLine(to: CGPoint(x: w - 5, y: h))
                ctx.stroke(br, with: .color(gold.opacity(0.35)), style: s)
            }
            .allowsHitTesting(false)
            VStack(spacing: 2) {
                LorcanaSymbol().frame(width: 18, height: 18).opacity(0.3)
                Text(card.name).font(.system(size: 6)).foregroundStyle(Color(hex: "#8A7A4A"))
                    .lineLimit(2).multilineTextAlignment(.center).padding(.horizontal, 2)
            }
        }
    }
}

struct MissingCardView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#0A0614"))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(style: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(Color(hex: "#3A2F5A")))
            LorcanaSymbol().frame(width: 14, height: 14).opacity(0.18)
        }
    }
}

// MARK: - Arcane filter chip (sorteer / hulpfilters)

struct ArcaneFilterChip: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 9, design: .monospaced))
            .tracking(1)
            .foregroundStyle(isActive ? Color(hex: "#C9A961") : Color(hex: "#6A5A3A"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Rectangle()
                    .fill(isActive ? Color(hex: "#C9A961").opacity(0.10) : Color.clear)
                    .overlay(
                        Rectangle().strokeBorder(
                            isActive ? Color(hex: "#C9A961").opacity(0.55) : Color(hex: "#3A2F5A").opacity(0.7),
                            lineWidth: 0.5
                        )
                    )
            )
    }
}
