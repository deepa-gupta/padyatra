// TempleHeroGallery.swift
// Full-width paged image strip for the temple detail hero.
import SwiftUI

// MARK: - TempleHeroGallery

struct TempleHeroGallery: View {

    let images: TempleImages
    let templeName: String

    // MARK: - Constants

    private let galleryHeight: CGFloat = 260

    // MARK: - Body

    var body: some View {
        let allImages = allImageNames()

        TabView {
            ForEach(Array(allImages.enumerated()), id: \.offset) { index, imageName in
                imageSlide(named: imageName, index: index, total: allImages.count)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: galleryHeight)
        .clipped()
    }

    // MARK: - Slide

    @ViewBuilder
    private func imageSlide(named imageName: String, index: Int, total: Int) -> some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: galleryHeight)
                .clipped()
                .accessibilityLabel("\(templeName) — photo \(index + 1) of \(total)")
        } else {
            placeholderGradient
                .accessibilityLabel("\(templeName) — photo \(index + 1) of \(total)")
        }
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

    // MARK: - Helpers

    /// Returns hero image followed by gallery images, deduplicating as needed.
    private func allImageNames() -> [String] {
        var result = [images.heroImageName]
        for name in images.galleryImageNames where name != images.heroImageName {
            result.append(name)
        }
        return result
    }
}

// MARK: - Preview

#Preview("Temple Hero Gallery") {
    TempleHeroGallery(
        images: TempleImages(
            heroImageName: "somnath_hero",
            galleryImageNames: ["somnath_gallery_1", "somnath_gallery_2"],
            thumbnailImageName: "somnath_thumb"
        ),
        templeName: "Somnath Temple"
    )
}
