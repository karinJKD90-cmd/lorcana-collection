import SwiftUI

extension Color {
    static let lorcanaGold = Color(hex: "#C9A961")
    static let lorcanaGoldLight = Color(hex: "#F4E4A1")
    static let lorcanaGoldDeep = Color(hex: "#8A7A4A")
    static let lorcanaVoid = Color(hex: "#0A0614")
    static let lorcanaPurple = Color(hex: "#1A1040")
    static let lorcanaMystic = Color(hex: "#2A1F4A")
    static let lorcanaFaded = Color(hex: "#3A2F5A")

    static let inkAmber = Color(hex: "#E8A923")
    static let inkAmethyst = Color(hex: "#B378BF")
    static let inkEmerald = Color(hex: "#3A9D5D")
    static let inkRuby = Color(hex: "#E24B4A")
    static let inkSapphire = Color(hex: "#5A8FBF")
    static let inkSteel = Color(hex: "#A8B5C0")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension ShapeStyle where Self == Color {
    static var lorcanaGold: Color { .lorcanaGold }
    static var lorcanaGoldLight: Color { .lorcanaGoldLight }
    static var lorcanaGoldDeep: Color { .lorcanaGoldDeep }
    static var lorcanaVoid: Color { .lorcanaVoid }
    static var lorcanaPurple: Color { .lorcanaPurple }
    static var lorcanaMystic: Color { .lorcanaMystic }
    static var lorcanaFaded: Color { .lorcanaFaded }
}
