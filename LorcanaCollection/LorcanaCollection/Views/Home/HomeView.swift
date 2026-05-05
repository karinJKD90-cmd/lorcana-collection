import SwiftUI
import SwiftData

struct HomeView: View {
    @Query var cards: [Card]
    @Environment(\.modelContext) private var context

    var ownedCount: Int { cards.filter { $0.owned }.count }
    var setCount: Int { Set(cards.filter { $0.owned }.map { $0.setNumber }).count }
    var totalValue: Double {
        cards.filter { $0.owned }.compactMap {
            $0.isFoil ? $0.currentPriceFoil : $0.currentPriceNormal
        }.reduce(0, +)
    }
    var wishlistCount: Int { cards.filter { !$0.owned && $0.inPriorityWishlist }.count }

    var lastSet: (number: Int, name: String, owned: Int, total: Int)? {
        let ownedCards = cards.filter { $0.owned }
        let grouped = Dictionary(grouping: ownedCards) { $0.setNumber }
        guard !grouped.isEmpty else { return nil }
        return grouped.map { setNum, setCards -> (number: Int, name: String, owned: Int, total: Int, lastModified: Date) in
            let total = cards.filter { $0.setNumber == setNum }.count
            let latest = setCards.compactMap { $0.lastModified }.max() ?? .distantPast
            return (setNum, setCards.first?.setName ?? "", setCards.count, total, latest)
        }
        .sorted { $0.lastModified > $1.lastModified }
        .first
        .map { (number: $0.number, name: $0.name, owned: $0.owned, total: $0.total) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SwirlBackground()
                ArcaneFrame()

                ScrollView {
                    VStack(spacing: 0) {

                        // MARK: Header
                        VStack(spacing: 0) {
                            Text("· personal ·")
                                .font(.system(size: 9, design: .monospaced))
                                .tracking(4.2)
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                                .padding(.top, 106)

                            VStack(spacing: 5) {
                                Text("LORCANA")
                                    .font(.custom("Georgia", size: 34))
                                    .foregroundStyle(Color(hex: "#E8D08A"))
                                    .shadow(color: Color(hex: "#E6BE78").opacity(0.35), radius: 14)
                                    .shadow(color: Color(hex: "#E6BE78").opacity(0.4), radius: 3)

                                Text("collection")
                                    .font(.custom("Georgia", size: 16))
                                    .italic()
                                    .foregroundStyle(Color(hex: "#B39968"))
                            }
                            .padding(.top, 6)

                            Image("ink_basic")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .opacity(0.85)
                                .shadow(color: Color(hex: "#E6BE78").opacity(0.3), radius: 12)
                                .padding(.top, 24)
                                .padding(.bottom, 31)
                        }

                        // MARK: Stats strip
                        ArcaneStatsRow(owned: ownedCount, value: totalValue, sets: setCount)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 25)

                        // MARK: Vervolg je queeste
                        SectionLabel(title: "continue your quest")
                            .padding(.horizontal, 18)
                            .padding(.bottom, 15)

                        if let set = lastSet {
                            NavigationLink(destination: CardGridView(setNumber: set.number, setName: set.name)) {
                                ArcaneFeaturedTile(cardSet: set)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 25)
                        } else {
                            Text("Start scanning or add cards")
                                .font(.custom("Georgia", size: 12))
                                .italic()
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                                .padding(.horizontal, 18)
                                .padding(.bottom, 25)
                        }

                        // MARK: Grimoire tools
                        SectionLabel(title: "grimoire")
                            .padding(.horizontal, 18)
                            .padding(.bottom, 17)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            NavigationLink(destination: CollectionView()) {
                                ArcaneActionTile(icon: "rectangle.stack.fill", title: "My collection", subtitle: "\(setCount) sets")
                            }.buttonStyle(ArcaneTileButtonStyle())

                            NavigationLink(destination: WishlistView()) {
                                ArcaneActionTile(
                                    icon: "moon.stars.fill",
                                    title: "Wishlist",
                                    subtitle: "priority cards",
                                    badge: wishlistCount > 0 ? "\(wishlistCount)" : nil
                                )
                            }.buttonStyle(ArcaneTileButtonStyle())

                            NavigationLink(destination: DatabaseView()) {
                                ArcaneActionTile(icon: "book.closed.fill", title: "Grimoire", subtitle: "search database")
                            }.buttonStyle(ArcaneTileButtonStyle())

                            NavigationLink(destination: DashboardView()) {
                                ArcaneActionTile(
                                    icon: "crown.fill",
                                    title: "Treasury",
                                    subtitle: "€ \(String(format: "%.0f", totalValue))",
                                    subtitleGold: true
                                )
                            }.buttonStyle(ArcaneTileButtonStyle())

                            NavigationLink(destination: ScanHomeView()) {
                                ArcaneActionTile(icon: "camera.viewfinder", title: "Scan cards", subtitle: "photo · bulk · manual")
                            }.buttonStyle(ArcaneTileButtonStyle())

                            NavigationLink(destination: DeckListView()) {
                                ArcaneActionTile(icon: "wand.and.stars", title: "Decks", subtitle: "build your deck")
                            }.buttonStyle(ArcaneTileButtonStyle())
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 21)

                        // MARK: Footer
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(LinearGradient(colors: [.clear, Color(hex: "#3A2F5A"), .clear],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(height: 0.5)
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 6)

                        Text("✦  may your collection grow  ✦")
                            .font(.custom("Georgia", size: 11))
                            .italic()
                            .foregroundStyle(Color(hex: "#6A5A3A"))
                            .tracking(2)
                            .padding(.bottom, 52)
                    }
                }
            }
            .ignoresSafeArea()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "scroll")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#C9A961"))
                    }
                }
            }
            .onAppear { migrateAlwaysFoil() }
        }
    }

    /// Eenmalige migratie: zet isFoil=true voor owned kaarten met altijd-foil rarity.
    private func migrateAlwaysFoil() {
        let needsMigration = cards.filter { $0.owned && $0.alwaysFoil && !$0.isFoil }
        guard !needsMigration.isEmpty else { return }
        for card in needsMigration { card.isFoil = true }
        try? context.save()
    }
}

