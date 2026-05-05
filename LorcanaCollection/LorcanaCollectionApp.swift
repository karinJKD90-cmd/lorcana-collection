import SwiftUI
import SwiftData
import UIKit

@main
struct LorcanaCollectionApp: App {

    init() {
        // ── Navigation bar: altijd donker, nooit wit ──────────────────────
        let bg = UIColor(red: 0.024, green: 0.012, blue: 0.067, alpha: 1)     // #060311
        let gold = UIColor(red: 0.788, green: 0.663, blue: 0.380, alpha: 1)   // #C9A961

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bg
        appearance.shadowColor = UIColor(white: 1, alpha: 0.08)
        appearance.titleTextAttributes = [.foregroundColor: gold]
        appearance.largeTitleTextAttributes = [.foregroundColor: gold]

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
        UINavigationBar.appearance().tintColor            = gold

        // ── Tab bar: donker ───────────────────────────────────────────────
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = bg
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Card.self, PricePoint.self, Deck.self, DeckEntry.self])
    }
}
