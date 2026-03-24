// AchievementDefinition.swift
// Static definition of an achievement. Completion is always derived — never stored here.
import Foundation
import SwiftUI

// MARK: - AchievementDefinition

struct AchievementDefinition: Identifiable, Codable, Hashable {
    let id: String
    let categoryID: String
    let name: String
    let description: String
    let iconAssetName: String
    let rarity: AchievementRarity
    let colors: AchievementColors
}

// MARK: - AchievementColors

struct AchievementColors: Codable, Hashable {
    /// Hex string for the locked/unearned state.
    let locked: String
    /// Hex string for the unlocked/earned state.
    let unlocked: String
}

// MARK: - AchievementRarity

enum AchievementRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary

    var displayName: String {
        switch self {
        case .common:    return "Common"
        case .rare:      return "Rare"
        case .epic:      return "Epic"
        case .legendary: return "Legendary"
        }
    }

    /// The brand color associated with this rarity level.
    var color: Color {
        switch self {
        case .common:    return Color.brandTempleGrey
        case .rare:      return Color.brandSaffron
        case .epic:      return Color.brandDeepOrange
        case .legendary: return Color.brandGold
        }
    }
}
