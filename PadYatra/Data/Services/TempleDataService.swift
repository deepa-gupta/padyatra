// TempleDataService.swift
// Single source of truth for all static temple data.
// Loads from Documents/temples.json (remote cache) if present, else Bundle.
// Runs migration + validation on version change or after remote JSON replace.
// Builds O(1) indices after loading.
import Foundation
import OSLog
import SwiftData

// MARK: - TemplePayload

/// Top-level Codable container matching the JSON schema exactly.
struct TemplePayload: Codable {
    let version: Int
    let lastUpdated: String
    let temples: [Temple]
    let categories: [TempleCategory]
    let achievements: [AchievementDefinition]
}

// MARK: - TempleDataService

@MainActor
final class TempleDataService: ObservableObject {

    // MARK: Published (main-thread only, @MainActor enforced)

    @Published private(set) var temples: [Temple] = []
    @Published private(set) var categories: [TempleCategory] = []
    @Published private(set) var achievements: [AchievementDefinition] = []
    @Published private(set) var isLoaded: Bool = false

    // MARK: O(1) Static Indices — rebuilt only when JSON changes

    private(set) var templeIndex: [String: Temple] = [:]
    private(set) var templesByCategory: [String: [Temple]] = [:]
    private(set) var templesByState: [String: [Temple]] = [:]

    // MARK: Visit-Derived — rebuilt on every visit change

    private(set) var visitedTempleIDs: Set<String> = []

    // MARK: Private

    private let logger = Logger(subsystem: "com.padyatra", category: "TempleDataService")
    private let validator = TempleDataValidator()

    private enum Defaults {
        static let lastSeenVersionKey = "pd_lastSeenDataVersion"
        static let remoteReplacedKey  = "pd_remoteJSONWasJustReplaced"
    }

    // MARK: - Public API

    func load(modelContext: ModelContext) async {
        // Step 1: I/O + decode off the main thread — never block the UI.
        guard let payload = await loadPayloadOffMain() else {
            logger.error("Failed to load any temple JSON — app will show empty state.")
            return
        }

        // Step 2: Validate (fast, already back on main for the assert).
        let errors = validator.validate(payload)
        assert(errors.isEmpty, "Temple JSON validation failed: \(errors.map(\.description))")

        // Step 3: Migration touches ModelContext — must stay on main actor.
        runMigrationIfNeeded(payload: payload, modelContext: modelContext)

        // Step 4: Build indices off the main thread (pure CPU, no actor state read).
        let built = await buildIndicesOffMain(from: payload)

        // Step 5: Apply results on main actor all at once.
        temples            = built.temples
        categories         = built.categories
        achievements       = built.achievements
        templeIndex        = built.templeIndex
        templesByCategory  = built.templesByCategory
        templesByState     = built.templesByState

        UserDefaults.standard.set(payload.version, forKey: Defaults.lastSeenVersionKey)
        UserDefaults.standard.set(false, forKey: Defaults.remoteReplacedKey)

        isLoaded = true
        logger.info("TempleDataService loaded v\(payload.version): \(self.temples.count) temples.")
    }

    /// Rebuilds visitedTempleIDs from the current set of persisted visits.
    /// Call this after every insert, update, or delete in VisitService.
    func rebuildVisitedSet(from visits: [TempleVisit]) {
        visitedTempleIDs = Set(visits.map { $0.templeID })
    }

    /// Single filtering entry point used by both TempleListViewModel and MapViewModel.
    /// Returns the subset of `temples` that passes the active filter.
    /// Sorting and grouping are the caller's responsibility.
    func applyFilter(
        to temples: [Temple],
        mode: TempleFilterMode,
        categoryID: String? = nil
    ) -> [Temple] {
        switch mode {
        case .all, .nearMe:
            return temples
        case .byCategory:
            guard let catID = categoryID,
                  let category = categories.first(where: { $0.id == catID })
            else { return temples }
            return temples.filter { category.templeIDs.contains($0.id) }
        case .visited:
            return temples.filter { visitedTempleIDs.contains($0.id) }
        case .notVisited:
            return temples.filter { !visitedTempleIDs.contains($0.id) }
        }
    }

    // MARK: - JSON Loading (off main thread)

    /// Runs file I/O and JSON decode on a background thread.
    private func loadPayloadOffMain() async -> TemplePayload? {
        await Task.detached(priority: .userInitiated) { [logger] in
            Self.loadJSONSync(logger: logger)
        }.value
    }

