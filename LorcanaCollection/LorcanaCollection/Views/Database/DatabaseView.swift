import SwiftUI
import SwiftData

struct DatabaseView: View {
    @Query var allCards: [Card]

    // Zoek + filter state
    @State private var searchText        = ""
    @State private var cardNumberSearch  = ""
    @State private var filter: CardFilter    = .missing
    @State private var sortMode: DBSortMode  = .cardNumber
    @State private var selectedRarities: Set<String> = []
    @State private var selectedInks: Set<String>     = []
    @State private var selectedSets: Set<Int>        = []
    @State private var showOnlySigned = false

    // Dropdown-state
    @State private var showSetPicker = false
    @State private var showInkPicker = false

    // Focus
    @FocusState private var searchFocused: Bool
    @FocusState private var numberFocused: Bool

    // Async filter
    @State private var displayedCards: [Card] = []
    @State private var filterTask: Task<Void, Never>? = nil

    // MARK: — Enums

    enum CardFilter: String, CaseIterable {
        case all      = "ALL"
        case missing  = "MISSING"
        case owned    = "OWNED"
        case priority = "PRIORITY"
    }

    enum DBSortMode: String, CaseIterable {
        case cardNumber = "#"
        case priceDesc  = "€↓"
        case priceAsc   = "€↑"
    }

    // MARK: — Constanten

    let inkOptions = ["Amber","Amethyst","Emerald","Ruby","Sapphire","Steel"]
    let inkColors: [String: Color] = [
        "Amber":    Color(hex: "#E8A923"), "Amethyst": Color(hex: "#B378BF"),
        "Emerald":  Color(hex: "#3A9D5D"), "Ruby":     Color(hex: "#E24B4A"),
        "Sapphire": Color(hex: "#5A8FBF"), "Steel":    Color(hex: "#A8B5C0")
    ]
    let rarityOptions = ["Common","Uncommon","Rare","Super_rare","Legendary",
                         "Enchanted","Epic","Iconic","Special_rarity","Promo"]

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

    // MARK: — Computed

    var uniqueSets: [(number: Int, name: String)] {
        let grouped = Dictionary(grouping: allCards) { $0.setNumber }
        return grouped
            .map { setNum, _ in (setNum, allCards.first(where: { $0.setNumber == setNum })?.setName ?? "") }
            .filter { $0.number > 0 }
            .sorted { $0.number < $1.number }
    }

    var selectedSetLabel: String {
        if selectedSets.isEmpty { return "all sets" }
        return uniqueSets
            .filter { selectedSets.contains($0.number) }
            .map { "Set \(String(format: "%02d", $0.number))" }
            .joined(separator: "  ·  ")
    }

    var hasActiveFilter: Bool {
        !selectedInks.isEmpty || !selectedRarities.isEmpty || !selectedSets.isEmpty
            || showOnlySigned || sortMode != .cardNumber
            || !searchText.isEmpty || !cardNumberSearch.isEmpty || filter != .missing
    }

    // MARK: — Filter

