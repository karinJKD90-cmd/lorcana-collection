import Foundation
import SwiftData

@Model
class Deck {
    var name: String
    var createdAt: Date
    var lastModified: Date
    var notes: String?

    @Relationship(deleteRule: .cascade) var entries: [DeckEntry] = []

    var totalCards: Int { entries.reduce(0) { $0 + $1.quantity } }

    var isValid: Bool {
        let colors = inkColors
        return totalCards == 60 && colors.count >= 1 && colors.count <= 2
    }

    var inkColors: [String] {
        let inks = entries.map { $0.ink }.filter { !$0.isEmpty && $0 != "None" }
        return Array(Set(inks)).sorted()
    }

    /// Aantal kaarten in het deck dat inkable is.
    var inkableCount: Int {
        entries.reduce(0) { sum, entry in
            sum + ((entry.inkable == true) ? entry.quantity : 0)
        }
    }

    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.lastModified = Date()
    }

    /// Voeg een kaart toe of verhoog de hoeveelheid (max 4).
    func addCard(_ card: Card) {
        if let existing = entries.first(where: { $0.cardID == card.id }) {
            if existing.quantity < 4 { existing.quantity += 1 }
        } else {
            entries.append(DeckEntry(card: card))
        }
        lastModified = Date()
    }

    /// Verlaag hoeveelheid, verwijder entry als 0.
    func removeCard(cardID: String) {
        guard let idx = entries.firstIndex(where: { $0.cardID == cardID }) else { return }
        if entries[idx].quantity > 1 {
            entries[idx].quantity -= 1
        } else {
            entries.remove(at: idx)
        }
        lastModified = Date()
    }

    /// Verwijder alle kopieën van een kaart uit het deck.
    func removeAllCopies(cardID: String) {
        entries.removeAll { $0.cardID == cardID }
        lastModified = Date()
    }

    /// Verhoog hoeveelheid van een bestaande entry (voor stepper in DeckBuilderView).
    func incrementEntry(cardID: String) {
        guard let entry = entries.first(where: { $0.cardID == cardID }),
              entry.quantity < 4 else { return }
        entry.quantity += 1
        lastModified = Date()
    }

    func quantityFor(cardID: String) -> Int {
        entries.first(where: { $0.cardID == cardID })?.quantity ?? 0
    }
}

@Model
class DeckEntry {
    var cardID: String
    var cardName: String
    var cardVersion: String?
    var ink: String
    var cost: Int
    var inkable: Bool?
    var cardType: String?
    var imageUrl: String
    var quantity: Int

    init(card: Card, quantity: Int = 1) {
        self.cardID = card.id
        self.cardName = card.name
        self.cardVersion = card.version
        self.ink = card.ink
        self.cost = card.cost
        self.inkable = card.inkable
        self.cardType = card.type
        self.imageUrl = card.imageUrl
        self.quantity = quantity
    }
}
