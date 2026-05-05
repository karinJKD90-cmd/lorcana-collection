import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Vangt de safe area boven en onder op — nooit wit
            Color(hex: "#060311").ignoresSafeArea()
            HomeView()
        }
        .preferredColorScheme(.dark)
    }
}
