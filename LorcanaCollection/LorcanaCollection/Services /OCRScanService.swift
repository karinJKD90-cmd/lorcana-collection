import Foundation
import Vision
import UIKit

// MARK: - Result type

enum OCRScanResult {
    case exactMatch(card: Card)
    case fuzzyMatches(candidates: [(card: Card, score: Double)])
    case noMatch
}

// MARK: - OCR observation met positie

private struct TextObservation {
    let text: String
    let midY: CGFloat  // 0 = onderkant, 1 = bovenkant (Vision coords)
    let midX: CGFloat
}

// MARK: - Service

class OCRScanService {

    // MARK: - Public API

    func scanCard(image: UIImage, cards: [Card], selectedSetNumber: Int?) async -> OCRScanResult {
        let observations = await recognizeTextWithPositions(in: image)

        // Log ALLE observaties met positie zodat we de layout kunnen kalibreren
        print("━━━ OCR DUMP ━━━")
        for obs in observations.sorted(by: { $0.midY > $1.midY }) {
            print(String(format: "  y=%.2f x=%.2f  '%@'", obs.midY, obs.midX, obs.text))
        }
        print("━━━━━━━━━━━━━━━━")

        // Stap 1: Kaartnummer + set
        // De onderkant van een Lorcana-kaart bevat "40/204 – EN – 10"
        // met zowel kaartnummer als setnummer in één regel (y ≈ 0.30–0.38)
        let bottomObs  = observations.filter { $0.midY < 0.40 }
        let bottomLeft = observations.filter { $0.midY < 0.40 && $0.midX < 0.55 }
        let (cardNum, setNum) = extractCardAndSetNumber(
            bottomObservations: bottomObs,
            bottomLeftObservations: bottomLeft,
            selectedSetNumber: selectedSetNumber
        )

        // Stap 2: Naam — staat in de gekleurde ink-balk net boven de kaartnummer-regel
        // Op basis van de dump: y ≈ 0.34–0.42, ALL CAPS, kort (1–3 woorden)
        // Probeer zones van smal naar breed
        let nameZones: [(CGFloat, CGFloat)] = [(0.33, 0.42), (0.30, 0.48), (0.28, 0.55)]
        var ocrName: String? = nil
        for (lo, hi) in nameZones {
            let zone = observations.filter { $0.midY >= lo && $0.midY <= hi }
            if let name = extractCardName(from: zone) {
                ocrName = name
                print("📛 Naam gevonden in zone y=\(lo)–\(hi): '\(name)'")
                break
            }
        }

        print("🔢 Kaartnummer: \(cardNum.map(String.init) ?? "?")  Set: \(setNum.map(String.init) ?? "?")  Naam: \(ocrName ?? "?")")

        return resolve(
            cardNum: cardNum,
            setNum: setNum,
            ocrName: ocrName,
            cards: cards,
            selectedSetNumber: selectedSetNumber
        )
    }

    // MARK: - OCR met bounding boxes

