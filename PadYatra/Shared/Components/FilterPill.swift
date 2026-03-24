// FilterPill.swift
// Capsule-shaped filter pill used in TempleFilterBar.
// Two styles: .primary (mode pills) and .secondary (category chips).
import SwiftUI

struct FilterPill: View {

    let label: String
    let isSelected: Bool
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary    // larger: sort mode pills
        case secondary  // smaller: category chips
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(style == .primary
                    ? .subheadline.weight(.semibold)
                    : .caption.weight(.semibold))
                .foregroundStyle(textColor)
                .padding(.horizontal, style == .primary ? AppSpacing.md : AppSpacing.sm)
                .padding(.vertical,   style == .primary ? AppSpacing.sm : AppSpacing.xs)
                .background(backgroundFill, in: Capsule())
                .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var textColor: Color {
        switch (style, isSelected) {
        case (.primary, true):   return .white
        case (.secondary, true): return Color.brandSaffron
        default:                 return Color.brandEarthBrown
        }
    }

    private var backgroundFill: Color {
        switch (style, isSelected) {
        case (.primary, true):   return Color.brandSaffron
        case (.secondary, true): return Color.brandSaffron.opacity(0.12)
        default:                 return Color.brandWarmCream
        }
    }

    private var strokeColor: Color {
        switch (style, isSelected) {
        case (.primary, true):   return Color.brandDeepOrange.opacity(0.3)
        case (.secondary, true): return Color.brandSaffron
        default:                 return Color.brandTempleGrey.opacity(0.3)
        }
    }
}
