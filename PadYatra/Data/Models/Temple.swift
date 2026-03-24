// Temple.swift
// Static model types for temple data. Never mix with SwiftData models.
import Foundation
import CoreLocation

// MARK: - Temple

struct Temple: Identifiable, Codable, Hashable {
    let id: String
    let slug: String
    let legacyIDs: [String]
    let isActive: Bool
    let name: String
    let alternateName: String?
    let deity: String
    let location: TempleLocation
    let categoryIDs: [String]
    let description: String
    let shortDescription: String
    let facts: TempleFacts
    let images: TempleImages
    let festivals: [TempleFestival]
    let significance: TempleSignificance
    let isUNESCO: Bool
    let sourceURL: String?
}

// MARK: - TempleLocation

struct TempleLocation: Codable, Hashable {
    let latitude: Double?
    let longitude: Double?
    let city: String
    let district: String?
    let state: String
    let country: String
    let address: String?
    let pincode: String?
}

// MARK: - TempleFacts

struct TempleFacts: Codable, Hashable {
    let established: String?
    let dynasty: String?
    let architectureStyle: String?
    let openingMonth: Int?      // 1-12, nil if open year-round
    let closingMonth: Int?      // 1-12, nil if open year-round
    let altitude: Int?          // metres above sea level
    let dresscode: String?
    let photographyAllowed: Bool?
    let entryFee: String?
    let darshanaTimings: String?
}

// MARK: - TempleImages

struct TempleImages: Codable, Hashable {
    let heroImageName: String
    let galleryImageNames: [String]
    let thumbnailImageName: String
    let remoteHeroURL: String?
}

// MARK: - TempleFestival

struct TempleFestival: Codable, Hashable {
    let name: String
    let approximateMonth: Int?  // 1-12; nil if variable
    let isLunar: Bool
    let description: String
    let significance: FestivalSignificance
}

// MARK: - FestivalSignificance

enum FestivalSignificance: String, Codable, CaseIterable {
    case high
    case medium
    case low
}

// MARK: - TempleSignificance

enum TempleSignificance: String, Codable, CaseIterable {
    case jyotirlinga
    case shaktipeeth
    case divyaDesam
    case charDham
    case panchaKedar       = "panch_kedar"
    case ashtavinayak
    case other
}

// MARK: - Coordinate Convenience

extension Temple {
    /// Returns a MapKit coordinate, or nil if this temple has no geocode yet.
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = location.latitude, let lon = location.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var hasCoordinate: Bool { coordinate != nil }
}
