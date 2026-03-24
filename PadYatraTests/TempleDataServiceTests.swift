// TempleDataServiceTests.swift
// Unit tests for TempleDataService — JSON loading, indexing, migration, and filtering.
import XCTest
import SwiftData
@testable import PadYatra

@MainActor
final class TempleDataServiceTests: XCTestCase {

    var service: TempleDataService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        service = TempleDataService()
        // Fresh in-memory container per test to prevent state leakage.
        let schema = Schema([TempleVisit.self, AchievementReveal.self])
        modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        modelContext = ModelContext(modelContainer)
        // Clear migration flags so each test starts clean.
        UserDefaults.standard.removeObject(forKey: "pd_lastSeenDataVersion")
        UserDefaults.standard.removeObject(forKey: "pd_remoteJSONWasJustReplaced")
    }

    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        modelContext = nil
        UserDefaults.standard.removeObject(forKey: "pd_lastSeenDataVersion")
        UserDefaults.standard.removeObject(forKey: "pd_remoteJSONWasJustReplaced")
        try await super.tearDown()
    }

    // MARK: - Loading

    func test_load_setsIsLoaded() async {
        await service.load(modelContext: modelContext)
        XCTAssertTrue(service.isLoaded)
    }

    func test_load_populatesTemples() async {
        await service.load(modelContext: modelContext)
        XCTAssertFalse(service.temples.isEmpty)
    }

    func test_load_filtersInactiveTemples() async {
        // Invariant: all vended temples must have isActive == true.
        await service.load(modelContext: modelContext)
        XCTAssertTrue(service.temples.allSatisfy { $0.isActive })
    }

    func test_load_populatesCategories() async {
        await service.load(modelContext: modelContext)
        XCTAssertFalse(service.categories.isEmpty)
    }

    func test_load_categoriesSortedBySortOrder() async {
        await service.load(modelContext: modelContext)
        let orders = service.categories.map { $0.sortOrder }
        XCTAssertEqual(orders, orders.sorted(), "Categories must be sorted by sortOrder ascending")
    }

    func test_load_populatesAchievements() async {
        await service.load(modelContext: modelContext)
        XCTAssertFalse(service.achievements.isEmpty)
    }

    // MARK: - O(1) Index Building

    func test_templeIndex_returnsTempleByID() async {
        await service.load(modelContext: modelContext)
        let firstTemple = service.temples.first!
        let indexed = service.templeIndex[firstTemple.id]
        XCTAssertNotNil(indexed)
        XCTAssertEqual(indexed?.id, firstTemple.id)
    }

    func test_templeIndex_coversAllLoadedTemples() async {
        await service.load(modelContext: modelContext)
        for temple in service.temples {
            XCTAssertNotNil(service.templeIndex[temple.id], "Missing index entry for '\(temple.id)'")
        }
    }

    func test_templesByCategory_groupsCorrectly() async {
        await service.load(modelContext: modelContext)
        for category in service.categories {
            let temples = service.templesByCategory[category.id] ?? []
            for temple in temples {
                XCTAssertTrue(
                    category.templeIDs.contains(temple.id),
                    "Temple '\(temple.id)' is in category '\(category.id)' but its ID is not in templeIDs"
                )
            }
        }
    }

    func test_templesByState_groupsCorrectly() async {
        await service.load(modelContext: modelContext)
        for (state, temples) in service.templesByState {
            XCTAssertTrue(
                temples.allSatisfy { $0.location.state == state },
                "templesByState['\(state)'] contains temples from other states"
            )
        }
    }

    // MARK: - Visited Set

    func test_rebuildVisitedSet_reflectsVisits() {
        let visits = [
            TempleVisit(templeID: "t_somnath", visitedAt: .now),
            TempleVisit(templeID: "t_kedarnath", visitedAt: .now)
        ]
        service.rebuildVisitedSet(from: visits)

        XCTAssertTrue(service.visitedTempleIDs.contains("t_somnath"))
        XCTAssertTrue(service.visitedTempleIDs.contains("t_kedarnath"))
        XCTAssertEqual(service.visitedTempleIDs.count, 2)
    }

    func test_rebuildVisitedSet_emptyVisits_clearsSet() {
        // Seed the set.
        service.rebuildVisitedSet(from: [TempleVisit(templeID: "t_somnath", visitedAt: .now)])
        XCTAssertFalse(service.visitedTempleIDs.isEmpty)

        // Clear it.
        service.rebuildVisitedSet(from: [])
        XCTAssertTrue(service.visitedTempleIDs.isEmpty)
    }

    func test_rebuildVisitedSet_deduplicatesMultipleVisitsSameTemple() {
        let visits = [
            TempleVisit(templeID: "t_somnath", visitedAt: .now),
            TempleVisit(templeID: "t_somnath", visitedAt: .now.addingTimeInterval(-3600))
        ]
        service.rebuildVisitedSet(from: visits)

        XCTAssertEqual(service.visitedTempleIDs.count, 1)
        XCTAssertTrue(service.visitedTempleIDs.contains("t_somnath"))
    }

    // MARK: - Migration

    func test_migration_doesNotCorruptCurrentIDs() async {
        // Load to populate temples, then insert a visit with a current valid ID.
        await service.load(modelContext: modelContext)
        guard let temple = service.temples.first else {
            XCTFail("No temples loaded"); return
        }
        let visit = TempleVisit(templeID: temple.id, visitedAt: .now)
        modelContext.insert(visit)
        try! modelContext.save()

        // Force migration re-run by resetting the version key.
        UserDefaults.standard.removeObject(forKey: "pd_lastSeenDataVersion")

        // Reload — triggers migration. Current valid ID should be unchanged.
        let service2 = TempleDataService()
        await service2.load(modelContext: modelContext)

        let descriptor = FetchDescriptor<TempleVisit>()
        let visits = try! modelContext.fetch(descriptor)
        XCTAssertTrue(visits.contains { $0.templeID == temple.id },
                      "Migration corrupted a current valid temple ID")
    }

    func test_migration_runsWhenRemoteFlagIsSet() async {
        // First load sets baseline.
        await service.load(modelContext: modelContext)

        // Simulate remote JSON replacement.
        UserDefaults.standard.set(true, forKey: "pd_remoteJSONWasJustReplaced")

        // Second load should clear the flag.
        let service2 = TempleDataService()
        await service2.load(modelContext: modelContext)

        XCTAssertFalse(UserDefaults.standard.bool(forKey: "pd_remoteJSONWasJustReplaced"),
                       "pd_remoteJSONWasJustReplaced must be cleared after load")
    }

    func test_load_clearsRemoteFlagAfterLoad() async {
        UserDefaults.standard.set(true, forKey: "pd_remoteJSONWasJustReplaced")
        await service.load(modelContext: modelContext)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "pd_remoteJSONWasJustReplaced"))
    }

    // MARK: - Decoding Edge Cases

    func test_decoding_handlesExtraJSONFields() {
        let json = """
        {
            "version": 1,
            "lastUpdated": "2026-01-01",
            "unknownTopLevelKey": "ignored",
            "temples": [],
            "categories": [],
            "achievements": []
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(
            try JSONDecoder().decode(TemplePayload.self, from: json),
            "Extra JSON fields must not cause a decode error"
        )
    }

    func test_decoding_handlesMissingOptionalFields() {
        // Temple with only required fields — all optional fields absent.
        let json = """
        {
            "version": 1,
            "lastUpdated": "2026-01-01",
            "temples": [
                {
                    "id": "t_min",
                    "slug": "t-min",
                    "legacyIDs": [],
                    "isActive": true,
                    "name": "Min Temple",
                    "deity": "Shiva",
                    "location": {
                        "city": "City", "district": "Dist",
                        "state": "State", "country": "India"
                    },
                    "categoryIDs": [],
                    "description": "Desc.",
                    "shortDescription": "Short.",
                    "facts": {},
                    "images": {
                        "heroImageName": "hero",
                        "galleryImageNames": [],
                        "thumbnailImageName": "thumb"
                    },
                    "festivals": [],
                    "significance": "other",
                    "isUNESCO": false
                }
            ],
            "categories": [],
            "achievements": []
        }
        """.data(using: .utf8)!

        let payload = try? JSONDecoder().decode(TemplePayload.self, from: json)
        XCTAssertNotNil(payload)
        XCTAssertNil(payload?.temples.first?.sourceURL)
        XCTAssertNil(payload?.temples.first?.alternateName)
        XCTAssertNil(payload?.temples.first?.location.latitude)
        XCTAssertNil(payload?.temples.first?.location.longitude)
    }

    // MARK: - applyFilter

    func test_applyFilter_all_returnsAll() async {
        await service.load(modelContext: modelContext)
        let result = service.applyFilter(to: service.temples, mode: .all)
        XCTAssertEqual(result.count, service.temples.count)
    }

    func test_applyFilter_visited_returnsOnlyVisited() async {
        await service.load(modelContext: modelContext)
        guard let temple = service.temples.first else { return }
        service.rebuildVisitedSet(from: [TempleVisit(templeID: temple.id, visitedAt: .now)])

        let result = service.applyFilter(to: service.temples, mode: .visited)
        XCTAssertTrue(result.allSatisfy { service.visitedTempleIDs.contains($0.id) })
        XCTAssertEqual(result.count, 1)
    }

    func test_applyFilter_notVisited_excludesVisited() async {
        await service.load(modelContext: modelContext)
        guard let temple = service.temples.first else { return }
        service.rebuildVisitedSet(from: [TempleVisit(templeID: temple.id, visitedAt: .now)])

        let result = service.applyFilter(to: service.temples, mode: .notVisited)
        XCTAssertFalse(result.contains { $0.id == temple.id })
        XCTAssertEqual(result.count, service.temples.count - 1)
    }

    func test_applyFilter_byCategory_returnsOnlyCategoryTemples() async {
        await service.load(modelContext: modelContext)
        guard let category = service.categories.first(where: { !$0.templeIDs.isEmpty }) else { return }

        let result = service.applyFilter(to: service.temples, mode: .byCategory, categoryID: category.id)
        XCTAssertTrue(result.allSatisfy { category.templeIDs.contains($0.id) })
    }

    func test_applyFilter_byCategory_nilCategoryID_returnsAll() async {
        await service.load(modelContext: modelContext)
        let result = service.applyFilter(to: service.temples, mode: .byCategory, categoryID: nil)
        XCTAssertEqual(result.count, service.temples.count)
    }
}
