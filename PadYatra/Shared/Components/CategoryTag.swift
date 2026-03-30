// CategoryTag.swift
// Pill-shaped tag displaying a TempleCategory name with its associated color as a tint.
import SwiftUI

struct CategoryTag: View {

    let category: TempleCategory

    // MARK: - Body

    var body: some View {
        Text(category.name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(categoryColor.opacity(0.9))
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                categoryColor.opacity(0.15),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(categoryColor.opacity(0.35), lineWidth: 1)
            )
    }

    // MARK: - Private

    private var categoryColor: Color {
        Color(hex: category.color)
    }
}

// MARK: - Preview

#Preview("Category Tags") {
    let sample = TempleCategory(
        id: "jyotirlinga",
        name: "Jyotirlinga",
        description: "12 sacred abodes of Lord Shiva",
        templeIDs: [],
        achievementID: "ach_jyotirlinga",
        iconAssetName: "icon_jyotirlinga",
        badgeImageName: nil,
        color: "#FF6B35",
        deity: "Shiva",
        sortOrder: 0
    )
    let sample2 = TempleCategory(
        id: "char_dham",
        name: "Char Dham",
        description: "Four sacred pilgrimage sites",
        templeIDs: [],
        achievementID: "ach_char_dham",
        iconAssetName: "icon_char_dham",
        badgeImageName: nil,
        color: "#FFB830",
        deity: nil,
        sortOrder: 1
    )
    HStack(spacing: AppSpacing.sm) {
        CategoryTag(category: sample)
        CategoryTag(category: sample2)
    }
    .padding()
}
