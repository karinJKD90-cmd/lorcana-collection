import Foundation
import SwiftData

struct ImportResult {
    let updated: Int
    let notFound: Int
    let malformed: Int
}

enum CSVError: LocalizedError {
    case invalidFormat(String)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let msg): return "Ongeldig CSV-formaat: \(msg)"
        case .unreadable: return "Bestand kon niet worden gelezen"
        }
    }
}

struct CSVService {

    // MARK: - Header

    private static let header = "id,name,setName,setNumber,cardNumber,rarity,ink,owned,isFoil,isSigned,inPriorityWishlist,purchasePrice,purchaseDate,notes"

    // MARK: - Export

    static func exportCollection(_ cards: [Card]) -> String {
        buildCSV(cards.filter { $0.owned }.sorted { $0.setNumber == $1.setNumber ? $0.cardNumber < $1.cardNumber : $0.setNumber < $1.setNumber })
    }

    static func exportWishlist(_ cards: [Card]) -> String {
        buildCSV(cards.filter { $0.inPriorityWishlist && !$0.owned }.sorted { ($0.currentPriceNormal ?? 0) > ($1.currentPriceNormal ?? 0) })
    }

    private static func buildCSV(_ cards: [Card]) -> String {
        var rows = [header]
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        for card in cards {
            let purchaseDateStr = card.purchaseDate.map { dateFormatter.string(from: $0) } ?? ""
            let row = [
                csvField(card.id),
                csvField(card.name),
                csvField(card.setName),
                "\(card.setNumber)",
                "\(card.cardNumber)",
                csvField(card.rarity),
                csvField(card.ink),
                card.owned ? "1" : "0",
                card.isFoil ? "1" : "0",
                card.isSigned ? "1" : "0",
                card.inPriorityWishlist ? "1" : "0",
                card.purchasePrice.map { String(format: "%.2f", $0) } ?? "",
                purchaseDateStr,
                csvField(card.notes)
            ].joined(separator: ",")
            rows.append(row)
        }
        return rows.joined(separator: "\n")
    }

    /// Quote a string field; doubles any internal quotes.
    private static func csvField(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else { return "" }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        // Only quote if the value contains commas, quotes, or newlines
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    // MARK: - Import

    static func importCollection(csv: String, context: ModelContext) throws -> ImportResult {
        var lines = csv.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .init(charactersIn: "\r")) }.filter { !$0.isEmpty }
        guard !lines.isEmpty else { throw CSVError.invalidFormat("leeg bestand") }

        // Validate header
        let firstTokens = parseRow(lines[0])
        guard firstTokens.first == "id" else { throw CSVError.invalidFormat("eerste kolom moet 'id' zijn") }
        lines.removeFirst()

        // Fetch all cards once for O(1) lookup
        let allCards = (try? context.fetch(FetchDescriptor<Card>())) ?? []
        let cardIndex = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        var updated = 0, notFound = 0, malformed = 0

        for line in lines {
            let tokens = parseRow(line)
            guard tokens.count >= 14 else { malformed += 1; continue }

            let id = tokens[0]
            guard let card = cardIndex[id] else { notFound += 1; continue }

            card.owned              = tokens[7] == "1"
            card.isFoil             = tokens[8] == "1"
            card.isSigned           = tokens[9] == "1"
            card.inPriorityWishlist = tokens[10] == "1"
            card.purchasePrice      = Double(tokens[11])
            card.purchaseDate       = tokens[12].isEmpty ? nil : dateFormatter.date(from: tokens[12])
            card.notes              = tokens[13].isEmpty ? nil : tokens[13]
            card.lastModified       = Date()

            // Enforce alwaysFoil consistency
            if card.alwaysFoil && card.owned { card.isFoil = true }

            updated += 1
        }

        try context.save()
        return ImportResult(updated: updated, notFound: notFound, malformed: malformed)
    }

    // MARK: - CSV tokenizer (handles quoted fields with "" escapes)

    private static func parseRow(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let ch = line[i]
            if inQuotes {
                if ch == "\"" {
                    let next = line.index(after: i)
                    if next < line.endIndex && line[next] == "\"" {
                        // Escaped quote
                        current.append("\"")
                        i = line.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == "," {
                    tokens.append(current)
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            i = line.index(after: i)
        }
        tokens.append(current)
        return tokens
    }
}