// MARK: - Hex embleem

struct ArcaneHexEmblem: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width; let h = size.height
            let cx = w / 2; let cy = h / 2
            let sc = min(w, h) / 150

            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: cx + (x - 75) * sc, y: cy + (y - 75) * sc)
            }
            func s(_ v: CGFloat) -> CGFloat { v * sc }

            // Buitenste hexagon
            var outerHex = Path()
            let outerPts: [(CGFloat, CGFloat)] = [(75,10),(130,40),(130,110),(75,140),(20,110),(20,40)]
            outerHex.move(to: p(outerPts[0].0, outerPts[0].1))
            for pt in outerPts.dropFirst() { outerHex.addLine(to: p(pt.0, pt.1)) }
            outerHex.closeSubpath()
            ctx.stroke(outerHex, with: .color(Color(hex: "#C9A961").opacity(0.8)), style: StrokeStyle(lineWidth: 0.8))

            // Binnenste hexagon
            var innerHex = Path()
            let innerPts: [(CGFloat, CGFloat)] = [(75,20),(121,45),(121,105),(75,130),(29,105),(29,45)]
            innerHex.move(to: p(innerPts[0].0, innerPts[0].1))
            for pt in innerPts.dropFirst() { innerHex.addLine(to: p(pt.0, pt.1)) }
            innerHex.closeSubpath()
            ctx.stroke(innerHex, with: .color(Color(hex: "#C9A961").opacity(0.45)), style: StrokeStyle(lineWidth: 0.5))

            // Gloedcirkel
            let gr = s(36)
            let glowGrad = Gradient(stops: [
                .init(color: Color(hex: "#E8C880").opacity(0.55), location: 0),
                .init(color: Color(hex: "#C9A961").opacity(0.15), location: 0.7),
                .init(color: .clear, location: 1)
            ])
            ctx.fill(Path(ellipseIn: CGRect(x: cx - gr, y: cy - gr, width: gr * 2, height: gr * 2)),
                     with: .radialGradient(glowGrad, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: gr))

            // Binnenste cirkel
            ctx.stroke(Path(ellipseIn: CGRect(x: cx - s(30), y: cy - s(30), width: s(60), height: s(60))),
                       with: .color(Color(hex: "#C9A961").opacity(0.45)), style: StrokeStyle(lineWidth: 0.6))

            // 4-puntige ster
            let spL = s(28); let spS = s(18); let spW = s(3)

            var up = Path()
            up.move(to: CGPoint(x: cx, y: cy - spL))
            up.addQuadCurve(to: CGPoint(x: cx, y: cy), control: CGPoint(x: cx - spW, y: cy - spW * 2))
            up.addQuadCurve(to: CGPoint(x: cx, y: cy - spL), control: CGPoint(x: cx + spW, y: cy - spW * 2))
            up.closeSubpath()
            ctx.fill(up, with: .color(Color(hex: "#0A0410")))
            ctx.stroke(up, with: .color(Color(hex: "#C9A961").opacity(0.8)), style: StrokeStyle(lineWidth: 0.5))

            var dn = Path()
            dn.move(to: CGPoint(x: cx, y: cy + spL))
            dn.addQuadCurve(to: CGPoint(x: cx, y: cy), control: CGPoint(x: cx - spW, y: cy + spW * 2))
            dn.addQuadCurve(to: CGPoint(x: cx, y: cy + spL), control: CGPoint(x: cx + spW, y: cy + spW * 2))
            dn.closeSubpath()
            ctx.fill(dn, with: .color(Color(hex: "#0A0410")))
            ctx.stroke(dn, with: .color(Color(hex: "#C9A961").opacity(0.8)), style: StrokeStyle(lineWidth: 0.5))

            var lf = Path()
            lf.move(to: CGPoint(x: cx - spS, y: cy))
            lf.addQuadCurve(to: CGPoint(x: cx, y: cy), control: CGPoint(x: cx - spW * 2, y: cy - spW))
            lf.addQuadCurve(to: CGPoint(x: cx - spS, y: cy), control: CGPoint(x: cx - spW * 2, y: cy + spW))
            lf.closeSubpath()
            ctx.fill(lf, with: .color(Color(hex: "#0A0410")))
            ctx.stroke(lf, with: .color(Color(hex: "#C9A961").opacity(0.8)), style: StrokeStyle(lineWidth: 0.5))

            var rt = Path()
            rt.move(to: CGPoint(x: cx + spS, y: cy))
            rt.addQuadCurve(to: CGPoint(x: cx, y: cy), control: CGPoint(x: cx + spW * 2, y: cy - spW))
            rt.addQuadCurve(to: CGPoint(x: cx + spS, y: cy), control: CGPoint(x: cx + spW * 2, y: cy + spW))
            rt.closeSubpath()
            ctx.fill(rt, with: .color(Color(hex: "#0A0410")))
            ctx.stroke(rt, with: .color(Color(hex: "#C9A961").opacity(0.8)), style: StrokeStyle(lineWidth: 0.5))

            // Middelpunt glans
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 2.5, y: cy - 2.5, width: 5, height: 5)),
                     with: .color(Color(hex: "#FFF5D8")))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10)),
                     with: .color(Color(hex: "#FFF5D8").opacity(0.3)))

            // Hoekdotjes
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 1.2, y: cy - s(65) - 1.2, width: 2.4, height: 2.4)),
                     with: .color(Color(hex: "#C9A961")))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 1.2, y: cy + s(65) - 1.2, width: 2.4, height: 2.4)),
                     with: .color(Color(hex: "#C9A961")))

            // Mini swirlringen
            var sw1 = Path()
            sw1.move(to: CGPoint(x: cx - s(35), y: cy - s(20)))
            sw1.addQuadCurve(to: CGPoint(x: cx, y: cy - s(33)), control: CGPoint(x: cx - s(20), y: cy - s(35)))
            ctx.stroke(sw1, with: .color(Color(hex: "#F4E4A1").opacity(0.4)), style: StrokeStyle(lineWidth: 0.4))

            var sw2 = Path()
            sw2.move(to: CGPoint(x: cx + s(35), y: cy - s(20)))
            sw2.addQuadCurve(to: CGPoint(x: cx, y: cy - s(33)), control: CGPoint(x: cx + s(20), y: cy - s(35)))
            ctx.stroke(sw2, with: .color(Color(hex: "#F4E4A1").opacity(0.4)), style: StrokeStyle(lineWidth: 0.4))

            var sw3 = Path()
            sw3.move(to: CGPoint(x: cx - s(35), y: cy + s(20)))
            sw3.addQuadCurve(to: CGPoint(x: cx, y: cy + s(33)), control: CGPoint(x: cx - s(20), y: cy + s(35)))
            ctx.stroke(sw3, with: .color(Color(hex: "#F4E4A1").opacity(0.4)), style: StrokeStyle(lineWidth: 0.4))

            var sw4 = Path()
            sw4.move(to: CGPoint(x: cx + s(35), y: cy + s(20)))
            sw4.addQuadCurve(to: CGPoint(x: cx, y: cy + s(33)), control: CGPoint(x: cx + s(20), y: cy + s(35)))
            ctx.stroke(sw4, with: .color(Color(hex: "#F4E4A1").opacity(0.4)), style: StrokeStyle(lineWidth: 0.4))
        }
    }
}

