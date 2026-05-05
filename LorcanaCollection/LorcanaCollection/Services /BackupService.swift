import Foundation
import SwiftData

// MARK: - Models

struct BackupFile: Codable {
    let version: Int
    let exportDate: Date
    let cards: [CardBackup]
}

struct CardBackup: Codable {
    let id: String
    let owned: Bool
    let isFoil: Bool
    let isSigned: Bool
    let inPriorityWishlist: Bool
    let purchasePrice: Double?
    let purchaseDate: Date?
    let notes: String?
    let lastModified: Date?
}

struct BackupRestoreResult {
    let restored: Int
    let notFound: Int
}

// MARK: - Service

struct BackupService {

    // MARK: - Export

    static func createBackup(cards: [Card]) throws -> URL {
        let backupCards = cards.map { card in
            CardBackup(
                id: card.id,
                owned: card.owned,
                isFoil: card.isFoil,
                isSigned: card.isSigned,
                inPriorityWishlist: card.inPriorityWishlist,
                purchasePrice: card.purchasePrice,
                purchaseDate: card.purchaseDate,
                notes: card.notes,
                lastModified: card.lastModified
            )
        }

        let backup = BackupFile(version: 1, exportDate: Date(), cards: backupCards)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let filename = "lorcana_backup_\(dateStr).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }

    // MARK: - Restore

    static func restoreBackup(from url: URL, context: ModelContext) throws -> BackupRestoreResult {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupFile.self, from: data)

        let allCards = (try? context.fetch(FetchDescriptor<Card>())) ?? []
        let cardIndex = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })

        var restored = 0
        var notFound = 0

        for entry in backup.cards {
            guard let card = cardIndex[entry.id] else { notFound += 1; continue }

            card.owned              = entry.owned
            card.isFoil             = entry.isFoil
            card.isSigned           = entry.isSigned
            card.inPriorityWishlist = entry.inPriorityWishlist
            card.purchasePrice      = entry.purchasePrice
            card.purchaseDate       = entry.purchaseDate
            card.notes              = entry.notes
            card.lastModified       = entry.lastModified ?? Date()

            // Foil consistentie
            if card.alwaysFoil && card.owned { card.isFoil = true }

            restored += 1
        }

        try context.save()
        return BackupRestoreResult(restored: restored, notFound: notFound)
    }
}
