// VisitShareService.swift
// Generates a shareable UIImage card for a temple visit using ImageRenderer.
// Must be called on the main actor (ImageRenderer requirement).
import SwiftUI
import OSLog

// MARK: - VisitShareService

@MainActor
enum VisitShareService {

    private static let logger = Logger(subsystem: "com.padyatra", category: "VisitShareService")

    /// Generates a visit share card and returns its JPEG data, or nil on failure.
    /// Downloads the temple hero image first, then renders synchronously.
    static func generateCard(temple: Temple, visit: TempleVisit) async -> Data? {
        // 1. Try to fetch and download the hero image
        var heroImage: UIImage? = nil
        let urls = await TempleImageService.shared.imageURLs(for: temple)
        if let firstURL = urls.first,
           let (data, _) = try? await URLSession.shared.data(from: firstURL) {
            heroImage = UIImage(data: data)
        }

        // 2. Render the card view to UIImage
        let card = VisitShareCardView(temple: temple, visit: visit, heroImage: heroImage)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        renderer.proposedSize = ProposedViewSize(
            width:  VisitShareCardView.canvasWidth,
            height: VisitShareCardView.canvasHeight
        )

        guard let uiImage = renderer.uiImage,
              let jpeg = uiImage.jpegData(compressionQuality: 0.85)
        else {
            logger.error("ImageRenderer failed for temple '\(temple.id)'.")
            return nil
        }

        logger.debug("Share card generated for '\(temple.id)' (\(jpeg.count) bytes).")
        return jpeg
    }
}
