// TempleDetailPreviewFixtures.swift
// Shared preview fixtures and ViewModel factory for TempleDetail SwiftUI previews.
// Extracted to keep TempleDetailView.swift under the 300-line limit.
import SwiftUI

// MARK: - TempleDetailViewModel Preview Extension

extension TempleDetailViewModel {
    /// Returns a pre-configured view model suitable for SwiftUI previews.
    /// Uses PersistenceController.preview (in-memory) so no live CloudKit is needed.
    @MainActor
    static func preview() -> TempleDetailViewModel {
        let temple = PreviewFixtures.somnathTemple
        let context = PersistenceController.preview.container.mainContext
        let dataService = TempleDataService()
        let visitService = VisitService(modelContext: context, templeDataService: dataService)
        let achievementService = AchievementService(modelContext: context, templeDataService: dataService)
        return TempleDetailViewModel(
            temple: temple,
            visitService: visitService,
            achievementService: achievementService
        )
    }
}

// MARK: - Preview Fixtures

/// Shared static fixtures used across all TempleDetail previews.
enum PreviewFixtures {
    static let somnathTemple = Temple(
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
            address: "Prabhas Patan, Veraval",
            pincode: "362268"
        ),
        categoryIDs: ["jyotirlinga"],
        description: """
        Somnath is one of the twelve Jyotirlinga shrines of Shiva. Located on the western \
        coast of Gujarat at Prabhas Patan, Veraval, the temple has been destroyed and rebuilt \
        multiple times over the centuries, and stands today as a magnificent example of \
        Chaulukya architectural style.
        """,
        shortDescription: "First of the twelve Jyotirlinga shrines.",
        facts: TempleFacts(
            established: "Unknown antiquity",
            dynasty: "Chaulukya",
            architectureStyle: "Solanki",
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
            galleryImageNames: ["somnath_gallery_1", "somnath_gallery_2"],
            thumbnailImageName: "somnath_thumb",
            remoteHeroURL: nil
        ),
        festivals: [
            TempleFestival(
                name: "Mahashivratri",
                approximateMonth: 2,
                isLunar: true,
                description: "The great night of Shiva. All-night vigils and special darshan.",
                significance: .high
            )
        ],
        significance: .jyotirlinga,
        isUNESCO: false,
        sourceURL: "https://somnath.org"
    )
}
