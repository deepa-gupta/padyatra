// ContentView.swift
// Root tab container for Pad Yatra. Four tabs: Map, Temples, Achievements, Profile.
// Services that require ModelContext are created here via init so they're available synchronously.
import SwiftUI
import SwiftData

struct ContentView: View {

    // MARK: - Environment

    @EnvironmentObject private var dataService: TempleDataService
    @EnvironmentObject private var locationService: LocationService

    // MARK: - Services (created once, held in @State to survive re-renders)

    @State private var achievementService: AchievementService
    @State private var visitService: VisitService

    // MARK: - Init

    init(modelContext: ModelContext, dataService: TempleDataService) {
        let achievement = AchievementService(modelContext: modelContext, templeDataService: dataService)
        let visit = VisitService(modelContext: modelContext, templeDataService: dataService)
        _achievementService = State(initialValue: achievement)
        _visitService = State(initialValue: visit)
    }

    // MARK: - Body

    var body: some View {
        TabView {
            // MARK: Map Tab
            MapView(
                dataService: dataService,
                locationService: locationService,
                visitService: visitService,
                achievementService: achievementService
            )
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            // MARK: Temples Tab
            TempleListView(
                dataService: dataService,
                locationService: locationService,
                visitService: visitService,
                achievementService: achievementService
            )
            .tabItem {
                Label("Temples", systemImage: "building.columns.fill")
            }

            // MARK: Achievements Tab
            AchievementsGridView(
                dataService: dataService,
                achievementService: achievementService
            )
            .tabItem {
                Label("Achievements", systemImage: "medal.fill")
            }

            // MARK: Profile Tab
            ProfileView(achievementService: achievementService)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color.brandSaffron)
    }
}

// MARK: - Preview

#Preview("Content View") {
    let persistence = PersistenceController.preview
    let dataService = TempleDataService()
    let context = persistence.container.mainContext

    return ContentView(modelContext: context, dataService: dataService)
        .environmentObject(dataService)
        .environmentObject(LocationService())
        .modelContainer(persistence.container)
}
