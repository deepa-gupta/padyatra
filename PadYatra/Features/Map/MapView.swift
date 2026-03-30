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

            // Top-right utility buttons — zoom out + near me
            VStack {
                HStack {
                    Spacer()
                    topRightButtons
                        .padding(.top, AppSpacing.sm)
                        .padding(.trailing, AppSpacing.md)
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
        // filterMode + selectedCategoryID changes are handled inside MapViewModel
        // via a CombineLatest subscription — no double-reload on category tap.
    }

    // MARK: - Top-right buttons (zoom out + near me)

    private var topRightButtons: some View {
        VStack(spacing: AppSpacing.xs) {
            mapIconButton(icon: "arrow.up.left.and.arrow.down.right", active: false) {
                vm.resetToIndia()
            }
            .accessibilityLabel("Zoom to full India view")

            mapIconButton(icon: "location.fill", active: vm.filterMode == .nearMe) {
                vm.filterMode = .nearMe
                vm.zoomToUserLocation()
            }
            .accessibilityLabel("Show temples near me")
        }
    }

    private func mapIconButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(active ? Color.white : Color.brandEarthBrown)
                .frame(width: 44, height: 44)
                .background(
                    active ? Color.brandSaffron : Color(uiColor: .systemBackground).opacity(0.95),
                    in: RoundedRectangle(cornerRadius: AppRadius.sm)
                )
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
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
