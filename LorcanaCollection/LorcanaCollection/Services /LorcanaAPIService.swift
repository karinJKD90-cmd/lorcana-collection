import Foundation
import Combine
import SwiftData

// MARK: - Lorcast API modellen

struct LorcastSet: Codable {
    let id: String
    let code: String
    let name: String
    let language: String?
}

struct LorcastSetsResponse: Codable {
    let results: [LorcastSet]
}

struct LorcastCard: Codable {
    let id: String
    let name: String
    let version: String?
    let collector_number: String
    let set: LorcastSet
    let rarity: String
    let ink: String?
    let cost: Int?
    let strength: Int?
    let willpower: Int?
    let lore: Int?
    let inkable: Bool?
    let type: [String]
    let body_text: String?
    let flavor_text: String?
    let image_uris: ImageUris?
    let prices: Prices?

    struct ImageUris: Codable {
        let digital: DigitalImages?

        struct DigitalImages: Codable {
            let small: String?
            let normal: String?
            let large: String?
        }

        init(from decoder: Decoder) throws {
            let container = try? decoder.container(keyedBy: CodingKeys.self)
            digital = try? container?.decodeIfPresent(DigitalImages.self, forKey: .digital)
        }

        enum CodingKeys: String, CodingKey {
            case digital
        }
    }

    struct Prices: Codable {
        let usd: Double?
        let usd_foil: Double?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let usdString = try? container.decodeIfPresent(String.self, forKey: .usd) {
                usd = Double(usdString)
            } else {
                usd = try? container.decodeIfPresent(Double.self, forKey: .usd)
            }
            if let foilString = try? container.decodeIfPresent(String.self, forKey: .usd_foil) {
                usd_foil = Double(foilString)
            } else {
                usd_foil = try? container.decodeIfPresent(Double.self, forKey: .usd_foil)
            }
        }

        enum CodingKeys: String, CodingKey {
            case usd
            case usd_foil
        }
    }
}

// MARK: - Service

