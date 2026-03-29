// ProfileViewModel.swift
// Computes all stats shown on the Profile tab from live visit data.
import Foundation
import OSLog

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var totalVisited: Int = 0
    @Published private(set) var totalTemples: Int = 0
    @Published private(set) var statesVisited: Int = 0
    @Published private(set) var achievementsEarned: Int = 0
    @Published private(set) var earnedAchievementNames: [String] = []
    @Published private(set) var categoryProgress: [(name: String, visited: Int, total: Int)] = []

    // MARK: - Private

    private let logger = Logger(subsystem: "com.padyatra", category: "ProfileViewModel")

    // MARK: - Public API

    /// Rebuilds all stats. Call on appear and whenever visits change.
    func reload(from dataService: TempleDataService, achievementService: AchievementService) {
        totalVisited   = dataService.visitedTempleIDs.count
        totalTemples   = dataService.temples.count
        statesVisited  = countStatesVisited(dataService: dataService)
        earnedAchievementNames = buildEarnedAchievementNames(
            dataService: dataService,
            achievementService: achievementService
        )
        achievementsEarned = earnedAchievementNames.count
        categoryProgress = buildCategoryProgress(
            dataService: dataService,
            achievementService: achievementService
        )
        logger.debug("ProfileViewModel reloaded: \(self.totalVisited)/\(self.totalTemples) visited, \(self.statesVisited) states, \(self.achievementsEarned) achievements.")
    }

    // MARK: - Derived Stats

    /// Fraction of temples visited, clamped 0–1. Safe for use as a progress value.
    var visitFraction: Double {
        guard totalTemples > 0 else { return 0 }
        return min(1, Double(totalVisited) / Double(totalTemples))
    }

    /// Share text for the ShareLink button.
    var shareText: String {
        var lines: [String] = []
        lines.append("I've visited \(totalVisited) of \(totalTemples) temples on my Pad Yatra journey, exploring \(statesVisited) state\(statesVisited == 1 ? "" : "s") across India! 🙏")

        if !earnedAchievementNames.isEmpty {
            lines.append("")
            lines.append("🏆 Achievements earned (\(earnedAchievementNames.count)):")
            lines.append(contentsOf: earnedAchievementNames.map { "• \($0)" })
        }

        lines.append("")
        lines.append("Join me on the sacred path — download Pad Yatra!")
        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private func countStatesVisited(dataService: TempleDataService) -> Int {
        var states = Set<String>()
        for id in dataService.visitedTempleIDs {
            if let temple = dataService.templeIndex[id] {
                states.insert(temple.location.state)
            }
        }
        return states.count
    }

    private func buildEarnedAchievementNames(
        dataService: TempleDataService,
        achievementService: AchievementService
    ) -> [String] {
        dataService.categories
            .filter { achievementService.isCompleted($0) }
            .compactMap { category -> String? in
                guard let achievementID = category.achievementID else { return nil }
                return dataService.achievements.first(where: { $0.id == achievementID })?.name
                    ?? category.name
            }
    }

    private func buildCategoryProgress(
        dataService: TempleDataService,
        achievementService: AchievementService
    ) -> [(name: String, visited: Int, total: Int)] {
        dataService.categories.map { category in
            let visited = achievementService.visitedCount(in: category)
            return (name: category.name, visited: visited, total: category.totalRequired)
        }
    }
}