// MARK: - Stats rij

struct ArcaneStatsRow: View {
    let owned: Int
    let value: Double
    let sets: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.70)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.35), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 0.6)
                Spacer()
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.35), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 0.6)
            }

            HStack(spacing: 0) {
                // ◆ ornament links
                Text("◆")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#C9A961"))
                    .padding(.leading, -3)

                Spacer()

                ArcaneStatCol(value: "\(owned)", label: "cards")
                arcaneStatSeparator()
                ArcaneStatCol(value: "€ \(String(format: "%.0f", value))", label: "value")
                arcaneStatSeparator()
                ArcaneStatCol(value: "\(sets)", label: "sets")

                Spacer()

                Text("◆")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#C9A961"))
                    .padding(.trailing, -3)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
        }
        .frame(height: 56)
    }
}

private struct ArcaneStatCol: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Georgia", size: 20))
                .foregroundStyle(Color(hex: "#F4E4A1"))
                .lineHeight(1)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .tracking(2.4)
                .foregroundStyle(Color(hex: "#8A7A4A"))
        }
        .frame(maxWidth: .infinity)
    }
}

private func arcaneStatSeparator() -> some View {
    Rectangle()
        .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.4), .clear],
                             startPoint: .top, endPoint: .bottom))
        .frame(width: 1)
        .padding(.vertical, 8)
}

