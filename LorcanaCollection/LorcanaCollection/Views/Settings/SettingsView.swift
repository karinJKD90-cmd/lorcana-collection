import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allCards: [Card]

    @State private var showCleanupConfirm = false
    @State private var cleanupResult: String? = nil

    @State private var showImporter = false
    @State private var importResult: ImportResult? = nil
    @State private var importError: String? = nil
    @State private var showImportError = false
    @State private var isImporting = false

    @State private var showBackupRestorer = false
    @State private var backupResult: BackupRestoreResult? = nil
    @State private var isRestoring = false

    private let apiService = LorcanaAPIService()

    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    // MARK: Synchronisatie
                    SectionLabel(title: "sync")
                        .padding(.horizontal, 18)
                        .padding(.bottom, 17)

                    VStack(spacing: 12) {
                        NavigationLink(destination: SyncView()) {
                            ScanOptionTile(icon: "dollarsign.circle", title: "Sync prices", subtitle: "update card values")
                        }.buttonStyle(.plain)

                        NavigationLink(destination: SyncSetsView()) {
                            ScanOptionTile(icon: "arrow.down.circle", title: "Sync sets", subtitle: "add missing cards")
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)

                    Spacer().frame(height: 32)

                    // MARK: Back-up
                    SectionLabel(title: "back-up")
                        .padding(.horizontal, 18)
                        .padding(.bottom, 17)

                    VStack(spacing: 12) {
                        Button {
                            makeBackup()
                        } label: {
                            ScanOptionTile(
                                icon: "externaldrive",
                                title: "Create backup",
                                subtitle: "exports full collection status as JSON"
                            )
                        }.buttonStyle(.plain)

                        Button {
                            showBackupRestorer = true
                        } label: {
                            ScanOptionTile(
                                icon: "externaldrive.badge.plus",
                                title: "Restore backup",
                                subtitle: "imports a previously created backup"
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isRestoring)

                        if isRestoring {
                            HStack(spacing: 8) {
                                ProgressView().tint(Color(hex: "#C9A961"))
                                Text("Restoring...")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                            }
                        }

                        if let result = backupResult {
                            VStack(alignment: .leading, spacing: 4) {
                                importResultRow(icon: "checkmark.circle", color: "#3A9D5D", label: "\(result.restored) cards restored")
                                if result.notFound > 0 {
                                    importResultRow(icon: "questionmark.circle", color: "#E8A923", label: "\(result.notFound) not found in database")
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 18)

                    Spacer().frame(height: 32)

                    // MARK: Export / Import
                    SectionLabel(title: "export / import")
                        .padding(.horizontal, 18)
                        .padding(.bottom, 17)

                    VStack(spacing: 12) {
                        Button {
                            exportCSV(filename: "lorcana_collectie.csv",
                                      csv: CSVService.exportCollection(allCards))
                        } label: {
                            ScanOptionTile(
                                icon: "square.and.arrow.up",
                                title: "Export collection",
                                subtitle: "\(allCards.filter { $0.owned }.count) cards · CSV"
                            )
                        }.buttonStyle(.plain)

                        Button {
                            exportCSV(filename: "lorcana_verlanglijst.csv",
                                      csv: CSVService.exportWishlist(allCards))
                        } label: {
                            ScanOptionTile(
                                icon: "heart.circle",
                                title: "Export wishlist",
                                subtitle: "\(allCards.filter { $0.inPriorityWishlist && !$0.owned }.count) cards · CSV"
                            )
                        }.buttonStyle(.plain)

                        Button {
                            showImporter = true
                        } label: {
                            ScanOptionTile(
                                icon: "square.and.arrow.down",
                                title: "Import collection",
                                subtitle: "overwrites owned/foil/notes via CSV"
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isImporting)

                        if isImporting {
                            HStack(spacing: 8) {
                                ProgressView().tint(Color(hex: "#C9A961"))
                                Text("Importing...")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#8A7A4A"))
                            }
                        }

                        if let result = importResult {
                            VStack(alignment: .leading, spacing: 4) {
                                importResultRow(icon: "checkmark.circle", color: "#3A9D5D", label: "\(result.updated) updated")
                                if result.notFound > 0 {
                                    importResultRow(icon: "questionmark.circle", color: "#E8A923", label: "\(result.notFound) not found")
                                }
                                if result.malformed > 0 {
                                    importResultRow(icon: "exclamationmark.triangle", color: "#E24B4A", label: "\(result.malformed) invalid rows")
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 18)

                    Spacer().frame(height: 32)

                    // MARK: Database
                    SectionLabel(title: "database")
                        .padding(.horizontal, 18)
                        .padding(.bottom, 17)

                    VStack(spacing: 12) {
                        Button {
                            showCleanupConfirm = true
                        } label: {
                            ScanOptionTile(icon: "flag", title: "Remove non-EN cards", subtitle: "removes ZH/JA/FR/DE cards")
                        }.buttonStyle(.plain)

                        if let result = cleanupResult {
                            Text(result)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color(hex: "#8A7A4A"))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 18)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(Color(hex: "#C9A961"))
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .fileImporter(
            isPresented: $showBackupRestorer,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleBackupRestore(result: result)
        }
        .alert("Import failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "Unknown error")
        }
        .confirmationDialog("Remove non-EN cards?", isPresented: $showCleanupConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                let removed = apiService.removeNonEnglishCards(context: context)
                cleanupResult = removed > 0 ? "\(removed) cards removed" : "Nothing found to remove"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Cards you don't own that have a non-English language code will be removed.")
        }
    }

    // MARK: - Share

    private func presentShareSheet(url: URL) {
        let avc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
              let root = window.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        if let popover = avc.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        top.present(avc, animated: true)
    }

    // MARK: - Back-up

    private func makeBackup() {
        do {
            let url = try BackupService.createBackup(cards: allCards)
            presentShareSheet(url: url)
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }

    private func handleBackupRestore(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
            showImportError = true
        case .success(let urls):
            guard let url = urls.first else { return }
            isRestoring = true
            backupResult = nil
            Task {
                do {
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    let res = try BackupService.restoreBackup(from: url, context: context)
                    await MainActor.run { backupResult = res; isRestoring = false }
                } catch {
                    await MainActor.run {
                        importError = error.localizedDescription
                        showImportError = true
                        isRestoring = false
                    }
                }
            }
        }
    }

    // MARK: - Export

    private func exportCSV(filename: String, csv: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            presentShareSheet(url: url)
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }

    // MARK: - Import

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
            showImportError = true
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            importResult = nil
            Task {
                do {
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    guard let csv = try? String(contentsOf: url, encoding: .utf8) else {
                        throw CSVError.unreadable
                    }
                    let res = try CSVService.importCollection(csv: csv, context: context)
                    await MainActor.run { importResult = res; isImporting = false }
                } catch {
                    await MainActor.run {
                        importError = error.localizedDescription
                        showImportError = true
                        isImporting = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func importResultRow(icon: String, color: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(Color(hex: color))
            Text(label).font(.system(size: 11, design: .monospaced)).foregroundStyle(Color(hex: color))
        }
    }
}

