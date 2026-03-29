// FeaturedAchievementCard.swift
// Full-width featured card shown at the top of the achievements grid.
// Spotlights the incomplete category closest to completion.
import SwiftUI

struct FeaturedAchievementCard: View {

    let category: TempleCategory
    let visitedCount: Int
    let definition: AchievementDefinition?

    private var fraction: Double {
        category.totalRequired > 0
            ? min(1.0, Double(visitedCount) / Double(category.totalRequired))
            : 0
    }

    private var remaining: Int {
        max(0, category.totalRequired - visitedCount)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            headerRow
            progressSection
            footerLabel
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .appShadow(.modal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Almost There")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(category.name)
                    .font(AppFont.templeTitle)
                    .foregroundStyle(Color.white)
            }

            Spacer()

            Image(systemName: definition?.iconAssetName ?? "seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ProgressBar(fraction: fraction, height: 8, animated: true)

            HStack {
                Text("\(visitedCount) of \(category.totalRequired) temples visited")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
                Spacer()
                Text("\(Int(fraction * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white)
            }
        }
    }

    private var footerLabel: some View {
        Text("\(remaining) temple\(remaining == 1 ? "" : "s") to unlock the achievement")
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.7))
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        let base = Color(hex: category.color)
        return LinearGradient(
            colors: [base, base.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        "\(category.name), featured progress, \(visitedCount) of \(category.totalRequired) visited, \(remaining) remaining"
    }
}

// MARK: - Preview

#Preview("Featured Achievement Card") {
    let category = TempleCategory(
        id: "c_jyotirlinga",
        name: "Jyotirlinga",
        description: "12 sacred Shiva shrines.",
        templeIDs: Array(repeating: "t", count: 12),
        achievementID: "a_jyotirlinga_complete",
        iconAssetName: "flame.fill",
        color: "#FF6B35",
        deity: "Shiva",
        sortOrder: 1
    )

    FeaturedAchievementCard(
        category: category,
        visitedCount: 9,
        definition: nil
    )
    .padding(AppSpacing.md)
    .background(Color.brandWarmCream)
}
