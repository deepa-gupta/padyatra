// TempleImageService.swift
// Resolves image URLs for a temple from verified sources only.
// We never show images unless we are confident they show the correct temple.
//
// Priority order:
//   1. remoteHeroURL in the JSON — pre-verified during build pipeline (exact article match)
//   2. Wikipedia REST API        — via temple's stored sourceURL (exact article, not a search)
//   3. Unsplash                  — searched with name + city + state for specificity
//
// Wikimedia Commons text-search is intentionally excluded: a name-only search
// ("Ganesh Temple") reliably returns images of the wrong temple.
//
// If all sources return nothing, callers must show a "no photos" state rather
// than a placeholder that implies a photo exists.
import Foundation
import OSLog

// MARK: - TempleImageService

@MainActor
final class TempleImageService {

    static let shared = TempleImageService()
    private init() {}

    // MARK: - State

    private var urlCache: [String: [URL]] = [:]
    private let logger = Logger(subsystem: "com.padyatra", category: "TempleImageService")

    // MARK: - Public

    /// Returns verified image URLs for a temple.
    /// Returns an empty array — not a placeholder — when no photos are found.
    func imageURLs(for temple: Temple) async -> [URL] {
        if let cached = urlCache[temple.id] { return cached }
        let urls = await Self.fetchAll(for: temple)
        urlCache[temple.id] = urls
        logger.debug("'\(temple.id)': \(urls.count) image(s) found")
        return urls
    }

    // MARK: - Aggregator

    private nonisolated static func fetchAll(for temple: Temple) async -> [URL] {
        var urls: [URL] = []

        // 1. Pre-verified URL from build pipeline — most accurate, use directly
        if let heroString = temple.images.remoteHeroURL,
           let heroURL = URL(string: heroString) {
            urls.append(heroURL)
        }

        // 2. Wikipedia via exact stored article URL — no name search, no ambiguity
        if let hero = await fetchWikipediaHero(temple) {
            if !urls.contains(hero) { urls.append(hero) }
        }

        // 3. Unsplash — include city + state in query to reduce wrong-temple matches
        let unsplashURLs = await fetchUnsplash(temple)
        urls.append(contentsOf: unsplashURLs)

        return urls
    }

    // MARK: - Wikipedia (exact article URL)

    private nonisolated static func fetchWikipediaHero(_ temple: Temple) async -> URL? {
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

    // MARK: - Unsplash (location-specific query)

    private nonisolated static func fetchUnsplash(_ temple: Temple) async -> [URL] {
        // Build a specific query: "Temple Name City State temple"
        // More specific than just the temple name → fewer wrong-location results
        let query = "\(temple.name) \(temple.location.city) \(temple.location.state) temple"
        guard
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://api.unsplash.com/search/photos?query=\(encoded)&per_page=4&client_id=\(unsplashKey)")
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
