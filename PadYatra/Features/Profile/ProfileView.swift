// ProfileView.swift
// Profile tab: visit count hero, progress ring, stats grid, category breakdown, share button.
import SwiftUI
import SwiftData

struct ProfileView: View {

    // MARK: - Environment & State

    @EnvironmentObject private var dataService: TempleDataService
    @StateObject private var vm = ProfileViewModel()
    @Query private var allVisits: [TempleVisit]

    private let achievementService: AchievementService

    // MARK: - Init

    init(achievementService: AchievementService) {
        self.achievementService = achievementService
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    heroSection
                    statsGrid
                    categorySection
                    shareButton
                }
                .padding(AppSpacing.md)
            }
            .background(Color.brandWarmCream)
            .navigationTitle("My Journey")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(Color.brandSaffron)
        .onAppear {
            dataService.rebuildVisitedSet(from: allVisits)
            reload()
        }
        .onChange(of: allVisits) { _, visits in
            dataService.rebuildVisitedSet(from: visits)
            reload()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                // Track ring
                Circle()
                    .stroke(Color.brandTempleGrey.opacity(0.15), lineWidth: 16)
                    .frame(width: 140, height: 140)

                // Progress arc
                Circle()
                    .trim(from: 0, to: vm.visitFraction)
                    .stroke(
                        LinearGradient(
                            colors: [Color.brandSaffron, Color.brandDeepOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: vm.visitFraction)

                // Centre count
                VStack(spacing: 0) {
                    Text("\(vm.totalVisited)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.brandEarthBrown)
                    Text("/ \(vm.totalTemples)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandTempleGrey)
                }
            }

            Text(visitHeadline)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandEarthBrown)
                .multilineTextAlignment(.center)

            Text("Keep walking the sacred path 🙏")
                .font(.subheadline)
                .foregroundStyle(Color.brandTempleGrey)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .appShadow()
    }

    private var visitHeadline: String {
        "\(vm.totalVisited) temple\(vm.totalVisited == 1 ? "" : "s") visited"
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: AppSpacing.md) {
            StatTile(
                value: "\(vm.statesVisited)",
                label: "States\nExplored"
            )
            StatTile(
                value: "\(vm.achievementsEarned)",
                label: "Achievements\nEarned"
            )
            StatTile(
                value: percentageText,
                label: "Complete"
            )
        }
    }

    private var percentageText: String {
        "\(Int(vm.visitFraction * 100))%"
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Progress by Category")
                .font(.headline)
                .foregroundStyle(Color.brandEarthBrown)
                .padding(.bottom, AppSpacing.xs)

            if vm.categoryProgress.isEmpty {
                Text("No categories loaded yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandTempleGrey)
            } else {
                VStack(spacing: AppSpacing.md) {
                    ForEach(vm.categoryProgress, id: \.name) { item in
                        CategoryProgressRow(
                            name: item.name,
                            visited: item.visited,
                            total: item.total
                        )
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.white.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .appShadow()
            }
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        ShareLink(item: vm.shareText) {
            Label("Share My Progress", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(Color.brandSaffron)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: - Helpers

    private func reload() {
        vm.reload(from: dataService, achievementService: achievementService)
    }
}

// MARK: - Preview

#Preview("Profile View") {
    let persistence = PersistenceController.preview
    let dataService = TempleDataService()
    let achievementService = AchievementService(
        modelContext: persistence.container.mainContext,
        templeDataService: dataService
    )

    return ProfileView(achievementService: achievementService)
        .environmentObject(dataService)
        .modelContainer(persistence.container)
}
