// TempleListViewModel.swift
// Business logic for the temple list: filtering, grouping, sorting.
// Filter predicate lives in TempleDataService.applyFilter (shared with MapViewModel).
import Foundation
import Combine
import OSLog

// MARK: - TempleListViewModel

@MainActor
final class TempleListViewModel: ObservableObject {

    // MARK: - Published State

    @Published var filterMode: TempleFilterMode = .all
    @Published var searchText: String = ""
    @Published var selectedCategoryID: String? = nil
    @Published private(set) var displayedSections: [(title: String, temples: [Temple])] = []

    // MARK: - Cached Derived State

    /// Sorted once after load — categories never change at runtime.
    private(set) lazy var availableCategories: [TempleCategory] = {
        dataService.categories.sorted { $0.sortOrder < $1.sortOrder }
    }()

    // MARK: - Dependencies

    private let dataService: TempleDataService
    private let locationService: LocationService
    private let logger = Logger(subsystem: "com.padyatra", category: "TempleListViewModel")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(dataService: TempleDataService, locationService: LocationService) {
        self.dataService = dataService
        self.locationService = locationService
        setupAutoRecompute()
    }

    // MARK: - Public API

    /// Explicit trigger used by the view on first appear and when visits change.
    /// (Filter/search changes are handled internally via Combine.)
    func recompute() {
        let sections = buildSections()
        displayedSections = sections
        logger.debug("TempleListViewModel recomputed: \(sections.count) sections")
    }

    // MARK: - Combine Auto-Recompute

    private func setupAutoRecompute() {
        // Search text: debounce 300 ms so typing doesn't recompute on every character.
        let debouncedSearch = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { _ in () }

        // Filter mode + category: respond immediately (these are tap-driven, not typing).
        let filterChange = Publishers.CombineLatest($filterMode, $selectedCategoryID)
            .dropFirst()          // skip the initial emission on subscription
            .map { _ in () }

        // Merge both streams; one sink calls recompute.
        debouncedSearch
            .merge(with: filterChange)
            .sink { [weak self] in self?.recompute() }
            .store(in: &cancellables)
    }

    // MARK: - Private Grouping

    private func buildSections() -> [(title: String, temples: [Temple])] {
        var pool = dataService.temples
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            pool = pool.filter { $0.name.lowercased().contains(query) }
        }
        pool = dataService.applyFilter(to: pool, mode: filterMode, categoryID: selectedCategoryID)

        switch filterMode {
        case .nearMe:     return nearMeSections(from: pool)
        case .byCategory: return categorySections(from: pool)
        default:          return groupedByState(pool)
        }
    }

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
        let categories = availableCategories

        if let selectedID = selectedCategoryID,
           let category = categories.first(where: { $0.id == selectedID }) {
            let temples = pool.sorted { $0.name < $1.name }
            return temples.isEmpty ? [] : [(title: category.name, temples: temples)]
        }

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
