import SwiftUI

// MARK: - Arcane achtergrond (vervangt SwirlBackground)

struct SwirlBackground: View {
    var body: some View {
        ZStack {
            Color(hex: "#060311")

            // Kleurwaas — paars/rood/teal hazes
            RadialGradient(
                colors: [Color(hex: "#5A328C").opacity(0.35), .clear],
                center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 320
            )
            RadialGradient(
                colors: [Color(hex: "#281450").opacity(0.45), .clear],
                center: UnitPoint(x: 0.5, y: 0.8), startRadius: 0, endRadius: 360
            )
            RadialGradient(
                colors: [Color(hex: "#3C1E5A").opacity(0.3), .clear],
                center: UnitPoint(x: 0.15, y: 0.9), startRadius: 0, endRadius: 260
            )

            // Zwarte overlay voor kalmere achtergrond
            Color.black.opacity(0.40)

            // Zachte kleurblobs (geblurd)
            Canvas { ctx, size in
                let w = size.width; let h = size.height
                let redGrad = Gradient(colors: [Color(hex: "#AA3C46").opacity(0.3), .clear])
                ctx.fill(
                    Path(ellipseIn: CGRect(x: 0, y: h * 0.05, width: 220, height: 130)),
                    with: .radialGradient(redGrad, center: CGPoint(x: w * 0.15, y: h * 0.20), startRadius: 0, endRadius: 110)
                )
                let purpGrad = Gradient(colors: [Color(hex: "#7850B4").opacity(0.3), .clear])
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.05, width: 220, height: 150)),
                    with: .radialGradient(purpGrad, center: CGPoint(x: w * 0.82, y: h * 0.28), startRadius: 0, endRadius: 120)
                )
                let tealGrad = Gradient(colors: [Color(hex: "#3C7878").opacity(0.22), .clear])
                ctx.fill(
                    Path(ellipseIn: CGRect(x: 0, y: h * 0.6, width: 180, height: 110)),
                    with: .radialGradient(tealGrad, center: CGPoint(x: w * 0.12, y: h * 0.72), startRadius: 0, endRadius: 100)
                )
            }
            .blur(radius: 8)

            // Swirl filaments
            GeometryReader { geo in
                Canvas { ctx, size in
                    let w = size.width; let h = size.height
                    let sx = w / 375; let sy = h / 768

                    // Rood/roze
                    var s1 = Path()
                    s1.move(to: CGPoint(x: 40 * sx, y: 120 * sy))
                    s1.addQuadCurve(to: CGPoint(x: 340 * sx, y: 140 * sy), control: CGPoint(x: 180 * sx, y: 320 * sy))
                    ctx.stroke(s1, with: .color(Color(hex: "#D16472").opacity(0.42)), style: StrokeStyle(lineWidth: 1.4))

                    // Paars
                    var s2 = Path()
                    s2.move(to: CGPoint(x: 20 * sx, y: 220 * sy))
                    s2.addQuadCurve(to: CGPoint(x: 360 * sx, y: 260 * sy), control: CGPoint(x: 180 * sx, y: 400 * sy))
                    ctx.stroke(s2, with: .color(Color(hex: "#B38FD9").opacity(0.38)), style: StrokeStyle(lineWidth: 1.5))

                    // Crème
                    var s3 = Path()
                    s3.move(to: CGPoint(x: 60 * sx, y: 80 * sy))
                    s3.addQuadCurve(to: CGPoint(x: 350 * sx, y: 420 * sy), control: CGPoint(x: 200 * sx, y: 300 * sy))
                    ctx.stroke(s3, with: .color(Color(hex: "#F4E4C5").opacity(0.25)), style: StrokeStyle(lineWidth: 1.0))

                    // Lagere paars
                    var s4 = Path()
                    s4.move(to: CGPoint(x: 10 * sx, y: 500 * sy))
                    s4.addQuadCurve(to: CGPoint(x: 360 * sx, y: 500 * sy), control: CGPoint(x: 180 * sx, y: 420 * sy))
                    ctx.stroke(s4, with: .color(Color(hex: "#B38FD9").opacity(0.28)), style: StrokeStyle(lineWidth: 1.2))

                    // Lagere crème
                    var s5 = Path()
                    s5.move(to: CGPoint(x: 30 * sx, y: 620 * sy))
                    s5.addQuadCurve(to: CGPoint(x: 350 * sx, y: 600 * sy), control: CGPoint(x: 200 * sx, y: 520 * sy))
                    ctx.stroke(s5, with: .color(Color(hex: "#F4E4C5").opacity(0.22)), style: StrokeStyle(lineWidth: 1.0))

                    // Teal onder
                    var s6 = Path()
                    s6.move(to: CGPoint(x: 50 * sx, y: 700 * sy))
                    s6.addQuadCurve(to: CGPoint(x: 350 * sx, y: 680 * sy), control: CGPoint(x: 220 * sx, y: 580 * sy))
                    ctx.stroke(s6, with: .color(Color(hex: "#8CC5C5").opacity(0.28)), style: StrokeStyle(lineWidth: 1.0))

                    // Goud accent
                    var s7 = Path()
                    s7.move(to: CGPoint(x: 80 * sx, y: 40 * sy))
                    s7.addQuadCurve(to: CGPoint(x: 300 * sx, y: 380 * sy), control: CGPoint(x: 200 * sx, y: 220 * sy))
                    ctx.stroke(s7, with: .color(Color(hex: "#E8D08A").opacity(0.20)), style: StrokeStyle(lineWidth: 0.8))

                    // Fijn accent
                    var a1 = Path()
                    a1.move(to: CGPoint(x: 100 * sx, y: 340 * sy))
                    a1.addQuadCurve(to: CGPoint(x: 260 * sx, y: 340 * sy), control: CGPoint(x: 180 * sx, y: 360 * sy))
                    ctx.stroke(a1, with: .color(Color(hex: "#F4E4A1").opacity(0.35)), style: StrokeStyle(lineWidth: 0.4))
                }
            }

            // Stofdeeltjes / sterren
            Canvas { ctx, size in
                let dust: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.12, 0.08, 1.1), (0.78, 0.14, 0.9), (0.22, 0.42, 0.7),
                    (0.88, 0.58, 1.2), (0.44, 0.78, 0.8), (0.62, 0.36, 1.0),
                    (0.08, 0.72, 0.8), (0.94, 0.88, 1.0), (0.34, 0.14, 0.6),
                    (0.68, 0.84, 0.7), (0.50, 0.52, 0.9), (0.28, 0.92, 0.6)
                ]
                for d in dust {
                    let r = d.2
                    let rect = CGRect(x: size.width * d.0 - r, y: size.height * d.1 - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: "#F4E4A1").opacity(0.8)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Arcane kader (vergulde rand met hoekversieringen)

struct ArcaneFrame: View {
    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(Color(hex: "#C9A961").opacity(0.45), lineWidth: 0.8)
                .padding(6)
            Rectangle()
                .strokeBorder(Color(hex: "#C9A961").opacity(0.22), lineWidth: 0.5)
                .padding(9)
            // Hoekversieringen
            Canvas { ctx, size in
                let w = size.width; let h = size.height
                let gold = Color(hex: "#C9A961")
                let goldLight = Color(hex: "#F4E4A1")
                let outer = StrokeStyle(lineWidth: 0.9)
                let inner = StrokeStyle(lineWidth: 0.5)

                // Hoek TL
                var tlO = Path()
                tlO.move(to: CGPoint(x: 4, y: 22)); tlO.addLine(to: CGPoint(x: 4, y: 10))
                tlO.addQuadCurve(to: CGPoint(x: 10, y: 4), control: CGPoint(x: 4, y: 4))
                tlO.addLine(to: CGPoint(x: 22, y: 4))
                ctx.stroke(tlO, with: .color(gold.opacity(0.9)), style: outer)

                var tlI = Path()
                tlI.move(to: CGPoint(x: 7, y: 16)); tlI.addLine(to: CGPoint(x: 7, y: 11))
                tlI.addQuadCurve(to: CGPoint(x: 11, y: 7), control: CGPoint(x: 7, y: 7))
                tlI.addLine(to: CGPoint(x: 16, y: 7))
                ctx.stroke(tlI, with: .color(gold.opacity(0.55)), style: inner)
                ctx.fill(Path(ellipseIn: CGRect(x: 9.1, y: 9.1, width: 1.8, height: 1.8)), with: .color(goldLight))

                // Hoek TR
                var trO = Path()
                trO.move(to: CGPoint(x: w - 4, y: 22)); trO.addLine(to: CGPoint(x: w - 4, y: 10))
                trO.addQuadCurve(to: CGPoint(x: w - 10, y: 4), control: CGPoint(x: w - 4, y: 4))
                trO.addLine(to: CGPoint(x: w - 22, y: 4))
                ctx.stroke(trO, with: .color(gold.opacity(0.9)), style: outer)

                var trI = Path()
                trI.move(to: CGPoint(x: w - 7, y: 16)); trI.addLine(to: CGPoint(x: w - 7, y: 11))
                trI.addQuadCurve(to: CGPoint(x: w - 11, y: 7), control: CGPoint(x: w - 7, y: 7))
                trI.addLine(to: CGPoint(x: w - 16, y: 7))
                ctx.stroke(trI, with: .color(gold.opacity(0.55)), style: inner)
                ctx.fill(Path(ellipseIn: CGRect(x: w - 10.9, y: 9.1, width: 1.8, height: 1.8)), with: .color(goldLight))

                // Hoek BL
                var blO = Path()
                blO.move(to: CGPoint(x: 4, y: h - 22)); blO.addLine(to: CGPoint(x: 4, y: h - 10))
                blO.addQuadCurve(to: CGPoint(x: 10, y: h - 4), control: CGPoint(x: 4, y: h - 4))
                blO.addLine(to: CGPoint(x: 22, y: h - 4))
                ctx.stroke(blO, with: .color(gold.opacity(0.9)), style: outer)

                var blI = Path()
                blI.move(to: CGPoint(x: 7, y: h - 16)); blI.addLine(to: CGPoint(x: 7, y: h - 11))
                blI.addQuadCurve(to: CGPoint(x: 11, y: h - 7), control: CGPoint(x: 7, y: h - 7))
                blI.addLine(to: CGPoint(x: 16, y: h - 7))
                ctx.stroke(blI, with: .color(gold.opacity(0.55)), style: inner)
                ctx.fill(Path(ellipseIn: CGRect(x: 9.1, y: h - 10.9, width: 1.8, height: 1.8)), with: .color(goldLight))

                // Hoek BR
                var brO = Path()
                brO.move(to: CGPoint(x: w - 4, y: h - 22)); brO.addLine(to: CGPoint(x: w - 4, y: h - 10))
                brO.addQuadCurve(to: CGPoint(x: w - 10, y: h - 4), control: CGPoint(x: w - 4, y: h - 4))
                brO.addLine(to: CGPoint(x: w - 22, y: h - 4))
                ctx.stroke(brO, with: .color(gold.opacity(0.9)), style: outer)

                var brI = Path()
                brI.move(to: CGPoint(x: w - 7, y: h - 16)); brI.addLine(to: CGPoint(x: w - 7, y: h - 11))
                brI.addQuadCurve(to: CGPoint(x: w - 11, y: h - 7), control: CGPoint(x: w - 7, y: h - 7))
                brI.addLine(to: CGPoint(x: w - 16, y: h - 7))
                ctx.stroke(brI, with: .color(gold.opacity(0.55)), style: inner)
                ctx.fill(Path(ellipseIn: CGRect(x: w - 10.9, y: h - 10.9, width: 1.8, height: 1.8)), with: .color(goldLight))
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Arcane actietegel (2x grid op home)

struct ArcaneActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    var subtitleGold: Bool = false
    var badge: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.70)

            // Dubbele rand
            Rectangle()
                .strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)
            Rectangle()
                .strokeBorder(Color(hex: "#C9A961").opacity(0.15), lineWidth: 0.4)
                .padding(2)

            // Hoekmarkeringen
            Canvas { ctx, size in
                let w = size.width; let h = size.height
                let gold = Color(hex: "#C9A961")
                let s = StrokeStyle(lineWidth: 0.8)

                var tl = Path()
                tl.move(to: CGPoint(x: -1, y: 7)); tl.addLine(to: CGPoint(x: -1, y: -1))
                tl.addLine(to: CGPoint(x: 7, y: -1))
                ctx.stroke(tl, with: .color(gold), style: s)

                var br = Path()
                br.move(to: CGPoint(x: w + 1, y: h - 7)); br.addLine(to: CGPoint(x: w + 1, y: h + 1))
                br.addLine(to: CGPoint(x: w - 7, y: h + 1))
                ctx.stroke(br, with: .color(gold), style: s)
            }
            .allowsHitTesting(false)

            // Inhoud
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: "#E8D08A"))
                    .shadow(color: Color(hex: "#C9A961").opacity(0.55), radius: 9)
                    .shadow(color: Color(hex: "#C9A961").opacity(0.25), radius: 18)
                    .frame(width: 46, height: 46)

                Spacer()

                Text(title)
                    .font(.custom("Georgia", size: 15))
                    .italic()
                    .foregroundStyle(Color(hex: "#E8D08A"))
                    .lineLimit(1)
                    .padding(.bottom, 3)

                Text(subtitle)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(subtitleGold ? Color(hex: "#C9A961") : Color(hex: "#8A7A4A"))
                    .lineLimit(1)
            }
            .padding(12)

            // Badge rechts boven
            if let badge = badge {
                Text(badge)
                    .font(.custom("Georgia", size: 13))
                    .foregroundStyle(Color(hex: "#C9A961"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#0A0614").opacity(0.65))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(hex: "#8A7A4A").opacity(0.5), lineWidth: 0.5))
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 10)
                    .padding(.trailing, 10)
            }
        }
        .aspectRatio(1.15, contentMode: .fit)
    }
}

