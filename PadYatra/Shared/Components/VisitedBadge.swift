// VisitedBadge.swift
// Small reusable badge indicating whether a temple has been visited.
import SwiftUI

struct VisitedBadge: View {

    let isVisited: Bool

    // MARK: - Constants

    private let size: CGFloat = 22

    // MARK: - Body

    var body: some View {
        Group {
            if isVisited {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.brandVisited)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(Color.brandTempleGrey)
            }
        }
        .font(.system(size: size))
        .frame(width: size, height: size)
        .accessibilityLabel(isVisited ? "Visited" : "Not visited")
    }
}

// MARK: - Preview

#Preview("Visited and Not Visited") {
    HStack(spacing: AppSpacing.lg) {
        VisitedBadge(isVisited: true)
        VisitedBadge(isVisited: false)
    }
    .padding()
}
