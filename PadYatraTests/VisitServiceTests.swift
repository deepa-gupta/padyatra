// VisitServiceTests.swift
// Unit tests for VisitService — CRUD, validation, visited set, and widget sync.
import XCTest
import SwiftData
@testable import PadYatra

@MainActor
final class VisitServiceTests: XCTestCase {

    var visitService: VisitService!
    var templeDataService: TempleDataService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        modelContainer = PersistenceController.preview.container
        modelContext = ModelContext(modelContainer)
        templeDataService = await TempleDataService()
        visitService = VisitService(
            modelContext: modelContext,
            templeDataService: templeDataService
        )
    }

    override func tearDown() async throws {
        visitService = nil
        templeDataService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - addVisit

    func test_addVisit_persistsVisit() throws {
        // TODO: Call addVisit for a templeID.
        // Fetch all TempleVisit records.
        // Assert one record exists with the correct templeID.
    }

    func test_addVisit_multipleVisitsSameTemple_allPersisted() throws {
        // TODO: Call addVisit for the same templeID twice.
        // Assert both records exist (multiple visits allowed).
    }

    func test_addVisit_invalidRating_throws() throws {
        // TODO: Call addVisit with rating = 0 (invalid).
        // Assert throws VisitServiceError.invalidRating.
        // Repeat with rating = 6.
    }

    func test_addVisit_validRatingRange_succeeds() throws {
        // TODO: Call addVisit with ratings 1, 3, 5 — all valid.
        // Assert no error is thrown.
    }

    func test_addVisit_rebuildsVisitedSet() throws {
        // TODO: Assert templeDataService.visitedTempleIDs is empty.
        // Call addVisit for a templeID.
        // Assert visitedTempleIDs contains that templeID.
    }

    // MARK: - isVisited

    func test_isVisited_falseBeforeVisit() {
        // TODO: Assert isVisited("t_somnath") == false with no visits.
    }

    func test_isVisited_trueAfterVisit() throws {
        // TODO: addVisit for "t_somnath".
        // Assert isVisited("t_somnath") == true.
    }

    func test_isVisited_falseAfterDeletion() throws {
        // TODO: addVisit then deleteVisit for a templeID.
        // If it was the only visit, assert isVisited returns false.
    }

    func test_isVisited_trueWithMultipleVisits() throws {
        // TODO: addVisit twice for the same temple, delete one.
        // Assert isVisited still returns true (one visit remains).
    }

    // MARK: - visits(for:)

    func test_visitsForTemple_sortedByDateDescending() throws {
        // TODO: Insert three visits for the same temple with different dates.
        // Assert the returned array is sorted newest-first.
    }

    func test_visitsForTemple_doesNotReturnOtherTempleVisits() throws {
        // TODO: Insert visits for two different temples.
        // Assert visits(for: templeA) does not contain visits for templeB.
    }

    // MARK: - updateVisit

    func test_updateVisit_changesDate() throws {
        // TODO: Add a visit, then update its visitedAt to a new date.
        // Fetch and assert the date changed.
    }

    func test_updateVisit_changesNotes() throws {
        // TODO: Add a visit with no notes, update with a note string.
        // Fetch and assert notes matches.
    }

    func test_updateVisit_setsLastEditedAt() throws {
        // TODO: Add a visit, capture lastEditedAt.
        // Wait 1 second (or mock time), then update.
        // Assert lastEditedAt is newer.
    }

    func test_updateVisit_invalidRating_throws() throws {
        // TODO: Add a visit. Try updating with rating = 0.
        // Assert throws VisitServiceError.invalidRating.
    }

    // MARK: - deleteVisit

    func test_deleteVisit_removesRecord() throws {
        // TODO: Add then delete a visit.
        // Fetch all visits and assert count is 0.
    }

    func test_deleteVisit_rebuildsVisitedSet() throws {
        // TODO: Add a visit (only visit for that temple).
        // Delete it. Assert visitedTempleIDs no longer contains the templeID.
    }

    // MARK: - allVisits

    func test_allVisits_sortedByDateDescending() throws {
        // TODO: Insert visits at different timestamps.
        // Assert allVisits() returns them newest-first.
    }

    func test_allVisits_emptyWhenNoVisits() throws {
        // TODO: Assert allVisits() returns an empty array with no data.
    }

    // MARK: - Edge Cases

    func test_addVisit_withNilNotesAndRating_succeeds() throws {
        // TODO: Add a visit with notes=nil, rating=nil.
        // Assert it persists without error.
    }

    func test_addVisit_gpsVerifiedFlag_persisted() throws {
        // TODO: Add a visit with isGPSVerified=true.
        // Fetch and assert isGPSVerified == true.
    }
}
