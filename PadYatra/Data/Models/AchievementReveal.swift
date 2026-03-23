// AchievementReveal.swift
// Persists only whether the user has seen (scratched) an achievement reveal card.
// Completion state is ALWAYS derived from visit data — never stored here.
//
// CloudKit safety: @Attribute(.unique) is deliberately omitted from achievementID.
// Uniqueness is enforced via fetch-before-insert in AchievementService.
import SwiftData
import Foundation

@Model
final class AchievementReveal {
    /// Opaque FK into AchievementDefinition.id (static JSON).
    /// NOT marked @Attribute(.unique) — CloudKit + unique attribute = crash risk.
    /// Uniqueness enforced manually via fetch-before-insert.
    var achievementID: String

    /// When the unlock was first detected and the record was created.
    var revealedAt: Date

    /// True once the user has interacted with (seen) the reveal animation.
    /// Monotonic: once true, remains true (true wins in CloudKit merge).
    var hasBeenRevealed: Bool

    // MARK: - Init

    init(achievementID: String) {
        self.achievementID = achievementID
        self.revealedAt = .now
        self.hasBeenRevealed = false
    }
}
