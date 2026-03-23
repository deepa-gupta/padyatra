// TempleDetailViewModel.swift
// Business logic for TempleDetailView: visit CRUD, achievement unlock detection.
import Foundation
import OSLog

// MARK: - TempleDetailViewModel

@MainActor
final class TempleDetailViewModel: ObservableObject {

    // MARK: - Public State

    let temple: Temple

    @Published private(set) var visits: [TempleVisit] = []
    @Published private(set) var isVisited: Bool = false
    @Published var showingAddVisit: Bool = false
    @Published var newlyUnlockedAchievements: [AchievementDefinition] = []
    @Published private(set) var error: String? = nil

    // MARK: - Dependencies

    private let visitService: VisitService
    private let achievementService: AchievementService
    private let logger = Logger(subsystem: "com.padyatra", category: "TempleDetailViewModel")

    // MARK: - Init

    init(
        temple: Temple,
        visitService: VisitService,
        achievementService: AchievementService
    ) {
        self.temple = temple
        self.visitService = visitService
        self.achievementService = achievementService
    }

    // MARK: - Load

    /// Fetches all persisted visits for this temple and refreshes isVisited.
    func loadVisits() {
        do {
            visits = try visitService.visits(for: temple.id)
            isVisited = visitService.isVisited(temple.id)
            logger.info("Loaded \(self.visits.count) visit(s) for '\(self.temple.id)'.")
        } catch {
            self.error = error.localizedDescription
            logger.error("Failed to load visits for '\(self.temple.id)': \(error.localizedDescription)")
        }
    }

    // MARK: - Mark Visited

    /// Records a new visit and checks for newly unlocked achievements.
    func markVisited(notes: String?, rating: Int?, isGPSVerified: Bool) {
        let resolvedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveNotes = resolvedNotes?.isEmpty == false ? resolvedNotes : nil
        let effectiveRating = rating == 0 ? nil : rating

        do {
            _ = try visitService.addVisit(
                templeID: temple.id,
                visitedAt: .now,
                notes: effectiveNotes,
                rating: effectiveRating,
                isGPSVerified: isGPSVerified
            )
            loadVisits()
            checkForUnlocks()
            logger.info("Visit added for '\(self.temple.id)'.")
        } catch {
            self.error = error.localizedDescription
            logger.error("Failed to add visit for '\(self.temple.id)': \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Visit

    /// Deletes an existing visit and reloads the visit list.
    func deleteVisit(_ visit: TempleVisit) {
        do {
            try visitService.deleteVisit(visit)
            loadVisits()
            logger.info("Deleted visit \(visit.id) for '\(self.temple.id)'.")
        } catch {
            self.error = error.localizedDescription
            logger.error("Failed to delete visit \(visit.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Update Visit

    /// Updates an existing visit's fields and reloads.
    func update(_ visit: TempleVisit, visitedAt: Date, notes: String?, rating: Int?) {
        let resolvedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveNotes = resolvedNotes?.isEmpty == false ? resolvedNotes : nil
        let effectiveRating = rating == 0 ? nil : rating

        do {
            try visitService.updateVisit(
                visit,
                visitedAt: visitedAt,
                notes: effectiveNotes,
                rating: effectiveRating
            )
            loadVisits()
            logger.info("Updated visit \(visit.id) for '\(self.temple.id)'.")
        } catch {
            self.error = error.localizedDescription
            logger.error("Failed to update visit \(visit.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func checkForUnlocks() {
        do {
            let unlocked = try achievementService.checkUnlocks(for: temple.id)
            if !unlocked.isEmpty {
                newlyUnlockedAchievements = unlocked
                logger.info("Unlocked \(unlocked.count) achievement(s) for '\(self.temple.id)'.")
            }
        } catch {
            // Achievement unlock failure is non-critical — log but don't surface to user.
            logger.error("Achievement check failed for '\(self.temple.id)': \(error.localizedDescription)")
        }
    }
}
