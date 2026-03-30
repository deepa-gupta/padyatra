// AchievementsGridView.swift
// 2-column grid of achievement cards with a featured card at top.
// Manages the scratch-card reveal modal.
import SwiftUI
import SwiftData

struct AchievementsGridView: View {

    // MARK: - State

    @StateObject private var vm: AchievementsViewModel
    @Query private var allVisits: [TempleVisit]

    private let dataService: TempleDataService

    // MARK: - Layout

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    // MARK: - Init

    init(dataService: TempleDataService, achievementService: AchievementService) {
        self.dataService = dataService
        _vm = StateObject(
            wrappedValue: AchievementsViewModel(
                dataService: dataService,
                achievementService: achievementService
            )
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    // Featured card: incomplete category closest to completion
                    if let featured = featuredItem {
                        FeaturedAchievementCard(
                            category: featured.category,
                            visitedCount: featured.visited,
                            definition: vm.definition(for: featured.category)
                        )
                    }

                    LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                        ForEach(
                            Array(vm.categoryProgress.enumerated()),
                            id: \.element.category.id
                        ) { index, item in
                            let definition = vm.definition(for: item.category)
                            let revealed   = vm.isRevealed(for: item.category)

                            AchievementCardView(
                                definition: definition ?? placeholderDefinition(for: item.category),
                                category: item.category,
                                visitedCount: item.visited,
                                isComplete: item.isComplete,
                                isRevealed: revealed,
                                animationDelay: Double(index) * 0.04,
                                onTap: {
                                    if item.isComplete && !revealed, let def = definition {
                                        vm.beginReveal(for: def)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(Color.brandWarmCream)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(Color.brandSaffron)
        .fullScreenCover(item: $vm.scratchingAchievement) { achievement in
            ScratchCardView(achievement: achievement) {
                vm.finishReveal(for: achievement)
            }
        }
        .onAppear {
            dataService.rebuildVisitedSet(from: allVisits)
            vm.reload()
        }
        .onChange(of: allVisits) { _, visits in
            dataService.rebuildVisitedSet(from: visits)
            vm.reload()
        }
    }

    // MARK: - Featured Item

    /// Returns the incomplete category with the highest visit fraction — purely presentational.
    private var featuredItem: (category: TempleCategory, visited: Int, isComplete: Bool)? {
        vm.categoryProgress
            .filter { !$0.isComplete && $0.category.totalRequired > 0 }
            .max {
                Double($0.visited) / Double($0.category.totalRequired)
                    < Double($1.visited) / Double($1.category.totalRequired)
            }
            .map { ($0.category, $0.visited, $0.isComplete) }
    }

    // MARK: - Helpers

    private func placeholderDefinition(for category: TempleCategory) -> AchievementDefinition {
        AchievementDefinition(
            id: category.achievementID ?? category.id,
            categoryID: category.id,
            name: category.name,
            description: "Complete all temples in \(category.name).",
            iconAssetName: category.iconAssetName,
            badgeImageName: nil,
            rarity: .common,
            colors: AchievementColors(locked: category.color, unlocked: category.color)
        )
    }
}

// MARK: - Preview

#Preview("Achievements Grid") {
    let persistence = PersistenceController.preview
    let dataService = TempleDataService()
    let achievementService = AchievementService(
        modelContext: persistence.container.mainContext,
        templeDataService: dataService
    )

    return AchievementsGridView(dataService: dataService, achievementService: achievementService)
        .modelContainer(persistence.container)
}
