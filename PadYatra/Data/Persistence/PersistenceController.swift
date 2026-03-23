// PersistenceController.swift
// Configures the SwiftData ModelContainer for production (CloudKit) and preview/test (in-memory).
import SwiftData
import Foundation

// @unchecked Sendable: ModelContainer is internally thread-safe; we never
// mutate PersistenceController state after init.
final class PersistenceController: @unchecked Sendable {

    static let shared = PersistenceController()

    /// In-memory container for SwiftUI Previews and unit tests.
    static let preview = PersistenceController(inMemory: true)

    let container: ModelContainer

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
            // force-unwrap: configuration is controlled by us; failure here is a
            // programming error that must be caught in development, not swallowed.
            container = try! ModelContainer(for: schema, configurations: [config]) // swiftlint:disable:this force_try
        }
    }
}