    private func computeFilter() -> [Card] {
        var result = allCards

        if !selectedSets.isEmpty     { result = result.filter { selectedSets.contains($0.setNumber) } }
        if !selectedRarities.isEmpty { result = result.filter { selectedRarities.contains($0.rarity) } }
        if !selectedInks.isEmpty     { result = result.filter { selectedInks.contains($0.ink) } }
        if !searchText.isEmpty       { result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        if !cardNumberSearch.isEmpty, let n = Int(cardNumberSearch) { result = result.filter { $0.cardNumber == n } }
        if showOnlySigned            { result = result.filter { $0.isSigned } }

        switch filter {
        case .all:      break
        case .missing:  result = result.filter { !$0.owned }
        case .owned:    result = result.filter { $0.owned }
        case .priority: result = result.filter { $0.inPriorityWishlist }
        }

        switch sortMode {
        case .cardNumber:
            return result.sorted { $0.setNumber == $1.setNumber ? $0.cardNumber < $1.cardNumber : $0.setNumber < $1.setNumber }
        case .priceDesc:
            return result.sorted { a, b in
                let pa = (a.isFoil ? a.currentPriceFoil : a.currentPriceNormal) ?? (a.currentPriceNormal ?? 0)
                let pb = (b.isFoil ? b.currentPriceFoil : b.currentPriceNormal) ?? (b.currentPriceNormal ?? 0)
                return pa > pb
            }
        case .priceAsc:
            return result.sorted { a, b in
                let pa = (a.isFoil ? a.currentPriceFoil : a.currentPriceNormal) ?? (a.currentPriceNormal ?? 0)
                let pb = (b.isFoil ? b.currentPriceFoil : b.currentPriceNormal) ?? (b.currentPriceNormal ?? 0)
                return pa < pb
            }
        }
    }

    private func scheduleFilter(delay: Bool = false) {
        filterTask?.cancel()
        filterTask = Task { @MainActor in
            if delay { try? await Task.sleep(for: .milliseconds(150)) }
            guard !Task.isCancelled else { return }
            displayedCards = computeFilter()
        }
    }

    // MARK: — Sub-views (type-checker opsplitsing)

    @ViewBuilder
    private var rarityRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(rarityOptions, id: \.self) { rarity in
                    let isActive  = selectedRarities.contains(rarity)
                    let hasSel    = !selectedRarities.isEmpty
                    let assetName = rarity == "Special_rarity" ? "rarity_promo" : "rarity_\(rarity.lowercased())"
                    Button {
                        if isActive { selectedRarities.remove(rarity) }
                        else        { selectedRarities.insert(rarity) }
                    } label: {
                        VStack(spacing: 5) {
                            Image(assetName)
                                .resizable().scaledToFit()
                                .frame(width: 36, height: 36)
                                .opacity(hasSel && !isActive ? 0.12 : 1.0)
                                .saturation(hasSel && !isActive ? 0 : 1)
                            Text(rarityLabel(rarity).lowercased())
                                .font(.system(size: 7.5))
                                .foregroundStyle(
                                    isActive ? Color(hex: "#F4E4A1")
                                        : (hasSel ? Color(hex: "#2A2040") : Color(hex: "#6A5A7A"))
                                )
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .padding(.vertical, 8)
                        .background(ZStack {
                            if isActive {
                                Rectangle().fill(Color(hex: "#C9A961").opacity(0.10))
                                VStack {
                                    Rectangle().fill(Color(hex: "#C9A961")).frame(height: 1.5)
                                    Spacer()
                                }
                            }
                        })
                    }
                    .buttonStyle(.plain)
                    .animation(.easeOut(duration: 0.13), value: isActive)
                }

                Rectangle().fill(Color(hex: "#221840")).frame(width: 0.5, height: 36).padding(.horizontal, 4)

                Button { showOnlySigned.toggle() } label: {
                    VStack(spacing: 5) {
                        Canvas { ctx, size in
                            let w = size.width; let h = size.height
                            let col = Color(hex: "#C9A961").opacity(showOnlySigned ? 1.0 : (selectedRarities.isEmpty ? 0.45 : 0.18))
                            var feather = Path()
                            feather.move(to: CGPoint(x: w * 0.76, y: h * 0.07))
                            feather.addCurve(to: CGPoint(x: w * 0.26, y: h * 0.72),
                                             control1: CGPoint(x: w * 0.96, y: h * 0.32),
                                             control2: CGPoint(x: w * 0.58, y: h * 0.64))
                            feather.addCurve(to: CGPoint(x: w * 0.76, y: h * 0.07),
                                             control1: CGPoint(x: w * 0.04, y: h * 0.46),
                                             control2: CGPoint(x: w * 0.52, y: h * 0.10))
                            ctx.fill(feather, with: .color(col.opacity(0.15)))
                            ctx.stroke(feather, with: .color(col), style: StrokeStyle(lineWidth: 1.1))
                            var spine = Path()
                            spine.move(to: CGPoint(x: w * 0.76, y: h * 0.07))
                            spine.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.88),
                                           control1: CGPoint(x: w * 0.62, y: h * 0.34),
                                           control2: CGPoint(x: w * 0.40, y: h * 0.66))
                            ctx.stroke(spine, with: .color(col), style: StrokeStyle(lineWidth: 0.9))
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
                                showOnlySigned ? Color(hex: "#F4E4A1")
                                    : (selectedRarities.isEmpty ? Color(hex: "#6A5A7A") : Color(hex: "#2A2040"))
                            )
                    }
                    .padding(.vertical, 8)
                    .background(ZStack {
                        if showOnlySigned {
                            Rectangle().fill(Color(hex: "#C9A961").opacity(0.10))
                            VStack {
                                Rectangle().fill(Color(hex: "#C9A961")).frame(height: 1.5)
                                Spacer()
                            }
                        }
                    })
                }
                .buttonStyle(.plain)
                .animation(.easeOut(duration: 0.13), value: showOnlySigned)

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
                                .frame(width: 36, height: 36)
                            Text("clear")
                                .font(.system(size: 7.5))
                                .foregroundStyle(Color(hex: "#C9A961").opacity(0.4))
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 6)
        }
        .background(Color(hex: "#06030F"))
    }

    @ViewBuilder
    private var inkDropdown: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.12)) { selectedInks = [] }
            } label: {
                HStack(spacing: 12) {
                    Color.clear.frame(width: 20, height: 20)
                    Text("all inks")
                        .font(.system(size: 11, design: .monospaced)).tracking(0.5)
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
                            .resizable().scaledToFit().frame(width: 20, height: 20)
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

    @ViewBuilder
    private var setDropdown: some View {
        ScrollView {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeOut(duration: 0.12)) { selectedSets = [] }
                } label: {
                    HStack(spacing: 12) {
                        Color.clear.frame(width: 20, height: 20)
                        Text("all sets")
                            .font(.system(size: 11, design: .monospaced)).tracking(0.5)
                            .foregroundStyle(selectedSets.isEmpty ? Color(hex: "#C9A961") : Color(hex: "#6A5A7A"))
                        Spacer()
                        if selectedSets.isEmpty {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color(hex: "#C9A961"))
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(selectedSets.isEmpty ? Color(hex: "#C9A961").opacity(0.07) : Color.clear)
                }
                .buttonStyle(.plain)
                Rectangle().fill(Color(hex: "#2A1F40")).frame(height: 0.5)
                ForEach(uniqueSets, id: \.number) { set in
                    let isActive = selectedSets.contains(set.number)
                    Button {
                        withAnimation(.easeOut(duration: 0.12)) {
                            if isActive { selectedSets.remove(set.number) }
                            else        { selectedSets.insert(set.number) }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", set.number))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(isActive ? Color(hex: "#C9A961") : Color(hex: "#8A7A4A"))
                                .frame(width: 20)
                            Text(set.name.lowercased())
                                .font(.system(size: 12))
                                .foregroundStyle(isActive ? Color(hex: "#F4E4A1") : Color(hex: "#6A5A7A"))
                            Spacer()
                            if isActive {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#C9A961"))
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(isActive ? Color(hex: "#C9A961").opacity(0.07) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    if set.number != uniqueSets.last?.number {
                        Rectangle().fill(Color(hex: "#1A1230")).frame(height: 0.5)
                    }
                }
            }
        }
        .frame(maxHeight: 320)
        .background(
            Color(hex: "#08050F").opacity(0.97)
                .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.22), lineWidth: 0.5))
        )
        .padding(.horizontal, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: — Body

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()
            VStack(spacing: 0) {

                // ── 1. Set multi-select ─────────────────────────────────
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            showSetPicker.toggle()
                            if showSetPicker { showInkPicker = false }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.down.dashed")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                            Text(selectedSetLabel)
                                .font(.system(size: 11))
                                .foregroundStyle(selectedSets.isEmpty ? Color(hex: "#6A5A7A") : Color(hex: "#F4E4A1"))
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: showSetPicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                                .animation(.easeOut(duration: 0.18), value: showSetPicker)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(
                            Color.black.opacity(0.55)
                                .overlay(Rectangle().strokeBorder(
                                    selectedSets.isEmpty ? Color(hex: "#221840") : Color(hex: "#C9A961").opacity(0.40),
                                    lineWidth: 0.5
                                ))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 7)
                .background(Color(hex: "#06030F"))

                // ── 2. Rarity + SIG — multiselect ──────────────────────
                rarityRow

                // ── 3. Zoeken ───────────────────────────────────────────
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                            .font(.system(size: 11)).foregroundStyle(Color(hex: "#8A7A4A"))
                        TextField("#", text: $cardNumberSearch)
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .font(.system(size: 12, design: .monospaced))
                            .keyboardType(.numberPad)
                            .frame(width: 40)
                            .focused($numberFocused)
                        if !cardNumberSearch.isEmpty {
                            Button { cardNumberSearch = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11)).foregroundStyle(Color(hex: "#8A7A4A"))
                            }
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Color.black.opacity(0.55).overlay(Rectangle().strokeBorder(Color(hex: "#221840"), lineWidth: 0.5)))
                    .contentShape(Rectangle())
                    .onTapGesture { numberFocused = true }

                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11)).foregroundStyle(Color(hex: "#8A7A4A"))
                        TextField("name...", text: $searchText)
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .font(.system(size: 12))
                            .focused($searchFocused)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11)).foregroundStyle(Color(hex: "#8A7A4A"))
                            }
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Color.black.opacity(0.55).overlay(Rectangle().strokeBorder(Color(hex: "#221840"), lineWidth: 0.5)))
                    .contentShape(Rectangle())
                    .onTapGesture { searchFocused = true }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Color(hex: "#06030F"))

                // ── 4. Card filter chips ────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CardFilter.allCases, id: \.self) { f in
                            Button { filter = f } label: {
                                Text(f.rawValue)
                                    .font(.custom("Georgia", size: 10))
                                    .fontWeight(filter == f ? .medium : .regular)
                                    .foregroundStyle(filter == f ? Color(hex: "#F4E4A1") : Color(hex: "#8A7A4A"))
                                    .padding(.horizontal, 12).padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(filter == f ? Color(hex: "#C9A961").opacity(0.15) : Color.clear)
                                            .overlay(RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(filter == f ? Color(hex: "#C9A961") : Color(hex: "#3A2F5A"),
                                                              lineWidth: 0.5))
                                    )
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color(hex: "#06030F"))

                // ── 5. Inkt + Sortering ─────────────────────────────────
                HStack(alignment: .center, spacing: 0) {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            showInkPicker.toggle()
                            if showInkPicker { showSetPicker = false }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 10)).foregroundStyle(Color(hex: "#8A7A4A"))
                            if selectedInks.isEmpty {
                                Text("all inks")
                                    .font(.system(size: 11)).foregroundStyle(Color(hex: "#6A5A7A"))
                            } else {
                                HStack(spacing: 4) {
                                    ForEach(inkOptions.filter { selectedInks.contains($0) }, id: \.self) { ink in
                                        Image("ink_\(ink.lowercased())")
                                            .resizable().scaledToFit().frame(width: 16, height: 16)
                                    }
                                }
                            }
                            Image(systemName: showInkPicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9)).foregroundStyle(Color(hex: "#8A7A4A"))
                                .animation(.easeOut(duration: 0.18), value: showInkPicker)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Color.black.opacity(0.45).overlay(Rectangle().strokeBorder(
                            selectedInks.isEmpty ? Color(hex: "#221840") : Color(hex: "#C9A961").opacity(0.40),
                            lineWidth: 0.5
                        )))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if showInkPicker || showSetPicker {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    showInkPicker = false; showSetPicker = false
                                }
                            }
                        }

                    if hasActiveFilter {
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) {
                                selectedInks = []; selectedRarities = []; selectedSets = []
                                showOnlySigned = false; sortMode = .cardNumber
                                searchText = ""; cardNumberSearch = ""
                                filter = .missing
                                showInkPicker = false; showSetPicker = false
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
                        ForEach(Array(DBSortMode.allCases.enumerated()), id: \.element) { idx, mode in
                            let active = sortMode == mode
                            Button { sortMode = mode } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(active ? Color(hex: "#C9A961") : Color(hex: "#4A3A2A"))
                                    .frame(width: 36, height: 30)
                                    .background(active ? Color(hex: "#C9A961").opacity(0.10) : Color.clear)
                            }
                            .buttonStyle(.plain)
                            if idx < DBSortMode.allCases.count - 1 {
                                Rectangle().fill(Color(hex: "#221840")).frame(width: 0.5, height: 16)
                            }
                        }
                    }
                    .background(ZStack {
                        Rectangle().fill(Color(hex: "#08050F"))
                        Rectangle().strokeBorder(Color(hex: "#221840"), lineWidth: 0.5)
                    })
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color(hex: "#06030F"))

                // Scheidingslijn
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.20), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 0.6)

                // ── Lijst ───────────────────────────────────────────────
                List(displayedCards) { card in
                    NavigationLink(destination: CardPageView(
                        cards: displayedCards,
                        currentIndex: displayedCards.firstIndex(where: { $0.id == card.id }) ?? 0
                    )) {
                        DatabaseRow(card: card)
                    }
                    .listRowBackground(Color.black.opacity(0.6))
                    .listRowSeparatorTint(Color(hex: "#3A2F5A"))
                }
                .scrollContentBackground(.hidden)
                .overlay(alignment: .top) {
                    if showSetPicker { setDropdown }
                    if showInkPicker { inkDropdown }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Database")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
        .task(id: allCards.count) { scheduleFilter() }
        .onChange(of: selectedSets)     { scheduleFilter() }
        .onChange(of: selectedRarities) { scheduleFilter() }
        .onChange(of: selectedInks)     { scheduleFilter() }
        .onChange(of: showOnlySigned)   { scheduleFilter() }
        .onChange(of: filter)           { scheduleFilter() }
        .onChange(of: sortMode)         { scheduleFilter() }
        .onChange(of: searchText)       { scheduleFilter(delay: true) }
        .onChange(of: cardNumberSearch) { scheduleFilter(delay: true) }
    }
}

