// TempleCategory.swift
// Static model for a named group of temples (Jyotirlinga, Char Dham, etc.).
import Foundation

struct TempleCategory: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let templeIDs: [String]
    let achievementID: String?
    let iconAssetName: String
    /// PNG badge asset name in Assets.xcassets for this category.
    let badgeImageName: String?
    /// Hex string. Convert to Color via Color(hex:) extension at the view layer — never here.
    let color: String
    let deity: String?
    let sortOrder: Int

    // MARK: - Computed

    /// The number of temples that must be visited to complete this category.
    /// Computed from templeIDs — never stored.
    var totalRequired: Int { templeIDs.count }
}
