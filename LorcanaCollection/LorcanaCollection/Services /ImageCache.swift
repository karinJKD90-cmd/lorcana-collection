import SwiftUI
import UIKit

// MARK: - ImageCache

/// Actor-gebaseerde image cache: memory (NSCache, 80 MB) + disk (~/Library/Caches/LorcanaImages/).
/// Eerste load = netwerk; daarna instant uit cache. Duplicate requests worden gedeupliceerd.
actor ImageCache {
    static let shared = ImageCache()

    private let memCache: NSCache<NSString, UIImage>
    private let diskCacheDir: URL
    private let session: URLSession
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    private init() {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 500
        cache.totalCostLimit = 80 * 1024 * 1024
        memCache = cache

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDir = caches.appendingPathComponent("LorcanaImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheDir, withIntermediateDirectories: true)

        let cfg = URLSessionConfiguration.default
        cfg.urlCache = nil
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: cfg)
    }

    func load(_ urlString: String) async -> UIImage? {
        guard !urlString.isEmpty else { return nil }
        let key = NSString(string: urlString)

        // 1. Memory hit — instant
        if let cached = memCache.object(forKey: key) { return cached }

        // 2. Disk hit — geen netwerk nodig
        let diskURL = diskCacheDir.appendingPathComponent(filename(for: urlString))
        if let data = try? Data(contentsOf: diskURL), let img = UIImage(data: data) {
            memCache.setObject(img, forKey: key, cost: cost(img))
            return img
        }

        // 3. Dedup: al een lopende request voor deze URL? Wacht erop mee.
        if let existing = inFlight[urlString] {
            return await existing.value
        }

        // 4. Nieuw netwerk-request
        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString),
                  let (data, _) = try? await session.data(from: url),
                  let img = UIImage(data: data) else { return nil }
            self.store(img, data: data, key: key, diskURL: diskURL)
            return img
        }
        inFlight[urlString] = task
        let result = await task.value
        inFlight.removeValue(forKey: urlString)
        return result
    }

    private func store(_ img: UIImage, data: Data, key: NSString, diskURL: URL) {
        memCache.setObject(img, forKey: key, cost: cost(img))
        try? data.write(to: diskURL, options: .atomic)
    }

    func clearMemory() {
        memCache.removeAllObjects()
    }

    private func filename(for urlString: String) -> String {
        "\(abs(urlString.hashValue)).jpg"
    }

    private func cost(_ img: UIImage) -> Int {
        Int(img.size.width * img.scale * img.size.height * img.scale * 4)
    }
}

// MARK: - CachedAsyncImage

/// Drop-in vervanging voor AsyncImage. Gebruik: voeg .scaledToFit() / .frame() toe als modifier.
struct CachedAsyncImage: View {
    let urlString: String

    @State private var uiImage: UIImage? = nil
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
                    .transition(.opacity.animation(.easeIn(duration: 0.2)))
            } else {
                GeometryReader { geo in
                    ZStack {
                        Color(hex: "#100C1E")
                        // Shimmer sweep
                        LinearGradient(
                            colors: [.clear, Color(hex: "#C9A961").opacity(0.07), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .offset(x: shimmerPhase * geo.size.width * 2.5)
                        .clipped()
                    }
                }
                .onAppear {
                    shimmerPhase = -1
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        shimmerPhase = 1
                    }
                }
                .task(id: urlString) {
                    uiImage = await ImageCache.shared.load(urlString)
                }
            }
        }
    }
}

// Prefetch helper — fire-and-forget vanuit views
extension ImageCache {
    func prefetch(_ urlStrings: [String]) {
        Task {
            for url in urlStrings {
                _ = await load(url)
            }
        }
    }
}
