// RemoteDataService.swift
// Fetches updated temples.json from CDN and caches it locally.
// Sets UserDefaults flag "pd_remoteJSONWasJustReplaced" = true on successful update.
// TempleDataService reads this flag on the next load to trigger migration.
// The remote URL is read from Info.plist — never hardcoded here.
import Foundation
import OSLog

// MARK: - RemoteDataServiceError

enum RemoteDataServiceError: Error, LocalizedError {
    case missingInfoPlistKey
    case networkError(underlying: Error)
    case badHTTPStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingInfoPlistKey:       return "Info.plist key 'TempleDataURL' is missing."
        case .networkError(let e):       return "Network error: \(e.localizedDescription)"
        case .badHTTPStatus(let code):   return "Bad HTTP status: \(code)"
        case .decodingFailed:            return "Remote JSON failed to decode as TemplePayload."
        }
    }
}

// MARK: - RemoteDataService

final class RemoteDataService: Sendable {

    private let logger = Logger(subsystem: "com.padyatra", category: "RemoteDataService")

    private enum Defaults {
        static let remoteReplacedKey = "pd_remoteJSONWasJustReplaced"
    }

    // MARK: - Public API

    /// Call on app launch (async, non-blocking). Silently no-ops on any error.
    func fetchIfNeeded() async {
        guard let url = remoteURL else {
            logger.warning("No TempleDataURL in Info.plist — remote fetch skipped.")
            return
        }

        let localVersion = cachedVersion()

        do {
            let data = try await download(from: url)

            // Decode just enough to compare versions — avoid full load cost here.
            let payload = try JSONDecoder().decode(TemplePayload.self, from: data)

            guard payload.version > localVersion else {
                logger.info("Remote JSON v\(payload.version) is not newer than local v\(localVersion) — skipping.")
                return
            }

            try writeToCache(data)
            UserDefaults.standard.set(true, forKey: Defaults.remoteReplacedKey)
            logger.info("Remote JSON v\(payload.version) cached — migration will run on next load.")

        } catch {
            // Log but never crash; app continues with cached / bundle data.
            logger.error("Remote fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    /// Reads the CDN URL from Info.plist key "TempleDataURL". Never hardcoded.
    private var remoteURL: URL? {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "TempleDataURL") as? String,
              !urlString.isEmpty else {
            return nil
        }
        return URL(string: urlString)
    }

    private func localCacheURL() -> URL {
        // safe: .documentDirectory always exists on iOS — force-unwrap is intentional
        FileManager.default // swiftlint:disable:next force_unwrapping
            .urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("temples.json")
    }

    /// Reads the `version` field from the locally cached JSON, or 0 if none exists.
    private func cachedVersion() -> Int {
        guard let data = try? Data(contentsOf: localCacheURL()),
              let payload = try? JSONDecoder().decode(TemplePayload.self, from: data) else {
            return 0
        }
        return payload.version
    }

    private func download(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw RemoteDataServiceError.networkError(underlying: URLError(.badServerResponse))
        }
        guard (200...299).contains(http.statusCode) else {
            throw RemoteDataServiceError.badHTTPStatus(http.statusCode)
        }
        return data
    }

    private func writeToCache(_ data: Data) throws {
        try data.write(to: localCacheURL(), options: .atomic)
    }
}
