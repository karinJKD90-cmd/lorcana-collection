import SwiftUI
import SwiftData

struct SinglePhotoScanView: View {
    @Environment(\.modelContext) private var context
    @Query var allCards: [Card]
    @State private var shouldCapture = false
    @State private var capturedImage: UIImage? = nil
    @State private var isAnalyzing = false
    @State private var scanResult: OCRScanResult? = nil
    @State private var showManualSearch = false

    private let ocrService = OCRScanService()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if capturedImage == nil {
                // Camera view
                LiveCameraView(capturedImage: $capturedImage, shouldCapture: $shouldCapture)
                    .ignoresSafeArea()

                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(hex: "#C9A961"), lineWidth: 2)
                    .frame(width: 280, height: 395)

                VStack {
                    HStack {
                        Spacer()
                        Text("AIM AT CARD")
                            .font(.system(size: 11)).tracking(2)
                            .foregroundStyle(Color(hex: "#C9A961"))
                        Spacer()
                    }
                    .padding(.horizontal, 24).padding(.top, 20)

                    Spacer()

                    Button { shouldCapture = true } label: {
                        ZStack {
                            Circle().strokeBorder(Color(hex: "#C9A961"), lineWidth: 2).frame(width: 64, height: 64)
                            Circle().fill(Color(hex: "#C9A961")).frame(width: 54, height: 54)
                        }
                    }
                    .padding(.bottom, 40)
                }
            } else {
                // Resultaat view
                ScrollView {
                    VStack(spacing: 24) {
                        if let img = capturedImage {
                            Image(uiImage: img)
                                .resizable().scaledToFit()
                                .frame(maxWidth: 180).cornerRadius(8)
                                .padding(.top, 40)
                        }

                        if isAnalyzing {
                            HStack(spacing: 10) {
                                ProgressView().tint(Color(hex: "#C9A961"))
                                Text("Recognizing card...")
                                    .font(.custom("Georgia", size: 13))
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                            }

                        } else if showManualSearch {
                            manualSearchView

                        } else {
                            switch scanResult {
                            case .exactMatch(let card):
                                exactMatchView(card: card)
                            case .fuzzyMatches(let candidates):
                                fuzzyMatchView(candidates: candidates)
                            case .noMatch, nil:
                                noMatchView
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Scan")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
        .onChange(of: capturedImage) { _, img in
            if img != nil { Task { await analyze() } }
        }
    }

    // MARK: - Sub-views

    func exactMatchView(card: Card) -> some View {
        VStack(spacing: 16) {
            Text("This is:")
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(Color(hex: "#8A7A4A"))

            CachedAsyncImage(urlString: card.imageUrl)
                .scaledToFit()
                .cornerRadius(8)
                .frame(maxWidth: 120)

            VStack(spacing: 4) {
                Text(card.name)
                    .font(.custom("Georgia", size: 20)).fontWeight(.medium)
                    .foregroundStyle(Color(hex: "#F4E4A1"))
                    .multilineTextAlignment(.center)
                Text("\(card.setName) · #\(card.cardNumber)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#8A7A4A"))
            }

            if card.alwaysFoil {
                Button {
                    card.markOwned()
                    try? context.save(); reset()
                } label: {
                    Text("Add (always foil)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "#0A0614"))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color(hex: "#C9A961")).cornerRadius(8)
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        card.markOwned()
                        try? context.save(); reset()
                    } label: {
                        Text("Normal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#0A0614"))
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color(hex: "#C9A961")).cornerRadius(8)
                    }
                    Button {
                        card.markOwned(); card.isFoil = true
                        try? context.save(); reset()
                    } label: {
                        Text("Foil")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#C9A961"))
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#C9A961"), lineWidth: 1))
                    }
                }
            }

            Button("That's not right") { showManualSearch = true }
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#8A7A4A"))
        }
    }

    func fuzzyMatchView(candidates: [(card: Card, score: Double)]) -> some View {
        VStack(spacing: 16) {
            Text("Did you mean one of these?")
                .font(.custom("Georgia", size: 14))
                .foregroundStyle(Color(hex: "#8A7A4A"))

            ForEach(candidates, id: \.card.id) { item in
                Button {
                    item.card.markOwned()
                    try? context.save(); reset()
                } label: {
                    HStack(spacing: 12) {
                        CachedAsyncImage(urlString: item.card.imageUrl)
                            .scaledToFit()
                            .cornerRadius(4)
                            .frame(width: 36, height: 50)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.card.name)
                                .font(.custom("Georgia", size: 14))
                                .foregroundStyle(Color(hex: "#F4E4A1"))
                            Text("\(item.card.setName) · #\(item.card.cardNumber)")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color(hex: "#C9A961"))
                            .font(.system(size: 12))
                    }
                    .padding(12)
                    .background(
                        Color.black.opacity(0.70)
                            .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6))
                    )
                }
                .buttonStyle(.plain)
            }

            Button("None of these · search manually") { showManualSearch = true }
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#8A7A4A"))
                .padding(.top, 4)
        }
    }

    var noMatchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "#3A2F5A"))
            Text("Card not recognized")
                .font(.custom("Georgia", size: 16))
                .foregroundStyle(Color(hex: "#8A7A4A"))
            Button("Search manually") { showManualSearch = true }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#0A0614"))
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color(hex: "#C9A961")).cornerRadius(8)
            Button("Scan again") { reset() }
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#8A7A4A"))
        }
    }

    var manualSearchView: some View {
        ManualCardSearchView(allCards: allCards) { card, isFoil in
            card.markOwned()
            if !card.alwaysFoil { card.isFoil = isFoil }
            try? context.save(); reset()
        } onCancel: {
            reset()
        }
    }

    // MARK: - Logic

    func analyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        guard let image = capturedImage else { return }
        let result = await ocrService.scanCard(image: image, cards: allCards, selectedSetNumber: nil)
        await MainActor.run { scanResult = result }
    }

    func reset() {
        capturedImage = nil
        scanResult = nil
        showManualSearch = false
    }
}

