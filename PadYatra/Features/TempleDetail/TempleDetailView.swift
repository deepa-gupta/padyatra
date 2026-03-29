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
                    TempleHeroGallery(
                        imageURLs: imageURLs,
                        templeName: vm.temple.name,
                        isLoaded: imagesLoaded
                    )

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        titleBlock
                        locationRow

                        TempleFactsGrid(facts: vm.temple.facts)
                            .glassSection()

                        descriptionText
                            .glassSection()

                        if !vm.temple.festivals.isEmpty {
                            TempleFestivalSection(festivals: vm.temple.festivals)
                                .glassSection()
                        }

                        VisitHistorySection(vm: vm)
                            .glassSection()

                        if !similarTemples.isEmpty,
                           let vs = visitService,
                           let as_ = achievementService {
                            SimilarTemplesSection(
                                temples: similarTemples,
                                visitService: vs,
                                achievementService: as_
                            )
                            .glassSection()
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl + AppSpacing.xl)
                }
            }
            .safeAreaInset(edge: .bottom) {
                fabArea
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
                    .font(AppFont.templeTitle)
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

    // MARK: - Floating Action Button

    private var fabArea: some View {
        HStack {
            Spacer()
            fabButton
            Spacer()
        }
        .padding(.vertical, AppSpacing.sm)
        .background(
            LinearGradient(
                colors: [Color.brandWarmCream.opacity(0), Color.brandWarmCream.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var fabButton: some View {
        Button { vm.showingAddVisit = true } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                Text("Mark Visited")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(
                LinearGradient(
                    colors: [Color.brandSaffron, Color.brandDeepOrange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .appShadow(.modal)
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
