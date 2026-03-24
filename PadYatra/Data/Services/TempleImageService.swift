// TempleImageService.swift
// Resolves image URLs for a temple, in priority order:
//   1. remoteHeroURL in the JSON  — pre-verified during build pipeline (most accurate)
//   2. Wikipedia REST API         — live fetch using temple's Wikipedia sourceURL
//   3. Wikimedia Commons search   — additional gallery images (CC licensed)
//   4. Unsplash search            — high-quality photography (name-based, last resort)
//
// URL lists are persisted to disk via URLCache so re-fetching is avoided between launches.
// Actual image pixel data is also disk-cached by AsyncImage via the same URLCache.
import Foundation
import OSLog

// MARK: - TempleImageService

@MainActor
final class TempleImageService {

    static let shared = TempleImageService()
    private init() {}

    // MARK: - State

    /// In-memory URL list cache. Persists for the lifetime of the process.
    private var urlCache: [String: [URL]] = [:]
    private let logger = Logger(subsystem: "com.padyatra", category: "TempleImageService")

    // MARK: - Public

    /// Returns image URLs for a temple. First call fetches; subsequent calls return cached.
    func imageURLs(for temple: Temple) async -> [URL] {
        if let cached = urlCache[temple.id] { return cached }
        let urls = await Self.fetchAll(for: temple)
        urlCache[temple.id] = urls
        logger.debug("Cached \(urls.count) URL(s) for '\(temple.id)'")
        return urls
    }

    // MARK: - Aggregator

    private nonisolated static func fetchAll(for temple: Temple) async -> [URL] {
        var urls: [URL] = []

        // 1. Pre-verified hero image from JSON build pipeline — use directly, no search needed
        if let heroString = temple.images.remoteHeroURL, let heroURL = URL(string: heroString) {
            urls.append(heroURL)
        }

        // 2. Wikipedia article page — use stored sourceURL for accurate article lookup
        //    Skip if we already have a hero from the same Wikipedia source
        if urls.isEmpty, let hero = await fetchWikipediaHero(temple) {
            urls.append(hero)
        }

        // 3. Wikimedia Commons gallery images (independent of hero source)
        let wikimediaURLs = await fetchWikimedia(temple.name)
        urls.append(contentsOf: wikimediaURLs)

        // 4. Unsplash — last resort, name-based search
        if urls.count < 3 {
            let unsplashURLs = await fetchUnsplash(temple.name)
            urls.append(contentsOf: unsplashURLs)
        }

        return urls
    }

    // MARK: - Wikipedia (by article URL, not name search)

    /// Fetches the hero image from the temple's stored Wikipedia article URL.
    /// This avoids name-ambiguity bugs — we use the exact article already identified
    /// during the build pipeline, not a free-text search.
    private nonisolated static func fetchWikipediaHero(_ temple: Temple) async -> URL? {
        // Derive article title from sourceURL (e.g. ".../wiki/Somnath_temple" → "Somnath_temple")
        guard
            let sourceURL = temple.sourceURL,
            let articleTitle = sourceURL.components(separatedBy: "/wiki/").last,
            !articleTitle.isEmpty
        else { return nil }

        guard let apiURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(articleTitle)")
        else { return nil }

        var request = URLRequest(url: apiURL)
        request.setValue("PadYatra/1.0 (iOS; contact@padyatra.com)", forHTTPHeaderField: "User-Agent")

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }

        struct WikiSummary: Decodable {
            struct Image: Decodable { let source: String }
            let thumbnail: Image?
            let originalimage: Image?
        }
        guard let summary = try? JSONDecoder().decode(WikiSummary.self, from: data) else { return nil }

        if let thumbSource = summary.thumbnail?.source,
           let widened = widenWikimediaThumb(thumbSource, width: 1200) {
            return widened
        }
        return summary.originalimage.flatMap { URL(string: $0.source) }
    }

    /// Rewrites a Wikimedia thumbnail URL to request a specific width.
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

    // MARK: - Wikimedia Commons

    private nonisolated static func fetchWikimedia(_ name: String) async -> [URL] {
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

        let photoTitles = items.map(\.title).filter {
            let lower = $0.lowercased()
            return lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg")
                || lower.hasSuffix(".png") || lower.hasSuffix(".webp")
        }
        guard !photoTitles.isEmpty else { return [] }

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

    // MARK: - Unsplash

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
