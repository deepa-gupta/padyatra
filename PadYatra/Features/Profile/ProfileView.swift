// ProfileView.swift
// Profile tab: full-bleed gradient hero, stats grid, category progress, share button.
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
                VStack(spacing: 0) {
                    gradientHeader

                    VStack(spacing: AppSpacing.lg) {
                        statsGrid
                        categorySection
                        shareButton
                    }
                    .padding(AppSpacing.md)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.brandWarmCream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

    // MARK: - Gradient Hero Header

    private var gradientHeader: some View {
        ZStack(alignment: .bottom) {
            // Background gradient extending to status bar
            LinearGradient(
                colors: [Color.brandDeepOrange, Color.brandSaffron, Color.brandPeach],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Content — rings + labels sit above safe area
            VStack(spacing: AppSpacing.md) {
                progressRing
                headerLabels
            }
            .padding(.bottom, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl + AppSpacing.lg)  // clears status bar + nav bar
        }
        .frame(minHeight: 300)
    }

    private var progressRing: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 14)
                .frame(width: 130, height: 130)

            // Progress arc
            Circle()
                .trim(from: 0, to: vm.visitFraction)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: vm.visitFraction)

            // Centre count
            VStack(spacing: 0) {
                Text("\(vm.totalVisited)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("/ \(vm.totalTemples)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
    }

    private var headerLabels: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(visitHeadline)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)

            Text("Keep walking the sacred path 🙏")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.8))
        }
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
            SectionHeader(title: "Progress by Category")

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
                .background(.thinMaterial)
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
