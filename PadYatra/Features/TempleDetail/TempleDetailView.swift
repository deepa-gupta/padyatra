// TempleDetailView.swift
// Full detail page for a single temple.
// Composed from sub-views; the view itself holds no business logic.
import SwiftUI

// MARK: - TempleDetailView

struct TempleDetailView: View {

    @StateObject var vm: TempleDetailViewModel
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var dataService: TempleDataService

    // Injected so SimilarTemplesSection can navigate to new detail views
    var visitService: VisitService? = nil
    var achievementService: AchievementService? = nil

    @State private var imageURLs: [URL] = []
    @State private var imagesLoaded = false
    @State private var similarTemples: [Temple] = []

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TempleHeroGallery(imageURLs: imageURLs, templeName: vm.temple.name, isLoaded: imagesLoaded)

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        titleBlock
                        locationRow

                        Divider().padding(.vertical, AppSpacing.xs)

                        TempleFactsGrid(facts: vm.temple.facts)

                        Divider().padding(.vertical, AppSpacing.xs)

                        descriptionText

                        if !vm.temple.festivals.isEmpty {
                            Divider().padding(.vertical, AppSpacing.xs)
                            TempleFestivalSection(festivals: vm.temple.festivals)
                        }

                        Divider().padding(.vertical, AppSpacing.xs)

                        VisitHistorySection(vm: vm)

                        if !similarTemples.isEmpty, let vs = visitService, let as_ = achievementService {
                            Divider().padding(.vertical, AppSpacing.xs)
                            SimilarTemplesSection(
                                temples: similarTemples,
                                visitService: vs,
                                achievementService: as_
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.lg)
                }
            }

            // Achievement unlock toast
            if !vm.newlyUnlockedAchievements.isEmpty {
                AchievementToastView(achievements: vm.newlyUnlockedAchievements)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.newlyUnlockedAchievements.isEmpty)
        .background(Color.brandWarmCream.ignoresSafeArea())
        .navigationTitle(vm.temple.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { visitButton }
        }
        .sheet(isPresented: $vm.showingAddVisit, onDismiss: { vm.loadVisits() }) {
            AddVisitSheet(vm: vm)
                .environmentObject(locationService)
        }
        .onAppear { vm.loadVisits() }
        .task(id: vm.temple.id) {
            imageURLs = []
            imagesLoaded = false
            similarTemples = vm.similarTemples(from: dataService)
            imageURLs = await TempleImageService.shared.imageURLs(for: vm.temple)
            imagesLoaded = true
        }
        .onChange(of: vm.newlyUnlockedAchievements) { _, newValue in
            guard !newValue.isEmpty else { return }
            HapticService.heavyImpact()
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { vm.dismissUnlockToast() }
            }
        }
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .top) {
                Text(vm.temple.name)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.brandEarthBrown)

                Spacer(minLength: AppSpacing.sm)

                VisitedBadge(isVisited: vm.isVisited)
                    .padding(.top, AppSpacing.xs)
            }

            if let alternateName = vm.temple.alternateName {
                Text(alternateName)
                    .font(.subheadline)
                    .foregroundStyle(Color.brandTempleGrey)
            }

            DeityPill(deity: vm.temple.deity)
                .padding(.top, AppSpacing.xs)
        }
    }

    // MARK: - Location Row

    private var locationRow: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(Color.brandSaffron)

            Text("\(vm.temple.location.city), \(vm.temple.location.state)")
                .font(.subheadline)
                .foregroundStyle(Color.brandEarthBrown)

            if vm.temple.isUNESCO {
                Spacer()
                UNESCOBadge()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(locationAccessibilityLabel)
    }

    // MARK: - Description

    private var descriptionText: some View {
        Text(vm.temple.description)
            .font(.body)
            .foregroundStyle(Color.brandEarthBrown)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(4)
    }

    // MARK: - Visit Button

    private var visitButton: some View {
        Button {
            vm.showingAddVisit = true
        } label: {
            Label("Visit", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandSaffron)
        }
        .accessibilityLabel("Log a visit to \(vm.temple.name)")
    }

    // MARK: - Accessibility

    private var locationAccessibilityLabel: String {
        var label = "\(vm.temple.location.city), \(vm.temple.location.state)"
        if vm.temple.isUNESCO { label += ", UNESCO World Heritage Site" }
        return label
    }
}

// MARK: - DeityPill

private struct DeityPill: View {
    let deity: String

    var body: some View {
        Text(deity)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.brandSaffron)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.brandSaffron.opacity(0.12))
            .clipShape(Capsule())
            .accessibilityLabel("Deity: \(deity)")
    }
}

// MARK: - UNESCOBadge

private struct UNESCOBadge: View {
    var body: some View {
        Text("UNESCO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 2)
            .background(Color.brandGold)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .accessibilityLabel("UNESCO World Heritage Site")
    }
}

// MARK: - Preview

#Preview("Temple Detail View") {
    @Previewable @StateObject var vm = TempleDetailViewModel.preview()
    @Previewable @StateObject var locationService = LocationService()
    @Previewable @StateObject var dataService = TempleDataService()

    NavigationStack {
        TempleDetailView(vm: vm)
            .environmentObject(locationService)
            .environmentObject(dataService)
    }
}
