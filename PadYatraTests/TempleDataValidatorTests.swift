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

    // MARK: - Duplicate Temple IDs

    func test_duplicateTempleID_returnsError() {
        // TODO: Build a TemplePayload with two temples sharing the same ID.
        // Assert validator returns exactly one .duplicateTempleID error.
    }

    func test_uniqueTempleIDs_returnsNoError() {
        // TODO: Build a TemplePayload with all unique IDs.
        // Assert validator returns no errors.
    }

    // MARK: - Broken Category References

    func test_brokenCategoryRef_missingTemple_returnsError() {
        // TODO: Build a TemplePayload where a category references a non-existent templeID.
        // Assert validator returns .brokenCategoryReference for the missing ID.
    }

    func test_validCategoryRefs_returnsNoError() {
        // TODO: Build a TemplePayload where all category templeIDs exist.
        // Assert validator returns no errors.
    }

    // MARK: - Broken Achievement References

    func test_brokenAchievementRef_missingCategory_returnsError() {
        // TODO: Build a TemplePayload where an achievement references a non-existent categoryID.
        // Assert validator returns .brokenAchievementReference.
    }

    func test_validAchievementRefs_returnsNoError() {
        // TODO: All achievement categoryIDs exist in categories.
        // Assert validator returns no errors.
    }

    // MARK: - Coordinate Bounds

    func test_coordinateOutsideIndiaBounds_returnsError() {
        // TODO: Build a temple with lat/lng outside India + Nepal buffer (lat 5–38, lng 65–98).
        // Assert validator returns .suspiciousCoordinate.
    }

    func test_coordinateOnBoundary_returnsNoError() {
        // TODO: Build a temple with coordinates on the edge of the valid range.
        // Assert validator returns no coordinate errors.
    }

    func test_bundleJSONPassesAllValidation() {
        // TODO: Load the real temples.json from the test bundle and run the full validator.
        // Assert errors array is empty — this is the canonical data integrity test.
    }

    // MARK: - Multiple Errors

    func test_multipleErrors_areAllReturned() {
        // TODO: Build a payload with a duplicate ID and a bad coordinate.
        // Assert both errors are returned in the same call.
    }
}
