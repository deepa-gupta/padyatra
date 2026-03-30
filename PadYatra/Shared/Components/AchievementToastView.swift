// AchievementToastView.swift
// Bottom banner shown when one or more achievements are newly unlocked.
// Presented as an overlay in TempleDetailView; auto-dismissed after 3 seconds.
import SwiftUI

// MARK: - AchievementToastView

struct AchievementToastView: View {

    let achievements: [AchievementDefinition]

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(Color.brandGold)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievements.count == 1 ? "Achievement Unlocked!" : "\(achievements.count) Achievements Unlocked!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(achievements.map(\.name).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.brandEarthBrown.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .appShadow(.modal)
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let names = achievements.map(\.name).joined(separator: ", ")
        return "Achievement\(achievements.count == 1 ? "" : "s") unlocked: \(names)"
    }
}

// MARK: - Preview

#Preview("Achievement Toast — single") {
    ZStack(alignment: .bottom) {
        Color.brandWarmCream.ignoresSafeArea()

        AchievementToastView(achievements: [
            AchievementDefinition(
                id: "a1", categoryID: "c_jyotirlinga",
                name: "Jyotirlinga Pilgrim", description: "Visit all 12.",
                iconAssetName: "shiva", badgeImageName: nil, rarity: .legendary,
                colors: AchievementColors(locked: "#8A7B72", unlocked: "#FFB830")
            )
        ])
    }
}

#Preview("Achievement Toast — multiple") {
    ZStack(alignment: .bottom) {
        Color.brandWarmCream.ignoresSafeArea()

        AchievementToastView(achievements: [
            AchievementDefinition(id: "a1", categoryID: "c1", name: "Jyotirlinga Pilgrim",
                description: "", iconAssetName: "", badgeImageName: nil, rarity: .legendary,
                colors: AchievementColors(locked: "#8A7B72", unlocked: "#FFB830")),
            AchievementDefinition(id: "a2", categoryID: "c2", name: "Char Dham Yatri",
                description: "", iconAssetName: "", badgeImageName: nil, rarity: .epic,
                colors: AchievementColors(locked: "#8A7B72", unlocked: "#FF6B35")),
        ])
    }
}
