// TempleVisit.swift
// SwiftData model representing a single user visit to a temple.
// Multiple visits to the same temple are allowed.
import SwiftData
import Foundation

@Model
final class TempleVisit {
    // @Attribute(.unique) is safe on UUID id because it's never used as a
    // foreign key from another CloudKit-synced model. UUIDs are device-local.
    @Attribute(.unique) var id: UUID

    /// Opaque reference to Temple.id from static JSON. NOT unique — users may
    /// visit the same temple multiple times.
    var templeID: String

    var visitedAt: Date

    /// Used for CloudKit conflict resolution: latest write wins.
    var lastEditedAt: Date

    var notes: String?

    /// Optional star rating 1–5. nil means unrated.
    var rating: Int?

    /// Asset identifiers for photos stored in the user's photo library.
    var photoAssetIDs: [String]

    /// True when the visit was recorded with GPS confirmation at or near the temple.
    var isGPSVerified: Bool

    // MARK: - Init

    init(
        templeID: String,
        visitedAt: Date = .now,
        notes: String? = nil,
        rating: Int? = nil,
        photoAssetIDs: [String] = [],
        isGPSVerified: Bool = false
    ) {
        self.id = UUID()
        self.templeID = templeID
        self.visitedAt = visitedAt
        self.lastEditedAt = .now
        self.notes = notes
        self.rating = rating
        self.photoAssetIDs = photoAssetIDs
        self.isGPSVerified = isGPSVerified
    }
}
