// TempleHeroGallery.swift
// Full-width paged image strip for the temple detail hero.
// Images are loaded remotely via AsyncImage; shows a branded gradient
// placeholder while loading or if no URLs are available.
import SwiftUI

// MARK: - TempleHeroGallery

struct TempleHeroGallery: View {

    let imageURLs: [URL]
    let templeName: String

    // MARK: - Constants

    private let galleryHeight: CGFloat = 260

    // MARK: - Body

    var body: some View {
        if imageURLs.isEmpty {
            placeholderGradient
        } else {
            TabView {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    imageSlide(url: url, index: index, total: imageURLs.count)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: galleryHeight)
            .clipped()
        }
    }

    // MARK: - Slide

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
            default:
                placeholderGradient
            }
        }
        .accessibilityLabel("\(templeName) — photo \(index + 1) of \(total)")
    }

    // MARK: - Placeholder

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color.brandSaffron, Color.brandPeach],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(maxWidth: .infinity)
        .frame(height: galleryHeight)
        .overlay(
            Image(systemName: "building.columns")
                .font(.system(size: 52))
                .foregroundStyle(Color.white.opacity(0.7))
        )
    }
}

// MARK: - Preview

#Preview("Temple Hero Gallery") {
    TempleHeroGallery(
        imageURLs: [],
        templeName: "Somnath Temple"
    )
}
