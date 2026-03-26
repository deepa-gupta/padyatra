// VisitHistorySection.swift
// Shows all recorded visits for a temple with swipe-to-delete and tap-to-edit.
// Each row also has a share button that generates a visit card via VisitShareService.
import SwiftUI

// MARK: - VisitHistorySection

struct VisitHistorySection: View {

    @ObservedObject var vm: TempleDetailViewModel
    @State private var editingVisit: TempleVisit? = nil

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            header

            if vm.visits.isEmpty {
                emptyState
            } else {
                visitList
            }
        }
        .sheet(item: $editingVisit) { visit in
            VisitEditView(vm: vm, visit: visit)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Your Visits (\(vm.visits.count))")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandEarthBrown)

            Spacer()

            Button {
                vm.showingAddVisit = true
            } label: {
                Label("Add Another Visit", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.brandSaffron)
            }
            .accessibilityLabel("Add another visit")
        }
    }

    // MARK: - Visit List

    private var visitList: some View {
        VStack(spacing: AppSpacing.xs) {
            ForEach(vm.visits) { visit in
                VisitRow(temple: vm.temple, visit: visit)
                    .contentShape(Rectangle())
                    .onTapGesture { editingVisit = visit }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            vm.deleteVisit(visit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "mappin.slash")
                .font(.title2)
                .foregroundStyle(Color.brandTempleGrey)

            Text("No visits recorded yet.\nTap Visit to log your first visit.")
                .font(.subheadline)
                .foregroundStyle(Color.brandTempleGrey)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No visits recorded yet. Tap Visit to log your first visit.")
    }
}

// MARK: - VisitRow

struct VisitRow: View {

    let temple: Temple
    let visit: TempleVisit

    @State private var shareItem: ShareableImage? = nil
    @State private var isPreparingShare: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Text(visit.visitedAt.shortVisitDisplay)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandEarthBrown)

                Spacer()

                if visit.isGPSVerified { GPSVerifiedChip() }

                // Share button
                Button {
                    Task { await generateShareCard() }
                } label: {
                    if isPreparingShare {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundStyle(Color.brandTempleGrey)
                    }
                }
                .disabled(isPreparingShare)
                .accessibilityLabel("Share this visit")
            }

            StarRatingView(rating: visit.rating ?? 0)

            if let notes = visit.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(Color.brandEarthBrown.opacity(0.75))
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            if !visit.photoData.isEmpty {
                VisitPhotoStrip(photoData: visit.photoData)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.sm)
        .background(Color.brandWarmCream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .stroke(Color.brandEarthBrown.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .sheet(item: $shareItem) { shareable in
            ActivityViewController(data: shareable.data)
                .ignoresSafeArea()
        }
    }

    // MARK: - Share Card Generation

    private func generateShareCard() async {
        isPreparingShare = true
        defer { isPreparingShare = false }
        guard let data = await VisitShareService.generateCard(temple: temple, visit: visit) else { return }
        shareItem = ShareableImage(data: data)
    }

    private var rowAccessibilityLabel: String {
        var parts = ["Visit on \(visit.visitedAt.shortVisitDisplay)"]
        if let rating = visit.rating { parts.append("\(rating) out of 5 stars") }
        if let notes = visit.notes, !notes.isEmpty { parts.append("Notes: \(notes)") }
        if visit.isGPSVerified { parts.append("GPS verified") }
        return parts.joined(separator: ". ")
    }
}

// MARK: - ActivityViewController

private struct ActivityViewController: UIViewControllerRepresentable {
    let data: Data

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let image = UIImage(data: data) ?? UIImage()
        return UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - GPSVerifiedChip

private struct GPSVerifiedChip: View {
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "location.fill")
                .font(.caption2)
                .foregroundStyle(Color.brandVisited)
            Text("GPS verified")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.brandVisited)
        }
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 2)
        .background(Color.brandVisited.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("GPS verified visit")
    }
}

// MARK: - ShareableImage + Identifiable

extension ShareableImage: Identifiable {
    var id: Int { data.hashValue }
}

// MARK: - Preview

#Preview("Visit History Section — with visits") {
    @Previewable @StateObject var vm = TempleDetailViewModel.preview()

    ScrollView {
        VisitHistorySection(vm: vm)
            .padding()
    }
    .background(Color.brandWarmCream)
    .onAppear { vm.loadVisits() }
}

#Preview("Visit History Section — empty") {
    @Previewable @StateObject var vm = TempleDetailViewModel.preview()

    ScrollView {
        VisitHistorySection(vm: vm)
            .padding()
    }
    .background(Color.brandWarmCream)
}
