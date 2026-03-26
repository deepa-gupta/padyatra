// MapViewModel.swift
// Business logic for the map tab: region tracking, filter modes, and visible temple filtering.
import MapKit
import Combine
import OSLog

@MainActor
final class MapViewModel: ObservableObject {

    // MARK: - Published

    @Published var selectedTemple: Temple?
    @Published var cameraRegion: MKCoordinateRegion = MapViewModel.indiaRegion
    @Published private(set) var visibleTemples: [Temple] = []

    /// Filter state — combined in setupAutoReload so ONE change = ONE reload.
    @Published var filterMode: TempleFilterMode = .all
    @Published var selectedCategoryID: String? = nil

    /// Bumped by resetToIndia() — ClusteringMapView watches this to animate the camera.
    @Published private(set) var resetRegionID: UUID = UUID()

    // MARK: - Dependencies

    private let dataService: TempleDataService
    let locationService: LocationService
    private let logger = Logger(subsystem: "com.padyatra", category: "MapViewModel")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants

    static let indiaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.5, longitude: 82.0),
        span: MKCoordinateSpan(latitudeDelta: 25.0, longitudeDelta: 22.0)
    )

    // MARK: - Cached

    /// Sorted once — categories are static after load.
    private(set) lazy var availableCategories: [TempleCategory] = {
        dataService.categories.sorted { $0.sortOrder < $1.sortOrder }
    }()

    // MARK: - Init

    init(dataService: TempleDataService, locationService: LocationService) {
        self.dataService = dataService
        self.locationService = locationService
        visibleTemples = dataService.temples
        setupAutoReload()
    }

    // MARK: - Public API

    func isVisited(_ temple: Temple) -> Bool {
        dataService.visitedTempleIDs.contains(temple.id)
    }

    /// Zooms the map back to the full-India view and clears any active filter.
    func resetToIndia() {
        filterMode = .all
        selectedCategoryID = nil
        cameraRegion = MapViewModel.indiaRegion
        resetRegionID = UUID()
    }

    /// Zooms to the user's current location. Falls back to India region if unavailable.
    func zoomToUserLocation() {
        guard let loc = locationService.userLocation else { return }
        cameraRegion = MKCoordinateRegion(
            center: loc.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
        resetRegionID = UUID()
    }

    /// Called by ClusteringMapView when the user pans/zooms.
    func onRegionChange(_ region: MKCoordinateRegion) {
        cameraRegion = region
        applyFilter(in: region)
    }

    /// Explicit reload — call on appear.
    func reload() {
        applyFilter(in: cameraRegion)
        logger.info("MapViewModel reloaded: \(self.visibleTemples.count) temples visible.")
    }

    // MARK: - Combine Auto-Reload

    private func setupAutoReload() {
        // Coalesce filterMode + selectedCategoryID into a SINGLE reload.
        // Without this, tapping a category filter (which changes both) fires reload() twice.
        Publishers.CombineLatest($filterMode, $selectedCategoryID)
            .dropFirst()     // skip initial subscription emission
            .map { _ in () }
            .sink { [weak self] in
                guard let self else { return }
                self.applyFilter(in: self.cameraRegion)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private func applyFilter(in region: MKCoordinateRegion) {
        let pool = dataService.applyFilter(to: dataService.temples, mode: filterMode, categoryID: selectedCategoryID)
        visibleTemples = clipped(pool, to: region)
        logger.debug("Filter=\(self.filterMode.rawValue) — \(self.visibleTemples.count) temples visible.")
    }

    private func clipped(_ temples: [Temple], to region: MKCoordinateRegion) -> [Temple] {
        let minLat = region.center.latitude  - region.span.latitudeDelta  / 2
        let maxLat = region.center.latitude  + region.span.latitudeDelta  / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        return temples.filter {
            guard let lat = $0.location.latitude, let lon = $0.location.longitude else { return false }
            return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
        }
    }
}
