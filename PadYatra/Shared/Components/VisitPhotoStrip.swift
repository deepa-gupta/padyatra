// VisitPhotoStrip.swift
// Horizontal strip of thumbnails rendered from stored JPEG Data.
// No Photos library permission required.
import SwiftUI

// MARK: - VisitPhotoStrip

struct VisitPhotoStrip: View {

    let photoData: [Data]

    private let thumbSize: CGFloat = 72

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(Array(photoData.enumerated()), id: \.offset) { _, data in
                    PhotoThumb(data: data, size: thumbSize)
                }
            }
        }
    }
}

// MARK: - PhotoThumb

private struct PhotoThumb: View {

    let data: Data
    let size: CGFloat

    private var image: UIImage? { UIImage(data: data) }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.brandTempleGrey.opacity(0.15)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(Color.brandTempleGrey.opacity(0.5))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }
}
