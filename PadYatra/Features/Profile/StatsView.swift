// StatsView.swift
// Reusable stat tile and category progress row used by ProfileView.
import SwiftUI

// MARK: - StatTile

struct StatTile: View {

    let value: String
    let label: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.brandEarthBrown)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.brandTempleGrey)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.sm)
        .background(Color.brandWarmCream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - CategoryProgressRow

struct CategoryProgressRow: View {

    let name: String
    let visited: Int
    let total: Int

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(visited) / Double(total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.brandEarthBrown)

                Spacer()

                Text("\(visited) / \(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        visited == total ? Color.brandVisited : Color.brandTempleGrey
                    )
            }

            progressBar
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(visited) of \(total) visited")
        .accessibilityValue(visited == total ? "complete" : "\(Int(fraction * 100)) percent")
    }

    private var progressBar: some View {
        ProgressBar(fraction: fraction, height: 6, animated: true)
    }
}

// MARK: - Previews

#Preview("Stat Tile") {
    HStack(spacing: AppSpacing.md) {
        StatTile(value: "42", label: "Temples Visited")
        StatTile(value: "8", label: "States")
        StatTile(value: "3", label: "Achievements")
    }
    .padding(AppSpacing.md)
    .background(Color.brandWarmCream)
}

#Preview("Category Progress Row") {
    VStack(spacing: AppSpacing.md) {
        CategoryProgressRow(name: "Jyotirlinga",  visited: 12, total: 12)
        CategoryProgressRow(name: "Char Dham",    visited: 2,  total: 4)
        CategoryProgressRow(name: "Divya Desam",  visited: 0,  total: 108)
    }
    .padding(AppSpacing.md)
    .background(Color.brandWarmCream)
}
