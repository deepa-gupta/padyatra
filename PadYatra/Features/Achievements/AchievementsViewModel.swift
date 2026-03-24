// AchievementsViewModel.swift
// Drives the achievements grid: progress calculation, reveal sequencing.
import Foundation
import OSLog

@MainActor
final class AchievementsViewModel: ObservableObject {

    // MARK: - Published

    // categoryProgress is a derived presentation cache rebuilt fresh on every reload().
    // isComplete is derived by AchievementService (never stored in SwiftData).
    @Published private(set) var categoryProgress:
        [(category: TempleCategory, visited: Int, isComplete: Bool)] = []

    /// Set to the achievement the user should scratch. Drives .fullScreenCover.
    @Published var scratchingAchievement: AchievementDefinition?

    /// Set briefly while the reveal animation completes before clearing.
    @Published var pendingRevealAchievement: AchievementDefinition?

    // MARK: - Dependencies

    private let dataService: TempleDataService
    private let achievementService: AchievementService
    private let logger = Logger(subsystem: "com.padyatra", category: "AchievementsViewModel")

    // MARK: - Init

    init(dataService: TempleDataService, achievementService: AchievementService) {
        self.dataService = dataService
        self.achievementService = achievementService
    }

    // MARK: - Public API

    /// Rebuilds categoryProgress from the current visit data.
    /// Call on appear and after any visit change.
    func reload() {
        categoryProgress = dataService.categories.map { category in
            let visited   = achievementService.visitedCount(in: category)
            let complete  = achievementService.isCompleted(category)
            return (category: category, visited: visited, isComplete: complete)
        }
        logger.debug("AchievementsViewModel reloaded: \(self.categoryProgress.count) categories.")
    }

    /// Returns whether the achievement for a category has already been seen by the user.
    func isRevealed(for category: TempleCategory) -> Bool {
        guard let achievementID = category.achievementID,
              let reveal = try? achievementService.revealRecord(for: achievementID) else {
            return false
        }
        return reveal.hasBeenRevealed
    }

    /// Returns the AchievementDefinition for a given category, or nil if not found.
    func definition(for category: TempleCategory) -> AchievementDefinition? {
        guard let achievementID = category.achievementID else { return nil }
        return dataService.achievements.first { $0.id == achievementID }
    }

    /// Called when the user taps a completed-but-unrevealed card.
    /// Sets scratchingAchievement which triggers the scratch card modal.
    func beginReveal(for achievement: AchievementDefinition) {
        logger.info("Beginning reveal for achievement: \(achievement.id)")
        scratchingAchievement = achievement
    }

    /// Called when the scratch card completes. Persists the reveal and dismisses the modal.
    func finishReveal(for achievement: AchievementDefinition) {
        do {
            guard let reveal = try achievementService.revealRecord(for: achievement.id) else {
                logger.error("No reveal record found for '\(achievement.id)' — cannot mark as revealed.")
                scratchingAchievement = nil
                return
            }
            try achievementService.markRevealed(reveal)
            scratchingAchievement = nil
            reload()
            logger.info("Achievement '\(achievement.id)' marked as revealed.")
        } catch {
            logger.error("finishReveal failed for '\(achievement.id)': \(error.localizedDescription)")
            scratchingAchievement = nil
        }
    }
}