// MARK: - Home tegel (legacy, bewaard voor compatibiliteit)

struct HomeTile: View {
    let icon: String
    let title: String
    let subtitle: String
    var subtitleColor: Color = Color(hex: "#8A7A4A")
    var isHighlighted: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color(hex: "#2A1F4A").opacity(0.85), Color(hex: "#0A0614").opacity(0.9)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isHighlighted ? Color(hex: "#C9A961") : Color(hex: "#3A2F5A"),
                                  lineWidth: isHighlighted ? 1 : 0.5))

            if isHighlighted {
                LorcanaSymbol()
                    .frame(width: 55, height: 55)
                    .opacity(0.10)
                    .offset(x: 28, y: 18)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#C9A961"))
                Spacer()
                Text(title)
                    .font(.custom("Georgia", size: 14))
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: "#F4E4A1"))
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(subtitleColor)
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Rarity shapes

/// Gelijkzijdige driehoek omhoog (Rare)
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX,  y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX,  y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX,  y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Ruit / rotated square (Super Rare, Enchanted, Promo)
struct LorcanaDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX,  y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX,  y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX,  y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX,  y: rect.midY))
        p.closeSubpath()
        return p
    }
}

/// Regelmatige n-hoek
struct NGonShape: Shape {
    let sides: Int
    var startAngle: CGFloat = -.pi / 2  // punt omhoog

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        let cx = rect.midX; let cy = rect.midY
        for i in 0..<sides {
            let a = startAngle + CGFloat(i) * (2 * .pi / CGFloat(sides))
            let pt = CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// Open boek / Uncommon — twee vleugelvormen die samenkomen
struct BookShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width; let h = rect.height
        let cx = rect.minX + w * 0.5
        let top = rect.minY
        let bot = rect.maxY
        let spineTop = rect.minY + h * 0.28
        let spread = w * 0.10

        var p = Path()
        // Linker pagina
        p.move(to: CGPoint(x: cx - spread, y: spineTop))
        p.addLine(to: CGPoint(x: rect.minX, y: top))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.08, y: bot))
        p.addQuadCurve(to: CGPoint(x: cx, y: spineTop + h * 0.12),
                       control: CGPoint(x: cx - w * 0.18, y: bot - h * 0.12))
        p.closeSubpath()
        // Rechter pagina
        p.move(to: CGPoint(x: cx + spread, y: spineTop))
        p.addLine(to: CGPoint(x: rect.maxX, y: top))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.08, y: bot))
        p.addQuadCurve(to: CGPoint(x: cx, y: spineTop + h * 0.12),
                       control: CGPoint(x: cx + w * 0.18, y: bot - h * 0.12))
        p.closeSubpath()
        return p
    }
}

