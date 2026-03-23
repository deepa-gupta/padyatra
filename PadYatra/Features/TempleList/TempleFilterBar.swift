// TempleFilterBar.swift
// Horizontally scrolling pill buttons for selecting the temple list sort mode.
// When "By Category" is active, a second row of category chips appears below.
import SwiftUI

struct TempleFilterBar: View {

    @Binding var filterMode: TempleFilterMode
    @Binding var selectedCategoryID: String?
    let categories: [TempleCategory]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Sort mode pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(TempleFilterMode.allCases, id: \.self) { mode in
                        pillButton(for: mode)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }

            // Row 2: Category chips (only when By Category is active)
            if filterMode == .byCategory && !categories.isEmpty {
                Divider().padding(.horizontal, AppSpacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        // "All" chip
                        categoryChip(id: nil, name: "All")

                        ForEach(categories) { category in
                            categoryChip(id: category.id, name: category.name)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: filterMode)
    }

    // MARK: - Sort Pill

    @ViewBuilder
    private func pillButton(for mode: TempleFilterMode) -> some View {
        let isSelected = filterMode == mode

        Button {
            filterMode = mode
            if mode != .byCategory { selectedCategoryID = nil }
        } label: {
            Text(mode.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.brandEarthBrown)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    isSelected ? Color.brandSaffron : Color.brandWarmCream,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.brandDeepOrange.opacity(0.3) : Color.brandTempleGrey.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityLabel(mode.rawValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Category Chip

    @ViewBuilder
    private func categoryChip(id: String?, name: String) -> some View {
        let isSelected = selectedCategoryID == id

        Button {
            selectedCategoryID = id
        } label: {
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.brandSaffron : Color.brandEarthBrown)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    isSelected ? Color.brandSaffron.opacity(0.12) : Color.brandWarmCream,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.brandSaffron : Color.brandTempleGrey.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("Filter Bar") {
    @Previewable @State var mode = TempleFilterMode.all
    @Previewable @State var categoryID: String? = nil

    let categories: [TempleCategory] = [
        TempleCategory(id: "c_jyotirlinga", name: "Jyotirlinga", description: "", templeIDs: [], achievementID: nil, iconAssetName: "", color: "#FF6B35", deity: "Shiva", sortOrder: 1),
        TempleCategory(id: "c_shakti", name: "Shakti Peetha", description: "", templeIDs: [], achievementID: nil, iconAssetName: "", color: "#FF6B35", deity: "Devi", sortOrder: 2),
    ]

    return VStack(spacing: AppSpacing.md) {
        TempleFilterBar(filterMode: $mode, selectedCategoryID: $categoryID, categories: categories)
        Text("Mode: \(mode.rawValue), Category: \(categoryID ?? "All")")
            .foregroundStyle(Color.brandEarthBrown)
            .font(.caption)
    }
    .background(Color.brandWarmCream)
}
