// TempleDataServiceTests.swift
// Unit tests for TempleDataService — JSON loading, indexing, migration, and filtering.
import XCTest
import SwiftData
@testable import PadYatra

final class TempleDataServiceTests: XCTestCase {

    var service: TempleDataService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        service = await TempleDataService()
        modelContainer = PersistenceController.preview.container
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }

    // MARK: - Loading

    func test_load_setsIsLoaded() async {
        // TODO: Call service.load(modelContext:) with preview context.
        // Assert service.isLoaded == true after completion.
    }

    func test_load_populatesTemples() async {
        // TODO: Call service.load(modelContext:).
        // Assert service.temples is not empty.
    }

    func test_load_filtersInactiveTemples() async {
        // TODO: Inject a payload containing one isActive=false temple.
        // Assert service.temples does not contain the inactive temple.
    }

    func test_load_populatesCategories() async {
        // TODO: Call service.load(modelContext:).
        // Assert service.categories is not empty and sorted by sortOrder.
    }

    func test_load_populatesAchievements() async {
        // TODO: Call service.load(modelContext:).
        // Assert service.achievements is not empty.
    }

    // MARK: - O(1) Index Building

    func test_templeIndex_returnsTempleByID() async {
        // TODO: Load service, then look up a known temple ID in templeIndex.
        // Assert the correct Temple is returned.
    }

    func test_templesByCategory_groupsCorrectly() async {
        // TODO: Load service, check that a known category key maps to the right temples.
        // Assert all temple IDs in the category are present.
    }

    func test_templesByState_groupsCorrectly() async {
        // TODO: Load service, check that a known state key maps to temples in that state.
        // Assert no temple from another state appears.
    }

    // MARK: - Visited Set

    func test_rebuildVisitedSet_reflectsVisits() async {
        // TODO: Create TempleVisit instances for specific temple IDs.
        // Call service.rebuildVisitedSet(from:).
        // Assert visitedTempleIDs contains exactly those IDs.
    }

    func test_rebuildVisitedSet_emptyVisits_clearsSet() async {
        // TODO: Seed visitedTempleIDs, then call rebuildVisitedSet with empty array.
        // Assert visitedTempleIDs is empty.
    }

    // MARK: - Migration

    func test_migration_updatesLegacyIDs() async {
        // TODO: Insert a TempleVisit with a legacy temple ID.
        // Load a payload where that legacy ID maps to a new ID.
        // Run load() to trigger migration.
        // Fetch the visit and assert its templeID was updated to the new ID.
    }

    func test_migration_doesNotRunWhenVersionUnchanged() async {
        // TODO: Load once, set UserDefaults version to current.
        // Load again and assert migration logic is not re-run (no templeID changes).
    }

    func test_migration_runsWhenRemoteFlagIsSet() async {
        // TODO: Set UserDefaults "pd_remoteJSONWasJustReplaced" = true.
        // Load and assert migration runs even if version is unchanged.
        // Assert flag is cleared after load.
    }

    // MARK: - Decoding Edge Cases

    func test_decoding_handlesExtraJSONFields() {
        // TODO: Construct JSON with an unknown top-level key.
        // Assert it still decodes into TemplePayload without error.
    }

    func test_decoding_handlesMissingOptionalFields() {
        // TODO: Construct JSON with null or missing optional Temple fields.
        // Assert it still decodes and the optional fields are nil.
    }
}
