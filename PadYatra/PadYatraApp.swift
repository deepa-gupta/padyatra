// PadYatraApp.swift
// Application entry point. Bootstraps all services and injects them into the environment.
import SwiftUI
import SwiftData
import OSLog

@main
struct PadYatraApp: App {

    init() {
        // 50 MB memory + 300 MB disk image cache shared by AsyncImage and URLSession.
        URLCache.shared = URLCache(
            memoryCapacity: 50  * 1024 * 1024,
            diskCapacity:   300 * 1024 * 1024
        )
    }

    // MARK: - Services

    @StateObject private var templeDataService = TempleDataService()
    @StateObject private var locationService = LocationService()

    // RemoteDataService is not an ObservableObject — no published state needed at app level.
    private let remoteDataService = RemoteDataService()

    // MARK: - Private

    private let logger = Logger(subsystem: "com.padyatra", category: "PadYatraApp")

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            appContent
                .environmentObject(templeDataService)
                .environmentObject(locationService)
                .modelContainer(PersistenceController.shared.container)
                .onAppear {
                    // One-time dev wipe — remove once new data is loaded
                    if !UserDefaults.standard.bool(forKey: "dev.dataWipedV5") {
                        PersistenceController.shared.wipeAllData()
                        UserDefaults.standard.set(true, forKey: "dev.dataWipedV5")
                    }

                    let context = PersistenceController.shared.container.mainContext
                    Task {
                        await templeDataService.load(modelContext: context)
                        logger.info("TempleDataService load complete.")
                    }
                    Task {
                        await remoteDataService.fetchIfNeeded()
                        logger.info("RemoteDataService fetch complete.")
                    }
                }
        }
    }

    // MARK: - Root View

    @ViewBuilder
    private var appContent: some View {
        if templeDataService.isLoaded {
            ContentView(
                modelContext: PersistenceController.shared.container.mainContext,
                dataService: templeDataService
            )
        } else {
            splashScreen
        }
    }

    @ViewBuilder
    private var splashScreen: some View {
        ZStack {
            Color.brandWarmCream.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.brandSaffron)

                Text("Pad Yatra")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.brandEarthBrown)

                ProgressView()
                    .tint(Color.brandSaffron)
                    .padding(.top, AppSpacing.sm)
            }
        }
    }
}
