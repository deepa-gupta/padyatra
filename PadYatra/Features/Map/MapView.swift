// MapView.swift
// Full-screen map tab. Hosts ClusteringMapView (UIViewRepresentable) and a
// sheet for TempleDetailView when an annotation is tapped.
import SwiftUI
import MapKit
import OSLog

// MARK: - MapView

struct MapView: View {

    @StateObject private var vm: MapViewModel

    private let visitService: VisitService
    private let achievementService: AchievementService

    init(
        dataService: TempleDataService,
        locationService: LocationService,
        visitService: VisitService,
        achievementService: AchievementService
    ) {
        _vm = StateObject(
            wrappedValue: MapViewModel(
                dataService: dataService,
                locationService: locationService
            )
        )
        self.visitService = visitService
        self.achievementService = achievementService
    }

    @State private var showingFilterSheet = false

    var isFilterActive: Bool {
        vm.filterMode != .all
    }

    var body: some View {
        ZStack {
            ClusteringMapView(vm: vm)
                .ignoresSafeArea()

            // Zoom-out button — top right
            VStack {
                HStack {
                    Spacer()
                    Button { vm.resetToIndia() } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brandEarthBrown)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.sm))
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, AppSpacing.sm)
                    .padding(.trailing, AppSpacing.md)
                    .accessibilityLabel("Zoom to full India view")
                }
                Spacer()
            }

            // Filter FAB — bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    filterFAB
                        .padding(.bottom, AppSpacing.xl)
                        .padding(.trailing, AppSpacing.md)
                }
            }
        }
        .sheet(item: $vm.selectedTemple) { temple in
            NavigationStack {
                TempleDetailView(
                    vm: TempleDetailViewModel(
                        temple: temple,
                        visitService: visitService,
                        achievementService: achievementService
                    ),
                    visitService: visitService,
                    achievementService: achievementService
                )
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingFilterSheet) {
            MapFilterSheet(vm: vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            vm.reload()
            vm.locationService.requestWhenInUsePermission()
        }
        .onChange(of: vm.filterMode) { vm.reload() }
        .onChange(of: vm.selectedCategoryID) { vm.reload() }
    }

    // MARK: - Filter FAB

    private var filterFAB: some View {
        Button { showingFilterSheet = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isFilterActive ? Color.white : Color.brandEarthBrown)
                    .frame(width: 56, height: 56)
                    .background(
                        isFilterActive ? Color.brandSaffron : Color(uiColor: .systemBackground),
                        in: Circle()
                    )
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

                // Badge dot when filter is active
                if isFilterActive {
                    Circle()
                        .fill(Color.brandGold)
                        .frame(width: 12, height: 12)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFilterActive ? "Filters active, tap to change" : "Filter temples")
    }
}

// MARK: - ClusteringMapView

struct ClusteringMapView: UIViewRepresentable {

    @ObservedObject var vm: MapViewModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(vm.cameraRegion, animated: false)

        mapView.register(
            TempleMarkerView.self,
            forAnnotationViewWithReuseIdentifier: TempleMarkerView.reuseID
        )
        mapView.register(
            TempleClusterView.self,
            forAnnotationViewWithReuseIdentifier: TempleClusterView.reuseID
        )

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Animate to the new region if a programmatic reset was triggered
        if vm.resetRegionID != context.coordinator.lastAppliedResetID {
            context.coordinator.lastAppliedResetID = vm.resetRegionID
            mapView.setRegion(vm.cameraRegion, animated: true)
        }
        syncAnnotations(on: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(vm: vm)
    }

    // MARK: - Annotation Sync

    // NOTE: syncAnnotations lives in ClusteringMapView by design — it directly
    // mutates an MKMapView instance, which is a UIKit object that must never
    // be held or mutated from the ViewModel layer.
    private func syncAnnotations(on mapView: MKMapView) {
        let existing = mapView.annotations.compactMap { $0 as? TempleAnnotation }
        let existingIDs = Set(existing.map { $0.temple.id })
        let desiredIDs  = Set(vm.visibleTemples.map { $0.id })

        let toRemove = existing.filter { !desiredIDs.contains($0.temple.id) }
        let toAdd    = vm.visibleTemples.filter { !existingIDs.contains($0.id) }

        mapView.removeAnnotations(toRemove)

        let newAnnotations = toAdd.compactMap { temple -> TempleAnnotation? in
            guard let coord = temple.coordinate else { return nil }
            let a = TempleAnnotation()
            a.temple    = temple
            a.isVisited = vm.isVisited(temple)
            a.coordinate = coord
            a.title      = temple.name
            a.subtitle   = "\(temple.location.city), \(temple.location.state)"
            return a
        }
        mapView.addAnnotations(newAnnotations)

        // Refresh visited state for already-present annotations
        for annotation in existing where desiredIDs.contains(annotation.temple.id) {
            let nowVisited = vm.isVisited(annotation.temple)
            if annotation.isVisited != nowVisited {
                annotation.isVisited = nowVisited
                if let view = mapView.view(for: annotation) as? TempleMarkerView {
                    view.markerTintColor = nowVisited
                        ? UIColor(Color.brandVisited)
                        : UIColor(Color.brandSaffron)
                }
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {

        private let vm: MapViewModel
        private let logger = Logger(subsystem: "com.padyatra", category: "ClusteringMapView")
        /// Tracks the last reset we animated to, so we don't re-animate on unrelated updates.
        var lastAppliedResetID: UUID = UUID()

        init(vm: MapViewModel) {
            self.vm = vm
            self.lastAppliedResetID = vm.resetRegionID
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            switch annotation {
            case is TempleAnnotation:
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: TempleMarkerView.reuseID,
                    for: annotation
                ) as? TempleMarkerView
                view?.annotation = annotation
                return view

            case is MKClusterAnnotation:
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: TempleClusterView.reuseID,
                    for: annotation
                ) as? TempleClusterView
                view?.annotation = annotation
                return view

            default:
                return nil
            }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? TempleAnnotation else { return }
            logger.debug("Selected temple: \(annotation.temple.id)")
            Task { @MainActor in
                self.vm.selectedTemple = annotation.temple
            }
            mapView.deselectAnnotation(annotation, animated: false)
        }

        func mapView(
            _ mapView: MKMapView,
            annotationView view: MKAnnotationView,
            calloutAccessoryControlTapped control: UIControl
        ) {
            guard let annotation = view.annotation as? TempleAnnotation else { return }
            Task { @MainActor in
                self.vm.selectedTemple = annotation.temple
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let region = mapView.region
            Task { @MainActor in
                self.vm.onRegionChange(region)
            }
        }
    }
}

// MARK: - Preview

#Preview("Map View") {
    let persistence = PersistenceController.preview
    let dataService = TempleDataService()
    let locationService = LocationService()
    let context = persistence.container.mainContext
    let visitService = VisitService(modelContext: context, templeDataService: dataService)
    let achievementService = AchievementService(modelContext: context, templeDataService: dataService)

    return MapView(
        dataService: dataService,
        locationService: locationService,
        visitService: visitService,
        achievementService: achievementService
    )
    .environmentObject(dataService)
    .environmentObject(locationService)
    .modelContainer(persistence.container)
}
