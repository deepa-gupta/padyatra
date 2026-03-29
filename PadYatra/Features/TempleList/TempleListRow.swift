// TempleListRow.swift
// Full-width editorial card for the temple list.
// Hero image with gradient overlay, serif name, location strip.
import SwiftUI

struct TempleListRow: View {

    let temple: Temple
    let isVisited: Bool
    /// Stagger delay for entrance animation — set by the list view based on index.
    var animationDelay: Double = 0

    @State private var heroURL: URL?
    @State private var appeared = false

    private let cardImageHeight: CGFloat = 200

    // MARK: - Body

    var body: some View {
        cardContent
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.25)
                    .delay(min(animationDelay, 0.3))
                ) { appeared = true }
            }
            .task(id: temple.id) {
                heroURL = await TempleImageService.shared.thumbnailURL(for: temple)
            }
    }

    // MARK: - Card Shell

    private var cardContent: some View {
        VStack(spacing: 0) {
            heroImage
            bottomStrip
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .appShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        ZStack {
            AsyncImage(url: heroURL) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color.brandSaffron, Color.brandPeach],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "building.columns")
                            .font(.largeTitle)
                            .foregroundStyle(Color.white.opacity(0.6))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // Dark gradient at bottom for text legibility
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.35),
                    .init(color: Color.brandEarthBrown.opacity(0.72), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: cardImageHeight)
        .overlay(alignment: .bottomLeading) { imageBottomInfo }
        .overlay(alignment: .topTrailing) { imageTopBadges }
    }

    // MARK: - Image Overlays

    private var imageBottomInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(temple.name)
                .font(AppFont.templeName)
                .foregroundStyle(Color.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

            Text(temple.deity)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
    }

    private var imageTopBadges: some View {
        Group {
            if isVisited {
                VisitedBadge(isVisited: true)
            }
        }
        .padding(AppSpacing.sm)
    }

    // MARK: - Bottom Strip

    private var bottomStrip: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption2)
                .foregroundStyle(Color.brandSaffron)

            Text("\(temple.location.city), \(temple.location.state)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.brandTempleGrey)

            Spacer()

            if temple.isUNESCO {
                Text("UNESCO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.brandGold)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.white)
    }

    // MARK: - Accessibility

    private var rowAccessibilityLabel: String {
        let visitedState = isVisited ? "Visited" : "Not visited"
        return "\(temple.name), \(temple.deity), \(temple.location.state), \(visitedState)"
    }
}

// MARK: - Preview

#Preview("Temple List Row — Card") {
    let sampleTemple = Temple(
        id: "t_somnath",
        slug: "somnath",
        legacyIDs: [],
        isActive: true,
        name: "Somnath Temple",
        alternateName: "Somanatha",
        deity: "Shiva",
        location: TempleLocation(
            latitude: 20.8880,
            longitude: 70.4014,
            city: "Veraval",
            district: "Gir Somnath",
            state: "Gujarat",
            country: "India",
            address: nil,
            pincode: nil
        ),
        categoryIDs: ["c_jyotirlinga"],
        description: "First of the twelve Jyotirlinga shrines.",
        shortDescription: "First Jyotirlinga.",
        facts: TempleFacts(
            established: "Unknown antiquity",
            dynasty: nil,
            architectureStyle: "Chaulukya",
            openingMonth: nil,
            closingMonth: nil,
            altitude: nil,
            dresscode: "Traditional attire",
            photographyAllowed: false,
            entryFee: "Free",
            darshanaTimings: "6:00 AM – 9:30 PM"
        ),
        images: TempleImages(
            heroImageName: "",
            galleryImageNames: [],
            thumbnailImageName: "",
            remoteHeroURL: nil
        ),
        festivals: [],
        significance: .jyotirlinga,
        isUNESCO: false,
        sourceURL: nil
    )

    VStack(spacing: AppSpacing.md) {
        TempleListRow(temple: sampleTemple, isVisited: true)
        TempleListRow(temple: sampleTemple, isVisited: false)
    }
    .padding(AppSpacing.md)
    .background(Color.brandWarmCream)
}
