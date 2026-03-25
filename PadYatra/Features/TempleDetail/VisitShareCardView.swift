// VisitShareCardView.swift
// Fixed-size card rendered off-screen by VisitShareService via ImageRenderer.
// NOT placed in the live view hierarchy — it is rendered to UIImage then shared.
import SwiftUI

// MARK: - VisitShareCardView

struct VisitShareCardView: View {

    let temple: Temple
    let visit: TempleVisit
    /// Hero image downloaded asynchronously before rendering. Nil = use gradient.
    let heroImage: UIImage?

    // Fixed canvas size for consistent output across all devices
    static let canvasWidth:  CGFloat = 390
    static let canvasHeight: CGFloat = 230

    var body: some View {
        VStack(spacing: 0) {
            // ── Hero ──────────────────────────────────────────────────────────
            ZStack(alignment: .bottomLeading) {
                heroContent
                    .frame(width: Self.canvasWidth, height: 160)
                    .clipped()

                // Gradient scrim so text is legible over any photo
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: Self.canvasWidth, height: 160)

                VStack(alignment: .leading, spacing: 2) {
                    Text(temple.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("\(temple.location.city), \(temple.location.state)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }

            // ── Footer bar ────────────────────────────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Visited \(visit.visitedAt.shortVisitDisplay)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.brandEarthBrown)

                    if let rating = visit.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 9))
                                    .foregroundStyle(star <= rating ? Color.brandGold : Color.brandTempleGrey.opacity(0.4))
                            }
                        }
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "building.columns.fill")
                        .font(.caption2)
                    Text("Pad Yatra")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.brandSaffron)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(width: Self.canvasWidth, height: Self.canvasHeight - 160)
            .background(Color.brandWarmCream)
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    @ViewBuilder
    private var heroContent: some View {
        if let heroImage {
            Image(uiImage: heroImage)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [Color.brandSaffron, Color.brandPeach],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - ShareableImage (Transferable wrapper for sharing UIImage data)

struct ShareableImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { $0.data }
    }
}