    private func recognizeTextWithPositions(in image: UIImage) async -> [TextObservation] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let obs = results.compactMap { r -> TextObservation? in
                    guard let text = r.topCandidates(1).first?.string else { return nil }
                    return TextObservation(text: text, midY: r.boundingBox.midY, midX: r.boundingBox.midX)
                }
                continuation.resume(returning: obs)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }

    // MARK: - Extraheer kaartnummer + setnummer

    private func extractCardAndSetNumber(
        bottomObservations: [TextObservation],
        bottomLeftObservations: [TextObservation],
        selectedSetNumber: Int?
    ) -> (cardNum: Int?, setNum: Int?) {

        var cardNum: Int? = nil
        var setFromCard: Int? = nil

        for obs in bottomObservations {
            let text = obs.text

            // Formaat: "40/204 – EN – 10"  of  "40/204"
            // Groep 1 = kaartnummer, groep 2 = totaal, groep 3 (optioneel) = setnummer achteraan
            let fullPattern = #"(\d{1,3})\s*[/\\]\s*(\d{2,3})(?:\s*[-–—]\s*[A-Z]{2}\s*[-–—]\s*(\d{1,2}))?"#
            guard let regex = try? NSRegularExpression(pattern: fullPattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
            else { continue }

            if let r1 = Range(match.range(at: 1), in: text) {
                cardNum = Int(text[r1])
            }
            // Setnummer na "– EN –"
            if match.range(at: 3).location != NSNotFound,
               let r3 = Range(match.range(at: 3), in: text) {
                setFromCard = Int(text[r3])
            }

            print("🃏 Gevonden: kaart=\(cardNum ?? -1)  set=\(setFromCard ?? -1)  uit '\(text)'")
            break
        }

        // Fallback setnummer: standalone klein getal linksonder
        if setFromCard == nil {
            for obs in (bottomLeftObservations + bottomObservations).sorted(by: { $0.midX < $1.midX }) {
                let s = obs.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if let n = Int(s), n >= 1, n <= 20, n != cardNum {
                    setFromCard = n
                    print("🏷️ Setnummer fallback: \(n)")
                    break
                }
            }
        }

        return (cardNum, setFromCard ?? selectedSetNumber)
    }

    // MARK: - Extraheer kaartnaam

    private func extractCardName(from observations: [TextObservation]) -> String? {
        let blocked: Set<String> = ["INK", "COST", "LORE", "STR", "WILL",
                                    "ENCHANTED", "PROMO", "ITEM", "ACTION",
                                    "CHARACTER", "SONG", "LOCATION", "EN", "FR", "DE"]
        let abilityKeywords = ["challenger", "evasive", "rush", "ward", "reckless",
                               "bodyguard", "support", "shift", "resist", "vanish"]

        // Lorcana kaartnamen staan in de ink-balk: ALL CAPS, 2–30 tekens, geen +/•/–
        let allCaps = observations
            .map(\.text)
            .filter { t in
                guard t.count >= 2, t.count <= 35 else { return false }
                guard !blocked.contains(t.uppercased()) else { return false }
                guard t.contains(where: { $0.isLetter }) else { return false }
                // Geen ability-symbolen
                let hasSpecial = t.contains("+") || t.contains("•") || t.contains("–") || t.contains("(")
                guard !hasSpecial else { return false }
                // Geen ability-keywords
                let lower = t.lowercased()
                guard !abilityKeywords.contains(where: { lower.hasPrefix($0) }) else { return false }
                // Geef voorkeur aan ALL CAPS (naam) boven mixed (subtype/flavor)
                let letters = t.filter { $0.isLetter }
                let isAllCaps = letters.allSatisfy { $0.isUppercase }
                return isAllCaps
            }
            .sorted { $0.count > $1.count }  // kortere ALL CAPS = waarschijnlijker naam

        if let name = allCaps.first {
            return name
        }

        // Fallback: mixed case, maar kort en zonder speciale tekens
        let mixedFallback = observations
            .map(\.text)
            .filter { t in
                guard t.count >= 2, t.count <= 30 else { return false }
                guard !blocked.contains(t.uppercased()) else { return false }
                guard t.contains(where: { $0.isLetter }) else { return false }
                let hasSpecial = t.contains("+") || t.contains("•") || t.contains("–") || t.contains("(")
                guard !hasSpecial else { return false }
                let lower = t.lowercased()
                return !abilityKeywords.contains(where: { lower.hasPrefix($0) })
            }
            .sorted { $0.count < $1.count }  // kortste = meest waarschijnlijk naam

        return mixedFallback.first
    }

    // MARK: - Resolve

    private func resolve(
        cardNum: Int?,
        setNum: Int?,
        ocrName: String?,
        cards: [Card],
        selectedSetNumber: Int?
    ) -> OCRScanResult {

        let effectiveSet = setNum ?? selectedSetNumber
        let pool = effectiveSet.map { s in cards.filter { $0.setNumber == s } } ?? cards

        // Pad A: kaartnummer bekend
        if let num = cardNum, let card = pool.first(where: { $0.cardNumber == num }) {
            if let name = ocrName {
                let sim = stringSimilarity(name.lowercased(), card.name.lowercased())
                print("🔍 Naamcheck '\(name)' vs '\(card.name)': \(String(format: "%.2f", sim))")
                if sim >= 0.55 {
                    print("✅ Nummer + naam bevestigd: \(card.name)")
                    return .exactMatch(card: card)
                } else {
                    print("⚠️ Naam past niet, cross-check op naam in set")
                    return resolveByNameWithNumberHint(ocrName: name, ocrCardNum: num, pool: pool, fallbackCard: card)
                }
            }
            print("✅ Match op nummer (geen naam beschikbaar): \(card.name)")
            return .exactMatch(card: card)
        }

        // Pad B: alleen naam
        if let name = ocrName {
            return fuzzySearchByName(name: name, pool: pool)
        }

        return .noMatch
    }

    private func resolveByNameWithNumberHint(
        ocrName: String,
        ocrCardNum: Int,
        pool: [Card],
        fallbackCard: Card
    ) -> OCRScanResult {
        let scored: [(card: Card, score: Double)] = pool.compactMap { card in
            var score = stringSimilarity(ocrName.lowercased(), card.name.lowercased())
            let diff = abs(card.cardNumber - ocrCardNum)
            if diff == 0 { score += 0.10 } else if diff <= 2 { score += 0.05 }
            return score >= 0.50 ? (card, min(score, 1.0)) : nil
        }.sorted { $0.score > $1.score }

        guard !scored.isEmpty else {
            return .fuzzyMatches(candidates: [(fallbackCard, 0.50)])
        }
        if scored[0].score >= 0.85 {
            print("✅ Cross-check naam match: \(scored[0].card.name)")
            return .exactMatch(card: scored[0].card)
        }
        return .fuzzyMatches(candidates: Array(scored.prefix(3)))
    }

    private func fuzzySearchByName(name: String, pool: [Card]) -> OCRScanResult {
        let scored: [(card: Card, score: Double)] = pool.compactMap { card in
            let s = stringSimilarity(name.lowercased(), card.name.lowercased())
            return s >= 0.60 ? (card, s) : nil
        }.sorted { $0.score > $1.score }

        guard !scored.isEmpty else { return .noMatch }
        if scored[0].score >= 0.90 { return .exactMatch(card: scored[0].card) }
        return .fuzzyMatches(candidates: Array(scored.prefix(3)))
    }

    // MARK: - Levenshtein

    private func stringSimilarity(_ a: String, _ b: String) -> Double {
        let a = Array(a), b = Array(b)
        let m = a.count, n = b.count
        if m == 0 { return n == 0 ? 1.0 : 0.0 }
        if n == 0 { return 0.0 }
        var prev = Array(0...n), curr = Array(repeating: 0, count: n + 1)
        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                curr[j] = a[i-1] == b[j-1] ? prev[j-1] : 1 + min(prev[j], min(curr[j-1], prev[j-1]))
            }
            swap(&prev, &curr)
        }
        return 1.0 - Double(prev[n]) / Double(max(m, n))
    }
}
