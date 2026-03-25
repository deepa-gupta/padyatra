// SearchHistoryView.swift
// Shows recent search queries as tappable chips when the search bar is active and empty.
import SwiftUI

// MARK: - SearchHistoryView

struct SearchHistoryView: View {

    let queries: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Recent Searches")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandTempleGrey)
                    .textCase(.uppercase)

                Spacer()

                Button("Clear") {
                    HapticService.lightImpact()
                    onClear()
                }
                .font(.caption)
                .foregroundStyle(Color.brandTempleGrey)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(queries, id: \.self) { query in
                        Button {
                            HapticService.lightImpact()
                            onSelect(query)
                        } label: {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2)
                                Text(query)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Color.brandEarthBrown)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(Color.brandEarthBrown.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .padding(.bottom, AppSpacing.sm)
        .background(Color.brandWarmCream)
    }
}

// MARK: - Preview

#Preview("Search History") {
    SearchHistoryView(
        queries: ["Kedarnath", "Somnath", "Tirupati", "Vaishno Devi"],
        onSelect: { _ in },
        onClear: { }
    )
    .background(Color.brandWarmCream)
}
