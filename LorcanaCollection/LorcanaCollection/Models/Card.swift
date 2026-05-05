import Foundation
import SwiftData

@Model
class Card {
    // Metadata van Lorcana API
    @Attribute(.unique) var id: String
    var name: String
    var setName: String
    var setNumber: Int
    var cardNumber: Int
    var rarity: String
    var ink: String
    var cost: Int
    var version: String?      // subtitle, bijv. "Brave Little Tailor"
    var strength: Int?
    var willpower: Int?
    var lore: Int?            // lore per quest (◆) — cruciaal voor deck building
    var inkable: Bool?        // of de kaart als inkt gebruikt kan worden
    var bodyText: String?     // ability/effect tekst van de kaart
    var type: String
    var imageUrl: String

    // User state
    var owned: Bool = false
    var isFoil: Bool = false
    var isSigned: Bool = false
    var inPriorityWishlist: Bool = false
    var lastModified: Date? = nil

    // Rarities die altijd foil zijn — gebruiker kan dit niet wijzigen
    static let alwaysFoilRarities: Set<String> = ["Enchanted", "Epic", "Iconic"]
    var alwaysFoil: Bool { Card.alwaysFoilRarities.contains(rarity) }

    /// Zet owned en past foil automatisch toe voor speciale rarities.
    func markOwned() {
        owned = true
        if alwaysFoil { isFoil = true }
        lastModified = Date()
    }

    /// Reset owned + foil consistent.
    func markNotOwned() {
        owned = false
        isFoil = false
        isSigned = false
    }

    // Persoonlijke notities
    var purchasePrice: Double?
    var purchaseDate: Date?
    var notes: String?

    // Prijzen (Cardmarket)
    var currentPriceNormal: Double?
    var currentPriceFoil: Double?
    var lastPriceUpdate: Date?

    // Waardehistorie
    @Relationship(deleteRule: .cascade) var priceHistory: [PricePoint] = []

    init(
        id: String,
        name: String,
        setName: String,
        setNumber: Int,
        cardNumber: Int,
        rarity: String,
        ink: String,
        cost: Int,
        type: String,
        imageUrl: String
    ) {
        self.id = id
        self.name = name
        self.setName = setName
        self.setNumber = setNumber
        self.cardNumber = cardNumber
        self.rarity = rarity
        self.ink = ink
        self.cost = cost
        self.type = type
        self.imageUrl = imageUrl
    }
}

@Model
class PricePoint {
    var date: Date
    var totalCollectionValue: Double
    
    init(date: Date, totalCollectionValue: Double) {
        self.date = date
        self.totalCollectionValue = totalCollectionValue
    }
}
