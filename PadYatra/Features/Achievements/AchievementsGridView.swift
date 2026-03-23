// AchievementsGridView.swift
// 2-column grid of achievement cards. Manages the scratch-card reveal modal.
import SwiftUI
import SwiftData

struct AchievementsGridView: View {

    // MARK: - State

    @StateObject private var vm: AchievementsViewModel
    @Query private var allVisits: [TempleVisit]

    // MARK: - Layout

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md)
    ]

    // MARK: - Init

    init(dataService: TempleDataService, achievementService: AchievementService) {
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
                LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                    ForEach(vm.categoryProgress, id: \.category.id) { item in
                        let definition = vm.definition(for: item.category)
                        let revealed   = vm.isRevealed(for: item.category)

                        AchievementCardView(
                            definition: definition ?? placeholderDefinition(for: item.category),
                            category: item.category,
                            visitedCount: item.visited,
                            isComplete: item.isComplete,
                            isRevealed: revealed,
                            onTap: {
                                if item.isComplete && !revealed, let def = definition {
                                    vm.beginReveal(for: def)
                                }
                            }
                        )
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
        .onAppear { vm.reload() }
        .onChange(of: allVisits) { vm.reload() }
    }

    // MARK: - Helpers

    /// Returns a sensible placeholder so the grid never crashes if JSON is partially loaded.
    private func placeholderDefinition(for category: TempleCategory) -> AchievementDefinition {
        AchievementDefinition(
            id: category.achievementID ?? category.id,
            categoryID: category.id,
            name: category.name,
            description: "Complete all temples in \(category.name).",
            iconAssetName: category.iconAssetName,
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