// MARK: - DatabaseRow

struct DatabaseRow: View {
    let card: Card
    var inkColors: [String: Color] = [
        "Amber": Color(hex: "#E8A923"), "Amethyst": Color(hex: "#B378BF"),
        "Emerald": Color(hex: "#3A9D5D"), "Ruby": Color(hex: "#E24B4A"),
        "Sapphire": Color(hex: "#5A8FBF"), "Steel": Color(hex: "#A8B5C0")
    ]

    var statusLabel: String {
        if card.owned { return card.isFoil ? "FOIL" : "OWNED" }
        if card.inPriorityWishlist { return "PRIORITY" }
        return "MISSING"
    }

    var statusColor: Color {
        if card.owned { return Color(hex: "#3A9D5D") }
        if card.inPriorityWishlist { return Color(hex: "#E8A923") }
        return Color(hex: "#3A2F5A")
    }

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(urlString: card.imageUrl)
                .scaledToFit()
                .cornerRadius(3)
                .frame(width: 34, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(card.name).font(.system(size: 13, weight: .medium)).foregroundStyle(Color(hex: "#F4E4A1"))
                Text(card.type.isEmpty ? "" : card.type).font(.system(size: 10)).italic().foregroundStyle(Color(hex: "#8A7A4A"))
                HStack(spacing: 6) {
                    Image("ink_\(card.ink.lowercased())")
                        .resizable().scaledToFit().frame(width: 11, height: 11)
                    Text("#\(card.cardNumber)").font(.system(size: 10)).foregroundStyle(Color(hex: "#8A7A4A"))
                    if card.inPriorityWishlist {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill").font(.system(size: 8)).foregroundStyle(Color(hex: "#E24B4A"))
                            Text("PRIORITY").font(.system(size: 8)).foregroundStyle(Color(hex: "#E24B4A"))
                        }
                    }
                }
            }

            Spacer()

            Text(statusLabel)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(statusColor.opacity(0.6), lineWidth: 0.5))
        }
        .padding(.vertical, 4)
    }
}
