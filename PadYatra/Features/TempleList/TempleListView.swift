// TempleListView.swift
// Lists all temples with search, filter, and section grouping.
// Navigation leads to TempleDetailView (placeholder Text until that file is written).
import SwiftUI
import SwiftData
import OSLog

struct TempleListView: View {

    // MARK: - Environment

    @EnvironmentObject private var dataService: TempleDataService

    // MARK: - State

    @StateObject private var vm: TempleListViewModel
    @Query private var allVisits: [TempleVisit]

    // MARK: - Private

    private let logger = Logger(subsystem: "com.padyatra", category: "TempleListView")

    // MARK: - Dependencies (passed in for detail navigation)

    private let visitService: VisitService
    private let achievementService: AchievementService

    // MARK: - Init

    /// Designated initialiser — injects the VM so that environment objects are
    /// available before StateObject initialisation.
    init(
        dataService: TempleDataService,
        locationService: LocationService,
        visitService: VisitService,
        achievementService: AchievementService
    ) {
        _vm = StateObject(
            wrappedValue: TempleListViewModel(
                dataService: dataService,
                locationService: locationService
            )
        )
        self.visitService = visitService
        self.achievementService = achievementService
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TempleFilterBar(
                    filterMode: $vm.filterMode,
                    selectedCategoryID: $vm.selectedCategoryID,
                    categories: vm.availableCategories
                )
                .background(Color.brandWarmCream)

                Divider()

                templeList
            }
            .navigationTitle("Temples")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.brandWarmCream)
            .searchable(
                text: $vm.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search temples…"
            )
        }
        .tint(Color.brandSaffron)
        .onAppear {
            dataService.rebuildVisitedSet(from: allVisits)
            recompute()
        }
        .onChange(of: vm.filterMode) { recompute() }
        .onChange(of: vm.searchText) { recompute() }
        .onChange(of: vm.selectedCategoryID) { recompute() }
        .onChange(of: allVisits) { _, visits in
            dataService.rebuildVisitedSet(from: visits)
            recompute()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var templeList: some View {
        if dataService.isLoaded {
            if vm.displayedSections.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(vm.displayedSections, id: \.title) { section in
                        Section(header: sectionHeader(section.title)) {
                            ForEach(section.temples) { temple in
                                NavigationLink {
                                    TempleDetailView(
                                        vm: TempleDetailViewModel(
                                            temple: temple,
                                            visitService: visitService,
                                            achievementService: achievementService
                                        )
                                    )
                                } label: {
                                    TempleListRow(
                                        temple: temple,
                                        isVisited: dataService.visitedTempleIDs.contains(temple.id)
                                    )
                                }
                                .listRowBackground(Color.white)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.brandWarmCream)
            }
        } else {
            loadingState
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.brandTempleGrey)
            .textCase(.uppercase)
            .padding(.vertical, AppSpacing.xs)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "building.columns")
                .font(.system(size: 48))
                .foregroundStyle(Color.brandTempleGrey.opacity(0.4))

            Text(vm.searchText.isEmpty ? "No temples found" : "No results for \"\(vm.searchText)\"")
                .font(.headline)
                .foregroundStyle(Color.brandEarthBrown)

            if !vm.searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandTempleGrey)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brandWarmCream)
    }

    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(Color.brandSaffron)
            Text("Loading temples…")
                .font(.subheadline)
                .foregroundStyle(Color.brandTempleGrey)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brandWarmCream)
    }

    // MARK: - Helpers

    private func recompute() {
        vm.recompute()
        logger.debug("TempleListView recomputed sections: \(vm.displayedSections.count)")
    }
}

// MARK: - Preview

#Preview("Temple List") {
    let persistence = PersistenceController.preview
    let dataService = TempleDataService()
    let locationService = LocationService()
    let context = persistence.container.mainContext
    let visitService = VisitService(modelContext: context, templeDataService: dataService)
    let achievementService = AchievementService(modelContext: context, templeDataService: dataService)

    return TempleListView(
        dataService: dataService,
        locationService: locationService,
        visitService: visitService,
        achievementService: achievementService
    )
    .environmentObject(dataService)
    .modelContainer(persistence.container)
}
