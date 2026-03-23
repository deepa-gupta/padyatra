// TempleListViewModel.swift
// Business logic for the temple list: filtering, grouping, sorting.
// Filter predicate lives in TempleDataService.applyFilter (shared with MapViewModel).
import Foundation
import OSLog

// MARK: - TempleListViewModel

@MainActor
final class TempleListViewModel: ObservableObject {

    // MARK: - Published State

    @Published var filterMode: TempleFilterMode = .all
    @Published var searchText: String = ""
    @Published var selectedCategoryID: String? = nil
    @Published private(set) var displayedTemples: [Temple] = []
    @Published private(set) var displayedSections: [(title: String, temples: [Temple])] = []

    // MARK: - Dependencies

    private let dataService: TempleDataService
    private let locationService: LocationService
    private let logger = Logger(subsystem: "com.padyatra", category: "TempleListViewModel")

    // MARK: - Init

    init(dataService: TempleDataService, locationService: LocationService) {
        self.dataService = dataService
        self.locationService = locationService
    }

    // MARK: - Public API

    var availableCategories: [TempleCategory] {
        dataService.categories.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Rebuilds displayedSections. Call on appear and whenever filter state or visits change.
    func recompute() {
        // 1. Search
        var pool = dataService.temples
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            pool = pool.filter { $0.name.lowercased().contains(query) }
        }

        // 2. Shared filter predicate (visited/category/etc.) via TempleDataService
        pool = dataService.applyFilter(to: pool, mode: filterMode, categoryID: selectedCategoryID)

        // 3. Group for display — grouping strategy depends on mode
        let sections: [(title: String, temples: [Temple])]
        switch filterMode {
        case .nearMe:
            sections = nearMeSections(from: pool)
        case .byCategory:
            sections = categorySections(from: pool)
        default:
            sections = groupedByState(pool)
        }

        displayedSections = sections
        displayedTemples = sections.flatMap { $0.temples }
    }

    // MARK: - Private Grouping Helpers

    private func groupedByState(_ temples: [Temple]) -> [(title: String, temples: [Temple])] {
        var byState: [String: [Temple]] = [:]
        for temple in temples {
            byState[temple.location.state, default: []].append(temple)
        }
        return byState
            .map { (title: $0.key, temples: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.title < $1.title }
    }

    private func categorySections(from pool: [Temple]) -> [(title: String, temples: [Temple])] {
        let categories = dataService.categories.sorted { $0.sortOrder < $1.sortOrder }

        // Single category selected — one section, already filtered by applyFilter
        if let selectedID = selectedCategoryID,
           let category = categories.first(where: { $0.id == selectedID }) {
            let temples = pool.sorted { $0.name < $1.name }
            return temples.isEmpty ? [] : [(title: category.name, temples: temples)]
        }

        // All categories — one section per category (temples may appear in multiple)
        return categories.compactMap { category in
            let temples = pool.filter { category.templeIDs.contains($0.id) }
                              .sorted { $0.name < $1.name }
            return temples.isEmpty ? nil : (title: category.name, temples: temples)
        }
    }

    private func nearMeSections(from pool: [Temple]) -> [(title: String, temples: [Temple])] {
        guard locationService.userLocation != nil else {
            logger.info("Near Me requested but no user location — falling back to By State.")
            return groupedByState(pool)
        }
        let sorted = pool.sorted { a, b in
            (locationService.distance(to: a) ?? .infinity) < (locationService.distance(to: b) ?? .infinity)
        }
        return [(title: "Near Me", temples: sorted)]
    }
}
