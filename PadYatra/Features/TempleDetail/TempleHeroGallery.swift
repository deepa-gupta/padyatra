// TempleHeroGallery.swift
// Full-width paged image strip for the temple detail hero.
// Three distinct states: loading, no photos found, photos available.
import SwiftUI

// MARK: - TempleHeroGallery

struct TempleHeroGallery: View {

    let imageURLs: [URL]
    let templeName: String
    /// Set to true once the async image fetch has completed (success or empty).
    let isLoaded: Bool

    private let galleryHeight: CGFloat = 260

    var body: some View {
        if !imageURLs.isEmpty {
            // Photos available — show paged gallery
            TabView {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    imageSlide(url: url, index: index, total: imageURLs.count)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: galleryHeight)
            .clipped()
        } else if isLoaded {
            // Fetch completed — no verified photos found for this temple
            noPhotosPlaceholder
        } else {
            // Still loading
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
                    .frame(maxWidth: .infinity)
                    .frame(height: galleryHeight)
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
            .frame(height: galleryHeight)
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
            .frame(height: galleryHeight)
            .accessibilityLabel("No photos available for \(templeName)")
    }

    private var brandedBase: some View {
        LinearGradient(
            colors: [Color.brandSaffron, Color.brandPeach],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Temple Hero Gallery — Loading") {
    TempleHeroGallery(imageURLs: [], templeName: "Somnath Temple", isLoaded: false)
}

#Preview("Temple Hero Gallery — No Photos") {
    TempleHeroGallery(imageURLs: [], templeName: "Somnath Temple", isLoaded: true)
}
