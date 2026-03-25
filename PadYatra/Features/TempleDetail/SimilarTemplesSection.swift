// SimilarTemplesSection.swift
// "More like this" horizontal scroll at the bottom of a temple detail page.
// Primary match: shared categoryID. Fallback: same state.
import SwiftUI

// MARK: - SimilarTemplesSection

struct SimilarTemplesSection: View {

    let temples: [Temple]
    let visitService: VisitService
    let achievementService: AchievementService

    @EnvironmentObject private var dataService: TempleDataService

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("More Like This")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandEarthBrown)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(temples) { temple in
                        NavigationLink {
                            TempleDetailView(
                                vm: TempleDetailViewModel(
                                    temple: temple,
                                    visitService: visitService,
                                    achievementService: achievementService
                                )
                            )
                        } label: {
                            SimilarTempleCard(
                                temple: temple,
                                isVisited: dataService.visitedTempleIDs.contains(temple.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - SimilarTempleCard

private struct SimilarTempleCard: View {

    let temple: Temple
    let isVisited: Bool

    @State private var thumbURL: URL? = nil

    private let cardWidth: CGFloat = 120
    private let imageHeight: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            AsyncImage(url: thumbURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    placeholderGradient
                default:
                    placeholderGradient.overlay(ProgressView().tint(.white).scaleEffect(0.7))
                }
            }
            .frame(width: cardWidth, height: imageHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if isVisited {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.brandVisited)
                        .padding(AppSpacing.xs)
                }
            }

            Text(temple.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandEarthBrown)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(temple.location.state)
                .font(.caption2)
                .foregroundStyle(Color.brandTempleGrey)
                .lineLimit(1)
        }
        .frame(width: cardWidth)
        .task(id: temple.id) {
            thumbURL = await TempleImageService.shared.thumbnailURL(for: temple)
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color.brandSaffron.opacity(0.4), Color.brandPeach.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
