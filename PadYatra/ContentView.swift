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

    // MARK: - Sync Monitor

    @StateObject private var syncMonitor = CloudKitSyncMonitor()

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
        .overlay(alignment: .topTrailing) {
            if syncMonitor.isSyncing {
                CloudSyncIndicator()
                    .padding(.top, 56)
                    .padding(.trailing, 16)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: syncMonitor.isSyncing)
            }
        }
    }
}

// MARK: - CloudSyncIndicator

private struct CloudSyncIndicator: View {
    var body: some View {
        HStack(spacing: 4) {
            ProgressView()
                .scaleEffect(0.6)
                .tint(Color.brandTempleGrey)
            Text("Syncing…")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.brandTempleGrey)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: Capsule())
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
