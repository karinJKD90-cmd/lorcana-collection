import SwiftUI
import SwiftData

struct SyncSetsView: View {
    @Environment(\.modelContext) private var context
    @Query var cards: [Card]

    @State private var isSyncing = false
    @State private var syncDone = false
    @State private var statusMessage = ""
    @State private var resultMessage = ""

    var existingSetCount: Int {
        Set(cards.map { $0.setNumber }).count
    }

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()

            VStack(spacing: 30) {
                Spacer()

                LorcanaSymbol()
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isSyncing ? 360 : 0))
                    .animation(isSyncing ? .linear(duration: 4).repeatForever(autoreverses: false) : .default, value: isSyncing)

                Text(syncDone ? "Sync complete" : "Sync sets")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.lorcanaGold)

                if isSyncing {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(Color.lorcanaGold)

                        Text(statusMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.lorcanaGoldDeep)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else if syncDone {
                    Text(resultMessage)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.lorcanaGoldLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Text("\(existingSetCount) sets already in your collection")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.lorcanaGoldDeep)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                if !isSyncing {
                    Button {
                        Task { await startSyncSets() }
                    } label: {
                        Text(syncDone ? "Check again" : "Check for new sets")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.lorcanaVoid)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.lorcanaGold)
                            .cornerRadius(10)
                    }
                }

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sync sets")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
    }

    func startSyncSets() async {
        isSyncing = true
        syncDone = false
        statusMessage = "Fetching sets..."

        let service = LorcanaAPIService()
        let result = await service.syncNewSets(context: context) { message in
            statusMessage = message
        }

        resultMessage = result
        isSyncing = false
        syncDone = true
    }
}
