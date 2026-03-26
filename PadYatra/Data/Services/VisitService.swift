// VisitService.swift
// CRUD for TempleVisit. All mutations go through here.
// Every mutation rebuilds the visited set and reloads widgets.
import SwiftData
import Foundation
import OSLog
import WidgetKit

// MARK: - VisitServiceError

enum VisitServiceError: Error, LocalizedError {
    case invalidRating(Int)
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidRating(let r): return "Rating \(r) is out of range 1–5."
        case .saveFailed(let e):    return "Save failed: \(e.localizedDescription)"
        }
    }
}

// MARK: - VisitService

@MainActor
final class VisitService {

    private let modelContext: ModelContext
    private let templeDataService: TempleDataService
    private let logger = Logger(subsystem: "com.padyatra", category: "VisitService")

    init(modelContext: ModelContext, templeDataService: TempleDataService) {
        self.modelContext = modelContext
        self.templeDataService = templeDataService
    }

    // MARK: - Queries

    /// Returns all visits for a specific temple, sorted by visitedAt descending.
    func visits(for templeID: String) throws -> [TempleVisit] {
        var descriptor = FetchDescriptor<TempleVisit>(
            predicate: #Predicate { $0.templeID == templeID },
            sortBy: [SortDescriptor(\.visitedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 500 // reasonable upper bound
        return try modelContext.fetch(descriptor)
    }

    /// Returns all visits, sorted by visitedAt descending.
    func allVisits() throws -> [TempleVisit] {
        let descriptor = FetchDescriptor<TempleVisit>(
            sortBy: [SortDescriptor(\.visitedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Returns whether the temple has been visited at least once.
    /// O(1) lookup via the pre-built set in TempleDataService.
    func isVisited(_ templeID: String) -> Bool {
        templeDataService.visitedTempleIDs.contains(templeID)
    }

    // MARK: - Mutations

    /// Records a new visit. Multiple visits to the same temple are allowed.
    @discardableResult
    func addVisit(
        templeID: String,
        visitedAt: Date,
        notes: String? = nil,
        rating: Int? = nil,
        photoData: [Data] = [],
        isGPSVerified: Bool = false
    ) throws -> TempleVisit {
        if let r = rating {
            guard (1...5).contains(r) else { throw VisitServiceError.invalidRating(r) }
        }
        let visit = TempleVisit(
            templeID: templeID,
            visitedAt: visitedAt,
            notes: notes,
            rating: rating,
            photoData: photoData,
            isGPSVerified: isGPSVerified
        )
        modelContext.insert(visit)
        try rebuildAndSync()
        logger.info("Added visit to '\(templeID)' at \(visitedAt).")
        return visit
    }

    /// Updates fields on an existing visit.
    func updateVisit(
        _ visit: TempleVisit,
        visitedAt: Date? = nil,
        notes: String? = nil,
        rating: Int? = nil,
        photoData: [Data]? = nil
    ) throws {
        if let r = rating {
            guard (1...5).contains(r) else { throw VisitServiceError.invalidRating(r) }
        }
        if let date = visitedAt         { visit.visitedAt = date }
        if let notes = notes            { visit.notes = notes }
        if let rating = rating          { visit.rating = rating }
        if let photos = photoData   { visit.photoData = photos }
        visit.lastEditedAt = .now
        try rebuildAndSync()
        logger.info("Updated visit \(visit.id) for temple '\(visit.templeID)'.")
    }

    /// Deletes a visit and triggers achievement re-check downstream.
    func deleteVisit(_ visit: TempleVisit) throws {
        modelContext.delete(visit)
        try rebuildAndSync()
        logger.info("Deleted visit \(visit.id) for temple '\(visit.templeID)'.")
    }

    // MARK: - Private

    /// Saves context, rebuilds the visited set, and tells WidgetKit to reload.
    private func rebuildAndSync() throws {
        do {
            try modelContext.save()
        } catch {
            logger.error("ModelContext save failed: \(error.localizedDescription)")
            throw VisitServiceError.saveFailed(underlying: error)
        }
        let all = (try? allVisits()) ?? []
        templeDataService.rebuildVisitedSet(from: all)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
    