@MainActor
class LorcanaAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var loadingMessage = ""
    @Published var error: String?

    private let baseURL = "https://api.lorcast.com/v0"

    // Controleer of een set Engels is
    private func isEnglishSet(_ set: LorcastSet) -> Bool {
        let lang = set.language?.lowercased() ?? ""
        let blockedCodes = ["ZH", "JA", "PR", "PROMO", "FR", "DE", "IT", "PT"]
        guard !blockedCodes.contains(set.code.uppercased()) else { return false }
        // Expliciete niet-EN talen uitsluiten; lege language alleen toestaan als code numeriek is
        if ["zh", "ja", "fr", "de", "it", "pt", "ko"].contains(lang) { return false }
        if !lang.isEmpty && lang != "en" { return false }
        return true
    }

    // Controleer of een kaart vanuit de API Engels is
    private func isEnglishCard(_ apiCard: LorcastCard) -> Bool {
        let lang = apiCard.set.language?.lowercased() ?? ""
        if ["zh", "ja", "fr", "de", "it", "pt", "ko"].contains(lang) { return false }
        if !lang.isEmpty && lang != "en" { return false }
        return true
    }

    func syncCards(context: ModelContext) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            loadingMessage = "Sets ophalen..."
            let sets = try await fetchSets()
            print("✅ \(sets.count) sets gevonden")

            // Dictionary voor snelle lookup én updates van bestaande kaarten
            var existingCards: [String: Card] = Dictionary(
                uniqueKeysWithValues: (try? context.fetch(FetchDescriptor<Card>()))?.map { ($0.id, $0) } ?? []
            )

            var totalAdded = 0
            var totalUpdated = 0

            let enSets = sets.filter { isEnglishSet($0) }
            print("🌍 \(enSets.count) Engelse sets (van \(sets.count) totaal)")

            for set in enSets {
                loadingMessage = "Laden: \(set.name)..."
                print("📦 Laden: \(set.name)")

                let cards = try await fetchCards(forSet: set.code)

                for apiCard in cards {
                    guard isEnglishCard(apiCard) else { continue }

                    if let existing = existingCards[apiCard.id] {
                        // Bestaande kaart: update metadata, laat user-data ongemoeid
                        updateMetadata(of: existing, from: apiCard)
                        totalUpdated += 1
                    } else {
                        // Nieuwe kaart: aanmaken en toevoegen
                        let card = makeCard(from: apiCard)
                        context.insert(card)
                        existingCards[apiCard.id] = card
                        totalAdded += 1
                    }
                }

                try context.save()
                print("✅ \(set.name): klaar")
            }

            loadingMessage = "Deck entries bijwerken..."
            syncDeckEntries(context: context)

            loadingMessage = "Klaar! \(totalAdded) nieuw · \(totalUpdated) bijgewerkt"
            print("✅ Totaal: \(totalAdded) toegevoegd, \(totalUpdated) bijgewerkt")

        } catch {
            self.error = "Fout: \(error.localizedDescription)"
            print("❌ Fout: \(error)")
        }
    }

    /// Werkt API-velden bij op een bestaande kaart zonder user-data aan te raken.
    private func updateMetadata(of card: Card, from api: LorcastCard) {
        card.name      = api.name
        card.version   = api.version
        card.rarity    = api.rarity
        card.ink       = api.ink ?? card.ink
        card.cost      = api.cost ?? card.cost
        card.strength  = api.strength
        card.willpower = api.willpower
        card.lore      = api.lore
        card.inkable   = api.inkable
        card.bodyText  = api.body_text
        card.type      = api.type.first ?? card.type
        if let url = api.image_uris?.digital?.normal { card.imageUrl = url }
        if let price = api.prices?.usd {
            card.currentPriceNormal = price
            card.lastPriceUpdate = Date()
        }
        if let foil = api.prices?.usd_foil { card.currentPriceFoil = foil }
    }

    /// Maakt een nieuwe Card aan vanuit API-data.
    private func makeCard(from api: LorcastCard) -> Card {
        let card = Card(
            id: api.id,
            name: api.name,
            setName: api.set.name,
            setNumber: Int(api.set.code) ?? 0,
            cardNumber: Int(api.collector_number) ?? 0,
            rarity: api.rarity,
            ink: api.ink ?? "None",
            cost: api.cost ?? 0,
            type: api.type.first ?? "Character",
            imageUrl: api.image_uris?.digital?.normal ?? ""
        )
        card.version   = api.version
        card.lore      = api.lore
        card.strength  = api.strength
        card.willpower = api.willpower
        card.inkable   = api.inkable
        card.bodyText  = api.body_text
        card.currentPriceNormal = api.prices?.usd
        card.currentPriceFoil   = api.prices?.usd_foil
        if api.prices?.usd != nil { card.lastPriceUpdate = Date() }
        return card
    }

    // Verwijder niet-EN kaarten die al in de database staan
    func removeNonEnglishCards(context: ModelContext) -> Int {
        guard let allCards = try? context.fetch(FetchDescriptor<Card>()) else { return 0 }
        let blockedSubstrings = ["-ZH-", "-JA-", "-FR-", "-DE-", "-IT-", "-PT-", "-KO-"]
        var removed = 0
        for card in allCards {
            // Verwijder kaarten zonder collectie-waarde waarvan het ID een niet-EN taalcode bevat
            if !card.owned, blockedSubstrings.contains(where: { card.id.uppercased().contains($0) }) {
                context.delete(card)
                removed += 1
            }
        }
        try? context.save()
        return removed
    }

    // MARK: - Sync new sets

    func syncNewSets(context: ModelContext, progress: @escaping (String) -> Void) async -> String {
        do {
            progress("Sets ophalen...")
            let sets = try await fetchSets()
            let enSets = sets.filter { isEnglishSet($0) }

            // Bouw een volledige kaartindex eenmalig op
            var existingCards: [String: Card] = Dictionary(
                uniqueKeysWithValues: (try? context.fetch(FetchDescriptor<Card>()))?.map { ($0.id, $0) } ?? []
            )

            var totalAdded = 0
            var totalUpdated = 0

            for set in enSets {
                progress("Controleren: \(set.name)...")

                let cards = try await fetchCards(forSet: set.code)
                var setChanged = false

                for apiCard in cards {
                    guard isEnglishCard(apiCard) else { continue }

                    if let existing = existingCards[apiCard.id] {
                        // Bestaande kaart: update metadata
                        updateMetadata(of: existing, from: apiCard)
                        totalUpdated += 1
                        setChanged = true
                    } else {
                        // Ontbrekende kaart: toevoegen
                        let card = makeCard(from: apiCard)
                        context.insert(card)
                        existingCards[apiCard.id] = card
                        totalAdded += 1
                        setChanged = true
                    }
                }

                if setChanged {
                    try context.save()
                }
            }

            syncDeckEntries(context: context)

            if totalAdded == 0 && totalUpdated == 0 {
                return "Alles up-to-date"
            }
            return "\(totalAdded) kaarten toegevoegd · \(totalUpdated) bijgewerkt"

        } catch {
            return "Fout: \(error.localizedDescription)"
        }
    }

    // MARK: - Deck entry sync

    /// Werkt alle DeckEntry-velden bij vanuit de actuele Card-data.
    /// Aanroepen na elke card sync zodat decks altijd de juiste metadata hebben.
    func syncDeckEntries(context: ModelContext) {
        guard let entries = try? context.fetch(FetchDescriptor<DeckEntry>()),
              let cards = try? context.fetch(FetchDescriptor<Card>()) else { return }

        let cardLookup: [String: Card] = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })

        for entry in entries {
            guard let card = cardLookup[entry.cardID] else { continue }
            entry.cardName    = card.name
            entry.cardVersion = card.version
            entry.ink         = card.ink
            entry.cost        = card.cost
            entry.inkable     = card.inkable
            entry.cardType    = card.type
            entry.imageUrl    = card.imageUrl
        }

        try? context.save()
    }

    // MARK: - Private helpers

    private func fetchSets() async throws -> [LorcastSet] {
        guard let url = URL(string: "\(baseURL)/sets") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(LorcastSetsResponse.self, from: data)
        return response.results
    }

    private func fetchCards(forSet setCode: String) async throws -> [LorcastCard] {
        let urlString = "\(baseURL)/sets/\(setCode)/cards"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)

        if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = jsonObj["results"] as? [[String: Any]] {
            return decodeCards(from: results)
        }

        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return decodeCards(from: jsonArray)
        }

        print("⚠️ Set \(setCode): onverwacht formaat, overgeslagen")
        return []
    }

    private func decodeCards(from jsonArray: [[String: Any]]) -> [LorcastCard] {
        var cards: [LorcastCard] = []
        for item in jsonArray {
            guard let cardData = try? JSONSerialization.data(withJSONObject: item),
                  let card = try? JSONDecoder().decode(LorcastCard.self, from: cardData) else {
                continue
            }
            cards.append(card)
        }
        return cards
    }
}