// MARK: - Handmatig zoeken

struct ManualCardSearchView: View {
    let allCards: [Card]
    let onSelect: (Card, Bool) -> Void
    let onCancel: () -> Void

    @State private var searchText = ""

    var filtered: [Card] {
        guard !searchText.isEmpty else { return [] }
        return allCards
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.setNumber == $1.setNumber ? $0.cardNumber < $1.cardNumber : $0.setNumber < $1.setNumber }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Search card").font(.custom("Georgia", size: 16)).foregroundStyle(Color(hex: "#F4E4A1"))

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Color(hex: "#8A7A4A"))
                TextField("name...", text: $searchText)
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(Color(hex: "#F4E4A1"))
            }
            .padding(10)
            .background(Color.black.opacity(0.70).overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)))

            ForEach(filtered) { card in
                HStack(spacing: 10) {
                    CachedAsyncImage(urlString: card.imageUrl)
                        .scaledToFit()
                        .cornerRadius(3)
                        .frame(width: 30, height: 42)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.name).font(.custom("Georgia", size: 13)).foregroundStyle(Color(hex: "#F4E4A1"))
                        Text("\(card.setName) · #\(card.cardNumber)").font(.system(size: 10)).foregroundStyle(Color(hex: "#8A7A4A"))
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Button("N") { onSelect(card, false) }
                            .font(.system(size: 11, weight: .medium)).foregroundStyle(Color(hex: "#0A0614"))
                            .frame(width: 24, height: 24).background(Color(hex: "#C9A961")).cornerRadius(4)
                        Button("F") { onSelect(card, true) }
                            .font(.system(size: 11, weight: .medium)).foregroundStyle(Color(hex: "#C9A961"))
                            .frame(width: 24, height: 24).overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color(hex: "#C9A961"), lineWidth: 1))
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.70).overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)))
            }

            Button("Cancel") { onCancel() }
                .font(.system(size: 12)).foregroundStyle(Color(hex: "#8A7A4A"))
                .padding(.top, 4)
        }
    }
}
