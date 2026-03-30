// BadgeDetailView.swift
// Full-screen badge detail sheet — triggered by double-tapping a revealed achievement card.
import SwiftUI

struct BadgeDetailView: View {

    let definition: AchievementDefinition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            badgeImage

            VStack(spacing: AppSpacing.xs) {
                Text(definition.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.brandEarthBrown)
                    .multilineTextAlignment(.center)

                Text(definition.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.brandTempleGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Text(definition.rarity.displayName.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(definition.rarity.color)
                .clipShape(Capsule())

            Spacer()

            Button("Done") { dismiss() }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brandSaffron)
                .padding(.bottom, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brandWarmCream.ignoresSafeArea())
    }

    @ViewBuilder
    private var badgeImage: some View {
        if let badgeName = definition.badgeImageName {
            Image(badgeName)
                .resizable()
                .scaledToFit()
                .frame(width: 260, height: 260)
                .shadow(color: Color(hex: definition.colors.unlocked).opacity(0.4), radius: 30, x: 0, y: 10)
        } else {
            Image(systemName: definition.iconAssetName)
                .font(.system(size: 120))
                .foregroundStyle(Color(hex: definition.colors.unlocked))
        }
    }
}
