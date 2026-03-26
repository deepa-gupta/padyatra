// TempleImageService.swift
// Resolves image URLs for a temple from verified sources only.
// We never show images unless we are confident they show the correct temple.
//
// Two resolution tiers:
//   • thumbnailURL(for:) — 330 px image for list rows (low memory cost)
//   • imageURLs(for:)    — up to 5 full-resolution images for the detail gallery
//
// Priority order for both tiers:
//   1. remoteHeroURL in the JSON — pre-verified at build time
//   2. Wikipedia REST API        — via temple's stored sourceURL (exact article)
//
// Wikimedia Commons text-search is intentionally excluded: a name-only search
// ("Ganesh Temple") reliably returns images of the wrong temple.
//
// Caches use NSCache so iOS can evict entries under memory pressure.
import Foundation
import OSLog
import UIKit

// MARK: - TempleImageService

@MainActor
final class TempleImageService {

    static let shared = TempleImageService()

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    // MARK: - Caches (NSCache auto-evicts on memory pressure)

    private let galleryCache = NSCache<NSString, NSArray>()   // [URL]
    private let thumbCache   = NSCache<NSString, NSURL>()     // URL?
    private let logger = Logger(subsystem: "com.padyatra", category: "TempleImageService")

    // MARK: - Public

    /// Returns a single small (~330 px) URL for use in list row thumbnails.
    /// Returns nil when no verified image is available.
    func thumbnailURL(for temple: Temple) async -> URL? {
        let key = temple.id as NSString
        if let cached = thumbCache.object(forKey: key) { return cached as URL }
        let url = await Self.fetchThumbnail(for: temple)
        if let url { thumbCache.setObject(url as NSURL, forKey: key) }
        logger.debug("'\(temple.id)' thumbnail: \(url?.absoluteString ?? "none")")
        return url
    }

    /// Returns verified image URLs for the detail gallery (up to 5, full resolution).
    /// Returns an empty array — not a placeholder — when no photos are found.
    func imageURLs(for temple: Temple) async -> [URL] {
        let key = temple.id as NSString
        if let cached = galleryCache.object(forKey: key) as? [URL] { return cached }
        let urls = await Self.fetchGallery(for: temple)
        galleryCache.setObject(urls as NSArray, forKey: key)
        logger.debug("'\(temple.id)': \(urls.count) gallery image(s)")
        return urls
    }

    // MARK: - Memory

    @objc private func handleMemoryWarning() {
        galleryCache.removeAllObjects()
        thumbCache.removeAllObjects()
        logger.warning("Memory warning — image URL caches cleared.")
    }

    // MARK: - Thumbnail (330 px)

    private nonisolated static func fetchThumbnail(for temple: Temple) async -> URL? {
        if let heroString = temple.images.remoteHeroURL {
            return widenWikimediaThumb(heroString, width: 330)
                ?? URL(string: heroString)
        }
        guard
            let sourceURL = temple.sourceURL,
            let title = sourceURL.components(separatedBy: "/wiki/").last,
            !title.isEmpty
        else { return nil }
        return await fetchWikipediaSummaryHero(title, width: 330)
    }

    // MARK: - Gallery (up to 5 images, ~1280 px)

    private nonisolated static func fetchGallery(for temple: Temple) async -> [URL] {
        var urls: [URL] = []

        // Always start with the pre-verified hero image
        if let heroString = temple.images.remoteHeroURL,
           let heroURL = URL(string: heroString) {
            urls.append(heroURL)
        }

        // Fetch the Wikipedia media-list regardless of whether we already have a hero
        if let sourceURL = temple.sourceURL,
           let title = sourceURL.components(separatedBy: "/wiki/").last,
           !title.isEmpty {

            if let mediaURLs = await fetchWikipediaMediaList(title), !mediaURLs.isEmpty {
                // Append only URLs not already present (dedup hero vs media-list)
                let existing = Set(urls.map(\.absoluteString))
                for url in mediaURLs where !existing.contains(url.absoluteString) {
                    urls.append(url)
                    if urls.count == 5 { break }
                }
            } else if urls.isEmpty,
                      let hero = await fetchWikipediaSummaryHero(title, width: 1200) {
                // Fallback: summary hero only if we have nothing at all
                urls.append(hero)
            }
        }

        return urls
    }

    // MARK: - Wikipedia media-list (multiple images)

    private nonisolated static func fetchWikipediaMediaList(_ articleTitle: String) async -> [URL]? {
        guard let apiURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/media-list/\(articleTitle)")
        else { return nil }

        var request = URLRequest(url: apiURL, timeoutInterval: 10)
        request.setValue("PadYatra/1.0 (iOS; contact@padyatra.com)", forHTTPHeaderField: "User-Agent")

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }

        struct MediaList: Decodable {
            struct Item: Decodable {
                struct SrcEntry: Decodable { let src: String; let scale: String }
                let title: String
                let type: String
                let srcset: [SrcEntry]?
            }
            let items: [Item]
        }

        guard let mediaList = try? JSONDecoder().decode(MediaList.self, from: data) else { return nil }

        let blocked = ["map", "plan", "flag", "logo", "seal", "coat_of_arms", "location", ".svg"]

        let urls = mediaList.items
            .filter { item in
                guard item.type == "image", !(item.srcset?.isEmpty ?? true) else { return false }
                let lower = item.title.lowercased()
                return !blocked.contains(where: { lower.contains($0) })
            }
            .compactMap { item -> URL? in
                let src = item.srcset?.first(where: { $0.scale == "2x" })?.src
                    ?? item.srcset?.last?.src
                guard let src else { return nil }
                let absolute = src.hasPrefix("//") ? "https:" + src : src
                return URL(string: absolute)
            }

        return Array(urls.prefix(5))
    }

    // MARK: - Wikipedia summary (single image)

    private nonisolated static func fetchWikipediaSummaryHero(_ articleTitle: String, width: Int) async -> URL? {
        guard let apiURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(articleTitle)")
        else { return nil }

        var request = URLRequest(url: apiURL, timeoutInterval: 10)
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
           let widened = widenWikimediaThumb(thumbSource, width: width) {
            return widened
        }
        return summary.originalimage.flatMap { URL(string: $0.source) }
    }

    // MARK: - Wikimedia URL sizing

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

}
