// TempleImageService.swift
// Fetches temple image URLs from three sources in parallel:
//   1. Wikipedia REST API  — authoritative hero image
//   2. Wikimedia Commons   — additional gallery images (free/CC)
//   3. Unsplash            — high-quality photography
// Results are memory-cached by temple ID. Disk caching of the actual
// image data is handled automatically by URLSession/AsyncImage.
import Foundation
import OSLog

// MARK: - TempleImageService

@MainActor
final class TempleImageService {

    static let shared = TempleImageService()
    private init() {}

    // MARK: - State

    private var cache: [String: [URL]] = [:]
    private let logger = Logger(subsystem: "com.padyatra", category: "TempleImageService")

    // MARK: - Public

    /// Returns cached or freshly fetched image URLs for a temple.
    /// Always returns hero URL first (Wikipedia), then Wikimedia, then Unsplash.
    func imageURLs(for temple: Temple) async -> [URL] {
        if let cached = cache[temple.id] { return cached }
        logger.debug("Fetching images for '\(temple.id)'")
        let urls = await Self.fetchAll(for: temple.name)
        cache[temple.id] = urls
        logger.debug("Cached \(urls.count) URL(s) for '\(temple.id)'")
        return urls
    }

    // MARK: - Aggregator

    private nonisolated static func fetchAll(for name: String) async -> [URL] {
        async let wiki      = fetchWikipedia(name)
        async let wikimedia = fetchWikimedia(name)
        async let unsplash  = fetchUnsplash(name)
        let (w, wm, u)      = await (wiki, wikimedia, unsplash)

        var urls: [URL] = []
        if let hero = w { urls.append(hero) }
        urls.append(contentsOf: wm)
        urls.append(contentsOf: u)
        return urls
    }

    // MARK: - Wikipedia REST API

    /// Fetches the lead image from the Wikipedia article matching the temple name.
    /// Uses the `thumbnail` URL widened to 1200 px — Wikimedia serves any width
    /// via URL, giving a pre-processed JPEG that AsyncImage decodes reliably.
    /// Raw `originalimage` files can be very large or use JPEG sub-formats that
    /// trigger iOS decoder warnings, so we avoid them.
    private nonisolated static func fetchWikipedia(_ name: String) async -> URL? {
        guard
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
        else { return nil }

        var request = URLRequest(url: url)
        request.setValue("PadYatra/1.0 (iOS; contact@padyatra.com)", forHTTPHeaderField: "User-Agent")

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }

        struct WikiSummary: Decodable {
            struct Image: Decodable { let source: String }
            let originalimage: Image?
            let thumbnail: Image?
        }

        guard let summary = try? JSONDecoder().decode(WikiSummary.self, from: data) else { return nil }

        // Prefer thumbnail widened to 1200px; fall back to originalimage
        if let thumbSource = summary.thumbnail?.source,
           let widened = widenWikimediaThumb(thumbSource, width: 1200) {
            return widened
        }
        return summary.originalimage.flatMap { URL(string: $0.source) }
    }

    /// Rewrites a Wikimedia thumbnail URL to request a different width.
    /// Wikimedia thumbnail URLs end with `/{N}px-{filename}`.
    /// Replacing N serves a fresh resize at the requested width.
    private nonisolated static func widenWikimediaThumb(_ source: String, width: Int) -> URL? {
        guard var comps = URLComponents(string: source) else { return nil }
        var parts = comps.path.components(separatedBy: "/")
        guard let last = parts.last,
              let pxRange = last.range(of: "px-"),
              Int(last[last.startIndex..<pxRange.lowerBound]) != nil
        else { return URL(string: source) }
        parts[parts.count - 1] = "\(width)px-\(last[pxRange.upperBound...])"
        comps.path = parts.joined(separator: "/")
        return comps.url
    }

    // MARK: - Wikimedia Commons API

    /// Searches Wikimedia Commons for image files matching the temple name,
    /// then resolves their direct URLs. SVGs and non-photo formats are skipped.
    private nonisolated static func fetchWikimedia(_ name: String) async -> [URL] {
        // Step 1: search for image files
        guard
            let encoded = "\(name) temple".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let searchURL = URL(string: "https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=\(encoded)&srnamespace=6&srlimit=5&format=json")
        else { return [] }

        guard let (searchData, _) = try? await URLSession.shared.data(from: searchURL) else { return [] }

        struct SearchResponse: Decodable {
            struct Query: Decodable {
                struct Item: Decodable { let title: String }
                let search: [Item]
            }
            let query: Query?
        }

        guard
            let result = try? JSONDecoder().decode(SearchResponse.self, from: searchData),
            let items = result.query?.search, !items.isEmpty
        else { return [] }

        // Keep only photo formats; skip SVG diagrams and maps
        let photoTitles = items.map(\.title).filter { title in
            let lower = title.lowercased()
            return lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg")
                || lower.hasSuffix(".png") || lower.hasSuffix(".webp")
        }
        guard !photoTitles.isEmpty else { return [] }

        // Step 2: resolve direct download URLs
        guard
            let titlesEncoded = photoTitles.joined(separator: "|")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let infoURL = URL(string: "https://commons.wikimedia.org/w/api.php?action=query&titles=\(titlesEncoded)&prop=imageinfo&iiprop=url&format=json")
        else { return [] }

        guard let (infoData, _) = try? await URLSession.shared.data(from: infoURL) else { return [] }

        struct InfoResponse: Decodable {
            struct Query: Decodable {
                struct Page: Decodable {
                    struct ImageInfo: Decodable { let url: String }
                    let imageinfo: [ImageInfo]?
                }
                let pages: [String: Page]
            }
            let query: Query?
        }

        guard let info = try? JSONDecoder().decode(InfoResponse.self, from: infoData) else { return [] }
        return info.query?.pages.values.compactMap {
            $0.imageinfo?.first.flatMap { URL(string: $0.url) }
        } ?? []
    }

    // MARK: - Unsplash API

    /// Searches Unsplash for photos of the temple. Returns `regular`-size URLs
    /// (≈1080px wide) suitable for gallery display.
    private nonisolated static func fetchUnsplash(_ name: String) async -> [URL] {
        guard
            let encoded = "\(name) temple india".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://api.unsplash.com/search/photos?query=\(encoded)&per_page=3&client_id=\(unsplashKey)")
        else { return [] }

        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return [] }

        struct UnsplashResponse: Decodable {
            struct Photo: Decodable {
                struct Urls: Decodable { let regular: String }
                let urls: Urls
            }
            let results: [Photo]
        }

        guard let result = try? JSONDecoder().decode(UnsplashResponse.self, from: data) else { return [] }
        return result.results.compactMap { URL(string: $0.urls.regular) }
    }

    // MARK: - Constants

    // swiftlint:disable:next line_length
    private nonisolated static let unsplashKey = "X2BkzLjefkhQBAJmkv0Tnzf0xH7mktzQVPpd2juqELk"
}