// MARK: - Rarity icon — officiële Lorcana shapes

struct RarityPipIcon: View {
    let rawRarity: String
    let color: Color
    var dim: Bool = false

    private var opacity: Double { dim ? 0.22 : 1.0 }

    var body: some View {
        Group {
            switch rawRarity.lowercased() {

            // ── Cirkel (Common) ───────────────────────────────────────
            case "common":
                Circle()
                    .fill(RadialGradient(
                        colors: [color.opacity(0.85), color.opacity(0.55)],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 1, endRadius: 11
                    ))
                    .overlay(Circle().strokeBorder(color.opacity(0.4), lineWidth: 0.8))
                    .frame(width: 20, height: 20)

            // ── Open boek (Uncommon) ──────────────────────────────────
            case "uncommon":
                BookShape()
                    .fill(color.opacity(0.75))
                    .overlay(BookShape().stroke(color, lineWidth: 0.6))
                    .frame(width: 22, height: 18)

            // ── Driehoek (Rare) ───────────────────────────────────────
            case "rare":
                TriangleShape()
                    .fill(LinearGradient(
                        colors: [color.opacity(0.9), color.opacity(0.65)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(TriangleShape().stroke(color, lineWidth: 0.7))
                    .frame(width: 20, height: 18)

            // ── Ruit / rotated square (Super Rare) ───────────────────
            case "super_rare":
                LorcanaDiamond()
                    .fill(LinearGradient(
                        colors: [color.opacity(0.9), color.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .overlay(LorcanaDiamond().stroke(color, lineWidth: 0.7))
                    .frame(width: 20, height: 20)

            // ── Vijfhoek (Legendary) ──────────────────────────────────
            case "legendary":
                NGonShape(sides: 5)
                    .fill(LinearGradient(
                        colors: [color.opacity(0.95), color.opacity(0.65)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(NGonShape(sides: 5).stroke(color, lineWidth: 0.7))
                    .frame(width: 22, height: 22)

            // ── Zeshoek afgerond (Epic) ───────────────────────────────
            case "epic":
                ZStack {
                    NGonShape(sides: 6, startAngle: 0)  // flat-top hexagon
                        .fill(LinearGradient(
                            colors: [Color(hex: "#E8A040"), Color(hex: "#D45090"), Color(hex: "#9050C8")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    NGonShape(sides: 6, startAngle: 0)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.7)
                }
                .frame(width: 22, height: 22)

            // ── Ruit met ornamentele rand (Enchanted) ─────────────────
            case "enchanted":
                ZStack {
                    LorcanaDiamond()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#7ED4E6"), Color(hex: "#50B8C8")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 22, height: 22)
                    LorcanaDiamond()
                        .stroke(Color(hex: "#A0E8F0"), lineWidth: 1.2)
                        .frame(width: 16, height: 16)
                    LorcanaDiamond()
                        .stroke(Color(hex: "#7ED4E6").opacity(0.5), lineWidth: 0.5)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 26, height: 26)

            // ── Cirkel met ornamentele rand (Iconic) ──────────────────
            case "iconic":
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(hex: "#F08080"), Color(hex: "#C84060")],
                            center: .topLeading, startRadius: 1, endRadius: 14
                        ))
                        .frame(width: 20, height: 20)
                    Circle()
                        .stroke(Color(hex: "#F4A0B0"), lineWidth: 1.2)
                        .frame(width: 14, height: 14)
                    Circle()
                        .stroke(Color(hex: "#F08080").opacity(0.45), lineWidth: 0.5)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 26, height: 26)

            // ── Promo: ruit met donker accent ─────────────────────────
            case "promo", "special_rarity":
                ZStack {
                    LorcanaDiamond()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#A878C8"), Color(hex: "#6040A0")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                    LorcanaDiamond()
                        .stroke(Color(hex: "#C8A0E8").opacity(0.7), lineWidth: 0.8)
                        .frame(width: 20, height: 20)
                }

            // ── Fallback ──────────────────────────────────────────────
            default:
                LorcanaDiamond()
                    .fill(color)
                    .frame(width: 16, height: 16)
            }
        }
        .opacity(opacity)
    }
}

// MARK: - Rarity chip

struct RarityChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void
    var rawRarity: String? = nil

    private var accentColor: Color {
        switch (rawRarity ?? "").lowercased() {
        case "common":         return Color(hex: "#8A9AAA")
        case "uncommon":       return Color(hex: "#5A8FBF")
        case "rare":           return Color(hex: "#C9A961")
        case "super_rare":     return Color(hex: "#B378BF")
        case "legendary":      return Color(hex: "#E8A923")
        case "enchanted":      return Color(hex: "#7ED4E6")
        case "epic":           return Color(hex: "#E24B4A")
        case "iconic":         return Color(hex: "#F4E4A1")
        case "special_rarity": return Color(hex: "#3A9D5D")
        case "promo":          return Color(hex: "#C878C8")
        default:               return Color(hex: "#C9A961")
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon
                if let raw = rawRarity {
                    RarityPipIcon(rawRarity: raw, color: accentColor, dim: !isActive)
                        .frame(height: 22)
                } else {
                    // "ALLE" — kleine shapes-samenstelling als preview
                    let a: Double = isActive ? 0.9 : 0.25
                    HStack(spacing: 3) {
                        Circle().fill(Color(hex: "#8A9AAA").opacity(a)).frame(width: 7, height: 7)
                        TriangleShape().fill(Color(hex: "#C9A961").opacity(a)).frame(width: 8, height: 7)
                        LorcanaDiamond().fill(Color(hex: "#B378BF").opacity(a)).frame(width: 7, height: 7)
                        NGonShape(sides: 5).fill(Color(hex: "#E8A923").opacity(a)).frame(width: 8, height: 8)
                    }
                    .frame(height: 22)
                }

                // Label
                Text(label.lowercased())
                    .font(.system(size: 8))
                    .foregroundStyle(isActive ? accentColor.opacity(0.75) : Color(hex: "#2E2440"))
            }
            .frame(width: 54)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Rectangle().fill(isActive ? accentColor.opacity(0.08) : Color.clear)
                    Rectangle().strokeBorder(
                        isActive ? accentColor.opacity(0.45) : Color(hex: "#1A1230"),
                        lineWidth: 0.6
                    )
                    if isActive {
                        VStack {
                            Rectangle().fill(accentColor).frame(height: 1.5)
                            Spacer()
                        }
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

// MARK: - Lorcana symbool

struct LorcanaSymbol: View {
    var color: Color = Color(hex: "#C9A961")

    var body: some View {
        Image("lore_symbol")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
    }
}

// MARK: - Herbruikbaar zwart blok met gouden rand + hoekmarkeerders

struct ArcaneBlock<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.70)
            Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)
            Canvas { ctx, size in
                let w = size.width; let h = size.height
                let gold = Color(hex: "#C9A961")
                let s = StrokeStyle(lineWidth: 0.9)
                var tl = Path()
                tl.move(to: CGPoint(x: 0, y: 10)); tl.addLine(to: CGPoint(x: 0, y: 0)); tl.addLine(to: CGPoint(x: 10, y: 0))
                ctx.stroke(tl, with: .color(gold.opacity(0.7)), style: s)
                var br = Path()
                br.move(to: CGPoint(x: w, y: h - 10)); br.addLine(to: CGPoint(x: w, y: h)); br.addLine(to: CGPoint(x: w - 10, y: h))
                ctx.stroke(br, with: .color(gold.opacity(0.7)), style: s)
            }
            .allowsHitTesting(false)
            content.padding()
        }
    }
}

// MARK: - Arcane toggle stijl

struct ArcaneToggleStyle: ToggleStyle {
    var activeColor: Color = Color(hex: "#C9A961")

    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn

        ZStack(alignment: isOn ? .trailing : .leading) {
            // Track
            Rectangle()
                .fill(isOn ? activeColor.opacity(0.14) : Color(hex: "#080510"))
                .frame(width: 50, height: 28)
                .overlay(
                    ZStack {
                        Rectangle()
                            .strokeBorder(
                                isOn ? activeColor.opacity(0.65) : Color(hex: "#3A2F5A"),
                                lineWidth: 0.7
                            )
                        // Subtiele glow-lijn boven bij actief
                        if isOn {
                            VStack {
                                Rectangle()
                                    .fill(activeColor.opacity(0.5))
                                    .frame(height: 0.8)
                                Spacer()
                            }
                        }
                    }
                )

            // Thumb
            ZStack {
                Rectangle()
                    .fill(
                        isOn
                            ? LinearGradient(
                                colors: [activeColor.opacity(0.85), activeColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color(hex: "#1E1630"), Color(hex: "#140E28")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .frame(width: 20, height: 20)
                    .overlay(
                        Rectangle().strokeBorder(
                            isOn ? activeColor.opacity(0.9) : Color(hex: "#3A2F5A"),
                            lineWidth: 0.5
                        )
                    )

                // Lore-diamant binnenin thumb
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(
                        isOn ? Color(hex: "#0A0614").opacity(0.7) : Color(hex: "#3A2F5A")
                    )
            }
            .shadow(
                color: isOn ? activeColor.opacity(0.55) : .clear,
                radius: 8, x: 0, y: 0
            )
            .padding(4)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.18)) {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Tile press-animatie

struct ArcaneTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Foil hoekje

struct FoilCorner: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.32
            ZStack(alignment: .topTrailing) {
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width - size, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width, y: size))
                    path.closeSubpath()
                }
                .fill(Color(hex: "#F4C430"))

                Text("F")
                    .font(.system(size: size * 0.30, weight: .black))
                    .foregroundStyle(Color(hex: "#0A0614"))
                    .offset(x: -size * 0.14, y: size * 0.08)
            }
        }
    }
}
