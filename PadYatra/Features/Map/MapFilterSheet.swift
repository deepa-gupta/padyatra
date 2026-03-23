// MapFilterSheet.swift
// Bottom sheet for filtering and sorting the temple map.
// Presented from the filter FAB in MapView.
import SwiftUI

struct MapFilterSheet: View {

    @ObservedObject var vm: MapViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    filterSection
                    if vm.filterMode == .byCategory {
                        categorySection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(AppSpacing.lg)
                .animation(.easeInOut(duration: 0.2), value: vm.filterMode)
            }
            .background(Color.brandWarmCream.ignoresSafeArea())
            .navigationTitle("Filter Temples")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        vm.filterMode = .all
                        vm.selectedCategoryID = nil
                    }
                    .foregroundStyle(
                        vm.filterMode == .all ? Color.brandTempleGrey : Color.brandSaffron
                    )
                    .disabled(vm.filterMode == .all)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandSaffron)
                }
            }
        }
    }

    // MARK: - Filter Mode Section

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Show")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandTempleGrey)
                .textCase(.uppercase)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: AppSpacing.sm
            ) {
                ForEach(TempleFilterMode.allCases, id: \.self) { mode in
                    filterModeButton(for: mode)
                }
            }
        }
    }

    @ViewBuilder
    private func filterModeButton(for mode: TempleFilterMode) -> some View {
        let isSelected = vm.filterMode == mode

        Button {
            vm.filterMode = mode
            if mode == .nearMe {
                vm.zoomToUserLocation()
                dismiss()
            } else if mode != .byCategory {
                vm.selectedCategoryID = nil
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: modeIcon(for: mode))
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Color.white : Color.brandSaffron)
                    .frame(width: 20)

                Text(mode.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.brandEarthBrown)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                isSelected ? Color.brandSaffron : Color.white,
                in: RoundedRectangle(cornerRadius: AppRadius.sm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .strokeBorder(
                        isSelected ? Color.brandDeepOrange.opacity(0.3) : Color.brandTempleGrey.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(mode.rawValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func modeIcon(for mode: TempleFilterMode) -> String {
        switch mode {
        case .all:        return "map"
        case .nearMe:     return "location.fill"
        case .byCategory: return "square.grid.2x2"
        case .visited:    return "checkmark.seal.fill"
        case .notVisited: return "mappin"
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Category")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandTempleGrey)
                .textCase(.uppercase)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: AppSpacing.sm
            ) {
                categoryChip(id: nil, name: "All")
                ForEach(vm.availableCategories) { category in
                    categoryChip(id: category.id, name: category.name)
                }
            }
        }
    }

    @ViewBuilder
    private func categoryChip(id: String?, name: String) -> some View {
        let isSelected = vm.selectedCategoryID == id

        Button {
            vm.selectedCategoryID = id
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? Color.brandSaffron : Color.brandEarthBrown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.brandSaffron)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
            .background(
                isSelected ? Color.brandSaffron.opacity(0.1) : Color.white,
                in: RoundedRectangle(cornerRadius: AppRadius.sm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .strokeBorder(
                        isSelected ? Color.brandSaffron : Color.brandTempleGrey.opacity(0.15),
                        lineWidth: isSelected ? 1.5 : 1
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

#Preview("Map Filter Sheet") {
    let dataService = TempleDataService()
    let locationService = LocationService()
    let vm = MapViewModel(dataService: dataService, locationService: locationService)

    return MapFilterSheet(vm: vm)
}
