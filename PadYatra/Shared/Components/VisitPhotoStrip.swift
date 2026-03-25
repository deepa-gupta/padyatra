// VisitPhotoStrip.swift
// Horizontal strip of thumbnails loaded from PHAsset local identifiers.
// Uses PHImageManager for fast, cached thumbnail delivery.
import SwiftUI
import Photos

// MARK: - VisitPhotoStrip

struct VisitPhotoStrip: View {

    let assetIDs: [String]

    private let thumbSize: CGFloat = 72

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(assetIDs, id: \.self) { id in
                    PhotoThumb(assetID: id, size: thumbSize)
                }
            }
        }
    }
}

// MARK: - PhotoThumb

private struct PhotoThumb: View {

    let assetID: String
    let size: CGFloat

    @State private var image: UIImage? = nil

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
        .task(id: assetID) {
            image = await loadThumbnail(for: assetID, size: CGSize(width: size * 3, height: size * 3))
        }
    }

    private func loadThumbnail(for id: String, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let results = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
            guard let asset = results.firstObject else {
                continuation.resume(returning: nil)
                return
            }
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
