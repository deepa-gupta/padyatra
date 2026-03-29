// TempleHeroGallery.swift
// Full-width paged image strip for the temple detail hero.
// Three states: loading, no photos found, photos available.
// Wraps content in GeometryReader for a parallax scroll effect.
import SwiftUI

// MARK: - TempleHeroGallery

struct TempleHeroGallery: View {

    let imageURLs: [URL]
    let templeName: String
    /// Set to true once the async image fetch has completed (success or empty).
    let isLoaded: Bool

    private let galleryHeight: CGFloat = 280

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            heroContent(geo: geo)
                // Pull-to-stretch: grow taller and pin to top edge.
                // Scroll-up parallax: move at 40% of scroll speed.
                .frame(
                    width: geo.size.width,
                    height: galleryHeight + max(0, minY)
                )
                .offset(y: minY > 0 ? -minY : minY * 0.4)
        }
        .frame(height: galleryHeight)
        .clipped()
    }

    // MARK: - Hero Content

    @ViewBuilder
    private func heroContent(geo: GeometryProxy) -> some View {
        if !imageURLs.isEmpty {
            TabView {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    imageSlide(url: url, index: index, total: imageURLs.count)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        } else if isLoaded {
            noPhotosPlaceholder
        } else {
            loadingPlaceholder
        }
    }

    // MARK: - Image Slide

    @ViewBuilder
    private func imageSlide(url: URL, index: Int, total: Int) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            case .failure:
                noPhotosPlaceholder
            default:
                loadingPlaceholder
            }
        }
        .accessibilityLabel("\(templeName) — photo \(index + 1) of \(total)")
    }

    // MARK: - Placeholders

    private var loadingPlaceholder: some View {
        brandedBase
            .overlay(
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            )
    }

    private var noPhotosPlaceholder: some View {
        brandedBase
            .overlay(
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Text("No photos available for \(templeName)")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }
            )
            .accessibilityLabel("No photos available for \(templeName)")
    }

    private var brandedBase: some View {
        LinearGradient(
            colors: [Color.brandSaffron, Color.brandPeach],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Temple Hero Gallery — Loading") {
    TempleHeroGallery(imageURLs: [], templeName: "Somnath Temple", isLoaded: false)
}

#Preview("Temple Hero Gallery — No Photos") {
    TempleHeroGallery(imageURLs: [], templeName: "Somnath Temple", isLoaded: true)
}
