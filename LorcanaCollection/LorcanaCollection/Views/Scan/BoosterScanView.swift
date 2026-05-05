import SwiftUI
import SwiftData

struct BoosterScanView: View {
    @Environment(\.modelContext) private var context
    @Query var allCards: [Card]
    @State private var step: Step = .selectSet
    @State private var selectedSetNumber = 1
    @State private var scannedCards: [(card: Card, isFoil: Bool)] = []
    @State private var shouldCapture = false
    @State private var capturedImage: UIImage? = nil
    @State private var isAnalyzing = false
    @State private var pendingResult: OCRScanResult? = nil
    @State private var flashCard: Card? = nil
    @State private var flashOpacity: Double = 0

    private let ocrService = OCRScanService()

    enum Step { case selectSet, scanning, resolving, review }

    var availableSets: [(Int, String)] {
        Dictionary(grouping: allCards) { $0.setNumber }
            .map { ($0.key, $0.value.first?.setName ?? "") }
            .filter { $0.0 > 0 }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        ZStack {
            if step == .scanning {
                LiveCameraView(capturedImage: $capturedImage, shouldCapture: $shouldCapture)
                    .ignoresSafeArea()
            } else {
                SwirlBackground()
            }

            switch step {
            case .selectSet:   boosterSetPicker
            case .scanning:    boosterScanning
            case .resolving:   boosterResolving
            case .review:      boosterReview
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Bulk scan")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
        .onChange(of: capturedImage) { _, img in
            if img != nil { Task { await analyze() } }
        }
    }

    // MARK: - Set picker

    var boosterSetPicker: some View {
        VStack(spacing: 0) {
            Text("from which set?").font(.system(size: 11)).tracking(1)
                .foregroundStyle(Color(hex: "#8A7A4A")).padding(.top, 20)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(availableSets, id: \.0) { set in
                        Button {
                            selectedSetNumber = set.0
                            step = .scanning
                        } label: {
                            HStack(spacing: 12) {
                                LorcanaSymbol().frame(width: 20, height: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SET \(String(format: "%02d", set.0))").font(.system(size: 9)).tracking(1).foregroundStyle(Color(hex: "#8A7A4A"))
                                    Text(set.1).font(.custom("Georgia", size: 13)).foregroundStyle(Color(hex: "#F4E4A1"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Color(hex: "#C9A961"))
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.70).overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Scanning

    var boosterScanning: some View {
        ZStack {
            // Kaartframe overlay
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(hex: "#C9A961"), lineWidth: 2)
                .frame(width: 280, height: 395)

            // Flash: herkende kaart — tik om ongedaan te maken
            if let card = flashCard {
                Button {
                    if let idx = scannedCards.lastIndex(where: { $0.card.id == card.id }) {
                        scannedCards.remove(at: idx)
                    }
                    withAnimation(.easeOut(duration: 0.2)) { flashOpacity = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { flashCard = nil }
                } label: {
                    VStack(spacing: 12) {
                        Text("Found!")
                            .font(.custom("Georgia", size: 22))
                            .italic()
                            .foregroundStyle(Color(hex: "#C9A961"))
                            .shadow(color: Color(hex: "#C9A961").opacity(0.5), radius: 8)

                        CachedAsyncImage(urlString: card.imageUrl)
                            .scaledToFit()
                            .shadow(color: Color(hex: "#C9A961").opacity(0.7), radius: 20)
                            .frame(width: 220, height: 308)

                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "#3A9D5D"))
                            Text(card.name)
                                .font(.custom("Georgia", size: 14))
                                .foregroundStyle(Color(hex: "#F4E4A1"))
                        }

                        Text("tap to undo")
                            .font(.system(size: 9))
                            .tracking(1)
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                    }
                }
                .buttonStyle(.plain)
                .opacity(flashOpacity)
                .scaleEffect(flashOpacity == 1 ? 1 : 0.85)
                .transition(.opacity)
            }

            VStack {
                HStack {
                    Button { step = .selectSet } label: {
                        Image(systemName: "xmark").foregroundStyle(Color(hex: "#C9A961"))
                    }
                    Spacer()
                    Text("BULK · SET \(String(format: "%02d", selectedSetNumber))")
                        .font(.system(size: 10)).tracking(2).foregroundStyle(Color(hex: "#C9A961"))
                    Spacer()
                    // Klaar-knop: groter met checkmark
                    Button { step = .review } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Done")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: "#0A0614"))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color(hex: "#C9A961"))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20)

                Spacer()

                if isAnalyzing {
                    ProgressView().tint(Color(hex: "#C9A961"))
                        .padding(.bottom, 8)
                }

                VStack(spacing: 8) {
                    Text("SCANNED · \(scannedCards.count)")
                        .font(.system(size: 10)).tracking(2).foregroundStyle(Color(hex: "#C9A961"))
                    Button {
                        shouldCapture = true
                    } label: {
                        ZStack {
                            Circle().strokeBorder(Color(hex: "#C9A961"), lineWidth: 2).frame(width: 64, height: 64)
                            Circle().fill(Color(hex: "#C9A961")).frame(width: 54, height: 54)
                        }
                    }
                    .disabled(isAnalyzing)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Resolving (fuzzy / noMatch)

    var boosterResolving: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: "#0A0614").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Which card is this?")
                        .font(.custom("Georgia", size: 18))
                        .foregroundStyle(Color(hex: "#F4E4A1"))
                        .padding(.top, 40)

                    switch pendingResult {
                    case .fuzzyMatches(let candidates):
                        ForEach(candidates, id: \.card.id) { item in
                            Button {
                                scannedCards.append((card: item.card, isFoil: item.card.alwaysFoil))
                                continueScan()
                            } label: {
                                HStack(spacing: 12) {
                                    CachedAsyncImage(urlString: item.card.imageUrl)
                                        .scaledToFit()
                                        .cornerRadius(4)
                                        .frame(width: 40, height: 56)

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
                                }
                                .padding(12)
                                .background(
                                    Color.black.opacity(0.70)
                                        .overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6))
                                )
                            }
                            .buttonStyle(.plain)
                        }

                    default:
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(hex: "#3A2F5A"))
                        Text("Card not recognized")
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(Color(hex: "#8A7A4A"))
                    }

                    // Handmatig zoeken
                    boosterManualSearch

                    Button("Skip") { continueScan() }
                        .font(.system(size: 12)).foregroundStyle(Color(hex: "#8A7A4A"))
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }

            // Camera-knop rechtsboven
            Button { continueScan() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13))
                    Text("Camera")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#0A0614"))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color(hex: "#C9A961"))
                .cornerRadius(10)
            }
            .padding(.top, 56)
            .padding(.trailing, 16)
        }
    }

    var boosterManualSearch: some View {
        ManualCardSearchView(allCards: allCards) { card, isFoil in
            scannedCards.append((card: card, isFoil: isFoil))
            continueScan()
        } onCancel: {
            continueScan()
        }
    }

    // MARK: - Review

    var boosterReview: some View {
        VStack(spacing: 0) {
            Text("\(scannedCards.count) cards · swipe to remove")
                .font(.system(size: 10)).tracking(1)
                .foregroundStyle(Color(hex: "#8A7A4A")).padding(.vertical, 10)

            List {
                ForEach(scannedCards.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        CachedAsyncImage(urlString: scannedCards[i].card.imageUrl)
                            .scaledToFit()
                            .cornerRadius(3)
                            .frame(width: 34, height: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(scannedCards[i].card.name)
                                .font(.custom("Georgia", size: 13)).fontWeight(.medium)
                                .foregroundStyle(Color(hex: "#F4E4A1"))
                            Text("#\(scannedCards[i].card.cardNumber) · \(scannedCards[i].card.setName)")
                                .font(.system(size: 10)).foregroundStyle(Color(hex: "#8A7A4A"))
                        }

                        Spacer()

                        if scannedCards[i].card.alwaysFoil {
                            Text("F")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(hex: "#0A0614"))
                                .frame(width: 22, height: 22)
                                .background(Color(hex: "#C9A961"))
                                .cornerRadius(4)
                        } else {
                            HStack(spacing: 4) {
                                Button { scannedCards[i].isFoil = false } label: {
                                    Text("N").font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(!scannedCards[i].isFoil ? Color(hex: "#0A0614") : Color(hex: "#8A7A4A"))
                                        .frame(width: 22, height: 22)
                                        .background(!scannedCards[i].isFoil ? Color(hex: "#C9A961") : Color.black.opacity(0.6))
                                        .cornerRadius(4)
                                }
                                Button { scannedCards[i].isFoil = true } label: {
                                    Text("F").font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(scannedCards[i].isFoil ? Color(hex: "#0A0614") : Color(hex: "#8A7A4A"))
                                        .frame(width: 22, height: 22)
                                        .background(scannedCards[i].isFoil ? Color(hex: "#C9A961") : Color.black.opacity(0.6))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.black.opacity(0.6))
                    .listRowSeparatorTint(Color(hex: "#3A2F5A"))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { scannedCards.remove(at: i) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#0A0614"))

            HStack(spacing: 16) {
                Button("Cancel") { step = .scanning }
                    .font(.system(size: 13)).foregroundStyle(Color(hex: "#8A7A4A"))
                Button("Confirm & add to collection") { saveAll() }
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Color(hex: "#0A0614"))
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color(hex: "#C9A961")).cornerRadius(10)
            }
            .padding()
            .background(Color(hex: "#0A0614"))
        }
    }

    // MARK: - Logic

    func analyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false; capturedImage = nil }

        guard let image = capturedImage else { return }
        let result = await ocrService.scanCard(image: image, cards: allCards, selectedSetNumber: selectedSetNumber)

        await MainActor.run {
            switch result {
            case .exactMatch(let card):
                scannedCards.append((card: card, isFoil: card.alwaysFoil))
                print("✅ \(card.name) toegevoegd")
                showFlash(for: card)
            case .fuzzyMatches, .noMatch:
                pendingResult = result
                step = .resolving
            }
        }
    }

    func showFlash(for card: Card) {
        flashCard = card
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { flashOpacity = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { flashCard = nil }
        }
    }

    func continueScan() {
        pendingResult = nil
        step = .scanning
    }

    func saveAll() {
        for item in scannedCards {
            item.card.markOwned()
            if !item.card.alwaysFoil { item.card.isFoil = item.isFoil }
        }
        try? context.save()
    }
}
