// AddVisitSheet.swift
// Sheet for logging a new visit to a temple.
import SwiftUI
import OSLog

// MARK: - AddVisitSheet

struct AddVisitSheet: View {

    @ObservedObject var vm: TempleDetailViewModel
    @EnvironmentObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var visitedAt: Date = .now
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var isGPSVerified: Bool = false
    @State private var selectedPhotoData: [Data] = []
    @State private var showingPhotoPicker: Bool = false

    // MARK: - Constants

    private let maxDate: Date = .now
    private let logger = Logger(subsystem: "com.padyatra", category: "AddVisitSheet")

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                dateSection
                ratingSection
                notesSection
                photoSection
                if locationService.userLocation != nil {
                    gpsSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.brandWarmCream)
            .navigationTitle("Log Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.brandEarthBrown)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brandSaffron)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerRepresentable { data in
                    selectedPhotoData = data
                }
                .ignoresSafeArea()
            }
            .onAppear { autoSetGPS() }
        }
    }

    // MARK: - Sections

    private var dateSection: some View {
        Section {
            DatePicker(
                "Date Visited",
                selection: $visitedAt,
                in: ...maxDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .tint(Color.brandSaffron)
            .foregroundStyle(Color.brandEarthBrown)
        } header: {
            FormSectionHeader(text: "When did you visit?")
        }
        .listRowBackground(Color.brandWarmCream)
    }

    private var ratingSection: some View {
        Section {
            HStack {
                Text("Rating")
                    .foregroundStyle(Color.brandEarthBrown)
                Spacer()
                StarRatingView(rating: $rating, starSize: 24)
            }
        } header: {
            FormSectionHeader(text: "How was your experience?")
        }
        .listRowBackground(Color.brandWarmCream)
    }

    private var notesSection: some View {
        Section {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...8)
                .foregroundStyle(Color.brandEarthBrown)
                .tint(Color.brandSaffron)
        } header: {
            FormSectionHeader(text: "Notes (optional)")
        }
        .listRowBackground(Color.brandWarmCream)
    }

    private var photoSection: some View {
        Section {
            if !selectedPhotoData.isEmpty {
                VisitPhotoStrip(photoData: selectedPhotoData)
                    .padding(.vertical, AppSpacing.xs)
            }
            Button {
                showingPhotoPicker = true
            } label: {
                Label(
                    selectedPhotoData.isEmpty ? "Add Photos" : "Change Photos (\(selectedPhotoData.count))",
                    systemImage: "photo.on.rectangle.angled"
                )
                .foregroundStyle(Color.brandSaffron)
            }
        } header: {
            FormSectionHeader(text: "Photos (optional)")
        }
        .listRowBackground(Color.brandWarmCream)
    }

    private var gpsSection: some View {
        Section {
            Toggle(isOn: $isGPSVerified) {
                Label {
                    Text("GPS Verified")
                        .foregroundStyle(Color.brandEarthBrown)
                } icon: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color.brandSaffron)
                }
            }
            .tint(Color.brandSaffron)
        } header: {
            FormSectionHeader(text: "Location")
        } footer: {
            Text("Enable if you are at or near the temple right now.")
                .font(.caption)
                .foregroundStyle(Color.brandTempleGrey)
        }
        .listRowBackground(Color.brandWarmCream)
    }

    // MARK: - Helpers

    private func save() {
        let effectiveNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        vm.markVisited(
            notes: effectiveNotes.isEmpty ? nil : effectiveNotes,
            rating: rating == 0 ? nil : rating,
            photoData: selectedPhotoData,
            isGPSVerified: isGPSVerified
        )
        dismiss()
    }

    /// Auto-sets GPS verified if user is within 500m of the temple.
    private func autoSetGPS() {
        guard let distance = locationService.distance(to: vm.temple) else { return }
        isGPSVerified = distance <= 500
        logger.info("Auto GPS verified=\(self.isGPSVerified) (distance: \(distance)m) for '\(self.vm.temple.id)'.")
    }
}

// MARK: - Preview

#Preview("Add Visit Sheet") {
    @Previewable @StateObject var vm = TempleDetailViewModel.preview()
    @Previewable @StateObject var locationService = LocationService()

    AddVisitSheet(vm: vm)
        .environmentObject(locationService)
}
