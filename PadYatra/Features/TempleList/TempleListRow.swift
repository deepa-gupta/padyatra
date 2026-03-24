// TempleListRow.swift
// A single row in the temple list showing thumbnail, name/location, and visited badge.
import SwiftUI

struct TempleListRow: View {

    let temple: Temple
    let isVisited: Bool

    @State private var thumbnailURL: URL?

    // MARK: - Constants

    private let thumbnailSize: CGFloat = 56
    private let thumbnailCornerRadius: CGFloat = AppRadius.sm

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            thumbnail
            info
            Spacer(minLength: 0)
            VisitedBadge(isVisited: isVisited)
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .task(id: temple.id) {
            thumbnailURL = await TempleImageService.shared.thumbnailURL(for: temple)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnail: some View {
        AsyncImage(url: thumbnailURL) { phase in
            if case .success(let image) = phase {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color.brandSaffron, Color.brandPeach],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "building.columns")
                        .foregroundStyle(Color.white.opacity(0.8))
                        .font(.title3)
                )
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: thumbnailCornerRadius))
    }

    @ViewBuilder
    private var info: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(temple.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandEarthBrown)
                .lineLimit(2)

            Text("\(temple.location.city), \(temple.location.state)")
                .font(.caption)
                .foregroundStyle(Color.brandTempleGrey)
                .lineLimit(1)
        }
    }

    // MARK: - Accessibility

    private var rowAccessibilityLabel: String {
        let visitedState = isVisited ? "Visited" : "Not visited"
        return "\(temple.name), \(temple.deity), \(temple.location.state), \(visitedState)"
    }
}

// MARK: - Preview

#Preview("Temple List Row") {
    let sampleTemple = Temple(
        id: "somnath",
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
        categoryIDs: ["jyotirlinga"],
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
            heroImageName: "somnath_hero",
            galleryImageNames: [],
            thumbnailImageName: "somnath_thumb",
            remoteHeroURL: nil
        ),
        festivals: [],
        significance: .jyotirlinga,
        isUNESCO: false,
        sourceURL: nil
    )

    List {
        TempleListRow(temple: sampleTemple, isVisited: true)
        TempleListRow(temple: sampleTemple, isVisited: false)
    }
    .listStyle(.plain)
}
