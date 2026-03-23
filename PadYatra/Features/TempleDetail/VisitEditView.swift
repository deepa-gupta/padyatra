// VisitEditView.swift
// Sheet for editing an existing TempleVisit.
// Pre-fills all fields from the visit; includes a destructive delete button.
import SwiftUI
import OSLog

// MARK: - VisitEditView

struct VisitEditView: View {

    @ObservedObject var vm: TempleDetailViewModel
    let visit: TempleVisit

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var visitedAt: Date
    @State private var rating: Int
    @State private var notes: String
    @State private var showingDeleteAlert: Bool = false

    private let logger = Logger(subsystem: "com.padyatra", category: "VisitEditView")

    // MARK: - Init

    init(vm: TempleDetailViewModel, visit: TempleVisit) {
        self.vm = vm
        self.visit = visit
        _visitedAt = State(initialValue: visit.visitedAt)
        _rating = State(initialValue: visit.rating ?? 0)
        _notes = State(initialValue: visit.notes ?? "")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                dateSection
                ratingSection
                notesSection
                deleteSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.brandWarmCream)
            .navigationTitle("Edit Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.brandEarthBrown)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandSaffron)
                }
            }
            .alert("Delete This Visit?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    vm.deleteVisit(visit)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This visit will be permanently removed. This action cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private var dateSection: some View {
        Section {
            DatePicker(
                "Date Visited",
                selection: $visitedAt,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .tint(Color.brandSaffron)
            .foregroundStyle(Color.brandEarthBrown)
        } header: {
            sectionHeader("When did you visit?")
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
            sectionHeader("How was your experience?")
        }
        .listRowBackground(Color.brandWarmCream)
    }

    private var notesSection: some View {
        Section {
            TextField(
                "Notes",
                text: $notes,
                axis: .vertical
            )
            .lineLimit(3...8)
            .foregroundStyle(Color.brandEarthBrown)
            .tint(Color.brandSaffron)
        } header: {
            sectionHeader("Notes (optional)")
        }
        .listRowBackground(Color.brandWarmCream)
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete This Visit", systemImage: "trash")
                        .font(.body.weight(.medium))
                    Spacer()
                }
            }
            .foregroundStyle(Color.red)
        }
        .listRowBackground(Color.brandWarmCream)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.brandTempleGrey)
            .textCase(nil)
    }

    private func save() {
        let effectiveNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        vm.update(
            visit,
            visitedAt: visitedAt,
            notes: effectiveNotes.isEmpty ? nil : effectiveNotes,
            rating: rating == 0 ? nil : rating
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview("Visit Edit View") {
    @Previewable @StateObject var vm = TempleDetailViewModel.preview()

    let sampleVisit = TempleVisit(
        templeID: "somnath",
        visitedAt: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now,
        notes: "Breathtaking view from the cliff. Evening aarti was unforgettable.",
        rating: 5,
        isGPSVerified: true
    )

    VisitEditView(vm: vm, visit: sampleVisit)
}
