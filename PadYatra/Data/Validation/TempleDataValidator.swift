// TempleDataValidator.swift
// Validates a TemplePayload before it is vended to the UI.
// Returns an array of ValidationError — empty means the payload is clean.
import Foundation
import OSLog

// MARK: - TempleDataValidator

struct TempleDataValidator {

    private let logger = Logger(subsystem: "com.padyatra", category: "TempleDataValidator")

    // India + Nepal bounding box with a generous buffer for edge cases.
    private let latBounds: ClosedRange<Double> = 5.0...38.0
    private let lngBounds: ClosedRange<Double> = 65.0...98.0

    /// Validates the full payload. Returns all discovered errors; empty array means valid.
    func validate(_ payload: TemplePayload) -> [ValidationError] {
        var errors: [ValidationError] = []
        errors += checkDuplicateTempleIDs(payload.temples)
        errors += checkCategoryReferences(payload)
        errors += checkAchievementReferences(payload)
        errors += checkCoordinates(payload.temples)

        if errors.isEmpty {
            logger.info("TemplePayload v\(payload.version) passed all validation checks.")
        } else {
            logger.error("TemplePayload v\(payload.version) has \(errors.count) validation error(s).")
            for error in errors {
                logger.error("\(error.description)")
            }
        }
        return errors
    }

    // MARK: - Private Checks

    private func checkDuplicateTempleIDs(_ temples: [Temple]) -> [ValidationError] {
        var seen = Set<String>()
        var errors: [ValidationError] = []
        for temple in temples {
            if seen.contains(temple.id) {
                errors.append(.duplicateTempleID(temple.id))
            }
            seen.insert(temple.id)
        }
        return errors
    }

    private func checkCategoryReferences(_ payload: TemplePayload) -> [ValidationError] {
        let knownIDs = Set(payload.temples.map { $0.id })
        var errors: [ValidationError] = []
        for category in payload.categories {
            for templeID in category.templeIDs where !knownIDs.contains(templeID) {
                errors.append(.brokenCategoryReference(categoryID: category.id, templeID: templeID))
            }
        }
        return errors
    }

    private func checkAchievementReferences(_ payload: TemplePayload) -> [ValidationError] {
        let knownCategoryIDs = Set(payload.categories.map { $0.id })
        var errors: [ValidationError] = []
        for achievement in payload.achievements where !knownCategoryIDs.contains(achievement.categoryID) {
            errors.append(.brokenAchievementReference(achievementID: achievement.id))
        }
        return errors
    }

    private func checkCoordinates(_ temples: [Temple]) -> [ValidationError] {
        temples.compactMap { temple in
            let lat = temple.location.latitude
            let lng = temple.location.longitude
            guard latBounds.contains(lat), lngBounds.contains(lng) else {
                return ValidationError.suspiciousCoordinate(templeID: temple.id, lat: lat, lng: lng)
            }
            return nil
        }
    }
}

// MARK: - ValidationError

enum ValidationError: CustomStringConvertible {
    case duplicateTempleID(String)
    case brokenCategoryReference(categoryID: String, templeID: String)
    case brokenAchievementReference(achievementID: String)
    case suspiciousCoordinate(templeID: String, lat: Double, lng: Double)

    var description: String {
        switch self {
        case .duplicateTempleID(let id):
            return "Duplicate temple ID: '\(id)'"
        case .brokenCategoryReference(let catID, let templeID):
            return "Category '\(catID)' references unknown temple '\(templeID)'"
        case .brokenAchievementReference(let id):
            return "Achievement '\(id)' references an unknown category"
        case .suspiciousCoordinate(let id, let lat, let lng):
            return "Temple '\(id)' has suspicious coordinates: (\(lat), \(lng))"
        }
    }
}
