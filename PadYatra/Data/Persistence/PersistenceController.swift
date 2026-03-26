// PersistenceController.swift
// Configures the SwiftData ModelContainer for production (CloudKit) and preview/test (in-memory).
import SwiftData
import Foundation
import OSLog

// @unchecked Sendable: ModelContainer is internally thread-safe; we never
// mutate PersistenceController state after init.
final class PersistenceController: @unchecked Sendable {

    static let shared = PersistenceController()

    /// In-memory container for SwiftUI Previews and unit tests.
    static let preview = PersistenceController(inMemory: true)

    let container: ModelContainer

    private static let logger = Logger(subsystem: "com.padyatra", category: "PersistenceController")

    init(inMemory: Bool = false) {
        let schema = Schema([TempleVisit.self, AchievementReveal.self])

        if inMemory {
            // Previews and tests: no file on disk, no CloudKit.
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // force-unwrap: in-memory configuration cannot fail at runtime.
            container = try! ModelContainer(for: schema, configurations: [config]) // swiftlint:disable:this force_try
        } else {
            // Production: persistent store backed by CloudKit.
            let config = ModelConfiguration(
                "PadYatraCloud",
                schema: schema,
                cloudKitDatabase: .automatic
            )
            // Attempt to open the store. If migration fails (e.g. a schema rename
            // such as photoAssetIDs → photoData that SwiftData cannot auto-migrate),
            // delete the local store and recreate it. CloudKit will re-sync records
            // from iCloud on the next launch; any local-only records are lost, but
            // that's preferable to a hard crash on every launch.
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                Self.logger.error("ModelContainer failed to load (\(error)); wiping local store and retrying.")
                Self.deleteStoreFiles(for: config)
                // force-unwrap: if it fails again after a wipe, it's a programming error.
                container = try! ModelContainer(for: schema, configurations: [config]) // swiftlint:disable:this force_try
            }
        }
    }

    // MARK: - Store file deletion

    /// Removes all SQLite files associated with a ModelConfiguration so a fresh
    /// store can be created. Safe to call only after a migration failure.
    private static func deleteStoreFiles(for config: ModelConfiguration) {
        let base = config.url
        let companions = [base,
                          base.appendingPathExtension("shm"),
                          base.appendingPathExtension("wal")]
        for url in companions {
            do {
                try FileManager.default.removeItem(at: url)
                logger.info("Deleted store file: \(url.lastPathComponent)")
            } catch {
                // File may not exist (e.g. .shm/.wal not yet created) — ignore.
                logger.debug("Could not delete \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Dev Reset

    /// Deletes every TempleVisit and AchievementReveal record from the store.
    /// Called once on launch via a UserDefaults flag; safe to call in DEBUG only.
    @MainActor
    func wipeAllData() {
        let context = container.mainContext
        let logger = Logger(subsystem: "com.padyatra", category: "PersistenceController")
        do {
            try context.delete(model: TempleVisit.self)
            try context.delete(model: AchievementReveal.self)
            try context.save()
            logger.info("All SwiftData records wiped.")
        } catch {
            logger.error("Wipe failed: \(error.localizedDescription)")
        }
    }
}
