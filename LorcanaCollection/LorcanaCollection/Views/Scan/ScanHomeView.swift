import SwiftUI

struct ScanHomeView: View {
    var body: some View {
        ZStack {
            SwirlBackground()
            ArcaneFrame()
            VStack(spacing: 20) {
                Spacer()

                Text("choose a scan mode")
                    .font(.custom("Georgia", size: 13)).italic()
                    .foregroundStyle(Color(hex: "#8A7A4A"))

                NavigationLink(destination: SinglePhotoScanView()) {
                    ScanOptionTile(icon: "camera.fill", title: "Scan one card", subtitle: "identify a single card")
                }
                NavigationLink(destination: BoosterScanView()) {
                    ScanOptionTile(icon: "rectangle.stack.fill", title: "Bulk scan", subtitle: "multiple cards in sequence")
                }

                NavigationLink(destination: DatabaseView()) {
                    Text("or search manually →")
                        .font(.system(size: 12)).italic()
                        .foregroundStyle(Color(hex: "#8A7A4A")).underline()
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 24)
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
    }
}

struct ScanOptionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(Color(hex: "#C9A961")).frame(width: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(Color(hex: "#F4E4A1"))
                Text(subtitle).font(.system(size: 12)).foregroundStyle(Color(hex: "#8A7A4A"))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color(hex: "#8A7A4A"))
        }
        .padding(16)
        .background(Color.black.opacity(0.70).overlay(Rectangle().strokeBorder(Color(hex: "#C9A961").opacity(0.35), lineWidth: 0.6)))
    }
}
