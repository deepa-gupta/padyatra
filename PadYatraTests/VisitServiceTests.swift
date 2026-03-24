// VisitServiceTests.swift
// Unit tests for VisitService — CRUD, validation, visited set, and persistence.
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
        // Fresh in-memory container per test.
        let schema = Schema([TempleVisit.self, AchievementReveal.self])
        modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        modelContext = ModelContext(modelContainer)
        templeDataService = TempleDataService()
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
        try visitService.addVisit(templeID: "t_somnath", visitedAt: .now)

        let visits = try visitService.allVisits()
        XCTAssertEqual(visits.count, 1)
        XCTAssertEqual(visits.first?.templeID, "t_somnath")
    }

    func test_addVisit_multipleVisitsSameTemple_allPersisted() throws {
        try visitService.addVisit(templeID: "t_somnath", visitedAt: .now)
        try visitService.addVisit(templeID: "t_somnath", visitedAt: .now.addingTimeInterval(-3600))

        let visits = try visitService.visits(for: "t_somnath")
        XCTAssertEqual(visits.count, 2)
    }

    func test_addVisit_invalidRating_throws() throws {
        XCTAssertThrowsError(try visitService.addVisit(templeID: "t_test", visitedAt: .now, rating: 0)) { error in
            if case VisitServiceError.invalidRating(0) = error { } else {
                XCTFail("Expected invalidRating(0), got \(error)")
            }
        }
        XCTAssertThrowsError(try visitService.addVisit(templeID: "t_test", visitedAt: .now, rating: 6)) { error in
            if case VisitServiceError.invalidRating(6) = error { } else {
                XCTFail("Expected invalidRating(6), got \(error)")
            }
        }
    }

    func test_addVisit_validRatingRange_succeeds() throws {
        XCTAssertNoThrow(try visitService.addVisit(templeID: "t_a", visitedAt: .now, rating: 1))
        XCTAssertNoThrow(try visitService.addVisit(templeID: "t_b", visitedAt: .now, rating: 3))
        XCTAssertNoThrow(try visitService.addVisit(templeID: "t_c", visitedAt: .now, rating: 5))
    }

    func test_addVisit_rebuildsVisitedSet() throws {
        XCTAssertFalse(templeDataService.visitedTempleIDs.contains("t_somnath"))

        try visitService.addVisit(templeID: "t_somnath", visitedAt: .now)

        XCTAssertTrue(templeDataService.visitedTempleIDs.contains("t_somnath"))
    }

    func test_addVisit_withNilNotesAndRating_succeeds() throws {
        XCTAssertNoThrow(
            try visitService.addVisit(templeID: "t_test", visitedAt: .now, notes: nil, rating: nil)
        )
        let visits = try visitService.allVisits()
        XCTAssertEqual(visits.count, 1)
        XCTAssertNil(visits.first?.notes)
        XCTAssertNil(visits.first?.rating)
    }

    func test_addVisit_gpsVerifiedFlag_persisted() throws {
        try visitService.addVisit(templeID: "t_test", visitedAt: .now, isGPSVerified: true)

        let visits = try visitService.allVisits()
        XCTAssertEqual(visits.first?.isGPSVerified, true)
    }

    // MARK: - isVisited

    func test_isVisited_falseBeforeVisit() {
        XCTAssertFalse(visitService.isVisited("t_somnath"))
    }

    func test_isVisited_trueAfterVisit() throws {
        try visitService.addVisit(templeID: "t_somnath", visitedAt: .now)
        XCTAssertTrue(visitService.isVisited("t_somnath"))
    }

    func test_isVisited_falseAfterDeletion() throws {
        let visit = try visitService.addVisit(templeID: "t_somnath", visitedAt: .now)
        try visitService.deleteVisit(visit)
        XCTAssertFalse(visitService.isVisited("t_somnath"))
    }

    func test_isVisited_trueWithMultipleVisits() throws {
        let v1 = try visitService.addVisit(templeID: "t_somnath", visitedAt: .now)
        try visitService.addVisit(templeID: "t_somnath", visitedAt: .now.addingTimeInterval(-3600))

        // Delete one — temple should still be visited (one remains).
        try visitService.deleteVisit(v1)

        XCTAssertTrue(visitService.isVisited("t_somnath"))
    }

    // MARK: - visits(for:)

    func test_visitsForTemple_sortedByDateDescending() throws {
        let old = Date.now.addingTimeInterval(-7200)
        let mid = Date.now.addingTimeInterval(-3600)
        let new = Date.now

        try visitService.addVisit(templeID: "t_somnath", visitedAt: mid)
        try visitService.addVisit(templeID: "t_somnath", visitedAt: old)
        try visitService.addVisit(templeID: "t_somnath", visitedAt: new)

        let visits = try visitService.visits(for: "t_somnath")
        XCTAssertEqual(visits.count, 3)
        XCTAssertGreaterThanOrEqual(visits[0].visitedAt, visits[1].visitedAt)
        XCTAssertGreaterThanOrEqual(visits[1].visitedAt, visits[2].visitedAt)
    }

    func test_visitsForTemple_doesNotReturnOtherTempleVisits() throws {
        try visitService.addVisit(templeID: "t_somnath", visitedAt: .now)
        try visitService.addVisit(templeID: "t_kedarnath", visitedAt: .now)

        let somnathVisits = try visitService.visits(for: "t_somnath")
        XCTAssertTrue(somnathVisits.allSatisfy { $0.templeID == "t_somnath" })
        XCTAssertFalse(somnathVisits.contains { $0.templeID == "t_kedarnath" })
    }

    // MARK: - updateVisit

    func test_updateVisit_changesDate() throws {
        let visit = try visitService.addVisit(templeID: "t_test", visitedAt: .now)
        let newDate = Date(timeIntervalSince1970: 1_000_000)

        try visitService.updateVisit(visit, visitedAt: newDate)

        XCTAssertEqual(visit.visitedAt, newDate)
    }

    func test_updateVisit_changesNotes() throws {
        let visit = try visitService.addVisit(templeID: "t_test", visitedAt: .now)

        try visitService.updateVisit(visit, notes: "Breathtaking view")

        XCTAssertEqual(visit.notes, "Breathtaking view")
    }

    func test_updateVisit_setsLastEditedAt() async throws {
        let before = Date.now
        let visit = try visitService.addVisit(templeID: "t_test", visitedAt: .now)
        let beforeEdit = visit.lastEditedAt

        // Wait 10ms to ensure a measurable time difference.
        try await Task.sleep(nanoseconds: 10_000_000)
        try visitService.updateVisit(visit, notes: "Updated")

        XCTAssertGreaterThan(visit.lastEditedAt, beforeEdit)
        XCTAssertGreaterThan(visit.lastEditedAt, before)
    }

    func test_updateVisit_invalidRating_throws() throws {
        let visit = try visitService.addVisit(templeID: "t_test", visitedAt: .now)

        XCTAssertThrowsError(try visitService.updateVisit(visit, rating: 0)) { error in
            if case VisitServiceError.invalidRating(0) = error { } else {
                XCTFail("Expected invalidRating(0), got \(error)")
            }
        }
    }

    // MARK: - deleteVisit

    func test_deleteVisit_removesRecord() throws {
        let visit = try visitService.addVisit(templeID: "t_test", visitedAt: .now)
        try visitService.deleteVisit(visit)

        let all = try visitService.allVisits()
        XCTAssertEqual(all.count, 0)
    }

    func test_deleteVisit_rebuildsVisitedSet() throws {
        let visit = try visitService.addVisit(templeID: "t_test", visitedAt: .now)
        XCTAssertTrue(templeDataService.visitedTempleIDs.contains("t_test"))

        try visitService.deleteVisit(visit)

        XCTAssertFalse(templeDataService.visitedTempleIDs.contains("t_test"))
    }

    // MARK: - allVisits

    func test_allVisits_sortedByDateDescending() throws {
        try visitService.addVisit(templeID: "t_a", visitedAt: .now.addingTimeInterval(-3600))
        try visitService.addVisit(templeID: "t_b", visitedAt: .now)
        try visitService.addVisit(templeID: "t_c", visitedAt: .now.addingTimeInterval(-7200))

        let all = try visitService.allVisits()
        XCTAssertEqual(all.count, 3)
        XCTAssertGreaterThanOrEqual(all[0].visitedAt, all[1].visitedAt)
        XCTAssertGreaterThanOrEqual(all[1].visitedAt, all[2].visitedAt)
    }

    func test_allVisits_emptyWhenNoVisits() throws {
        let all = try visitService.allVisits()
        XCTAssertTrue(all.isEmpty)
    }
}