// MARK: - Section label

struct SectionLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.5), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.6)
            Text("◆")
                .font(.system(size: 7))
                .foregroundStyle(Color(hex: "#C9A961"))
            Text(title)
                .font(.system(size: 8.5, design: .monospaced))
                .tracking(4)
                .foregroundStyle(Color(hex: "#8A7A4A"))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 160)
            Text("◆")
                .font(.system(size: 7))
                .foregroundStyle(Color(hex: "#C9A961"))
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color(hex: "#C9A961").opacity(0.5), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.6)
        }
    }
}

// MARK: - Featured tile (vervolg je quest)

struct ArcaneFeaturedTile: View {
    let cardSet: (number: Int, name: String, owned: Int, total: Int)

    var percentage: Double {
        cardSet.total > 0 ? Double(cardSet.owned) / Double(cardSet.total) : 0
    }

    var body: some View {
        ZStack {
            // Achtergrond
            Color.black.opacity(0.70)
            LinearGradient(
                colors: [Color(hex: "#5A328C").opacity(0.18), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Dubbele gouden rand
            Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.6), lineWidth: 0.8)
            Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.25), lineWidth: 0.4).padding(3)

            VStack(spacing: 0) {
                // Bovenkant
                HStack(spacing: 12) {
                    // Hex badge
                    ZStack {
                        Canvas { ctx, size in
                            let cx = size.width / 2; let cy = size.height / 2
                            let r: CGFloat = 20
                            let hexPts: [(CGFloat, CGFloat)] = [
                                (cx, cy - r),
                                (cx + r * 0.866, cy - r * 0.5),
                                (cx + r * 0.866, cy + r * 0.5),
                                (cx, cy + r),
                                (cx - r * 0.866, cy + r * 0.5),
                                (cx - r * 0.866, cy - r * 0.5)
                            ]
                            var hex = Path()
                            hex.move(to: CGPoint(x: hexPts[0].0, y: hexPts[0].1))
                            for pt in hexPts.dropFirst() { hex.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
                            hex.closeSubpath()
                            ctx.fill(hex, with: .color(Color(hex: "#C9A961").opacity(0.15)))
                            ctx.stroke(hex, with: .color(Color(hex: "#F4E4A1").opacity(0.9)), style: StrokeStyle(lineWidth: 1))

                            let r2: CGFloat = 13
                            var innerHex = Path()
                            let innerPts: [(CGFloat, CGFloat)] = [
                                (cx, cy - r2),
                                (cx + r2 * 0.866, cy - r2 * 0.5),
                                (cx + r2 * 0.866, cy + r2 * 0.5),
                                (cx, cy + r2),
                                (cx - r2 * 0.866, cy + r2 * 0.5),
                                (cx - r2 * 0.866, cy - r2 * 0.5)
                            ]
                            innerHex.move(to: CGPoint(x: innerPts[0].0, y: innerPts[0].1))
                            for pt in innerPts.dropFirst() { innerHex.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
                            innerHex.closeSubpath()
                            ctx.stroke(innerHex, with: .color(Color(hex: "#C9A961").opacity(0.6)), style: StrokeStyle(lineWidth: 0.6))

                            ctx.fill(Path(ellipseIn: CGRect(x: cx - 1.5, y: cy - 1.5, width: 3, height: 3)),
                                     with: .color(Color(hex: "#F4E4A1")))
                        }
                    }
                    .frame(width: 44, height: 50)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(cardSet.name)
                            .font(.custom("Georgia", size: 17))
                            .italic()
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .lineLimit(1)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    Text("›")
                        .font(.custom("Georgia", size: 28))
                        .foregroundStyle(Color(hex: "#C9A961"))
                        .offset(y: -3)
                }

                // Progress rij
                HStack(spacing: 10) {
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: "#C9A961"))
                        .tracking(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "#C9A961").opacity(0.2))
                                .frame(height: 1.5)
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#C9A961").opacity(0.3), Color(hex: "#F4E4A1")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * percentage, height: 1.5)
                            // ◆ eindmarker
                            Text("◆")
                                .font(.system(size: 7))
                                .foregroundStyle(Color(hex: "#F4E4A1"))
                                .offset(x: geo.size.width * percentage - 4, y: 0)
                        }
                    }
                    .frame(height: 10)

                    Text("\(cardSet.owned) / \(cardSet.total)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: "#C9A961"))
                        .tracking(1)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Line height helper

extension View {
    func lineHeight(_ v: CGFloat) -> some View { self }
}
