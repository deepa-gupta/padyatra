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

    private func pillButton(for mode: TempleFilterMode) -> some View {
        FilterPill(label: mode.rawValue, isSelected: filterMode == mode, style: .primary) {
            filterMode = mode
            if mode != .byCategory { selectedCategoryID = nil }
        }
    }

    // MARK: - Category Chip

    private func categoryChip(id: String?, name: String) -> some View {
        FilterPill(label: name, isSelected: selectedCategoryID == id, style: .secondary) {
            selectedCategoryID = id
        }
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
