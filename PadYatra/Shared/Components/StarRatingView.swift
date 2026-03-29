// StarRatingView.swift
// Displays 1-5 stars. Supports display-only and interactive editing modes.
import SwiftUI

// MARK: - Mode

enum StarRatingMode {
    /// Read-only — tapping does nothing.
    case display
    /// Interactive — tapping a star updates the binding.
    case interactive(Binding<Int>)
}

// MARK: - StarRatingView

struct StarRatingView: View {

    let rating: Int
    let mode: StarRatingMode
    var starSize: CGFloat = 18

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(1...5, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: starSize))
                    .foregroundStyle(index <= rating ? Color.brandGold : Color.brandTempleGrey.opacity(0.4))
                    .onTapGesture {
                        if case .interactive(let binding) = mode {
                            // Allow tapping the same star to clear the rating (set to 0)
                            binding.wrappedValue = binding.wrappedValue == index ? 0 : index
                            HapticService.lightImpact()
                        }
                    }
                    .accessibilityLabel("\(index) star\(index == 1 ? "" : "s")")
                    .accessibilityAddTraits(index <= rating ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    // MARK: - Private Helpers

    private func starImage(for index: Int) -> Image {
        index <= rating
            ? Image(systemName: "star.fill")
            : Image(systemName: "star")
    }

    private var accessibilityLabel: String {
        switch mode {
        case .display:    return "Rating"
        case .interactive: return "Star rating, interactive"
        }
    }

    private var accessibilityValue: String {
        rating == 0 ? "Not rated" : "\(rating) out of 5"
    }
}

// MARK: - Convenience Initialisers

extension StarRatingView {
    /// Display-only initialiser.
    init(rating: Int, starSize: CGFloat = 18) {
        self.rating = rating
        self.mode = .display
        self.starSize = starSize
    }

    /// Interactive initialiser.
    init(rating: Binding<Int>, starSize: CGFloat = 18) {
        self.rating = rating.wrappedValue
        self.mode = .interactive(rating)
        self.starSize = starSize
    }
}

// MARK: - Preview

#Preview("Star Ratings") {
    @Previewable @State var editableRating = 3

    return VStack(spacing: AppSpacing.lg) {
        // Display modes
        ForEach([0, 1, 3, 5], id: \.self) { r in
            HStack {
                Text("\(r)/5")
                    .frame(width: 40, alignment: .leading)
                    .foregroundStyle(Color.brandEarthBrown)
                StarRatingView(rating: r)
            }
        }

        Divider()

        // Interactive mode
        VStack(spacing: AppSpacing.sm) {
            Text("Tap to rate")
                .font(.caption)
                .foregroundStyle(Color.brandTempleGrey)
            StarRatingView(rating: $editableRating, starSize: 28)
            Text("Selected: \(editableRating)")
                .font(.caption2)
                .foregroundStyle(Color.brandTempleGrey)
        }
    }
    .padding()
}
