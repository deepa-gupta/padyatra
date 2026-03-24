// TempleDataValidatorTests.swift
// Unit tests for TempleDataValidator.
import XCTest
@testable import PadYatra

final class TempleDataValidatorTests: XCTestCase {

    var validator: TempleDataValidator!

    override func setUp() {
        super.setUp()
        validator = TempleDataValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeTemple(
        id: String = "t_test",
        isActive: Bool = true,
        lat: Double? = 20.0,
        lng: Double? = 75.0
    ) -> Temple {
        Temple(
            id: id, slug: id, legacyIDs: [], isActive: isActive,
            name: "Test Temple", alternateName: nil, deity: "Shiva",
            location: TempleLocation(
                latitude: lat, longitude: lng,
                city: "City", district: "Dist",
                state: "State", country: "India",
                address: nil, pincode: nil
            ),
            categoryIDs: [], description: "Desc.", shortDescription: "Short.",
            facts: TempleFacts(
                established: nil, dynasty: nil, architectureStyle: nil,
                openingMonth: nil, closingMonth: nil, altitude: nil,
                dresscode: nil, photographyAllowed: nil, entryFee: nil, darshanaTimings: nil
            ),
            images: TempleImages(
                heroImageName: "", galleryImageNames: [], thumbnailImageName: "", remoteHeroURL: nil
            ),
            festivals: [], significance: .other, isUNESCO: false, sourceURL: nil
        )
    }

    private func makeCategory(
        id: String = "c_test",
        templeIDs: [String] = [],
        achievementID: String? = nil
    ) -> TempleCategory {
        TempleCategory(
            id: id, name: "Test", description: "",
            templeIDs: templeIDs, achievementID: achievementID,
            iconAssetName: "", color: "#FF0000", deity: nil, sortOrder: 0
        )
    }

    private func makeAchievement(id: String = "a_test", categoryID: String = "c_test") -> AchievementDefinition {
        AchievementDefinition(
            id: id, categoryID: categoryID,
            name: "Test Ach", description: "Desc.",
            iconAssetName: "star.fill", rarity: .common,
            colors: AchievementColors(locked: "#888888", unlocked: "#FFBB00")
        )
    }

    private func makePayload(
        version: Int = 1,
        temples: [Temple] = [],
        categories: [TempleCategory] = [],
        achievements: [AchievementDefinition] = []
    ) -> TemplePayload {
        TemplePayload(
            version: version, lastUpdated: "2026-01-01",
            temples: temples, categories: categories, achievements: achievements
        )
    }

    // MARK: - Duplicate Temple IDs

    func test_duplicateTempleID_returnsError() {
        let t1 = makeTemple(id: "t_same")
        let t2 = makeTemple(id: "t_same")
        let payload = makePayload(temples: [t1, t2])

        let errors = validator.validate(payload)

        let dupes = errors.filter {
            if case .duplicateTempleID("t_same") = $0 { return true }
            return false
        }
        XCTAssertEqual(dupes.count, 1)
    }

    func test_uniqueTempleIDs_returnsNoError() {
        let temples = [makeTemple(id: "t_a"), makeTemple(id: "t_b"), makeTemple(id: "t_c")]
        let payload = makePayload(temples: temples)

        let errors = validator.validate(payload)

        XCTAssertFalse(errors.contains { if case .duplicateTempleID = $0 { return true }; return false })
    }

    // MARK: - Broken Category References

    func test_brokenCategoryRef_missingTemple_returnsError() {
        let temple = makeTemple(id: "t_real")
        let category = makeCategory(id: "c_one", templeIDs: ["t_real", "t_missing"])
        let payload = makePayload(temples: [temple], categories: [category])

        let errors = validator.validate(payload)

        let broken = errors.filter {
            if case .brokenCategoryReference(categoryID: "c_one", templeID: "t_missing") = $0 { return true }
            return false
        }
        XCTAssertEqual(broken.count, 1)
    }

    func test_validCategoryRefs_returnsNoError() {
        let temple = makeTemple(id: "t_real")
        let category = makeCategory(id: "c_one", templeIDs: ["t_real"])
        let payload = makePayload(temples: [temple], categories: [category])

        let errors = validator.validate(payload)

        XCTAssertFalse(errors.contains { if case .brokenCategoryReference = $0 { return true }; return false })
    }

    // MARK: - Broken Achievement References

    func test_brokenAchievementRef_missingCategory_returnsError() {
        let achievement = makeAchievement(id: "a_test", categoryID: "c_nonexistent")
        let payload = makePayload(achievements: [achievement])

        let errors = validator.validate(payload)

        let broken = errors.filter {
            if case .brokenAchievementReference(achievementID: "a_test") = $0 { return true }
            return false
        }
        XCTAssertEqual(broken.count, 1)
    }

    func test_validAchievementRefs_returnsNoError() {
        let category = makeCategory(id: "c_test")
        let achievement = makeAchievement(id: "a_test", categoryID: "c_test")
        let payload = makePayload(categories: [category], achievements: [achievement])

        let errors = validator.validate(payload)

        XCTAssertFalse(errors.contains { if case .brokenAchievementReference = $0 { return true }; return false })
    }

    // MARK: - Coordinate Bounds

    func test_coordinateOutsideIndiaBounds_returnsError() {
        // New York City coords — clearly outside India
        let temple = makeTemple(id: "t_bad", lat: 40.7, lng: -74.0)
        let payload = makePayload(temples: [temple])

        let errors = validator.validate(payload)

        let coordErrors = errors.filter {
            if case .suspiciousCoordinate(templeID: "t_bad", lat: _, lng: _) = $0 { return true }
            return false
        }
        XCTAssertEqual(coordErrors.count, 1)
    }

    func test_coordinateOnBoundary_returnsNoError() {
        // Exact boundary values (lat 5–38, lng 65–98)
        let temple = makeTemple(id: "t_edge", lat: 5.0, lng: 65.0)
        let payload = makePayload(temples: [temple])

        let errors = validator.validate(payload)

        XCTAssertFalse(errors.contains { if case .suspiciousCoordinate = $0 { return true }; return false })
    }

    func test_nilCoordinate_skipsCoordinateCheck() {
        // Temples with nil coords should not produce a coordinate error
        let temple = makeTemple(id: "t_nocoord", lat: nil, lng: nil)
        let payload = makePayload(temples: [temple])

        let errors = validator.validate(payload)

        XCTAssertFalse(errors.contains { if case .suspiciousCoordinate = $0 { return true }; return false })
    }

    func test_bundleJSONPassesAllValidation() {
        // Load the real temples.json from the app bundle and run the full validator.
        // This is the canonical data integrity test — must have zero errors at all times.
        guard let url = Bundle.main.url(forResource: "temples", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(TemplePayload.self, from: data) else {
            XCTFail("Could not load temples.json from bundle")
            return
        }

        let errors = validator.validate(payload)
        XCTAssertEqual(errors.count, 0, "temples.json has validation errors: \(errors.map(\.description))")
    }

    // MARK: - Multiple Errors

    func test_multipleErrors_areAllReturned() {
        // Duplicate ID + coordinate out of bounds
        let t1 = makeTemple(id: "t_dup", lat: 90.0, lng: 200.0) // out of bounds
        let t2 = makeTemple(id: "t_dup")                          // duplicate
        let payload = makePayload(temples: [t1, t2])

        let errors = validator.validate(payload)

        XCTAssertGreaterThanOrEqual(errors.count, 2)
    }
}
