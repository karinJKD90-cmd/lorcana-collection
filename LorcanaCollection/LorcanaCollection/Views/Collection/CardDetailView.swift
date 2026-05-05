import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Bindable var card: Card
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()
            ScrollView {
                VStack(spacing: 20) {

                    Text("#\(String(format: "%03d", card.cardNumber)) · \(card.setName) · SET \(String(format: "%02d", card.setNumber))")
                        .font(.system(size: 10)).tracking(1)
                        .foregroundStyle(Color(hex: "#8A7A4A"))
                        .padding(.top, 12)

                    ZStack(alignment: .topTrailing) {
                        CachedAsyncImage(urlString: card.imageUrl)
                            .scaledToFit()
                            .cornerRadius(10)
                            .shadow(color: Color(hex: "#C9A961").opacity(0.25), radius: 16)
                            .frame(maxWidth: 200)

                        if card.isFoil {
                            FoilCorner().frame(width: 200, height: 280)
                        }
                    }

                    VStack(spacing: 4) {
                        Text(card.name)
                            .font(.custom("Georgia", size: 22))
                            .foregroundStyle(Color(hex: "#F4E4A1"))
                            .multilineTextAlignment(.center)
                        Text(card.type)
                            .font(.custom("Georgia", size: 11))
                            .fontWeight(.light)
                            .italic()
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                    }

                    HStack(spacing: 8) {
                        InkBadge(ink: card.ink)
                        MetaBadge(label: card.rarity.replacingOccurrences(of: "_", with: " ").uppercased())
                        MetaBadge(label: card.type.uppercased())
                    }

                    HStack(spacing: 20) {
                        StatBlock(icon: "cost", value: "\(card.cost)", color: Color(hex: "#C9A961"))
                        if let str = card.strength {
                            StatBlock(icon: "strength", value: "\(str)", color: Color(hex: "#E24B4A"))
                        }
                        if let will = card.willpower {
                            StatBlock(icon: "defense", value: "\(will)", color: Color(hex: "#5A8FBF"))
                        }
                        if let lore = card.lore {
                            StatBlock(icon: "pip", value: "\(lore)", color: Color(hex: "#C9A961"))
                        }
                    }

                    HStack(spacing: 12) {
                        PriceBlock(label: "NORMAL", price: card.currentPriceNormal)
                        PriceBlock(label: "+ FOIL", price: card.currentPriceFoil)
                    }
                    .padding(.horizontal)

                    if let date = card.lastPriceUpdate {
                        Text("last sync · \(date.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                    }

                    VStack(spacing: 0) {
                        ToggleRow(label: "In collection", icon: "checkmark.circle", color: Color(hex: "#C9A961"), isOn: Binding(
                            get: { card.owned },
                            set: { if !$0 { showDeleteConfirmation = true } else { card.markOwned() } }
                        ))
                        Divider().background(Color(hex: "#3A2F5A"))
                        if card.owned {
                            if card.alwaysFoil {
                                // Foil is verplicht voor deze rarity — toon readonly
                                HStack {
                                    Image(systemName: "sparkles").foregroundStyle(Color(hex: "#B378BF"))
                                    Text("✦ Foil version").font(.system(size: 13)).foregroundStyle(Color(hex: "#8A7A4A"))
                                    Spacer()
                                    Text("Always foil").font(.system(size: 10)).foregroundStyle(Color(hex: "#8A7A4A")).italic()
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                            } else {
                                ToggleRow(label: "✦ Foil version", icon: "sparkles", color: Color(hex: "#B378BF"), isOn: $card.isFoil)
                            }
                            Divider().background(Color(hex: "#3A2F5A"))
                            ToggleRow(label: "✍ Signed", icon: "pencil", color: Color(hex: "#3A9D5D"), isOn: $card.isSigned)
                            Divider().background(Color(hex: "#3A2F5A"))
                        }
                        ToggleRow(label: "♡ Priority wishlist", icon: "heart", color: Color(hex: "#E24B4A"), isOn: $card.inPriorityWishlist)
                    }
                    .background(
                        Color.black.opacity(0.70)
                            .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6))
                    )
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("MY NOTES")
                            .font(.system(size: 10)).tracking(1)
                            .foregroundStyle(Color(hex: "#8A7A4A"))

                        TextField("Add notes...", text: Binding(
                            get: { card.notes ?? "" },
                            set: { card.notes = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .foregroundStyle(Color(hex: "#F4E4A1"))
                        .font(.system(size: 13))
                        .lineLimit(3...6)

                        Divider().background(Color(hex: "#3A2F5A"))

                        HStack {
                            Text("Purchase price").font(.system(size: 12)).foregroundStyle(Color(hex: "#8A7A4A"))
                            Spacer()
                            TextField("€ 0,00", value: $card.purchasePrice, format: .number)
                                .foregroundStyle(Color(hex: "#C9A961"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 12))
                        }
                    }
                    .padding()
                    .background(
                        Color.black.opacity(0.70)
                            .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog(
            "Are you sure you want to remove \(card.name)?",
            isPresented: $showDeleteConfirmation, titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { card.markNotOwned() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct ToggleRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isOn ? color : Color(hex: "#4A3A6A"))
                .frame(width: 18)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(isOn ? Color(hex: "#F4E4A1") : Color(hex: "#8A7A5A"))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(ArcaneToggleStyle(activeColor: color))
                .labelsHidden()
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
    }
}

struct InkBadge: View {
    let ink: String
    let inkColors: [String: Color] = [
        "Amber": Color(hex: "#E8A923"), "Amethyst": Color(hex: "#B378BF"),
        "Emerald": Color(hex: "#3A9D5D"), "Ruby": Color(hex: "#E24B4A"),
        "Sapphire": Color(hex: "#5A8FBF"), "Steel": Color(hex: "#A8B5C0")
    ]

    var body: some View {
        HStack(spacing: 5) {
            let validInks = ["amber","amethyst","emerald","ruby","sapphire","steel"]
            let assetName = validInks.contains(ink.lowercased()) ? "ink_\(ink.lowercased())" : "ink_basic"
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text(ink.uppercased())
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#8A7A4A"))
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(
            Color.black.opacity(0.70)
                .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6))
        )
    }
}

struct MetaBadge: View {
    let label: String
    var body: some View {
        Text(label).font(.system(size: 9)).foregroundStyle(Color(hex: "#8A7A4A"))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.black.opacity(0.70).overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)))
    }
}

struct StatBlock: View {
    let icon: String
    let value: String
    var color: Color = Color(hex: "#C9A961")

    var body: some View {
        VStack(spacing: 4) {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(color.opacity(0.85))
            Text(value)
                .font(.custom("Georgia", size: 18))
                .foregroundStyle(color)
        }
        .frame(minWidth: 44)
    }
}

struct PriceBlock: View {
    let label: String
    let price: Double?
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 10)).tracking(1).foregroundStyle(Color(hex: "#8A7A4A"))
            Text(price.map { "€ \(String(format: "%.2f", $0))" } ?? "—")
                .font(.custom("Georgia", size: 18))
                .foregroundStyle(price != nil ? Color(hex: "#C9A961") : Color(hex: "#3A2F5A"))
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.black.opacity(0.70).overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)))
    }
}
