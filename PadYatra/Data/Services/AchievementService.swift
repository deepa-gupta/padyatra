// AchievementService.swift
// Manages achievement unlock logic. Completion is ALWAYS derived from visitedTempleIDs.
// Only AchievementReveal.hasBeenRevealed is persisted.
import SwiftData
import Foundation
import OSLog

// MARK: - AchievementServiceError

enum AchievementServiceError: Error, LocalizedError {
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let e): return "Save failed: \(e.localizedDescription)"
        }
    }
}

// MARK: - AchievementService

// @MainActor: always called alongside TempleDataService (which is @MainActor),
// so keeping the same isolation avoids cross-actor property access errors.
@MainActor
final class AchievementService {

    private let modelContext: ModelContext
    private let templeDataService: TempleDataService
    private let logger = Logger(subsystem: "com.padyatra", category: "AchievementService")

    init(modelContext: ModelContext, templeDataService: TempleDataService) {
        self.modelContext = modelContext
        self.templeDataService = templeDataService
    }

    // MARK: - Derived Completion (never stored)

    /// Derives completion by checking all required templeIDs against the live visited set.
    func isCompleted(_ category: TempleCategory) -> Bool {
        category.templeIDs.allSatisfy { templeDataService.visitedTempleIDs.contains($0) }
    }

    /// Count of visited temples in this category.
    func visitedCount(in category: TempleCategory) -> Int {
        category.templeIDs.filter { templeDataService.visitedTempleIDs.contains($0) }.count
    }

    // MARK: - Unlock Detection

    /// Checks all categories containing templeID for newly completed achievements.
    /// For each newly complete category, ensures an AchievementReveal record exists
    /// via fetch-before-insert (safe for CloudKit).
    /// Returns AchievementDefinitions for achievements where hasBeenRevealed == false.
    func checkUnlocks(for templeID: String) throws -> [AchievementDefinition] {
        let relevantCategories = templeDataService.categories.filter {
            $0.templeIDs.contains(templeID)
        }

        var newlyUnlocked: [AchievementDefinition] = []

        for category in relevantCategories where isCompleted(category) {
            guard let achievementID = category.achievementID else { continue }

            try ensureRevealRecord(achievementID: achievementID)

            if let reveal = try revealRecord(for: achievementID),
               !reveal.hasBeenRevealed,
               let definition = templeDataService.achievements.first(where: { $0.id == achievementID }) {
                newlyUnlocked.append(definition)
            }
        }

        if !newlyUnlocked.isEmpty {
            logger.info("Newly unlocked achievements for temple '\(templeID)': \(newlyUnlocked.map(\.id)).")
        }
        return newlyUnlocked
    }

    // MARK: - Reveal Records

    /// Returns all AchievementReveal records where hasBeenRevealed == false.
    func pendingReveals() throws -> [AchievementReveal] {
        let descriptor = FetchDescriptor<AchievementReveal>(
            predicate: #Predicate { !$0.hasBeenRevealed }
        )
        return try modelContext.fetch(descriptor)
    }

    /// Marks an AchievementReveal as seen by the user.
    func markRevealed(_ reveal: AchievementReveal) throws {
        reveal.hasBeenRevealed = true
        do {
            try modelContext.save()
            logger.info("Marked achievement '\(reveal.achievementID)' as revealed.")
        } catch {
            logger.error("Failed to mark reveal for '\(reveal.achievementID)': \(error.localizedDescription)")
            throw AchievementServiceError.saveFailed(underlying: error)
        }
    }

    /// Returns the reveal record for an achievement, or nil if none exists.
    func revealRecord(for achievementID: String) throws -> AchievementReveal? {
        var descriptor = FetchDescriptor<AchievementReveal>(
            predicate: #Predicate { $0.achievementID == achievementID }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Private

    /// Fetch-before-insert: only creates a new AchievementReveal if one does not exist.
    /// This is the required pattern for CloudKit-synced stores — @Attribute(.unique) is unsafe.
    private func ensureRevealRecord(achievementID: String) throws {
        guard try revealRecord(for: achievementID) == nil else { return }
        let reveal = AchievementReveal(achievementID: achievementID)
        modelContext.insert(reveal)
        do {
            try modelContext.save()
            logger.info("Created AchievementReveal for '\(achievementID)'.")
        } catch {
            logger.error("Failed to create reveal record for '\(achievementID)': \(error.localizedDescription)")
            throw AchievementServiceError.saveFailed(underlying: error)
        }
    }
}