    /// Pure function — no actor state. Safe to call from any thread.
    private nonisolated static func loadJSONSync(logger: Logger) -> TemplePayload? {
        let cacheURL = Self.localCacheURLStatic()
        if FileManager.default.fileExists(atPath: cacheURL.path),
           let data = try? Data(contentsOf: cacheURL),
           let payload = Self.decodeSync(data, logger: logger) {
            logger.info("Loaded temple JSON from Documents cache.")
            return payload
        }

        guard let bundleURL = Bundle.main.url(forResource: "temples", withExtension: "json"),
              let data = try? Data(contentsOf: bundleURL),
              let payload = Self.decodeSync(data, logger: logger) else {
            logger.error("Failed to load temples.json from bundle.")
            return nil
        }
        logger.info("Loaded temple JSON from app bundle.")
        return payload
    }

    private nonisolated static func decodeSync(_ data: Data, logger: Logger) -> TemplePayload? {
        do {
            return try JSONDecoder().decode(TemplePayload.self, from: data)
        } catch {
            logger.error("JSON decode failed: \(error.localizedDescription)")
            return nil
        }
    }

    private nonisolated static func localCacheURLStatic() -> URL {
        // swiftlint:disable:next force_unwrapping
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first! // safe: .documentDirectory always exists on iOS
            .appendingPathComponent("temples.json")
    }

    // MARK: - Migration

    private func runMigrationIfNeeded(payload: TemplePayload, modelContext: ModelContext) {
        let lastSeen = UserDefaults.standard.integer(forKey: Defaults.lastSeenVersionKey)
        let remoteReplaced = UserDefaults.standard.bool(forKey: Defaults.remoteReplacedKey)

        guard payload.version > lastSeen || remoteReplaced else { return }

        logger.info("Migration triggered: v\(lastSeen) → v\(payload.version), remoteReplaced=\(remoteReplaced)")
        migrateLegacyIDs(temples: payload.temples, modelContext: modelContext)
    }

    private func migrateLegacyIDs(temples: [Temple], modelContext: ModelContext) {
        // Build reverse map: legacyID → current ID
        var legacyMap: [String: String] = [:]
        for temple in temples {
            for legacyID in temple.legacyIDs {
                legacyMap[legacyID] = temple.id
            }
        }

        guard !legacyMap.isEmpty else {
            logger.info("No legacy ID mappings to process.")
            return
        }

        do {
            let descriptor = FetchDescriptor<TempleVisit>()
            let visits = try modelContext.fetch(descriptor)
            var migrated = 0
            for visit in visits {
                if let newID = legacyMap[visit.templeID] {
                    visit.templeID = newID
                    visit.lastEditedAt = .now
                    migrated += 1
                }
            }
            try modelContext.save()
            logger.info("Migrated \(migrated) TempleVisit record(s) to new IDs.")
        } catch {
            logger.error("Legacy ID migration failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Index Building (off main thread)

    private struct BuiltIndices: Sendable {
        let temples: [Temple]
        let categories: [TempleCategory]
        let achievements: [AchievementDefinition]
        let templeIndex: [String: Temple]
        let templesByCategory: [String: [Temple]]
        let templesByState: [String: [Temple]]
    }

    /// Runs all index construction on a background thread; returns a value type safe to send back.
    private func buildIndicesOffMain(from payload: TemplePayload) async -> BuiltIndices {
        await Task.detached(priority: .userInitiated) {
            Self.buildIndicesSync(from: payload)
        }.value
    }

    /// Pure function — no actor state reads or writes.
    private nonisolated static func buildIndicesSync(from payload: TemplePayload) -> BuiltIndices {
        let activeTemples = payload.temples.filter { $0.isActive }
        let sortedTemples = activeTemples.sorted { $0.name < $1.name }
        let sortedCategories = payload.categories.sorted { $0.sortOrder < $1.sortOrder }

        let index = Dictionary(uniqueKeysWithValues: activeTemples.map { ($0.id, $0) })

        var byCategory: [String: [Temple]] = [:]
        for category in payload.categories {
            byCategory[category.id] = category.templeIDs.compactMap { index[$0] }
        }

        var byState: [String: [Temple]] = [:]
        for temple in activeTemples {
            byState[temple.location.state, default: []].append(temple)
        }

        return BuiltIndices(
            temples: sortedTemples,
            categories: sortedCategories,
            achievements: payload.achievements,
            templeIndex: index,
            templesByCategory: byCategory,
            templesByState: byState
        )
    }
}
